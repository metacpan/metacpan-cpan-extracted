package    # hide from PAUSE
  TestDB;

# the trick to hide this tests-only package was copied from
# https://github.com/davidolrik/DBIx-Class-FormTools

use 5.010;
use strict;
use warnings;

use File::Temp ();
use File::Spec ();

use lib './t/lib';

use Schema;

sub init {
    my $temp_dir = File::Temp->newdir();
    my $db_file  = File::Spec->catfile( $temp_dir, 'books.db' );

    my $schema = Schema->connect("dbi:SQLite:${db_file}");
    $schema->deploy( { add_drop_table => 1 } );

    my $books = $schema->resultset('Book');
    $books->create(
        {
            title    => "Programming Perl",
            author   => "Tom Christiansen, brian d foy, Larry Wall, Jon Orwant",
            pub_date => "2012-03-18",
            num_pages => 1174,
            isbn      => "9780596004927"
        }
    );
    $books->create(
        {
            title     => "Perl by Example",
            author    => "Ellie Quigley",
            pub_date  => "1994-01-01",
            num_pages => 200,
            isbn      => "9780131228399"
        }
    );
    $books->create(
        {
            title    => "Perl in a Nutshell",
            author   => "Nathan Patwardhan, Ellen Siever and Stephen Spainhour",
            pub_date => "1999-01-01",
            num_pages => 654,
            isbn      => "9781565922860"
        }
    );
    $books->create(
        {
            title     => "Perl Best Practices",
            author    => "Damian Conway",
            pub_date  => "2005-07-01",
            num_pages => 517,
            isbn      => "9780596001735"
        }
    );
    $books->create(
        {
            title     => "Learning Perl, 7th Edition",
            author    => "Randal L. Schwartz, brian d foy, Tom Phoenix",
            pub_date  => "2016-10-05",
            num_pages => 369,
            isbn      => "9781491954324"
        }
    );

    return $schema;
}

1;

# vim: expandtab shiftwidth=4
