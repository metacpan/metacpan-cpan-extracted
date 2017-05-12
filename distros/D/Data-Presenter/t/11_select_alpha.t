# 11_select_alpha.t
#$Id: 11_select_alpha.t 1217 2008-02-10 00:06:02Z jimk $
use strict;
use warnings;
use Test::More 
tests => 202;
# qw(no_plan);
use_ok('Data::Presenter');
use_ok('Cwd');
use_ok('File::Temp', qw(tempdir) );
use_ok('IO::Capture::Stdout');
use_ok('IO::Capture::Stdout::Extended');
use_ok('Tie::File');
use lib ("./t");
use_ok('Data::Presenter::Sample::Census');
use_ok('Test::DataPresenterSpecial',  qw(:seen) );

# Declare variables needed for testing:
my $topdir = cwd();
{
    my $tdir = tempdir( CLEANUP => 1);
    ok(chdir $tdir, 'changed to temp directory for testing');

    # 0.01:  Names of variables imported from config file when do-d:

    our @fields = ();       # individual fields/columns in data
    our %parameters = ();   # parameters describing how individual 
                            # fields/columns in data are sorted and outputted
    our $index = q{};       # field in data source which serves as unique ID 
                            # for each record

    my $sourcefile = "$topdir/source/census.txt";
    my $fieldsfile = "$topdir/config/fields.census.data";
    do $fieldsfile;

    # ==

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'eq',
        choices     =>  [ qw( 1963-08-01 ) ],
        count       =>  1,
        predict     =>  [ qw( 456791 ) ],
        nonpredict  =>  [ qw( 456790 498703  803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'equals',
        choices     =>  [ qw( 1963-08-01 ) ],
        count       =>  1,
        predict     =>  [ qw( 456791 ) ],
        nonpredict  =>  [ qw( 456790 498703  803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is',
        choices     =>  [ qw( 1963-08-01 ) ],
        count       =>  1,
        predict     =>  [ qw( 456791 ) ],
        nonpredict  =>  [ qw( 456790 498703  803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is equal to',
        choices     =>  [ qw( 1963-08-01 ) ],
        count       =>  1,
        predict     =>  [ qw( 456791 ) ],
        nonpredict  =>  [ qw( 456790 498703  803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is a member of',
        choices     =>  [ qw( 1963-08-01 ) ],
        count       =>  1,
        predict     =>  [ qw( 456791 ) ],
        nonpredict  =>  [ qw( 456790 498703  803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is part of',
        choices     =>  [ qw( 1963-08-01 ) ],
        count       =>  1,
        predict     =>  [ qw( 456791 ) ],
        nonpredict  =>  [ qw( 456790 498703  803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '=',
        choices     =>  [ qw( 1963-08-01 ) ],
        count       =>  1,
        predict     =>  [ qw( 456791 ) ],
        nonpredict  =>  [ qw( 456790 498703  803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '==',
        choices     =>  [ qw( 1963-08-01 ) ],
        count       =>  1,
        predict     =>  [ qw( 456791 ) ],
        nonpredict  =>  [ qw( 456790 498703  803092 698389 ) ],
    );

    # !=

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'ne',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is not',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is not equal to',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is not a member of',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is not part of',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is less than or greater than',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is less than or more than',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is greater than or less than',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is more than or less than',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'does not equal',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'not',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'not equal to',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'not equals',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '!=',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '! =',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '!==',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '! ==',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '<>',
        choices     =>  [ qw(
            1949-08-12 1963-08-01 1969-06-29 1973-08-17 1973-10-02
        ) ],
        count       =>  6,
        predict     =>  [ qw(
            906786 456789 456787 456788 456790 498703
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 698389 359962 786792
        ) ],
    );

    # <

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '<',
        choices     =>  [ qw( 1960-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            698389 906786 498703 456787
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'lt',
        choices     =>  [ qw( 1960-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            698389 906786 498703 456787
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is less than',
        choices     =>  [ qw( 1960-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            698389 906786 498703 456787
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is fewer than',
        choices     =>  [ qw( 1960-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            698389 906786 498703 456787
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'before',
        choices     =>  [ qw( 1960-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            698389 906786 498703 456787
        ) ],
        nonpredict  =>  [ qw(
            456791 803092 359962
        ) ],
    );

    # >

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '>',
        choices     =>  [ qw( 1970-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            359962 786792 456789 456788
        ) ],
        nonpredict  =>  [ qw(
            698389 906786 498703 456787
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'gt',
        choices     =>  [ qw( 1970-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            359962 786792 456789 456788
        ) ],
        nonpredict  =>  [ qw(
            698389 906786 498703 456787
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is more than',
        choices     =>  [ qw( 1970-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            359962 786792 456789 456788
        ) ],
        nonpredict  =>  [ qw(
            698389 906786 498703 456787
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is greater than',
        choices     =>  [ qw( 1970-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            359962 786792 456789 456788
        ) ],
        nonpredict  =>  [ qw(
            698389 906786 498703 456787
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'after',
        choices     =>  [ qw( 1970-01-01 ) ],
        count       =>  4,
        predict     =>  [ qw(
            359962 786792 456789 456788
        ) ],
        nonpredict  =>  [ qw(
            698389 906786 498703 456787
        ) ],
    );

    # <=

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '<=',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  5,
        predict     =>  [ qw( 
            698389 906786 456787 498703 456790
         ) ],
        nonpredict  =>  [ qw( 
            456791 803092 456789 456788 786792 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'le',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  5,
        predict     =>  [ qw( 
            698389 906786 456787 498703 456790
         ) ],
        nonpredict  =>  [ qw( 
            456791 803092 456789 456788 786792 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is less than or equal to',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  5,
        predict     =>  [ qw( 
            698389 906786 456787 498703 456790
         ) ],
        nonpredict  =>  [ qw( 
            456791 803092 456789 456788 786792 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is fewer than or equal to',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  5,
        predict     =>  [ qw( 
            698389 906786 456787 498703 456790
         ) ],
        nonpredict  =>  [ qw( 
            456791 803092 456789 456788 786792 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'on or before',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  5,
        predict     =>  [ qw( 
            698389 906786 456787 498703 456790
         ) ],
        nonpredict  =>  [ qw( 
            456791 803092 456789 456788 786792 359962
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'before or on',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  5,
        predict     =>  [ qw( 
            698389 906786 456787 498703 456790
         ) ],
        nonpredict  =>  [ qw( 
            456791 803092 456789 456788 786792 359962
        ) ],
    );

    # >=

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  '>=',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  7,
        predict     =>  [ qw( 
            456790 456791 803092 456789 456788 786792 359962
         ) ],
        nonpredict  =>  [ qw( 
            698389 906786 456787 498703
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'ge',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  7,
        predict     =>  [ qw( 
            456790 456791 803092 456789 456788 786792 359962
         ) ],
        nonpredict  =>  [ qw( 
            698389 906786 456787 498703
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is more than or equal to',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  7,
        predict     =>  [ qw( 
            456790 456791 803092 456789 456788 786792 359962
         ) ],
        nonpredict  =>  [ qw( 
            698389 906786 456787 498703
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'is greater than or equal to',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  7,
        predict     =>  [ qw( 
            456790 456791 803092 456789 456788 786792 359962
         ) ],
        nonpredict  =>  [ qw( 
            698389 906786 456787 498703
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'on or after',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  7,
        predict     =>  [ qw( 
            456790 456791 803092 456789 456788 786792 359962
         ) ],
        nonpredict  =>  [ qw( 
            698389 906786 456787 498703
        ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  q{datebirth},
        relation    =>  'after or on',
        choices     =>  [ qw( 1960-14-02 ) ],
        count       =>  7,
        predict     =>  [ qw( 
            456790 456791 803092 456789 456788 786792 359962
         ) ],
        nonpredict  =>  [ qw( 
            698389 906786 456787 498703
        ) ],
    );

    ok(chdir $topdir, 'changed back to original directory after testing');
}

