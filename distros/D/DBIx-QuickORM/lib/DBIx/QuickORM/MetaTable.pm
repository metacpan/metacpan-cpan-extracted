package DBIx::QuickORM::MetaTable;
use strict;
use warnings;

our $VERSION = '0.000004';

use Carp qw/confess/;
use DBIx::QuickORM::Util qw/mod2file/;

sub import {
    my $class = shift;
    my $name = shift;
    my $cb = pop;
    my ($row_class, $extra) = @_;

    my $level = 0;
    my $caller = caller($level++);
    $caller = caller($level++) while $caller =~ m/BEGIN::Lift/;

    my $meta_table = $caller->can('_meta_table') // $caller->can('meta_table')
        or confess "Package '$caller' does not have the meta_table() function. Did you forget to `use DBIx::QuickORM ':META_TABLE';` first?";

    confess "loading $class requires a table name as the first argument" unless $name && !ref($name);
    confess "loading $class requires a subroutine reference as the last argument" unless $cb and ref($cb) eq 'CODE';
    confess "Too many arguments when loading $class" if $extra;

    my @args = ($name);

    if ($row_class) {
        eval { require(mod2file($row_class)); 1 } or confess "Could not load row class '$row_class': $@";
        push @args => $row_class;
    }

    push @args => $cb;

    $meta_table->(@args);
}

1;
