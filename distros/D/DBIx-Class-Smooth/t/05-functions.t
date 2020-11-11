use strict;
use warnings;
use 5.20.0;
use Test::More;
use if $ENV{'AUTHOR_TESTING'}, 'Test::Warnings';

use lib 't/lib';
use DateTime;
use DBIx::Class::Smooth::Functions -all;
use experimental qw/postderef signatures/;

BEGIN {
    eval "use Test::mysqld"; if($@) {
        plan skip_all => 'Test::mysqld not installed';
    }
}

use Test::DBIx::Class
    -config_path => [qw/t etc test_fixtures/],
    -traits=>['Testmysqld'];

my $mysqld = Test::mysqld->new(auto_start => undef) or plan skip_all => $Test::mysqld::errstr;

fixtures_ok 'basic';

subtest group_1 => sub {
    my $ascii_for_D = 68;
    is Country->annotate_get(ascii => Ascii('name'), 2), $ascii_for_D, 'ascii 1';
    is Country->annotate_get(ascii => Ascii(\'Denmark')), $ascii_for_D, 'ascii 2';
    #is Country->annotate_get(char => Char(Ascii('name'))), 'S';
    #is Country->annotate_get(chr => CharLength(Char(\"x'65'", { using => 'utf8' }))), 1 or diag explain Char(\"x'65'", { using => 'utf8' });
    is Country->annotate_get(charlength => CharLength('name')), 6;
    is Country->annotate_get(ascii_charlength => CharLength(Ascii(\'D'))), 2 or diag explain CharLength(Ascii(\'D'));
    is Country->annotate_get(ascii_charlength => CharLength(Ascii('name'))), 2 or diag explain CharLength(Ascii('name'));

    is Country->annotate_get(concat => Concat('id', 'name')), '1Sweden';
    is Country->annotate_get(concat => Concat('id', 'name', \'_', \'Sweden')), '1Sweden_Sweden';

    is Country->annotate_get(concat_ws => ConcatWS(\', ', 'id', 'name')), '1, Sweden';
    is Country->annotate_get(concat_ws => ConcatWS('id', 'name', 'created_date_time')), 'Sweden12020-08-20 12:32:42';

    is Country->annotate_get(element => Elt('id', \'S', \'w', \'e')), 'S';
    is Country->annotate_get(exports => ExportSet(\'3', \'y', \'n', 'id', \'4')), 'y1y1n1n';
    is Country->annotate_get(export_length => CharLength(ExportSet(\'3', \'y', \'n', 'id', \'4'))), 7 or diag explain CharLength(ExportSet(\'3', \'y', \'n', 'id', \'4'));
};



subtest substring => sub {
    my $got = Country->annotate(name_substr => Substring('name', 2, 2));
    is $got->first->get_column('name_substr'), 'we', or diag explain $got->as_query;

    $got = Country->annotate(name_substr => Substring('name', 2));
    is $got->first->get_column('name_substr'), 'weden', or diag explain $got->as_query;

};

done_testing;
