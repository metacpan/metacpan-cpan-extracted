use Test::More;
use Catalyst::Plugin::C3;

plan tests => 7;

{
    no warnings 'redefine';
    *NEXT::AUTOLOAD = \&Catalyst::Plugin::C3::__hacked_next_autoload;
}

package C3NT::Foo;
use base qw/ Catalyst::Component /;

sub new { my $class = shift; my %args = (@_); bless \%args => $class }
sub basic { return 42 }
sub c3_then_next { return 21 }
sub next_then_c3 { return 22 }

package C3NT::Bar;
use base qw/ C3NT::Foo /;

sub basic { shift->NEXT::basic; }
sub actual_fail_halfway { shift->NEXT::ACTUAL::actual_fail_halfway }
sub next_then_c3 { shift->next::method }

package C3NT::Baz;
use base qw/ C3NT::Foo /;

sub basic { shift->NEXT::basic; }
sub c3_then_next { shift->NEXT::c3_then_next }

package C3NT::Quux;
use base qw/ C3NT::Bar C3NT::Baz /;

sub basic { shift->NEXT::basic; }
sub non_exist { shift->NEXT::non_exist }
sub non_exist_actual { shift->NEXT::ACTUAL::non_exist_actual }
sub actual_fail_halfway { shift->NEXT::ACTUAL::actual_fail_halfway }
sub c3_then_next { shift->next::method }
sub next_then_c3 { shift->NEXT::next_then_c3 }

package main;

# Test 1, the very basics
my $quux_obj = C3NT::Quux->new;
is( $quux_obj->basic, 42, 'Basic inherited method returns correct value' );

# Tests 2+3, what happens with no underlying method
my $non_exist_rval;
eval { $non_exist_rval = $quux_obj->non_exist };
ok( !$@, 'Non-existant non-ACTUAL throws no errors' ) or diag $@;
is( $non_exist_rval, undef, 'Non-existant non-ACTUAL returns undef' );

# Test 4, again, but using ACTUAL
eval { $quux_obj->non_exist_actual };
like( $@, qr|^No next::method 'non_exist_actual' found for C3NT::Quux|, 'Non-existant ACTUAL throws correct error' );

# Test 5, again, but using ACTUAL, and failing halfway down the stack
eval { $quux_obj->actual_fail_halfway };
like( $@, qr|^No next::method 'actual_fail_halfway' found for C3NT::Quux|, 'Non-existant ACTUAL in superclass throws correct error' );

# Tests 6+7, C3/NEXT mixing
is( $quux_obj->c3_then_next, 21, 'C3 then NEXT' );
is( $quux_obj->next_then_c3, 22, 'NEXT then C3' );
