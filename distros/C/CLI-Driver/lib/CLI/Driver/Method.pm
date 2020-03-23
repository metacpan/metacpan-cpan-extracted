package CLI::Driver::Method;

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

1;
