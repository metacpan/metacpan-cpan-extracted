use Test::More;
use Caller::Hide qw[ hide_package reveal_package ];

package P5;   sub P5::func { &main::cmp_trace }
package P4;   sub P4::func { &P5::func; }
package P3;   sub P3::func { &P4::func; }
package P2;   sub P2::func { &P3::func; }
package P1;   sub P1::func { &P2::func; }
package main; sub cmp_packages { &P1::func }

cmp_packages([qw( P5 P4 P3 P2 P1 main main )], 'nothing hidden');

hide_package('P5');
cmp_packages([qw(    P4 P3 P2 P1 main main )], 'P5 hidden');

hide_package('P4');
cmp_packages([qw(       P3 P2 P1 main main )], 'P4 hidden');

hide_package('P3');
cmp_packages([qw(          P2 P1 main main )], 'P3 hidden');

hide_package('P2');
cmp_packages([qw(             P1 main main )], 'P2 hidden');

hide_package('P1');
cmp_packages([qw(                main main )], 'P1 hidden');

hide_package('main');
cmp_packages([qw(                          )], 'main hidden');

reveal_package('P5');
cmp_packages([qw( P5                       )], 'P5 revealed');

reveal_package('P4');
cmp_packages([qw( P5 P4                    )], 'P4 revealed');

reveal_package('P3');
cmp_packages([qw( P5 P4 P3                 )], 'P3 revealed');

reveal_package('P2');
cmp_packages([qw( P5 P4 P3 P2              )], 'P2 revealed');

reveal_package('P1');
cmp_packages([qw( P5 P4 P3 P2 P1           )], 'P1 revealed');

reveal_package('main');
cmp_packages([qw( P5 P4 P3 P2 P1 main main )], 'everything revealed');

done_testing();

sub cmp_trace {
    my ($expected_trace, $test_name) = @_;

    my ($frame, @trace) = (0);
    while (my $pkg = caller($frame++)) {
        push @trace, $pkg;
    }
    
    is_deeply \@trace, $expected_trace, $test_name or diag explain \@trace;
}
