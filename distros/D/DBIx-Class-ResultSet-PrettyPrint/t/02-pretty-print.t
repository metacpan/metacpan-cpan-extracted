#!perl
use 5.010;
use strict;
use warnings;

use Test::More import => [ qw( is plan use_ok ) ];
use Capture::Tiny qw( capture );

use lib './t/lib';

use DBIx::Class::ResultSet::PrettyPrint;

plan tests => 2;

use_ok('TestDB');

my $schema = TestDB->init();

my $books = $schema->resultset('Book');

my ( $stdout, $stderr ) = capture {
    my $pp = DBIx::Class::ResultSet::PrettyPrint->new();
    $pp->print_table($books);
};

my $expeced_output = <<"EOT";
+----+----------------------------+-------------------------------------------------------+------------+-----------+---------------+
| id | title                      | author                                                | pub_date   | num_pages | isbn          |
+----+----------------------------+-------------------------------------------------------+------------+-----------+---------------+
| 1  | Programming Perl           | Tom Christiansen, brian d foy, Larry Wall, Jon Orwant | 2012-03-18 | 1174      | 9780596004927 |
| 2  | Perl by Example            | Ellie Quigley                                         | 1994-01-01 | 200       | 9780131228399 |
| 3  | Perl in a Nutshell         | Nathan Patwardhan, Ellen Siever and Stephen Spainhour | 1999-01-01 | 654       | 9781565922860 |
| 4  | Perl Best Practices        | Damian Conway                                         | 2005-07-01 | 517       | 9780596001735 |
| 5  | Learning Perl, 7th Edition | Randal L. Schwartz, brian d foy, Tom Phoenix          | 2016-10-05 | 369       | 9781491954324 |
+----+----------------------------+-------------------------------------------------------+------------+-----------+---------------+
EOT

is( $stdout, $expeced_output, 'Pretty printed output matches expectations' );

# vim: expandtab shiftwidth=4
