#!perl -T
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use Data::Dumper;
use DBIx::XHTML_Table;

eval "use DBD::CSV";
plan skip_all => "DBD::CSV required" if $@;
eval "use HTML::TableExtract";
plan skip_all => "HTML::TableExtract required" if $@;

plan tests => 54;

my $dbh = DBI->connect ('dbi:CSV:', undef, undef, {
    f_ext      => '.csv/r',
    f_dir      => 't/data/unit/05',
    RaiseError => 1,
});

my ( $table, $query );
my $nbsp = chr( 160 );

{   # headers - no mixed case duplicates
    $query = 'select * from table1'; 
    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    is_deeply extract( $table, 0 ), [qw(Hd_one Hd_two Hd_three)],     "default header modifications";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { lc shift } );
    is_deeply extract( $table, 0 ), [qw(hd_one hd_two hd_three)],     "all headers changed";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { uc shift }, 2 );
    is_deeply extract( $table, 0 ), [qw(Hd_one Hd_two HD_THREE)],     "header changed by col index";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { lc shift }, qw(HD_three) );
    is_deeply extract( $table, 0 ), [qw(Hd_one Hd_two hd_three)],     "mixed-case query matched by lowercased col key";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { uc shift }, qw(hd_TWo) );
    is_deeply extract( $table, 0 ), [qw(Hd_one HD_TWO Hd_three)],     "mixed-case query match by col key search";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { lcfirst( uc( shift ) ) }, qw(HD_twO) );
    is_deeply extract( $table, 0 ), [qw(Hd_one hD_TWO Hd_three)],     "header changed by exact col key";
}

{   # headers - mixed case duplicates
    $query = 'select * from table2'; 

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    is_deeply extract( $table, 0 ), [qw(Hd_one Hd_one Hd_two Hd_two)],     "default header modifications";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { lc shift } );
    is_deeply extract( $table, 0 ), [qw(hd_one hd_one hd_two hd_two)],     "all headers changed";

SKIP: {
    skip "these are broken", 4;
    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { uc shift }, [ 1 ] );
    is_deeply extract( $table, 0 ), [qw(Hd_one HD_ONE Hd_two Hd_two)],     "header changed by col index";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { lc shift }, qw(HD_one) );
    is_deeply extract( $table, 0 ), [qw(Hd_one hd_one Hd_two Hd_two)],     "mixed-case query matched by lowercased col key";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { uc shift }, qw(Hd_Two) );
    is_deeply extract( $table, 0 ), [qw(Hd_one Hd_one Hd_two HD_TWO)],     "mixed-case query matched by col key search";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_head( sub { lcfirst( uc( shift ) ) }, qw(hd_TWO) );
    is_deeply extract( $table, 0 ), [qw(Hd_one Hd_one hD_TWO Hd_two)],     "header changed by exact col key";
    };
}

{   # rows - no mixed case duplicates
    $query = 'select * from table1'; 

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    is_deeply extract( $table, 1 ), [(1) x 3],     "no mods - row 1 unchanged";
    is_deeply extract( $table, 2 ), [(1) x 3],     "no mods - row 2 unchanged";
    is_deeply extract( $table, 3 ), [(1) x 3],     "no mods - row 3 unchanged";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_cell( sub { $_[0] + 1 } );
    is_deeply extract( $table, 1 ), [(2) x 3],     "all cells - row 1 correct";
    is_deeply extract( $table, 2 ), [(2) x 3],     "all cells - row 2 correct";
    is_deeply extract( $table, 3 ), [(2) x 3],     "all cells - row 3 correct";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_cell( sub { $_[0] + 1 }, 1 );
    is_deeply extract( $table, 1 ), [1,2,1],              "col index - row 1 correct";
    is_deeply extract( $table, 2 ), [1,2,1],              "col index - row 2 correct";
    is_deeply extract( $table, 3 ), [1,2,1],              "col index - row 3 correct";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_cell( sub { $_[0] + 1 }, qw(HD_three) );
    is_deeply extract( $table, 1 ), [1,1,2],              "mixed-case query matched by lc col key - row 1";
    is_deeply extract( $table, 2 ), [1,1,2],              "mixed-case query matched by lc col key - row 2";
    is_deeply extract( $table, 3 ), [1,1,2],              "mixed-case query matched by lc col key - row 3";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_cell( sub { $_[0] + 1 }, qw(hd_TWo) );
    is_deeply extract( $table, 1 ), [1,2,1],              "mixed-case query matched by col key search - row 1";
    is_deeply extract( $table, 2 ), [1,2,1],              "mixed-case query matched by col key search - row 2";
    is_deeply extract( $table, 3 ), [1,2,1],              "mixed-case query matched by col key search - row 3";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->map_cell( sub { $_[0] + 2 }, qw(HD_twO) );
    is_deeply extract( $table, 1 ), [1,3,1],              "cells changed by exact col key - row 1";
    is_deeply extract( $table, 2 ), [1,3,1],              "cells changed by exact col key - row 2";
    is_deeply extract( $table, 3 ), [1,3,1],              "cells changed by exact col key - row 3";


    #---------
    # calc totals == total will be 2nd row
    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->calc_totals( );
    is_deeply extract( $table, 1 ), [3,3,3],              "calc totals - no mods";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->calc_totals( [], '%03d' );
    is_deeply extract( $table, 1 ), [qw(003 003 003)],    "calc totals - with mask";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->calc_totals( 1 );
    is_deeply extract( $table, 1 ), [$nbsp,3,$nbsp],      "calc totals - by one col index";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->calc_totals( [0, 2] );
    is_deeply extract( $table, 1 ), [3,$nbsp,3],          "calc totals - by one col index";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->calc_totals( qw(HD_three) );
    is_deeply extract( $table, 1 ), [$nbsp,$nbsp,3],      "calc totals - by matched lc col key";

    $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->calc_totals( qw(HD_twO) );
    is_deeply extract( $table, 1 ), [$nbsp,3,$nbsp],      "calc totals - by exact col key";


    #---------
    # calc subtotals
    $query = 'select * from table3'; 
    $table = make_with_subtotals( $query, group => 0 );
    is_deeply extract( $table, 1 ), [$nbsp,30,30,$nbsp,60,60],      "1st group subtotals by col index - correct totals";

    $table = make_with_subtotals( $query, group => 0 );
    is_deeply extract( $table, 5 ), [$nbsp,15,15,$nbsp,30,30],      "1st group subtotals by col index - correct subtotals 1";

    $table = make_with_subtotals( $query, group => 0 );
    is_deeply extract( $table, 9 ), [$nbsp,15,15,$nbsp,30,30],      "1st group subtotals by col index - correct subtotals 2";

    $table = make_with_subtotals( $query, group => 'GRP_1' );
    is_deeply extract( $table, 1 ), [$nbsp,30,30,$nbsp,60,60],      "1st group subtotals by col key - correct totals";

    $table = make_with_subtotals( $query, group => 'GRP_1' );
    is_deeply extract( $table, 5 ), [$nbsp,15,15,$nbsp,30,30],      "1st group subtotals by col key - correct subtotals 1";

    $table = make_with_subtotals( $query, group => 'GRP_1' );
    is_deeply extract( $table, 9 ), [$nbsp,15,15,$nbsp,30,30],      "1st group subtotals by col key - correct subtotals 2";

    $table = make_with_subtotals( $query, group => 'grp_1' );
    is_deeply extract( $table, 1 ), [$nbsp,30,30,$nbsp,60,60],      "1st group subtotals by matched lc col key - correct totals";

    $table = make_with_subtotals( $query, group => 'grp_1' );
    is_deeply extract( $table, 5 ), [$nbsp,15,15,$nbsp,30,30],      "1st group subtotals by matched lc col key - correct subtotals 1";

    $table = make_with_subtotals( $query, group => 'grp_1' );
    is_deeply extract( $table, 9 ), [$nbsp,15,15,$nbsp,30,30],      "1st group subtotals by matched lc col key - correct subtotals 2";

    #---------
    $table = make_with_subtotals( $query, group => 3 );
    is_deeply extract( $table, 1 ), [$nbsp,30,30,$nbsp,60,60],      "2nd group subtotals by col index - correct totals";

    $table = make_with_subtotals( $query, group => 3 );
    is_deeply extract( $table, 6 ), [$nbsp,20,20,$nbsp,40,40],      "2nd group subtotals by col index - correct subtotals 1";

    $table = make_with_subtotals( $query, group => 3 );
    is_deeply extract( $table, 9 ), [$nbsp,10,10,$nbsp,20,20],      "2nd group subtotals by col index - correct subtotals 2";

    $table = make_with_subtotals( $query, group => 'GRP_2' );
    is_deeply extract( $table, 1 ), [$nbsp,30,30,$nbsp,60,60],      "2nd group subtotals by col key - correct totals";

    $table = make_with_subtotals( $query, group => 'GRP_2' );
    is_deeply extract( $table, 6 ), [$nbsp,20,20,$nbsp,40,40],      "2nd group subtotals by col key - correct subtotals 1";

    $table = make_with_subtotals( $query, group => 'GRP_2' );
    is_deeply extract( $table, 9 ), [$nbsp,10,10,$nbsp,20,20],      "2nd group subtotals by col key - correct subtotals 2";

    $table = make_with_subtotals( $query, group => 'grp_2' );
    is_deeply extract( $table, 1 ), [$nbsp,30,30,$nbsp,60,60],      "2nd group subtotals by matched lc col key - correct totals";

    $table = make_with_subtotals( $query, group => 'grp_2' );
    is_deeply extract( $table, 6 ), [$nbsp,20,20,$nbsp,40,40],      "2nd group subtotals by matched lc col key - correct subtotals 1";

    $table = make_with_subtotals( $query, group => 'grp_2' );
    is_deeply extract( $table, 9 ), [$nbsp,10,10,$nbsp,20,20],      "2nd group subtotals by matched lc col key - correct subtotals 2";
}



exit;

sub make_with_subtotals {
    my ($query,%args) = @_;
    my $table = DBIx::XHTML_Table->new( $dbh )->exec_query( $query );
    $table->set_group( $args{group} );
    $table->calc_totals( $args{totals} );
    $table->calc_subtotals( $args{subtotals} );
    return $table;
}

sub extract {
    my ($table,$row,$col) = @_;
    my $extract = HTML::TableExtract->new( keep_headers => 1 );
    $extract->parse( $table->output );
    if (defined $row) {
        return @{[ $extract->rows ]}[$row];
    } elsif (defined $col) {
        # TODO: if needed
    } else {
        return $extract->rows;
    }
}

# 6962 Support for mixed case field names returned by the SQL query
# promoted to a unit test :D
