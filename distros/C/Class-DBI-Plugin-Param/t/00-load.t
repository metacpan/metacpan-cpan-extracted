#!perl -T

use Test::More tests => 1;

BEGIN {
    use lib qw(t);
    use_ok( 'CD' ); # CD contains Class::DBI::Plugin::Param
}

diag( "Testing Class::DBI::Plugin::Param $Class::DBI::Plugin::Param::VERSION, Perl $], $^X" );
