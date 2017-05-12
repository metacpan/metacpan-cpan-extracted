#!/usr/bin/perl -w

# 
# +------------+
# |  WARNING!  |
# +------------+
# 
# The code in this script is only meant to perform 
# an installation test.
#
# It is not meant for production purposes, since it uses
# some NON-DOCUMENTED features.
#      ^^^^^^^^^^^^^^
#
# To perform a test with a real database, use the script
# in the "examples" directory

use strict;
use DBI;
use DBIx::SQLCrosstab         1.17;
use DBIx::SQLCrosstab::Format 0.07;
my $othertest = shift;

my $col_names = [ 'country', 'location', 
   'pers#employee#f', 'pers#employee#m','pers#employee', 
   'pers#contractor#m', 'pers#contractor', 'pers',
   'sales#employee#m', 'sales#employee', 
   'sales#contractor#m', 'sales#contractor', 
   'sales#consultant#f', 'sales#consultant', 'sales',
   'dev#employee#m', 'dev#employee', 
   'dev#consultant#f', 'dev#consultant',
   'dev', 'total' ];

my $records = [
  [ 'Germany', 'Berlin', 5500, 0, 5500, 0, 0, 5500, 0, 0, 0, 0, 0, 0, 0, 
                         6000, 6000, 0, 0, 6000, 11500 ],
  [ 'Germany', 'Bonn',   0, 0, 0, 0, 0, 0, 5000, 5000, 0, 0, 0, 0, 5000, 0, 
                         0, 0, 0, 0, 5000 ],
  [ 'Germany', 'Munich', 0, 5000, 5000, 0, 0, 5000, 0, 0, 0, 0, 5500, 5500,
                         5500, 0, 0, 0, 0, 0, 10500 ],
  [ 'Germany', 'zzzz',   5500, 5000, 10500, 0, 0, 10500, 5000, 5000, 0, 0, 
                         5500, 5500, 10500, 6000, 6000, 0, 0, 6000, 27000 ],
  [ 'Italy', 'Rome',     0, 6000, 6000, 0, 0, 6000, 0, 0, 0, 0, 0, 0, 0, 
                         0, 0, 6000, 6000, 6000, 12000 ],
  [ 'Italy', 'zzzz',     0, 6000, 6000, 0, 0, 6000, 0, 0, 0, 0, 0, 0, 0, 0,
                         0, 6000, 6000, 6000, 12000 ],
  [ 'UK', 'London',      0, 0, 0, 5000, 5000, 5000, 0, 0, 5500, 5500,
                         0, 0, 5500, 0, 0, 0, 0, 0, 10500 ],
  [ 'UK', 'zzzz',        0, 0, 0, 5000, 5000, 5000, 0, 0, 5500, 5500, 0, 0,
                         5500, 0, 0, 0, 0, 0, 10500 ],
  [ 'zzzz', 'zzzz',      5500, 11000, 16500, 5000, 5000, 21500, 5000,
                         5000, 5500, 5500, 5500, 5500, 16000, 6000,
                         6000, 6000, 6000, 12000, 49500 ]
];

my $params = {
    dbh            => {dsn=>"dbi:ExampleP:test"},
    op             => [[ 'SUM', 'salary' ] ],    
    # op_col         => 'salary',
    title          => 'DBIx::SQLCrosstab test',
    records        => $records,
    col_names      => $col_names,
    title_in_header=> 1,
    add_colors     => 1,
    col_total      => 1,
    col_sub_total  => 1,
    commify        => 1, 
    rows           => [       
                        { col => 'country' },
                        { col => 'loc',     alias => 'location' }
                       ],
    cols           => [
                    { 
                        id => 'dept_id', 
                        value => 'dept',     
                        from => 'depts' 
                    },
                    { 
                        id => 'cat_id',  
                        value => 'category', 
                        from => 'categories' 
                    },
                    { 
                        id => 'gender',   
                        col_list => [ {id=>'f'}, {id =>'m'}],
                        from => 'person' 
                    },
                    ],

    from           => "", 
    };
    
my $xt;
my $xt_stub;
eval {$xt = DBIx::SQLCrosstab::Format->new($params)} ;
eval {$xt_stub = DBIx::SQLCrosstab::Format->new('STUB')};

#
# Notice: the tests MUST run in this given sequence.
# 
# Calling a later test without passing the 
# initial ones will make eveything fail.

my @tests = (qw(creation stub_create set_param
                save_params load_params
                recs query recs_stub query_stub 
                table table_stub bare_table 
                xml xml_stub yaml
                struct_hoh struct_losh struct_hoh
                struct_loh struct_lol ));

eval {require YAML;};
if ($@) {
    @tests = grep { $_ ne 'yaml' } @tests;
}
        
my %all_tests = (
    creation    => sub { defined $xt },
    stub_create => sub { defined $xt_stub },
    set_param   => sub { $xt_stub->set_param(dbh => $params->{dbh})},
    save_params => sub { $xt->save_params("test/test_params") },
    load_params => sub { $xt_stub->load_params("test/test_params") },
    recs        => sub { $xt->get_recs },
    query       => sub { $xt->{query} },
    recs_stub   => sub { $xt_stub->get_recs },
    query_stub  => sub { $xt_stub->{query} },
    table       => sub { $xt->as_html },
    table_stub  => sub { $xt_stub->as_html },
    bare_table  => sub { $xt->as_bare_html },
    xml         => sub { $xt->as_xml },
    xml_stub    => sub { $xt_stub->as_xml },
    struct_lol  => sub { $xt->as_perl_struct('lol') },
    struct_loh  => sub { $xt->as_perl_struct('loh') },
    struct_losh => sub { $xt->as_perl_struct('losh') },
    struct_hoh  => sub { $xt->as_perl_struct('hoh') },
    yaml        => sub { $xt->as_yaml()},
    failure     => sub { DBIx::SQLCrosstab::seterr(
           'This test MUST fail - Testing error reporting function')},
    # to activate this latest test, call the script as 
    # $ perl test.pl failure
);
     
if ($othertest) {
    push @tests, $othertest if exists $all_tests{$othertest};
}

my $total_tests = @tests;
my $passed      = 0;
my $executed    = 0;
my $failed      = 0;

for my $test (@tests) {
    $executed++;
    printf "%s%s ", $test, '.' x (15 - length($test));
    if ( &{$all_tests{$test}} ) {
        $passed++;
        print "ok\n";
    }
    else {
        print "not ok ($DBIx::SQLCrosstab::errstr)\n";
        $failed++;
    }
    last unless $xt;
}
printf "%-14s: %2d\n%-14s: %2d\n%-14s: %2d\n%-14s: %2d\n", 
        "tests", $total_tests, 
        "executed", $executed, 
        "passed", $passed, 
        "failed", $failed, ;
if ($passed == $total_tests) {
    print "all tests passed\n";
    print "If DBD::SQLite is installed, you can try now an extended test\n";
    print "Do you want to try the extended test? (Y/n) [Y] ";
    my $agreement = <>;
    chomp $agreement;
    if ( $agreement =~ /^\s*y?\s*$/i){
        do "test/test_extended.pl"
    }
    else {
        print "You may run the test manually after the installation is completed\n";
    }
}
else {
    printf "%4.2f%s passed, %4.2f%s failed\n", 
        $passed / ($total_tests) * 100, '%',
        $failed / ($total_tests) * 100, '%' ;
    print "Object not created - Additional tests not performed\n" 
        unless $xt;
}

