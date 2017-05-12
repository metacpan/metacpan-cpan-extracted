package Dummy::DBIx::Skinny::Row;
use strict;
use warnings;

sub new { 
    my ($self, $hashref) = @_;
    bless $hashref, __PACKAGE__;
}

sub setup {}

package Stub::DBIx::Skinny;
use strict;
use warnings;
use DBIx::Skinny::Iterator;

sub new { bless {}, __PACKAGE__ }

sub set_iterator {
    my ($self, $val ) = @_;
    $_[0]->{iterator} = $val;
}

sub search_by_sql {
    my ($self, $sql, ) = @_;

    DBIx::Skinny::Iterator->new(
        skinny => $self,
        data => ( $self->{iterator} || [] ),
        row_class => "Dummy::DBIx::Skinny::Row",
    );
}

package main;
use strict;
use warnings;
use Test::More;
use DBIx::Skinny::Pager::Logic::PlusOne;

{
    my $stub = Stub::DBIx::Skinny->new;
    my $rs = DBIx::Skinny::Pager::Logic::PlusOne->new({ skinny => $stub });
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    my $limit = 10;
    $rs->limit($limit);
    $rs->offset(20);
    $rs->select([qw(foo bar baz)]);

    my $counter = $limit;
    my @iterator;
    while ( $counter ) {
        push(@iterator, {
            id => ($limit - $counter),
        });
        $counter--;
    }
    $stub->set_iterator(\@iterator);
    my ($iter, $pager) = $rs->retrieve;
    isa_ok($pager, "Data::Page");
    ok(!$pager->next_page, "next page should not exist");
    is($iter->count, $limit, "result and iter should be equal");
    my $last_row;
    while ( my $row = $iter->next ) {
        $last_row = $row;
    }
    is($last_row->{row_data}->{id}, $limit - 1, "last item should be 9th");

}

{
    my $stub = Stub::DBIx::Skinny->new;
    my $rs = DBIx::Skinny::Pager::Logic::PlusOne->new({ skinny => $stub });
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    my $limit = 10;
    $rs->limit($limit);
    $rs->offset(20);
    $rs->select([qw(foo bar baz)]);

    my $counter = $limit + 1;
    my @iterator;
    while ( $counter ) {
        push(@iterator, {
            id => ($limit - $counter + 1),
        });
        $counter--;
    }
    $stub->set_iterator(\@iterator);
    my ($iter, $pager) = $rs->retrieve;
    isa_ok($pager, "Data::Page");
    ok($pager->next_page, "next page should exist");
    is($iter->count, $limit, "result and iter should be equal");
    my $last_row;
    while ( my $row = $iter->next ) {
        $last_row = $row;
    }
    is($last_row->{row_data}->{id}, $limit - 1, "last item should be 9th");

}

{
    my $stub = Stub::DBIx::Skinny->new;
    my $rs = DBIx::Skinny::Pager::Logic::PlusOne->new({ skinny => $stub });
    $rs->from(['some_table']);
    $rs->add_where(foo => "bar");
    my $limit = 10;
    $rs->limit($limit);
    $rs->offset(20);
    $rs->select([qw(foo bar baz)]);

    my $counter = $limit + 1;
    my @iterator;
    while ( $counter ) {
        push(@iterator, {
            id => ($limit - $counter + 1),
        });
        $counter--;
    }
    $stub->set_iterator(\@iterator);
    my $resultset = $rs->retrieve;
    isa_ok($resultset->pager, "Data::Page");
    isa_ok($resultset->iterator, "DBIx::Skinny::Iterator");

}

done_testing();

