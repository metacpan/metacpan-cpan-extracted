#!perl -w
# reported by nekoya
package Person;
use Data::Util qw/:all/;

{
    no warnings 'redefine';
    my $before = modify_subroutine(
        get_code_ref(__PACKAGE__, 'before_chk'),
        before => [ sub { eval "use Hoge" } ]
    );

    my $after = modify_subroutine(
        get_code_ref(__PACKAGE__, 'after_chk'),
        after => [ sub { eval "use Hoge" } ]
    );

    my $around = modify_subroutine(
        get_code_ref(__PACKAGE__, 'around_chk'),
        around => [ sub {
            my $orig = shift;
            my $self = shift;
            eval "use Hoge";
            $self->$orig(@_);
        } ]
    );

    install_subroutine(__PACKAGE__, 'before_chk' => $before);
    install_subroutine(__PACKAGE__, 'after_chk' => $after);
    install_subroutine(__PACKAGE__, 'around_chk' => $around);
}

sub new { bless {}, shift }

sub before_chk { 'before checked' }
sub after_chk { 'after checked' }
sub around_chk { 'around checked' }

package main;
use strict;
use warnings;
use Test::More tests => 4;

my $pp = Person->new;
is $pp->before_chk, 'before checked', 'before check done';
is $pp->after_chk, 'after checked', 'after check done';
is $pp->around_chk, 'around checked', 'around check done';
ok 1, 'all tests finished';
