package CookBookA::Ex2;

require DynaLoader;
require Exporter;
@ISA = qw( Exporter DynaLoader );

$VERSION = '49.1';

# Perl variable which will be tied to a C variable.  This must be declared
# before it is exported, otherwise the tie() won't work.  The tie happens
# later.
$ex2_debug_c = 0;

@EXPORT = qw( ex2_debug_p ex2_debug_c $ex2_debug_p $ex2_debug_c );

# variable living on Perl side.
$ex2_debug_p = 77;

bootstrap CookBookA::Ex2 $VERSION;

# A tie() interface to share a variable living on the C side.
sub TIESCALAR {
	my $type = shift;
	my $x;
	bless \$x, $type;
}

sub STORE {
	my $self = shift;
	my $val = shift;
	ex2_debug_c( $val );
}

sub FETCH {
	my $self = shift;
	my $ret;
	$ret = ex2_debug_c();
	$ret;
}

# Here's the tie'd variable.
tie( $ex2_debug_c, 'CookBookA::Ex2' ) || die "Tie of CookBookA::Ex2 failed";

1;
