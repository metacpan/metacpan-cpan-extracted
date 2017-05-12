#!perl -w

#use Test::More qw(no_plan);
use Test::More tests => 20;

BEGIN { require "t/commons.pl"; }

use File::Spec;
use File::Basename;
use Cwd;

# calling external programs (calculated columns)
my @command;
my ($stdout, $stderr);
my $persons  = File::Spec->catfile (test_file(), 'persons.tsv');

unless (exists $ENV{COMBINE_SHEETS_EXT_PATH}) {
    my $cwd = getcwd;
    if (basename ($cwd) ne 't') {
        $ENV{COMBINE_SHEETS_EXT_PATH} = File::Spec->catfile ($cwd, 't');
    }
}
unshift (@INC, 't');   # because some tests need the testing Module

$config_file = File::Spec->catfile (test_file(), 'error-missing-output-column.cfg');
@command = ( '-config', $config_file, '-inputs', "PERSON=$persons" );
($stdout, $stderr) = my_run (@command);
ok ($stderr =~ m{\[WR10\]} && $stderr =~ m{'count-chars'},
    msgcmd ("Expected warning WR10 ('count-chars') for ", @command));
is (row_count ($stdout), 4, msgcmd2 ($stderr, "Rows count for ", @command));
is (col_count ($stdout), 3, msgcmd2 ($stderr, "Columns count for ", @command));
is (mtx_count ($stdout), 12, msgcmd2 ($stderr, "Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['First name', '',   'Surname'  ],
            ['Jitka',      '14', 'Gudernova'],
            ['Jan',        '8',  'Novak'    ],
            ['Martin',     '12', 'Senger'   ],
           ],
           "With: persons and count-chars");

$config_file = File::Spec->catfile (test_file(), 'config-with-calculated-columns.cfg');
@command = ( '-config', $config_file, '-inputs', "PERSON=$persons" );
($stdout, $stderr) = my_run (@command);
is (row_count ($stdout), 4, msgcmd2 ($stderr, "Rows count for ", @command));
is (col_count ($stdout), 5, msgcmd2 ($stderr, "Columns count for ", @command));
is (mtx_count ($stdout), 20, msgcmd2 ($stderr, "Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['First name', 'Characters Count', 'Initials 1', 'Initials 2', 'Surname'  ],
            ['Jitka',      '14',               'J1G',        'J1JG',       'Gudernova'],
            ['Jan',        '8',                'J8N',        'J8JN',       'Novak'    ],
            ['Martin',     '12',               'M1S',        'M1MS',       'Senger'   ],
           ],
           "With: persons and count-chars(2)");

$config_file = File::Spec->catfile (test_file(), 'error-bad-perl.cfg');
@command = ( '-config', $config_file, '-inputs', "PERSON=$persons" );
#$ENV{PERL5LIB} .= ':./t';
($stdout, $stderr) = my_run (@command);
ok ($stderr =~ m{\[WR13\]} && $stderr =~ m{Initials 1},
    msgcmd2 ($stderr, "Expected warning WR13 (Initials 1) for ", @command));
ok ($stderr =~ m{\[WR11\]} && $stderr =~ m{Initials 2},
    msgcmd2 ($stderr, "Expected warning WR11 (Initials 2) for ", @command));
ok ($stderr =~ m{\[WR11\]} && $stderr =~ m{Initials 3},
    msgcmd2 ($stderr, "Expected warning WR11 (Initials 3) for ", @command));
ok ($stderr =~ m{\[WR11\]} && $stderr =~ m{Initials 4},
    msgcmd2 ($stderr, "Expected warning WR11 (Initials 4) for ", @command));
ok ($stderr =~ m{\[WR12\]} && $stderr =~ m{Initials 5},
    msgcmd2 ($stderr, "Expected warning WR12 (Initials 5) for ", @command));
ok ($stderr =~ m{\[WR12\]} && $stderr =~ m{Initials 6},
    msgcmd2 ($stderr, "Expected warning WR12 (Initials 6) for ", @command));
ok ($stderr =~ m{\[WR14\]} && $stderr =~ m{'Not::Existing'},
    msgcmd2 ($stderr, "Expected warning WR14 ('Not::Existing') for ", @command));
is (row_count ($stdout), 4, msgcmd2 ($stderr, "Rows count for ", @command));
is (col_count ($stdout), 2, msgcmd2 ($stderr, "Columns count for ", @command));
is (mtx_count ($stdout), 8, msgcmd2 ($stderr, "Matrix count for ", @command));
is_deeply (cut_into_table ($stdout),
           [
            ['First name', 'Surname'  ],
            ['Jitka',      'Gudernova'],
            ['Jan',        'Novak'    ],
            ['Martin',     'Senger'   ],
           ],
           "With: persons and count-chars(3)");

__END__
