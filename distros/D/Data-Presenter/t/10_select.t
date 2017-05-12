# 10_select.t
#$Id: 10_select.t 1217 2008-02-10 00:06:02Z jimk $
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
        column      =>  'ward',
        relation    =>  'eq',
        choices     =>  [ qw( 0110 ) ],
        count       =>  2,
        predict     =>  [ qw( 456790 498703  ) ],
        nonpredict  =>  [ qw( 456791 803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'equals',
        choices     =>  [ qw( 0110 ) ],
        count       =>  2,
        predict     =>  [ qw( 456790 498703  ) ],
        nonpredict  =>  [ qw( 456791 803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is',
        choices     =>  [ qw( 0110 ) ],
        count       =>  2,
        predict     =>  [ qw( 456790 498703  ) ],
        nonpredict  =>  [ qw( 456791 803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is equal to',
        choices     =>  [ qw( 0110 ) ],
        count       =>  2,
        predict     =>  [ qw( 456790 498703  ) ],
        nonpredict  =>  [ qw( 456791 803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is a member of',
        choices     =>  [ qw( 0110 ) ],
        count       =>  2,
        predict     =>  [ qw( 456790 498703  ) ],
        nonpredict  =>  [ qw( 456791 803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is part of',
        choices     =>  [ qw( 0110 ) ],
        count       =>  2,
        predict     =>  [ qw( 456790 498703  ) ],
        nonpredict  =>  [ qw( 456791 803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '=',
        choices     =>  [ qw( 0110 ) ],
        count       =>  2,
        predict     =>  [ qw( 456790 498703  ) ],
        nonpredict  =>  [ qw( 456791 803092 698389 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '==',
        choices     =>  [ qw( 0110 ) ],
        count       =>  2,
        predict     =>  [ qw( 456790 498703  ) ],
        nonpredict  =>  [ qw( 456791 803092 698389 ) ],
    );

    # !=

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'ne',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is not',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is not equal to',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is not a member of',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is not part of',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is less than or greater than',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is less than or more than',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is greater than or less than',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is more than or less than',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'does not equal',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'not',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'not equal to',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'not equals',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '!=',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '! =',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '!==',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '! ==',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '<>',
        choices     =>  [ qw( 0110 0111 0209 0211 0217 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    # <

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '<',
        choices     =>  [ qw( 0107 ) ],
        count       =>  3,
        predict     =>  [ qw( 803092 786792 456787 ) ],
        nonpredict  =>  [ qw( 456788 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'lt',
        choices     =>  [ qw( 0107 ) ],
        count       =>  3,
        predict     =>  [ qw( 803092 786792 456787 ) ],
        nonpredict  =>  [ qw( 456788 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is less than',
        choices     =>  [ qw( 0107 ) ],
        count       =>  3,
        predict     =>  [ qw( 803092 786792 456787 ) ],
        nonpredict  =>  [ qw( 456788 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is fewer than',
        choices     =>  [ qw( 0107 ) ],
        count       =>  3,
        predict     =>  [ qw( 803092 786792 456787 ) ],
        nonpredict  =>  [ qw( 456788 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'before',
        choices     =>  [ qw( 0107 ) ],
        count       =>  3,
        predict     =>  [ qw( 803092 786792 456787 ) ],
        nonpredict  =>  [ qw( 456788 698389 359962 906786 456789 ) ],
    );

    # >

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '>',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 803092 786792 456787 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'gt',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 803092 786792 456787 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is more than',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 803092 786792 456787 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is greater than',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 803092 786792 456787 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'after',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 803092 786792 456787 ) ],
    );

    # <=

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '<=',
        choices     =>  [ qw( 0107 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'le',
        choices     =>  [ qw( 0107 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is less than or equal to',
        choices     =>  [ qw( 0107 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is fewer than or equal to',
        choices     =>  [ qw( 0107 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'on or before',
        choices     =>  [ qw( 0107 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'before or on',
        choices     =>  [ qw( 0107 ) ],
        count       =>  4,
        predict     =>  [ qw( 803092 786792 456787 456788 ) ],
        nonpredict  =>  [ qw( 698389 359962 906786 456789 ) ],
    );

    # >=

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  '>=',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 786792 803092 906786 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'ge',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 786792 803092 906786 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is more than or equal to',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 786792 803092 906786 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'is greater than or equal to',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 786792 803092 906786 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'on or after',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 786792 803092 906786 ) ],
    );

    selection_tests(
        source => $sourcefile,  fields => \@fields, 
        params => \%parameters, index  => $index,
        column      =>  'ward',
        relation    =>  'after or on',
        choices     =>  [ qw( 0200 ) ],
        count       =>  3,
        predict     =>  [ qw( 456789 456791 698389 ) ],
        nonpredict  =>  [ qw( 786792 803092 906786 ) ],
    );

    ok(chdir $topdir, 'changed back to original directory after testing');
}

