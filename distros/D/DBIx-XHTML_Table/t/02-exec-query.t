#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use DBIx::XHTML_Table;
use Test::More;
use Data::Dumper;

eval "use DBD::CSV";
plan skip_all => "DBD::CSV required" if $@;

eval "use HTML::TableExtract";
plan skip_all => "HTML::TableExtract required" if $@;

plan tests => 10;

my $dbh = DBI->connect ("dbi:CSV:", undef, undef, {
    f_ext      => ".csv/r",
    f_dir      => "t/data/unit/02/",
    RaiseError => 1,
});

is output( 'select * from test' ),
    '<table><thead><tr><th>Id</th><th>Parent</th><th>Name</th><th>Description</th></tr></thead><tbody><tr><td>1</td><td></td><td>root</td><td>the root</td></tr><tr><td>2</td><td>1</td><td>kid1</td><td>some kid</td></tr><tr><td>3</td><td>1</td><td>kid2</td><td>some other kid</td></tr><tr><td>4</td><td>2</td><td>grandkid1</td><td>a grandkid</td></tr><tr><td>5</td><td>3</td><td>grandkid2</td><td>another grandkid</td></tr><tr><td>6</td><td>3</td><td>greatgrandkid1</td><td>a great grandkid</td></tr></tbody></table>',
    "select * returns all rows"
;

is output( 'select id,parent,name,description from test' ),
    '<table><thead><tr><th>Id</th><th>Parent</th><th>Name</th><th>Description</th></tr></thead><tbody><tr><td>1</td><td></td><td>root</td><td>the root</td></tr><tr><td>2</td><td>1</td><td>kid1</td><td>some kid</td></tr><tr><td>3</td><td>1</td><td>kid2</td><td>some other kid</td></tr><tr><td>4</td><td>2</td><td>grandkid1</td><td>a grandkid</td></tr><tr><td>5</td><td>3</td><td>grandkid2</td><td>another grandkid</td></tr><tr><td>6</td><td>3</td><td>greatgrandkid1</td><td>a great grandkid</td></tr></tbody></table>',
    "select all fields returns all rows"
;

is_deeply [ output( 'select id from test', 1 ) ],
    [ map [$_], 'Id', 1 .. 6 ],
    "select id returns only id rows";

is_deeply [ output( 'select parent from test', 1 ) ],
    [ map [$_], 'Parent', undef, 1, 1, 2, 3, 3 ],
    "select parent returns only parent rows";

is_deeply [ output( 'select name from test', 1 ) ],
    [ map [$_], qw(Name root kid1 kid2 grandkid1 grandkid2 greatgrandkid1) ],
    "select name returns only name rows";

is_deeply [ output( 'select description from test', 1 ) ],
    [ map [$_], 'Description', 'the root', 'some kid', 'some other kid', 'a grandkid', 'another grandkid', 'a great grandkid' ],
    "select description returns only description rows";

is_deeply [ output( 'select name from test where id = 2', 1 ) ],
    [ map [$_], qw( Name kid1 )],
    "select with where works on one in-place arg";

is_deeply [ output( 'select id from test where name = ?', 1, [ 'kid1' ]  ) ],
    [ map [$_], qw( Id 2 )],
    "select with where works on one bind arg";

is_deeply [ output( 'select description from test where name = ? and parent = ?', 1, [ 'kid1', 1 ]  ) ],
    [ map [$_], 'Description', 'some kid' ],
    "select with where works on multiple bind args";

# self-joining is not implemented in SQL::Statement
# so we use an exact copy of our test csv file
is_deeply [ output( 'select t1.name as child, t2.name as parent from test t1 join test_copy t2 on t1.parent=t2.id', 1 ) ],
    [
        [ qw( Child Parent ) ],
        [ qw( kid1 root ) ],
        [ qw( kid2 root ) ],
        [ qw( grandkid1 kid1 ) ],
        [ qw( grandkid2 kid2 ) ],
        [ qw( greatgrandkid1 kid2 ) ],
    ],
    "inner join works";


sub output {
    my ($query, $extract, $bind_args) = @_;
    my $output = DBIx::XHTML_Table
        ->new($dbh)
        ->exec_query( $query, $bind_args )
        ->output({ no_indent => 1 })
    ;
    if ($extract) {
        $extract = HTML::TableExtract->new( keep_headers => 1 );
        $extract->parse( $output );
        return $extract->rows;
    } else {
        return $output;
    }
}
