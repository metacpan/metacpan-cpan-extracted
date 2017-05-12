#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 12;

BEGIN { require "t/commons.pl"; }

use File::Spec;
use File::Basename;
use Cwd;

# duplicating matching values
my @command;
my ($stdout, $stderr);

my $config_file = File::Spec->catfile (test_file(), 'things.cfg');
my $houses    = File::Spec->catfile (test_file(), 'houses.tsv');
my $furniture = File::Spec->catfile (test_file(), 'furniture.tsv');
my $paintings = File::Spec->catfile (test_file(), 'paintings.tsv');
my $drinks    = File::Spec->catfile (test_file(), 'drinks.tsv');
my $food      = File::Spec->catfile (test_file(), 'foods.tsv');

@command = ( '-config', $config_file, '-inputs',
             "HOUSE=$houses",
             "FUR=$furniture",
             "PAINT=$paintings",
             "DRINK=$drinks",
             "FOOD=$food" );
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), 13, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 6, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 78, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['Owner',   'House',   'Furniture', 'Painting', 'Drink', 'Food'   ],
            ['Blanka',  'bigger',  'chair',     'acryl',    '',      'salad'  ],
            ['Blanka',  'bigger',  'chair',     'acryl',    '',      'fruit'  ],
            ['Blanka',  'bigger',  'sofa',      'acryl',    '',      'salad'  ],
            ['Blanka',  'bigger',  'sofa',      'acryl',    '',      'fruit'  ],
            ['Katrin',  'big',     '',          'pencil',   'beer',  'swarma' ],
            ['Katrin',  'big',     '',          'pencil',   'soda',  'swarma' ],
            ['Kim',     'small',   'table',     'oil',      '',      'burger' ],
            ['Kim',     'small',   'bed',       'oil',      '',      'burger' ],
            ['Kim',     'small',   'drawer',    'oil',      '',      'burger' ],
            ['Kim',     'smaller', 'table',     'oil',      '',      'burger' ],
            ['Kim',     'smaller', 'bed',       'oil',      '',      'burger' ],
            ['Kim',     'smaller', 'drawer',    'oil',      '',      'burger' ],
           ],
           "With: things");

$config_file = File::Spec->catfile (test_file(), 'books_to_authors.cfg');
my $books   = File::Spec->catfile (test_file(), 'books.tsv');
my $authors = File::Spec->catfile (test_file(), 'authors.tsv');

@command = ( '-config', $config_file, '-inputs',
             "BOOK=$books",
             "AUTHOR=$authors" );
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), 6, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 4, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 24, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['Name',    'Title',   'Age', 'Note'      ],
            ['Blanka',  'Book 1',  '30',  'from B1-d' ],
            ['Katrin',  'Book 3',  '20',  'from B3-c' ],
            ['Katrin',  'Book 2',  '20',  'from B2-e' ],
            ['Kim',     'Book 1',  '28',  'from B1-a' ],
            ['Kim',     'Book 2',  '28',  'from B2-b' ],
           ],
           "With: books and authors");

@command = ( '-config', $config_file, '-inputs',
             "AUTHOR=$authors",
             "BOOK=$books" );
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), 7, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 4, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 28, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['Name',        'Title',   'Age', 'Note'      ],
            ['Blanka',      'Book 1',  '30',  'from B1-d' ],
            ['Katrin',      'Book 3',  '20',  'from B3-c' ],
            ['Katrin',      'Book 2',  '20',  'from B2-e' ],
            ['Kim',         'Book 1',  '28',  'from B1-a' ],
            ['Kim',         'Book 2',  '28',  'from B2-b' ],
            ['Lazy author', '',        '50',  ''          ],
           ],
           "With: authors and books");
__END__
