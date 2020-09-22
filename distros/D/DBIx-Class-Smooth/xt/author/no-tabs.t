use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::NoTabs 0.15

use Test::More 0.88;
use Test::NoTabs;

my @files = (
    'lib/DBIx/Class/Smooth.pm',
    'lib/DBIx/Class/Smooth/Fields.pm',
    'lib/DBIx/Class/Smooth/FilterItem.pm',
    'lib/DBIx/Class/Smooth/Flatten/DateTime.pm',
    'lib/DBIx/Class/Smooth/Helper/ResultSet/Shortcut/AddColumn.pm',
    'lib/DBIx/Class/Smooth/Helper/ResultSet/Shortcut/Join.pm',
    'lib/DBIx/Class/Smooth/Helper/ResultSet/Shortcut/OrderByCollation.pm',
    'lib/DBIx/Class/Smooth/Helper/ResultSet/Shortcut/RemoveColumns.pm',
    'lib/DBIx/Class/Smooth/Helper/Row/Definition.pm',
    'lib/DBIx/Class/Smooth/Helper/Row/JoinTable.pm',
    'lib/DBIx/Class/Smooth/Helper/Util.pm',
    'lib/DBIx/Class/Smooth/Lookup/DateTime.pm',
    'lib/DBIx/Class/Smooth/Lookup/DateTime/datepart.pm',
    'lib/DBIx/Class/Smooth/Lookup/DateTime/day.pm',
    'lib/DBIx/Class/Smooth/Lookup/DateTime/hour.pm',
    'lib/DBIx/Class/Smooth/Lookup/DateTime/minute.pm',
    'lib/DBIx/Class/Smooth/Lookup/DateTime/month.pm',
    'lib/DBIx/Class/Smooth/Lookup/DateTime/second.pm',
    'lib/DBIx/Class/Smooth/Lookup/DateTime/year.pm',
    'lib/DBIx/Class/Smooth/Lookup/Operators.pm',
    'lib/DBIx/Class/Smooth/Lookup/Operators/gt.pm',
    'lib/DBIx/Class/Smooth/Lookup/Operators/gte.pm',
    'lib/DBIx/Class/Smooth/Lookup/Operators/in.pm',
    'lib/DBIx/Class/Smooth/Lookup/Operators/like.pm',
    'lib/DBIx/Class/Smooth/Lookup/Operators/lt.pm',
    'lib/DBIx/Class/Smooth/Lookup/Operators/lte.pm',
    'lib/DBIx/Class/Smooth/Lookup/Operators/not_in.pm',
    'lib/DBIx/Class/Smooth/Lookup/Util.pm',
    'lib/DBIx/Class/Smooth/Lookup/ident.pm',
    'lib/DBIx/Class/Smooth/Lookup/substring.pm',
    'lib/DBIx/Class/Smooth/Q.pm',
    'lib/DBIx/Class/Smooth/Result.pm',
    'lib/DBIx/Class/Smooth/ResultBase.pm',
    'lib/DBIx/Class/Smooth/ResultSet.pm',
    'lib/DBIx/Class/Smooth/ResultSetBase.pm',
    'lib/DBIx/Class/Smooth/Schema.pm',
    't/00-compile.t',
    't/00-report-prereqs.dd',
    't/00-report-prereqs.t',
    't/01-field_functions.t',
    't/02-schema-helper-row-definition.t',
    't/03-q.t',
    't/04-filter.t',
    't/etc/test_fixtures.pl',
    't/lib/TestFor/DBIx/Class/Smooth/Schema.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/Result.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/Result/Author.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/Result/Book.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/Result/BookAuthor.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/Result/Country.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/Result/Edition.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/ResultBase.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/ResultSet.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/ResultSet/Author.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/ResultSet/Book.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/ResultSet/Country.pm',
    't/lib/TestFor/DBIx/Class/Smooth/Schema/ResultSetBase.pm'
);

notabs_ok($_) foreach @files;
done_testing;
