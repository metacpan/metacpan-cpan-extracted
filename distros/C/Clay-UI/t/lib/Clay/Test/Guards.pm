package Clay::Test::Guards;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
use Test2::Tools::Exception qw(dies);

use Clay::XS ();

our $VERSION = '0.01';

our @EXPORT_OK = qw(call_guarded call_with_fewest_arguments guarded_names);

# Perl's own arity check of an XSUB croaks "Usage: ..." before the body
# runs; no export takes more arguments than this.
my $MAX_ARGUMENTS = 6;

my $GUARDS = Clay::XS::_wrapper_guards();

# The exports whose wrapper guard row satisfies $predicate, sorted.
sub guarded_names ($predicate) {
	return sort grep { $predicate->( $GUARDS->{$_} ) } keys %$GUARDS;
}

# Calls Clay::XS::$name with the fewest copies of $filler its signature
# accepts (0, 1, 2, ... arguments, until the croak is no longer perl's
# "Usage:" one) and returns what the call returned in list context. Any
# other error is rethrown.
sub call_with_fewest_arguments ($name, $filler) {
	my $function = Clay::XS->can($name) or die "Clay::XS has no function $name\n";
	for my $count ( 0 .. $MAX_ARGUMENTS ) {
		my @result;
		# An undef filler that gets past the guard is read as an argument.
		no warnings 'uninitialized';
		my $error = dies { @result = $function->( ($filler) x $count ) };
		return @result unless defined $error;
		die $error unless $error =~ /^Usage: /;
	}
	die "$name: no call with up to $MAX_ARGUMENTS arguments got past its Usage check\n";
}

# Calls Clay::XS::$name with as many undef arguments as it needs. Every
# wrapper guard runs before the arguments are read, so the first error
# that is not a Usage one is the guard's, if the guard refuses the call.
sub call_guarded ($name) {
	return call_with_fewest_arguments( $name, undef );
}

1;
