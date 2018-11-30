use strict;
use warnings;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use DBIx::Class::Smooth::Fields -all;

ok 1, 'Loaded';

my $tests = [
    {
        test => 'IntegerField(nullable => 1)',
        result => {
            data_type => 'integer',
            is_numeric => 1,
            is_nullable => 1,
        },
    },
    {
        test => 'MediumIntField(size => 3)',
        result => {
            data_type => 'mediumint',
            size => 3,
            is_numeric => 1,
        },
    },
    {
        test => 'SerialField()',
        result => {
            data_type => 'serial',
            is_numeric => 1,
        },
    },
    {
        test => 'SerialField(auto_increment => 1)',
        result => {
            data_type => 'serial',
            is_numeric => 1,
            is_auto_increment => 1,
        },
    },
    {
        test => 'VarcharField(size => 150)',
        result => {
            data_type => 'varchar',
            is_numeric => 0,
            size => 150,
        },
    },
    {
        test => 'VarcharField(size => 150, nullable => 1, -zerofill => 1)',
        result => {
            data_type => 'varchar',
            is_numeric => 0,
            size => 150,
            is_nullable => 1,
            extra => {
                zerofill => 1,
            },
        },
    },
    {
        test => 'VarcharField()',
        result => {
            data_type => 'varchar',
            is_numeric => 0,
        },
    },
    {
        test => 'BooleanField()',
        result => {
            data_type => 'boolean',
            is_numeric => 1,
        },
    },
    {
        test => 'BigIntField(-unsigned => 1, foreign_key => 1)',
        result => {
            data_type => 'bigint',
            is_numeric => 1,
            is_foreign_key => 1,
            extra => {
                unsigned => 1,
            },
        },
    },
    {
        test => 'BitField()',
        result => {
            data_type => 'bit',
            is_numeric => 1,
        },
    },
    {
        test => 'TinyIntField()',
        result => {
            data_type => 'tinyint',
            is_numeric => 1,
        },
    },
    {
        test => 'SmallIntField()',
        result => {
            data_type => 'smallint',
            is_numeric => 1,
        },
    },

    {
        test => 'DecimalField()',
        result => {
            data_type => 'decimal',
            is_numeric => 1,
        },
    },
    {
        test => 'DecimalField(size => [3])',
        result => {
            data_type => 'decimal',
            size => [3],
            is_numeric => 1,
        },
    },
    {
        test => 'DecimalField(size => [3], -unsigned => 1)',
        result => {
            data_type => 'decimal',
            is_numeric => 1,
            size => [3],
            extra => {
                unsigned => 1,
            }
        },
    },
    {
        test => 'DecimalField(size => [4, 2])',
        result => {
            data_type => 'decimal',
            size => [4, 2],
            is_numeric => 1,
        },
    },
    {
        test => 'DecimalField(size => [4, 2], -unsigned => 1, auto_nextval => 1)',
        result => {
            data_type => 'decimal',
            size => [4, 2],
            is_numeric => 1,
            auto_nextval => 1,
            extra => {
                unsigned => 1,
            }
        },
    },
    {
        test => 'DecimalField(size => [4, 2], default => 3.14)',
        result => {
            data_type => 'decimal',
            size => [4, 2],
            is_numeric => 1,
            default_value => 3.14,
        },
    },
    {
        test => 'FloatField()',
        result => {
            data_type => 'float',
            is_numeric => 1,
        },
    },
    {
        test => 'FloatField(nullable => 1)',
        result => {
            data_type => 'float',
            is_numeric => 1,
            is_nullable => 1,
        },
    },
    {
        test => 'DoubleField()',
        result => {
            data_type => 'double',
            is_numeric => 1,
        },
    },
    {
        test => 'CharField()',
        result => {
            data_type => 'char',
            is_numeric => 0,
        },
    },
    {
        test => 'VarbinaryField()',
        result => {
            data_type => 'varbinary',
            is_numeric => 0,
        },
    },
    {
        test => 'BinaryField()',
        result => {
            data_type => 'binary',
            is_numeric => 0,
        },
    },
    {
        test => 'TinyTextField()',
        result => {
            data_type => 'tinytext',
            is_numeric => 0,
        },
    },
    {
        test => 'TextField()',
        result => {
            data_type => 'text',
            is_numeric => 0,
        },
    },
    {
        test => 'MediumTextField()',
        result => {
            data_type => 'mediumtext',
            is_numeric => 0,
        },
    },
    {
        test => 'LongTextField()',
        result => {
            data_type => 'longtext',
            is_numeric => 0,
        },
    },
    {
        test => 'TinyBlobField()',
        result => {
            data_type => 'tinyblob',
            is_numeric => 0,
        },
    },
    {
        test => 'BlobField()',
        result => {
            data_type => 'blob',
            is_numeric => 0,
        },
    },
    {
        test => 'MediumBlobField()',
        result => {
            data_type => 'mediumblob',
            is_numeric => 0,
        },
    },
    {
        test => 'LongBlobField()',
        result => {
            data_type => 'longblob',
            is_numeric => 0,
        },
    },
    {
        test => 'EnumField(-list => [qw/here are values/])',
        result => {
            data_type => 'enum',
            is_numeric => 0,
            extra => {
                list => [qw/here are values/],
            },
        },
    },
    {
        test => q{EnumField(-list => [qw/here are values/], default_value => 'values')},
        result => {
            data_type => 'enum',
            is_numeric => 0,
            extra => {
                list => [qw/here are values/],
            },
            default_value => 'values',
        },
    },
    {
        test => 'EnumField(extra => { thing => 1 }, -list => [qw/here are values/])',
        result => {
            data_type => 'enum',
            is_numeric => 0,
            extra => {
                thing => 1,
                list => [qw/here are values/],
            },
        },
    },

    {
        test => 'IntegerField(-unsigned => 1, -whatever => 1)',
        result => {
            data_type => 'integer',
            is_numeric => 1,
            extra => {
                unsigned => 1,
                whatever => 1,
            },
        },
    },
    {
        test => q{NonNumericField(data_type => 'point', stuff => 0)},
        result => {
            data_type => 'point',
            is_numeric => 0,
            stuff => 0,
        },
    },
    {
        test => q{NonNumericField(data_type => 'point')},
        result => {
            data_type => 'point',
            is_numeric => 0,
        },
    },
    {
        test => q{IntegerField(stuff => 0, accessor => 'read_column', -renamed_from => 'former_name')},
        result => {
            data_type => 'integer',
            stuff => 0,
            is_numeric => 1,
            accessor => 'read_column',
            extra => {
                renamed_from => 'former_name',
            },
        },
    },
    {
        test => q{IntegerField(-stuff => 0, -unsigned => 1, accessor => 'read_column')},
        result => {
            data_type => 'integer',
            is_numeric => 1,
            accessor => 'read_column',
            extra => {
                unsigned => 1,
                stuff => 0,
            },
        },
    },
    {
        test => q{NumericField(data_type => 'strangeint', auto_increment => 1, sequence => 'strangeseq', retrieve_on_insert => 1)},
        result => {
            data_type => 'strangeint',
            is_numeric => 1,
            is_auto_increment => 1,
            sequence => 'strangeseq',
            retrieve_on_insert => 1,
        },
    },
    {
        test => q{IntegerField(retrieve_on_insert => 1, sequence => 'mysequence', default_sql => undef)},
        result => {
            data_type => 'integer',
            is_numeric => 1,
            retrieve_on_insert => 1,
            sequence => 'mysequence',
            default_value => \'NULL',
        },
    },
    {
        test => q{NonNumericField(auto_nextval => 1, data_type => 'custom')},
        result => {
            data_type => 'custom',
            auto_nextval => 1,
            is_numeric => 0,
        },
    },
    {
        test => 'DateTimeField()',
        result => {
            data_type => 'datetime',
            is_numeric => 0,
        },
    },
    {
        test => 'DateTimeField(default_sql => "NOW()")',
        result => {
            data_type => 'datetime',
            is_numeric => 0,
            default_value => \'NOW()',
        },
    },
    {
        test => 'DateTimeField(default_sql => "now()")',
        result => {
            data_type => 'datetime',
            is_numeric => 0,
            default_value => \'now()'
        },
    },
    {
        test => 'DateField()',
        result => {
            data_type => 'date',
            is_numeric => 0,
        },
    },
    {
        test => 'TimestampField(set_on_update => 1, set_on_create => 1, default_sql => "CURRENT_TIMESTAMP")',
        result => {
            data_type => 'timestamp',
            is_numeric => 0,
            set_on_update => 1,
            set_on_create => 1,
            default_value => \'CURRENT_TIMESTAMP'
        },
    },
    {
        test => 'TimeField(set_on_update => 1)',
        result => {
            data_type => 'time',
            is_numeric => 0,
            set_on_update => 1,
        },
    },
    {
        test => 'YearField()',
        result => {
            data_type => 'year',
            is_numeric => 0,
        },
    },
];

for my $test (@{ $tests }) {
    next if !length $test->{'test'};
    my $got = eval($test->{'test'});
    is_deeply $got, $test->{'result'}, $test->{'test'} or diag explain $got;
}

done_testing;
