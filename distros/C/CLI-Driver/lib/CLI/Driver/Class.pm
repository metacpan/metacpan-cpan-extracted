package CLI::Driver::Class;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Method::Signatures;
use Data::Printer alias => 'pdump';
use CLI::Driver::Option;

with 'CLI::Driver::CommonRole';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has name => ( is => 'rw' );

has attr => (
	is      => 'rw',
	isa     => 'ArrayRef[CLI::Driver::Option]',
	default => sub { [] }
);

############################
###### PUBLIC METHODS ######
############################

method parse (HashRef :$href!) {

	# self->name
	if ( !$href->{name} ) {
		$self->warn("failed to find class name");
		return 0;    # failed
	}
	else {
		$self->name( $href->{name} );
	}

	# self->attr
	my $attr = $self->_parse_attrs( href => $href );
	if ( !$attr ) {
		return 0;    # failed
	}
	else {
		$self->attr($attr);
	}

	return 1;        # success
}

method find_req_attrs (Bool :$hard = 1, 
                       Bool :$soft = 1) {

	my @req;
	my @opts = @{ $self->attr };

	foreach my $opt (@opts) {

		if ( $opt->is_required ) {

			if ( $hard and $opt->is_hard ) {
				push @req, $opt;
			}
			elsif ( $soft and $opt->is_soft ) {
				push @req, $opt;
			}
			else {
				# drop it
			}
		}
	}

	return @req;
}

method find_opt_attrs {

	my @attr;
	my @opts = @{ $self->attr };

	foreach my $opt (@opts) {

		if ( $opt->is_optional ) {

			push @attr, $opt;
		}
	}

	return @attr;
}

method get_signature {

	my %return;
	my @opts = @{ $self->attr };

	foreach my $opt (@opts) {

		my %sig  = $opt->get_signature;
		my @keys = keys %sig;

		if ( @keys == 1 ) {
			# happy path
			my $key = shift @keys;
			$return{$key} = $sig{$key};
		}
		elsif ( @keys > 1 ) {
			confess "should not get here";
		}
		elsif ( $opt->is_required and $opt->is_hard ) {
			my $msg = sprintf( "missing args: -%s <%s>",
				$opt->cli_arg, $opt->method_arg );
			confess $msg;
		}
	}

	return %return;
}

###

method _parse_req_attrs (HashRef :$type_href) {

	my @ret;

	foreach my $subtype ( keys %$type_href ) {

		my $hard;
		if ( $subtype eq 'hard' ) {
			$hard = 1;
		}
		elsif ( $subtype eq 'soft' ) {
			$hard = 0;
		}
		else {
			$self->warn("unrecognized required arg subtype: $subtype");
		}

		my $subtype_href = $type_href->{$subtype};

		foreach my $cli_arg ( keys %$subtype_href ) {

			my $method_arg = $subtype_href->{$cli_arg};
			my $opt        = CLI::Driver::Option->new(
				required   => 1,
				hard       => $hard,
				cli_arg    => $cli_arg,
				method_arg => $method_arg
			);

			push @ret, $opt;
		}
	}

	return @ret;
}

method _parse_opt_attrs (HashRef :$type_href) {

	my @ret;

	foreach my $cli_arg ( keys %$type_href ) {

		my $method_arg = $type_href->{$cli_arg};

		my $opt = CLI::Driver::Option->new(
			required   => 0,
			cli_arg    => $cli_arg,
			method_arg => $method_arg
		);

		push @ret, $opt;
	}

	return @ret;
}

method _parse_flag_attrs (HashRef :$type_href) {

	my @ret;

	foreach my $cli_arg ( keys %$type_href ) {

		my $method_arg = $type_href->{$cli_arg};

		my $opt = CLI::Driver::Option->new(
			required   => 0,
			cli_arg    => $cli_arg,
			method_arg => $method_arg,
			flag       => 1,
		);

		push @ret, $opt;
	}

	return @ret;
}

method _parse_attrs (HashRef :$href!) {

	my @attr;

	my $attr_href = defined $href->{attr} ? $href->{attr} : {};
	foreach my $type ( keys %$attr_href ) {

		my $type_href = $attr_href->{$type};

		if ( defined $type_href ) {
			if ( $type =~ /^opt/ ) {
				my @opt = $self->_parse_opt_attrs( type_href => $type_href );
				push @attr, @opt;
			}
			elsif ( $type =~ /^req/ ) {
				my @req = $self->_parse_req_attrs( type_href => $type_href );
				push @attr, @req;
			}
			elsif ( $type =~ /^flag/ ) {
				my @flag = $self->_parse_flag_attrs( type_href => $type_href );
				push @attr, @flag;
			}
			else {
				$self->warn("unrecognized type: $type");
			}
		}
	}

	return \@attr;
}

1;
