#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 31;

BEGIN { use_ok('Chandra::Table') }

Chandra::Component->reset;

# ── Test data ─────────────────────────────────────────────

my @data = (
    { name => 'Alice',   email => 'alice@example.com',   role => 'admin', active => 1 },
    { name => 'Bob',     email => 'bob@example.com',     role => 'user',  active => 1 },
    { name => 'Charlie', email => 'charlie@example.com', role => 'user',  active => 0 },
    { name => 'Diana',   email => 'diana@example.com',   role => 'guest', active => 1 },
    { name => 'Eve',     email => 'eve@example.com',     role => 'admin', active => 0 },
);

my @columns = (
    { key => 'name',   label => 'Name',   sortable => 1 },
    { key => 'email',  label => 'Email',  sortable => 1 },
    { key => 'role',   label => 'Role',   filterable => 1, filter_options => [qw(admin user guest)] },
    { key => 'active', label => 'Active', type => 'boolean' },
);

# ── 1: Creation ──────────────────────────────────────────

my $table = Chandra::Table->new(
    columns   => \@columns,
    data      => \@data,
    page_size => 3,
);
ok($table, 'table created');
isa_ok($table, 'Chandra::Table');
isa_ok($table, 'Chandra::Component');

# ── 2: Render produces HTML ──────────────────────────────

my $html = $table->render;
like($html, qr/<table/, 'render produces table');
like($html, qr/<thead/, 'has thead');
like($html, qr/<tbody/, 'has tbody');
like($html, qr/Name/, 'header shows Name');
like($html, qr/Email/, 'header shows Email');
like($html, qr/Alice/, 'first row has Alice');
like($html, qr/Bob/, 'second row has Bob');
like($html, qr/Charlie/, 'third row has Charlie');
unlike($html, qr/Diana/, 'Diana not on page 1 (page_size=3)');

# ── 3: Pagination ────────────────────────────────────────

like($html, qr/page 1 of 2/, 'pagination shows page 1 of 2');

$table->on_page(2);
my $html2 = $table->render;
like($html2, qr/Diana/, 'page 2 has Diana');
like($html2, qr/Eve/, 'page 2 has Eve');
unlike($html2, qr/Alice/, 'page 2 does not have Alice');

# ── 4: Sorting ───────────────────────────────────────────

$table->on_page(1);
$table->on_sort_column('name');
my $sorted_html = $table->render;
# Ascending by name: Alice, Bob, Charlie
like($sorted_html, qr/Alice.*Bob.*Charlie/s, 'sorted ascending by name');

$table->on_sort_column('name');  # toggle to desc
my $desc_html = $table->render;
like($desc_html, qr/Eve.*Diana.*Charlie/s, 'sorted descending by name');

# ── 5: Filtering ─────────────────────────────────────────

# Reset sort
$table->on_sort_column('email');  # switch sort column to reset
$table->on_page(1);

$table->on_filter('role', 'admin');
my $filtered = $table->_filtered_data;
is(scalar @$filtered, 2, 'filter by admin returns 2 rows');

$table->on_filter('role', '');  # clear filter
my $unfiltered = $table->_filtered_data;
is(scalar @$unfiltered, 5, 'cleared filter returns all 5 rows');

# ── 6: Row selection ────────────────────────────────────

my $sel_table = Chandra::Table->new(
    columns    => \@columns,
    data       => \@data,
    page_size  => 10,
    selectable => 'multi',
);

$sel_table->on_select_row(0);
$sel_table->on_select_row(2);
my @selected = $sel_table->selected_rows;
is(scalar @selected, 2, 'multi select: 2 rows selected');

# Toggle off
$sel_table->on_select_row(0);
@selected = $sel_table->selected_rows;
is(scalar @selected, 1, 'deselect: 1 row remaining');

# Single select
my $single_table = Chandra::Table->new(
    columns    => \@columns,
    data       => \@data,
    page_size  => 10,
    selectable => 'single',
);
$single_table->on_select_row(0);
$single_table->on_select_row(2);
@selected = $single_table->selected_rows;
is(scalar @selected, 1, 'single select: only 1 row selected');

# ── 7: Boolean column ───────────────────────────────────

my $bool_html = $sel_table->render;
ok($bool_html =~ /\xe2\x9c\x93/ || $bool_html =~ /\x{2713}/, 'boolean true renders checkmark');

# ── 8: CSV export ────────────────────────────────────────

my $csv = $sel_table->to_csv;
my @csv_lines = split /\n/, $csv;
is($csv_lines[0], 'Name,Email,Role,Active', 'CSV header correct');
like($csv_lines[1], qr/Alice,alice\@example\.com,admin,1/, 'CSV first data row');
is(scalar @csv_lines, 6, 'CSV has 1 header + 5 data rows');

# ── 9: set_data ──────────────────────────────────────────

$sel_table->set_data([{ name => 'New', email => 'new@test.com', role => 'user', active => 1 }]);
my $new_html = $sel_table->render;
like($new_html, qr/New/, 'set_data replaces data');
unlike($new_html, qr/Alice/, 'old data gone after set_data');

# ── 10: Empty state ──────────────────────────────────────

$sel_table->set_data([]);
my $empty_html = $sel_table->render;
like($empty_html, qr/No data/, 'empty state message shown');

done_testing;
