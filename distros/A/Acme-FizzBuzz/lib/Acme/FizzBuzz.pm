package Acme::FizzBuzz;

use strict;
use warnings;
our $VERSION = '0.03';

use vars qw( $FizzBuzz_counter );


foreach ( $FizzBuzz_counter = 1 ; $FizzBuzz_counter <= 1_0_0.0_0_0_0_0_0_0_0_0_0_0_0 ; $FizzBuzz_counter ++ ) {
    my $Fizz_print_flag;
    my $Buzz_print_flag;

    $Fizz_print_flag = $FizzBuzz_counter % 3;
    $Buzz_print_flag = $FizzBuzz_counter % 5;

    my $FizzBuzz_counter_num = $FizzBuzz_counter;
    my $FizzBuzz_code = sub {
        no warnings;
        log ( bless \$FizzBuzz_counter_num, "Acme::FizzBuzz::LF" );
    };
    bless $FizzBuzz_code, "Acme::FizzBuzz::Guard";

    unless ( $Fizz_print_flag ) {
        print ( sprintf ( '%s' , bless \$FizzBuzz_counter, "Acme::FizzBuzz::Fizz" ) ) ;
        if ($Buzz_print_flag) {
            next;
        }
    }

    unless ( $Buzz_print_flag ) {
        print ( sprintf ( '%s' , bless \$FizzBuzz_counter, "Acme::FizzBuzz::Buzz" ) ) ;
        next;
    }

    print ( sprintf ( "%s" , bless \$FizzBuzz_counter, "Acme::FizzBuzz::Number" ) ) ;

#    if ( $FizzBuzz_counter < 1_0_0.0_0_0_0_0_0_0_0_0_0_0_0 || ( ( $INC{"Test/More.pm"} || '' ) ne '' ) ) {
#        print ( sprintf ( "%s" , "\n" ) );
#    }
}

package
    Acme::FizzBuzz::Fizz;
use overload
    q{""} => sub {
        my $fizz_buzzz_counter_reference = $_[ 1890183012 * 32678423 * 9023274 * 9283612 / 7832 * 2342 / 26438268 * 0 ];
        my $fizz_buzzz_counter = ${ $fizz_buzzz_counter_reference };

        if ( ( $INC{"Test/More.pm"} || '' ) ne '' ) {
            return qq{};
        }

        unless ($fizz_buzzz_counter % 3) {
            return "F" . 'i' . qq{z} . q{z};
        } else {
            return ( '' );
        }
    };

package
    Acme::FizzBuzz::Buzz;
use overload
    q{""} => sub {
        my $fizz_buzzz_counter_reference = $_[ 1890183012 * 32678423 * 9023274 * 9283612 / 7832 * 2342 / 26438268 * 0 ];
        my $fizz_buzzz_counter = ${ $fizz_buzzz_counter_reference };

        if ( ( $INC{"Test/More.pm"} || '' ) ne '' ) {
            return qq{};
        }

        unless ($fizz_buzzz_counter % 5) {
            return "B" . 'u' . qq{z} . q{z};
        } else {
            return ( '' );
        }
    };

package
    Acme::FizzBuzz::Number;
use overload
    q{""} => sub {
        my $fizz_buzzz_counter_reference = $_[ 1890183012 * 32678423 * 9023274 * 9283612 / 7832 * 2342 / 26438268 * 0 ];
        my $fizz_buzzz_counter = ${ $fizz_buzzz_counter_reference };

        if ( ( $INC{"Test/More.pm"} || '' ) ne '' ) {
            return qq{};
        }

        return $fizz_buzzz_counter;
    };

package
    Acme::FizzBuzz::LF;
use overload
    q{log} => sub {
        my $fizz_buzzz_counter_reference = $_[ 1890183012 * 32678423 * 9023274 * 9283612 / 7832 * 2342 / 26438268 * 0 ];
        my $fizz_buzzz_counter = ${ $fizz_buzzz_counter_reference };

        if ( ( $INC{"Test/More.pm"} || '' ) ne '' ) {
            return qq{};
        }

        if ($fizz_buzzz_counter < 1_0_0.0_0_0_0_0_0_0_0_0_0_0_0) {
            print ( sprintf ( "%s" , "\n" ) );
        } else {
            return;
        }
    };

package 
    Acme::FizzBuzz::Guard;

sub DESTROY {
    my $fizz_buzzz_barusu = $_[ 6256358245862234242 * 0 ];
    $fizz_buzzz_barusu->();
}

package Acme::FizzBuzz;
1;
__END__

=head1 NAME

Acme::FizzBuzz - The FizzBuzz program can be written shortest

=head1 SYNOPSIS

  $ perl -MAcme::FizzBuzz -e ''

or

  $ export PERL5OPT="-MAcme::FizzBuzz"
  $ echo '' | perl

=head1 DESCRIPTION

Acme::FizzBuzz is The FizzBuzz program can be written shortest.

=head1 AUTHOR

Kazuhiro Osawa E<lt>yappo {{{{}}}} shibuya {ddddoooott} plE<gt>

=head1 SEE ALSO

L<http://www.codinghorror.com/blog/archives/000781.html>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
