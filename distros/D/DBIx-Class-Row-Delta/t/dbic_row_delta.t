
package Test::DBIx::Class::Row::Delta;
use parent "Test::Class";

use strict;
use warnings;
use Test::Most;
use Test::Exception;

use DBIx::Class::Row::Delta;

sub fake_dbic_obj {
    return bless { }, "Schema::Car";
}

sub simple_delta {
    my $self = shift;
    return DBIx::Class::Row::Delta->new({
        dbic_row    => $self->fake_dbic_obj,
        changes_sub => sub { return { } },
    });
}

sub test_new_fail : Tests() {
    throws_ok(
        sub { DBIx::Class::Row::Delta->new() },
        qr/is required at /ms,
        "Missing required params dies ok",
    );
}

sub test_new : Tests() {
    my $self = shift;
    ok(
        my $delta = DBIx::Class::Row::Delta->new({
            dbic_row    => $self->fake_dbic_obj,
            changes_sub => sub { return { Same => 1 } },
        }),
        "New with ok values",
    );
}

sub test_diff : Tests() {
    my $self = shift;
    my $delta = $self->simple_delta;

    eq_or_diff(
        $delta->diff(
            { same => 1, changed_value => "a", only_in_before => 12 },
            { same => 1, changed_value => "b", only_in_after => "abc" }
        ),
        {
            only_in_after => "abc",
            changed_value => "b",
        },
        "Diff ok",
    );
}

sub test_changes_from_delta : Tests() {
    my $self = shift;


    my $delta = DBIx::Class::Row::Delta->new({
        dbic_row    => $self->fake_dbic_obj,
        changes_sub => sub {
            return { same => 1, changed_value => "a", only_in_before => 12 },
        },
    });
    is(
        $delta->changes_from_delta({only_in_after => "abc", changed_value => "b"}),
        "changed_value(a => b), only_in_after('' => abc)",
        "changes_from_delta works, including with undefs",
    )
}

__PACKAGE__->runtests();
