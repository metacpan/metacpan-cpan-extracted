#! perl

use Test2::V0;

use CXC::Number::Sequence::Fixed;
use constant Sequence => 'CXC::Number::Sequence::Fixed';

my %exp = ( elements => [ 0.5, 1.3, 2.1, 2.9, 3.7, 4.5, 5.3, 6.1, 6.9, 7.7 ], );

my $sequence = Sequence->new( elements => [ @{ $exp{elements} } ] );


is(
    $sequence,
    object {
        call min      => $exp{elements}[0];
        call max      => $exp{elements}[-1];
        call nelem    => $exp{elements}->@*;
        call elements => array {
            item float( $_ ) foreach $exp{elements}->@*;
            end;
        };
    },
);

done_testing;

