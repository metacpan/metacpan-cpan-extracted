
use strict;
use warnings;
use Test::More tests => 4 + 6 + 4 + 5 + 4 + 2;

use Contextual::Call qw(ccall);

my (@_dummy, $_dummy);

@_dummy = &test_list_context;   # 4.
$_dummy = &test_scalar_context; # 6.
&test_void_context;             # 4.

@_dummy = &test_force_scalar_on_list_context; # 5.
@_dummy = &test_force_void_on_list_context;   # 4.

&test_xfail; # 2.

sub test_list_context
{
	ok(wantarray, '[list] wantarray at here is true');
	my $cc_wantarray;
	my $cc = ccall(sub{ $cc_wantarray = wantarray; return (a=>99); });
	ok($cc_wantarray, '[list] wantarray in ccall is also true');
	is_deeply([$cc->result], [a=>99], '[list] result as list');
	is_deeply(scalar $cc->result, 2,  '[list] result as scalar');
}

sub test_scalar_context
{
	ok(!wantarray,         '[scalar] wantarray at here is false');
	ok(defined(wantarray), '[scalar]   but defined');
	my $cc_wantarray;
	my $cc = ccall(sub{ $cc_wantarray = wantarray; return (a=>99); });
	ok(!$cc_wantarray,         '[scalar] wantarray in ccall is false');
	ok(defined($cc_wantarray), '[scalar]   but defined');
	is_deeply([$cc->result], [99], '[scalar] result as list');
	is_deeply(scalar $cc->result, 99, '[scalar] result as scalar');
}

sub test_void_context
{
	is(wantarray, undef, '[void] wantarray at here is undef');
	my $cc_wantarray;
	my $cc = ccall(sub{ $cc_wantarray = wantarray; return (a=>99); });
	is($cc_wantarray, undef, '[void] wantarray in ccall is also undef');
	is_deeply([$cc->result], [], '[void] result as list');
	is_deeply(scalar $cc->result, undef, '[void] result as scalar');
}

# force list.
#
sub test_force_scalar_on_list_context
{
	ok(wantarray, '[force_scalar] wantarray at here is true');
	my $cc_wantarray;
	my $cc = ccall('', sub{ $cc_wantarray = wantarray; return (a=>99); });
	ok(!$cc_wantarray,         '[force_scalar] wantarray in ccall is false');
	ok(defined($cc_wantarray), '[force_scalar]   but defined');
	is_deeply([$cc->result], [99], '[force_scalar] result as list');
	is_deeply(scalar $cc->result, 99, '[force_scalar] result as scalar');
}

sub test_force_void_on_list_context
{
	ok(wantarray, '[force_void] wantarray at here is true');
	my $cc_wantarray;
	my $cc = ccall(undef, sub{ $cc_wantarray = wantarray; return (a=>99); });
	is($cc_wantarray, undef, '[force_void] wantarray in ccall is also undef');
	is_deeply([$cc->result], [], '[force_void] result as list');
	is_deeply(scalar $cc->result, undef, '[force_void] result as scalar');
}

sub test_xfail
{
	eval{ &ccall(); };
	my $err = $@;
	ok( $err, '[xfail] calling with no argument raises exception');
	like( $err, qr/argument required/, '[xfail] calling with no argument raises exception');
}
