package CLI::Driver::Method;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use CLI::Driver::Option;

with 'CLI::Driver::CommonRole';

###############################
###### PUBLIC ATTRIBUTES ######
###############################

has name => ( is => 'rw' );

has args => (
	is      => 'rw',
	isa     => 'ArrayRef[CLI::Driver::Option]',
	default => sub { [] }
);

method parse (HashRef :$href!) {

	# self->name
	if ( !$href->{name} ) {
		$self->warn("failed to find method name");
		return 0;    # failed
	}
	else {
		$self->name( $href->{name} );
	}

	# self->args
	my $args = $self->_parse_args( href => $href );
	if ( !$args ) {
		return 0;    # failed
	}
	else {
		$self->args($args);
	}

	return 1;        # success
}

method get_signature {

	my %return;
	my @opts = @{ $self->args };

	foreach my $opt (@opts) {

		my %sig  = $opt->get_signature;
		my @keys = keys %sig;

		if ( @keys == 1 ) {
			my $key = shift @keys;
			$return{$key} = $sig{$key};
		}
		elsif ( @keys > 1 ) {
			confess "should not get here";
		}
		elsif ( $opt->required and $opt->is_hard ) {
			my $msg = sprintf( "missing args: -%s <%s>",
				$opt->cli_arg, $opt->method_arg );
			confess $msg;				
		}
	}

	return %return;
}

method _parse_req_args (HashRef :$type_href) {

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

method _parse_opt_args (HashRef :$type_href) {

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

method _parse_flag_args (HashRef :$type_href) {

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

method _parse_args (HashRef :$href!) {

	my @args;

	my $args_href = defined $href->{args} ? $href->{args} : {};

	foreach my $type ( keys %$args_href ) {

		my $type_href = $args_href->{$type};

		if ( defined $type_href ) {
			if ( $type =~ /^opt/ ) {
				my @opt = $self->_parse_opt_args( type_href => $type_href );
				push @args, @opt;
			}
			elsif ( $type =~ /^req/ ) {
				my @req = $self->_parse_req_args( type_href => $type_href );
				push @args, @req;
			}
			elsif ( $type =~ /^flag/ ) {
				my @flag = $self->_parse_flag_args( type_href => $type_href );
				push @args, @flag;
			}
			else {
				$self->warn("unrecognized type: $type");
			}
		}
	}

	return \@args;
}

1;

1;
