#!perl
use 5.014;
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 2;
    use_ok( 'Data::Hopen' );
    # "Bail out!" is a magic string per https://books.google.com/books?id=b59cVHsH52kC&pg=PA212&lpg=PA212&dq=perl+%22use_ok%22+bail+out+on+failure&source=bl&ots=OJFLv0wb7e&sig=9FQFij7aOIDaQ0SVT68jR3pJqBE&hl=en&sa=X&ved=2ahUKEwjL5p7_0u7fAhUCqVQKHdheD_QQ6AEwBHoECAUQAQ#v=onepage&q=perl%20%22use_ok%22%20bail%20out%20on%20failure&f=false .
    # However, BAIL_OUT skips the remaining tests even if not running
    # under prove(1), which `print "Bail out!\n"` does not.
}

diag( "Testing Data::Hopen $Data::Hopen::VERSION, Perl $], $^X" );
ok($Data::Hopen::VERSION, 'has a VERSION');
