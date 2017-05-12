#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 42;

BEGIN { require "t/commons.pl"; }

use File::Spec;
use File::Basename;
use Cwd;

# test for error conditions AND good results
my @command;
my ($stdout, $stderr);

my $persons  = File::Spec->catfile (test_file(), 'persons.tsv');
my $cars     = File::Spec->catfile (test_file(), 'cars.csv');
my $children = File::Spec->catfile (test_file(), 'children.tsv');

my $person_and_car_results =
    [
     ['First name', 'Surname',   'Model',  'Sex', 'Nickname', 'Age', 'Year', 'Owned by' ],
     ['Jitka',      'Gudernova', 'Mini',   'F',   '',         '56',  '1968', 'Gudernova'],
     ['Jan',        'Novak',     '',       'M',   'Honza',    '52',  '',     ''         ],
     ['Martin',     'Senger',    'Skoda',  'M',   'Tulak',    '61',  '2002', 'Senger'   ],
    ];

$config_file = File::Spec->catfile (test_file(), 'config.cfg');

@command = ( '-config', $config_file, '-inputs', "PERSON=$persons" );
($stdout, $stderr) = my_run (@command);
ok ($stderr =~ m{\[WR07\]} && $stderr =~ m{'CHILD'},
    msgcmd2 ($stderr, "Expected warning WR07 ('CHILD') for ", @command));
ok ($stderr =~ m{\[WR07\]} && $stderr =~ m{'CAR'},
    msgcmd2 ($stderr, "Expected warning WR07 ('CAR') for ", @command));
is (row_count ($stdout), 4, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 5, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 20, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['First name', 'Surname',   'Sex', 'Nickname', 'Age'],
            ['Jitka',      'Gudernova', 'F',   '',         '56' ],
            ['Jan',        'Novak',     'M',   'Honza',    '52' ],
            ['Martin',     'Senger',    'M',   'Tulak',    '61' ],
           ],
           "With: persons");

@command = ( '-config', $config_file, '-inputs', "PERSON=$persons", "CAR=$cars" );
($stdout, $stderr) = my_run (@command);
ok ($stderr =~ m{\[WR07\]} && $stderr =~ m{'CHILD'},
    msgcmd2 ($stderr, "Expected warning WR07 ('CHILD') for ", @command));
is (row_count ($stdout), 4, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 8, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 32, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           $person_and_car_results,
           "With: persons and cars");

@command = ( '-config', $config_file, '-inputs', "PERSON=$persons", "CAR=$cars", "CHILDX=$children" );
($stdout, $stderr) = my_run (@command);
ok ($stderr =~ m{\[WR03\]} && $stderr =~ m{'CHILDX'},
    msgcmd2 ($stderr, "Expected warning WR03 ('CHILDX') for ", @command));
is (row_count ($stdout), 4, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 8, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 32, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           $person_and_car_results,
           "With: persons and cars");

@command = ( '-config', $config_file, '-inputs', "PERSON=$persons", "CAR=$cars", "CHILD=$children" );
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), 4, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 10, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 40, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['First name', 'Surname',   'Model', 'Sex', 'Name',    'Born',  'Nickname', 'Age', 'Year', 'Owned by' ],
            ['Jitka',      'Gudernova', 'Mini',  'F',   'Hrasek',  '1984',  '',         '56',  '1968', 'Gudernova'],
            ['Jan',        'Novak',     '',      'M',   'Kulisek', '1982',  'Honza',    '52',  '',     ''         ],
            ['Martin',     'Senger',    'Skoda', 'M',   '',        '',      'Tulak',    '61',  '2002', 'Senger'   ],
           ],
           "With: persons, cars and children");

@command = ( '-config', $config_file, '-inputs', "CAR=$cars", "CHILD=$children" );
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), 4, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 5, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 20, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['Model',  'Name',   'Born',   'Year',   'Owned by'    ],
            ['Mini',   'Hrasek', '1984',   '1968',   'Gudernova'   ],
            ['Skoda',  '',       '',       '2002',   'Senger'      ],
            ['Praga',  '',       '',       '1936',   'Someone else'],
           ],
           "With: cars and children");

@command = ( '-config', $config_file, '-inputs', "CHILD=$children", "CAR=$cars", "PERSON=$persons" );
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), 3, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 10, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 30, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['First name', 'Surname',   'Model', 'Sex', 'Name',    'Born', 'Nickname', 'Age', 'Year', 'Owned by' ],
            ['Jitka',      'Gudernova', 'Mini',  'F',   'Hrasek',  '1984', '',         '56',  '1968', 'Gudernova'],
            ['Jan',        'Novak',     '',      'M',   'Kulisek', '1982', 'Honza',    '52',  '',     ''         ],
           ],
           "With: children, person and car");

$config_file = File::Spec->catfile (test_file(), 'error-unknown-matching-column.cfg');
@command = ( '-config', $config_file, '-inputs', "PERSON=$persons", "CAR=$cars", "CHILD=$children" );
($stdout, $stderr) = my_run (@command);
ok ($stderr =~ m{\[WR05\]} && $stderr =~ m{'ParentX'},
    msgcmd2 ($stderr, "Expected warning WR05 ('ParentX') for ", @command));
is (row_count ($stdout), 4, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 8, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 32, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           $person_and_car_results,
           "With: persons and cars");

$config_file = File::Spec->catfile (test_file(), 'error-unknown-primary.cfg');
@command = ( '-config', $config_file, '-inputs', "PERSON=$persons", "CAR=$cars", "CHILD=$children" );
($stdout, $stderr) = my_run (@command);
ok ($stderr =~ m{\[WR05\]} && $stderr =~ m{'SurnameX'},
    msgcmd2 ($stderr, "Expected warning WR05 ('SurnameX') for ", @command));
ok ($stderr =~ m{\[ER03\]} && $stderr =~ m{'PERSON'},
    msgcmd2 ($stderr, "Expected error ER03 ('PERSON') for ", @command));

$config_file = File::Spec->catfile (test_file(), 'error-unknown-columns.cfg');
@command = ( '-config', $config_file, '-inputs', "CHILD=$children", "CAR=$cars", "PERSON=$persons" );
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), 3, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), 2, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 6, msgcmd ("Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['First name', 'Surname'  ],
            ['Jitka',      'Gudernova'],
            ['Jan',        'Novak'    ],
           ],
           "Unknown columns: children, person and car");

$config_file = File::Spec->catfile (test_file(), 'error-no-columns.cfg');
@command = ( '-config', $config_file, '-inputs', "PERSON=$persons", "CHILD=$children", "CAR=$cars");
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), undef, msgcmd ("Rows count for ", @command));
is (col_count ($stdout), undef, msgcmd ("Columns count for ", @command));
is (mtx_count ($stdout), 0, msgcmd ("Matrix count for ", @command));

__END__
