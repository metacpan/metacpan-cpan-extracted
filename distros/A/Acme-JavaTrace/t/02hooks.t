use strict; use Test;
BEGIN { plan tests => 6 }

# Explicitely set the WARN and DIE hooks to DEFAULT.
$SIG{'__WARN__'} = 'DEFAULT';
$SIG{'__DIE__' } = 'DEFAULT';

# Check that it's okay.
ok( $SIG{'__WARN__'}, 'DEFAULT' );  #01
ok( $SIG{'__DIE__' }, 'DEFAULT' );  #02

# Now load Acme::JavaTrace...
require Acme::JavaTrace;

# ... and check that the hooks are now pointing to some Perl code.
ok( ref $SIG{'__WARN__'}, 'CODE' );  #03
ok( ref $SIG{'__DIE__' }, 'CODE' );  #04


# Now check that Acme::JavaTrace is working as expected.
# For this, we define a few functions that call each others using 
# the differents mechanisms available in Perl. 
sub first_caller  { second_caller(@_) }
sub second_caller { third_caller(@_) }
sub third_caller  { goto &fourth_caller }
sub fourth_caller { eval "fifth_caller('$_[0]')"; die $@ if $@ }
sub fifth_caller  { eval "$_[0] 'hellooo nurse!!'"; die $@ if $@ }

# To intercept the messages, we redefine STDERR as a tie()ed object. 
my $stderr = '';
tie *STDERR, 'Acme::JavaTrace::Test';

# First we test warn().
$stderr = '';
first_caller('warn');
my $warn_msg = $stderr;

# Then we test die().
$stderr = '';
eval { first_caller('die') };
my $die_msg = $@;

# Now we check that what we got correspond to what we expected.
my($file) = $warn_msg =~ /\(([^<>]+?):\d+\)/;
my $errmsg = <<"ERRMSG";
hellooo nurse!!
	at <eval>(<eval>:1)
	at main::fifth_caller(${file}:27)
	at <eval>(<eval>:1)
	at main::fourth_caller(${file}:26)
	at main::second_caller(${file}:24)
	at main::first_caller(${file}:23)
	at main::(${file}:35)
ERRMSG

ok( $warn_msg, $errmsg );  #05

$errmsg = <<"ERRMSG";
hellooo nurse!!
	at <eval>(<eval>:1)
	at main::fifth_caller(${file}:27)
	at <eval>(<eval>:1)
	at main::fourth_caller(${file}:26)
	at main::second_caller(${file}:24)
	at main::first_caller(${file}:23)
	at <eval>(${file}:40)
	at main::(${file}:40)
ERRMSG

ok( $die_msg, $errmsg );  #06


package Acme::JavaTrace::Test;
sub TIEHANDLE {
    return bless {}, shift
}
sub PRINT {
    my $self = shift;
    $stderr .= join '', @_;
}
