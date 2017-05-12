package Dummy::DBIx::Skinny::Row;
use strict;
use warnings;

sub new {
    bless {}, __PACKAGE__;
}
sub row {
    10000 # dummy.
}

package Dummy::DBIx::Skinny::Iterator;
use strict;
use warnings;

sub new {
    my ($class, $container) = @_;
    $container ||= [];
    bless {pointer => 0, container => $container, }, __PACKAGE__;
}

sub next {
    my $self = $_[0];
    if ( length(@{ $self->{container}}) <= $self->{pointer} ) {
        return;
    }
    my $ret = $self->{container}->[$self->{pointer}];
    $self->{pointer}++;
    return $ret;
}

sub first {
    my $self = $_[0];
    $self->{container}->[0];
}

package Stub::DBIx::Skinny;
use strict;
use warnings;

sub new { bless +{}, __PACKAGE__ }

sub search_by_sql {
    my ($self, $sql, ) = @_;
    $self->{search_by_sql_log} ||= [];
    push @{$self->{search_by_sql_log}}, $sql;
    Dummy::DBIx::Skinny::Iterator->new([
        Dummy::DBIx::Skinny::Row->new,
    ]);
}

sub log {
    $_[0]->{search_by_sql_log};
}

package main;
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::Dumper;
use DBIx::Skinny::Pager::Logic::MySQLFoundRows;

{
    my $test_name = "normal case";

    my $stub = Stub::DBIx::Skinny->new;
    my $rs = DBIx::Skinny::Pager::Logic::MySQLFoundRows->new({ skinny => $stub });
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    my $limit = 10;
    $rs->limit($limit);
    $rs->offset(20);
    $rs->select([qw(foo bar baz)]);
    my ($iter, $pager) = $rs->retrieve;
    
    is(@{$stub->log}, 2, "$test_name: execute query 2 times")
        or diag(Dumper($stub->log));
    like($stub->log->[0], qr/SQL_CALC_FOUND_ROWS/, "$test_name: first query should contain SQL_CALC_FOUND_ROWS");
    like($stub->log->[1], qr/FOUND_ROWS\(\)/, "$test_name: second query should contain FOUND_ROWS()");

    isa_ok($pager, "Data::Page");
    is($pager->total_entries, Dummy::DBIx::Skinny::Row->row, "$test_name: shoud same as Dummy::DBIx::Skinny::Row#row");
    is($pager->entries_per_page, $limit, "$test_name: should same as limit argument");
    is($pager->current_page, 3);
}

{
    my $test_name = "use with page";

    my $stub = Stub::DBIx::Skinny->new;
    my $rs = DBIx::Skinny::Pager::Logic::MySQLFoundRows->new({ skinny => $stub });
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    my $limit = 10;
    $rs->limit($limit);
    my $page = 5;
    $rs->page(5);
    $rs->select([qw(foo bar baz)]);
    my ($iter, $pager) = $rs->retrieve;
    
    is(@{$stub->log}, 2, "$test_name: execute query 2 times")
        or diag(Dumper($stub->log));
    like($stub->log->[0], qr/SQL_CALC_FOUND_ROWS/, "$test_name: first query should contain SQL_CALC_FOUND_ROWS");
    like($stub->log->[0], qr/OFFSET @{[ ($page-1) * $limit ]}/, "$test_name: first query should contain offset");
    like($stub->log->[1], qr/FOUND_ROWS\(\)/, "$test_name: second query should contain FOUND_ROWS()");

    isa_ok($pager, "Data::Page");
    is($pager->total_entries, Dummy::DBIx::Skinny::Row->row, "$test_name: shoud same as Dummy::DBIx::Skinny::Row#row");
    is($pager->entries_per_page, $limit, "$test_name: should same as limit argument");
    is($pager->current_page, $page, "$test_name: should same as page argument");
}

{
    my $test_name = "with resultset";

    my $stub = Stub::DBIx::Skinny->new;
    my $rs = DBIx::Skinny::Pager::Logic::MySQLFoundRows->new({ skinny => $stub });
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    my $limit = 10;
    $rs->limit($limit);
    my $page = 5;
    $rs->page(5);
    $rs->select([qw(foo bar baz)]);
    my $resultset = $rs->retrieve;
    
    isa_ok($resultset, "DBIx::Skinny::Pager::ResultSet");
    isa_ok($resultset->pager, "Data::Page");
    isa_ok($resultset->iterator, "Dummy::DBIx::Skinny::Iterator");
}

done_testing();

