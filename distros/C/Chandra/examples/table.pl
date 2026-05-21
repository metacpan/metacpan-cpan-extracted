#!/usr/bin/env perl
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 'lib';
use Chandra::App;
use Chandra::Component;
use Chandra::Table;

my @users = (
    { name => 'Alice Johnson',   email => 'alice@example.com',   role => 'admin',  dept => 'Engineering', active => 1 },
    { name => 'Bob Smith',       email => 'bob@example.com',     role => 'user',   dept => 'Marketing',   active => 1 },
    { name => 'Charlie Brown',   email => 'charlie@example.com', role => 'user',   dept => 'Engineering', active => 0 },
    { name => 'Diana Prince',    email => 'diana@example.com',   role => 'admin',  dept => 'Management',  active => 1 },
    { name => 'Eve Torres',      email => 'eve@example.com',     role => 'guest',  dept => 'Sales',       active => 0 },
    { name => 'Frank Castle',    email => 'frank@example.com',   role => 'user',   dept => 'Engineering', active => 1 },
    { name => 'Grace Hopper',    email => 'grace@example.com',   role => 'admin',  dept => 'Engineering', active => 1 },
    { name => 'Hank Pym',        email => 'hank@example.com',    role => 'user',   dept => 'Research',    active => 1 },
    { name => 'Iris West',       email => 'iris@example.com',    role => 'user',   dept => 'Marketing',   active => 0 },
    { name => 'Jack Ryan',       email => 'jack@example.com',    role => 'guest',  dept => 'Sales',       active => 1 },
    { name => 'Karen Page',      email => 'karen@example.com',   role => 'user',   dept => 'Management',  active => 1 },
    { name => 'Leo Fitz',        email => 'leo@example.com',     role => 'user',   dept => 'Engineering', active => 1 },
);

my $app = Chandra::App->new(
    title  => 'Table Demo',
    width  => 900,
    height => 600,
);

$app->theme('dark');

my $table = Chandra::Table->new(
    columns => [
        { key => 'name',   label => 'Name',       sortable => 1, width => 180 },
        { key => 'email',  label => 'Email',      sortable => 1 },
        { key => 'role',   label => 'Role',       sortable => 1, filterable => 1,
          filter_options => [qw(admin user guest)] },
        { key => 'dept',   label => 'Department', sortable => 1, filterable => 1 },
        { key => 'active', label => 'Active',     type => 'boolean' },
    ],
    data       => \@users,
    page_size  => 5,
    selectable => 'multi',
    striped    => 1,
    on_row_click => sub {
        my ($row) = @_;
        print "Clicked: $row->{name}\n";
    },
);

$app->set_content('<div style="padding:20px;"><h1>User Directory</h1><div id="table"></div></div>');
$table->mount($app, '#table');

$app->run;
