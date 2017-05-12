#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Test::More;
use Capture::Tiny ':all';
use Encode qw/decode/;

BEGIN {
	use_ok( 'Acme::Aheui' );
}

{ # new interpreter and its internal codespace
    my $source = "가각\r\n힢힣\nA *";
    my $interpreter = Acme::Aheui->new( source => $source );
    ok( $interpreter );
    is( $$interpreter{_codespace}[0][0]{cho}, 0 );
    is( $$interpreter{_codespace}[0][0]{jung}, 0 );
    is( $$interpreter{_codespace}[0][0]{jong}, 0 );

    is( $$interpreter{_codespace}[0][1]{cho}, 0 );
    is( $$interpreter{_codespace}[0][1]{jung}, 0 );
    is( $$interpreter{_codespace}[0][1]{jong}, 1 );

    is( $$interpreter{_codespace}[1][0]{cho}, 18 );
    is( $$interpreter{_codespace}[1][0]{jung}, 20 );
    is( $$interpreter{_codespace}[1][0]{jong}, 26 );

    is( $$interpreter{_codespace}[1][1]{cho}, 18 );
    is( $$interpreter{_codespace}[1][1]{jung}, 20 );
    is( $$interpreter{_codespace}[1][1]{jong}, 27 );

    is( $$interpreter{_codespace}[2][0]{cho}, -1 );
    is( $$interpreter{_codespace}[2][0]{jung}, -1 );
    is( $$interpreter{_codespace}[2][0]{jong}, -1 );

    is( $$interpreter{_codespace}[2][1]{cho}, -1 );
    is( $$interpreter{_codespace}[2][1]{jung}, -1 );
    is( $$interpreter{_codespace}[2][1]{jong}, -1 );

    is( $$interpreter{_codespace}[2][2]{cho}, -1 );
    is( $$interpreter{_codespace}[2][2]{jung}, -1 );
    is( $$interpreter{_codespace}[2][2]{jong}, -1 );
}

{ # move cursor
    my $source = <<'__SOURCE__';
가나다
라마
바사아자차
카
타파하
__SOURCE__
    
    my $interpreter = Acme::Aheui->new( source => $source );
    is( $interpreter->{_x}, 0 );
    is( $interpreter->{_y}, 0 );
    is( $interpreter->{_dx}, 0 );
    is( $interpreter->{_dy}, 1 );

    $interpreter->{_dx} = 1;
    $interpreter->{_dy} = 0;
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [1, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [0, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [1, 0] );

    $interpreter->{_dx} = -1;
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [0, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [1, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [0, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 0] );

    $interpreter->{_dx} = 0;
    $interpreter->{_dy} = 1;
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 1] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 2] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 3] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 4] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 1] );

    $interpreter->{_dy} = -1;
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 4] );

    $interpreter->{_dx} = 2;
    $interpreter->{_dy} = 0;
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [0, 4] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 4] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [0, 4] );

    $interpreter->{_dx} = -2;
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 4] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [0, 4] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 4] );

    $interpreter->{_dx} = 0;
    $interpreter->{_dy} = 2;
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 2] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 4] );

    $interpreter->{_dy} = -2;
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 2] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 0] );
    $interpreter->_move_cursor();
    is_deeply( [$interpreter->{_x}, $interpreter->{_y}], [2, 4] );
}

{ # storages

    my $counter = 0;
    sub test_stack {
        my ($interpreter, $storage_index) = @_;

        # a push and a pop
        my $in = $counter++;
        $interpreter->_push($storage_index, $in);
        my $out = $interpreter->_pop($storage_index);
        is( $in, $out );

        # pushes, pops
        my ($in1, $in2, $in3) = ($counter++, $counter++, $counter++);
        $interpreter->_push($storage_index, $in1);
        $interpreter->_push($storage_index, $in2);
        $interpreter->_push($storage_index, $in3);
        my $out3 = $interpreter->_pop($storage_index);
        my $out2 = $interpreter->_pop($storage_index);
        my $out1 = $interpreter->_pop($storage_index);
        is_deeply( [$in1, $in2, $in3], [$out1, $out2, $out3] );

        # duplicate
        my $first_in = $counter++;
        my $later_in = $counter++;
        $interpreter->_push($storage_index, $first_in);
        $interpreter->_push($storage_index, $later_in);
        $interpreter->_duplicate($storage_index);
        my $out_dup1 = $interpreter->_pop($storage_index);
        my $out_dup2 = $interpreter->_pop($storage_index);
        is( $later_in, $out_dup1 );
        is( $later_in, $out_dup2 );
        $interpreter->_pop($storage_index);

        # swap
        $first_in = $counter++;
        $later_in = $counter++;
        $interpreter->_push($storage_index, $first_in);
        $interpreter->_push($storage_index, $later_in);
        $interpreter->_swap($storage_index);
        my $first_out = $interpreter->_pop($storage_index);
        my $later_out = $interpreter->_pop($storage_index);
        is( $first_in, $first_out );
        is( $later_in, $later_out );
    }

    sub test_queue {
        my ($interpreter, $storage_index) = @_;

        # a push and a pop
        my $in = $counter++;
        $interpreter->_push($storage_index, $in);
        my $out = $interpreter->_pop($storage_index);
        is( $in, $out );

        # pushes, pops
        my ($in1, $in2, $in3) = ($counter++, $counter++, $counter++);
        $interpreter->_push($storage_index, $in1);
        $interpreter->_push($storage_index, $in2);
        $interpreter->_push($storage_index, $in3);
        my $out1 = $interpreter->_pop($storage_index);
        my $out2 = $interpreter->_pop($storage_index);
        my $out3 = $interpreter->_pop($storage_index);
        is_deeply( [$in1, $in2, $in3], [$out1, $out2, $out3] );

        # duplicate
        my $first_in = $counter++;
        my $later_in = $counter++;
        $interpreter->_push($storage_index, $first_in);
        $interpreter->_push($storage_index, $later_in);
        $interpreter->_duplicate($storage_index);
        my $out_dup1 = $interpreter->_pop($storage_index);
        my $out_dup2 = $interpreter->_pop($storage_index);
        is( $first_in, $out_dup1 );
        is( $first_in, $out_dup2 );
        $interpreter->_pop($storage_index);

        # swap
        $first_in = $counter++;
        $later_in = $counter++;
        $interpreter->_push($storage_index, $first_in);
        $interpreter->_push($storage_index, $later_in);
        $interpreter->_swap($storage_index);
        my $first_out = $interpreter->_pop($storage_index);
        my $later_out = $interpreter->_pop($storage_index);
        is( $first_in, $later_out );
        is( $later_in, $first_out );
    }

    my $interpreter = Acme::Aheui->new( source => '' );
    for my $i (0..26) {
        if ($i == 21) { # ㅇ queue
            test_queue($interpreter, $i);
        }
        else { # '', ㄱ, ㄴ, ... ㅆ, ㅈ, .. ㅍ stack
            test_stack($interpreter, $i);
        }
    }
}

{ # termination code
    my $source = '밠히';
    my ($stdout, $stderr, @result) = capture {
        my $interpreter = Acme::Aheui->new( source => $source );
        $interpreter->execute();
    };
    is( $stdout, '' );
    is( $stderr, '' );
    is( $result[0], 7 );
}

{ # hello world
    my $source = << '__SOURCE__';
밤밣따빠밣밟따뿌
빠맣파빨받밤뚜뭏
돋밬탕빠맣붏두붇
볻뫃박발뚷투뭏붖
뫃도뫃희멓뭏뭏붘
뫃봌토범더벌뿌뚜
뽑뽀멓멓더벓뻐뚠
뽀덩벐멓뻐덕더벅
__SOURCE__

    my ($stdout, $stderr, @result) = capture {
        my $interpreter = Acme::Aheui->new( source => $source );
        $interpreter->execute();
    };
    is( $stdout, "Hello, world!\n" );
    is( $stderr, '' );
}

{ # exit without infinite loop in case of null program
    my ($stdout, $stderr, @result) = capture {
        my $interpreter = Acme::Aheui->new( source => '' );
        $interpreter->execute();
    };
    is( $stdout, '' );
    is( $stderr, '' );
}

{ # exit without infinite loop in case of no initial command
    my $source = "abc\ndef\nghi\n\n\n_반밧나망히\n";
    my ($stdout, $stderr, @result) = capture {
        my $interpreter = Acme::Aheui->new( source => $source );
        $interpreter->execute();
    };
    is( $stdout, '' );
    is( $stderr, '' );
}

{ # input number
    my ($stdout, $stderr, @result) = capture {
        my $stdin;
        open($stdin,'<&STDIN');
        *STDIN = *DATA;
        my $interpreter = Acme::Aheui->new( source => '방빠망망히' );
        $interpreter->execute();
        *STDIN = $stdin;
    };
    is( $stdout, '369369' );
    is( $stderr, '' );
}

{ # input characters
    my ($stdout, $stderr, @result) = capture {
        my $stdin;
        open($stdin,'<&STDIN');
        *STDIN = *DATA;
        my $interpreter = Acme::Aheui->new(
            source => '밯밯맣맣히',
            output_encoding => 'utf-8',
        );
        $interpreter->execute();
        *STDIN = $stdin;
    };
    is( decode('utf-8', $stdout), '몽즙' );
    is( $stderr, '' );
}

done_testing();


__DATA__
369
즙몽
