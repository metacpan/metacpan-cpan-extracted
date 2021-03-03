package CLI::Driver::Class;

use Modern::Perl;
use Moose;
use namespace::autoclean;
use Kavorka '-all';
use Data::Printer alias => 'pdump';
use CLI::Driver::Option;

with
  'CLI::Driver::CommonRole',
  'CLI::Driver::ArgParserRole';
  
###############################
###### PUBLIC ATTRIBUTES ######
###############################

has name => ( is => 'rw' );

has attr => (
	is      => 'rw',
	isa     => 'ArrayRef[CLI::Driver::Option]',
	default => sub { [] }
);

has 'use_argv_map' => ( is => 'rw', isa => 'Bool' );

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

########################################################

__PACKAGE__->meta->make_immutable;

1;
