#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::zxcvbn qw(cmp_match);
use Data::Password::zxcvbn::AdjacencyGraph;
use Data::Password::zxcvbn::Match::Spatial;

sub cmp_sp_match {
    my ($i,$j,$token,$keyboard,$turns,$shifts) = @_;
    cmp_match(
        $i,$j,'Spatial',
        token => $token,
        graph_name => $keyboard,
        turns => $turns,
        shifted_count => $shifts,
    );
}

sub test_scoring {
    my ($token, $graph, $turns, $shifts, $guesses, $message) = @_;

    my $match = Data::Password::zxcvbn::Match::Spatial->new({
        token => $token,
        turns => $turns,
        shifted_count => $shifts,
        graph_name => $graph,
        graph_meta => $Data::Password::zxcvbn::AdjacencyGraph::graphs{$graph},
        i => 0, j => 3,
    });

    cmp_deeply(
        $match->guesses,
        num($guesses,1),
        $message,
    );
}

sub test_making {
    my ($password, $graph_name, $expected, $message) = @_;

    my $graphs; # undef = default = use all graphs
    if ($graph_name) {
        $graphs = {
            $graph_name =>
                $Data::Password::zxcvbn::AdjacencyGraph::graphs{$graph_name},
        };
    }

    my $matches = Data::Password::zxcvbn::Match::Spatial->make(
        $password, { graphs => $graphs },
    );
    cmp_deeply(
        $matches,
        $expected,
        $message,
    ) or explain $matches;
}

subtest 'scoring' => sub {
    test_scoring(
        'zxcvbn','qwerty',1,0 => 2160,
        'with no turns or shifts, guesses is starts * degree * (len-1)',
    );

    test_scoring(
        'ZXCVBN','qwerty',1,6 => 4320,
        'when everything is shifted, guesses are doubled',
    );

    test_scoring(
        'ZxCvbn','qwerty',1,2 => 45360,
        'guesses is added for shifted keys, similar to capitals in dictionary matching',
    );

    test_scoring(
        'zxcft6yh','qwerty',3,0 => 558460,
        'spatial guesses accounts for turn positions, directions and starting keys',
    );
};

subtest 'making' => sub {
    for my $password ('',qw(/ qw */)) {
        test_making(
            $password,undef,
            [],
            "doesn't match 1- and 2-character spatial patterns",
        );
    }

    test_making(
        'rz!6tfGHJ%z','qwerty',
        [cmp_sp_match(3,8,'6tfGHJ','qwerty',2,3)],
        'matches against spatial patterns surrounded by non-spatial patterns',
    );

    for my $case (
        ['12345', 'qwerty', 1, 0],
        ['@WSX', 'qwerty', 1, 4],
        ['6tfGHJ', 'qwerty', 2, 3],
        ['hGFd', 'qwerty', 1, 2],
        ['/;p09876yhn', 'qwerty', 3, 0],
        ['Xdr%', 'qwerty', 1, 2],
        ['159-', 'keypad', 1, 0],
        ['*84', 'keypad', 1, 0],
        ['/8520', 'keypad', 1, 0],
        ['369', 'keypad', 1, 0],
        ['/963.', 'mac_keypad', 1, 0],
        ['*-632.0214', 'mac_keypad', 9, 0],
        ['aoEP%yIxkjq:', 'dvorak', 4, 5],
        [';qoaOQ:Aoq;a', 'dvorak', 11, 4],
    ) {
        my ($password,$graph,$turns,$shifts) = @{$case};
        test_making(
            $password,$graph,
            [ cmp_sp_match(0,length($password)-1,$password,$graph,$turns,$shifts) ],
            "matches $password as a $graph pattern",
        );
    }
};

done_testing;
