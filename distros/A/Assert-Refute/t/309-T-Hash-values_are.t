#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute qw(:core);
use Assert::Refute::Contract qw(contract);
use Assert::Refute::T::Hash;

my $rep;

$rep = contract {
    values_are { foo => 42, bar => 137 }
        , { foo => 42, bar => qr/\d+/, baz => undef }
        , "Happy case";
    values_are { foo => 42 }
        , { foo => contract {
                my ($self, $var) = @_;
                $self->like( $var, qr/4/, "Shouldn't appear in test output");
                $self->like( $var, qr/2/, "Shouldn't appear in test output");
            } need_object => 1 }
        , "Subcontract happy case";
}->apply;

contract_is $rep, "t2d", "Happy case ok";

$rep = contract {
    values_are { foo => 42, bar => 137, baz => 31415 }
        , {
            foo => undef,
            bar => 42,
            baz => contract {
                $_[0]->like( $_[1], qr/\d+/, "Digits" );
                $_[0]->cmp_ok( $_[1], "<", 1000, "Small number" );
            } need_object => 1,
        }
        , "Big failing test";
}->apply;

contract_is $rep, "tNd", "Not ok in every aspect";

note "REPORT\n".$rep->get_tap."/REPORT";

done_testing;
