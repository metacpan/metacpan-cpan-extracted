#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 67;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    note "************* DBIx::DR *************";
    use_ok 'DBIx::DR';
    use_ok 'DBD::SQLite';
    use_ok 'File::Temp', 'tempdir';
    use_ok 'File::Path', 'remove_tree';
    use_ok 'File::Spec::Functions', 'catfile', 'rel2abs';
    use_ok 'File::Basename', 'dirname', 'basename';
}

my $temp_dir = tempdir;
END {
    remove_tree $temp_dir, { verbose => 0 };
    ok !-d $temp_dir, "Temporary dir was removed: $temp_dir";
}
my $test_dir = catfile(dirname($0), 'sql');
ok -d $test_dir, 'Directory contained sqls is found: ' . $test_dir;

ok -d $temp_dir, "Temporary directory was created: $temp_dir";
my $db_file = "$temp_dir/db.sqlite";

my $dbh = DBIx::DR->connect(
    "dbi:SQLite:dbname=$db_file", '', '',
    {
            dr_sql_dir => $test_dir,
            RaiseError      => 1,
            PrintError      => 0,
            PrintWarn       => 0,
    });

isa_ok $dbh => 'DBIx::DR::db', 'Connector was created';
ok -r $db_file, 'Database file was created';

ok $dbh->{'private_DBIx::DR_iterator'} eq 'dbix-dr-iterator#new',
    'Default iterator class';
ok $dbh->{'private_DBIx::DR_item'} eq 'dbix-dr-iterator-item#new',
    'Default item class';

my $res = $dbh->perform(q{
        CREATE TABLE tbl (id INTEGER PRIMARY KEY, value CARCHAR(32))
    }
);
is $res, '0E0', 'Table tbl was created';

my @values = (1, 2, 3, 4, 6, 'abc', 'def');
for(@values) {
    $res = $dbh->perform(
        'INSERT INTO tbl (value) VALUES (<%= $value %>)',
        value  => $_
    );

    ok $res && $res ne '0E0', 'Array item was inserted';
}

$res = $dbh->perform(q[
        UPDATE
            tbl
        SET
            value = value || <%= $suffix %>
        WHERE
            id > <%= $id_limit %>
    ],
    suffix => '_suffix',
    id_limit => 2
);


ok $res == @values - 2, 'Updated was passed';

$res = $dbh->select('SELECT * FROM tbl');
isa_ok $res => 'DBIx::DR::Iterator', 'A few rows were fetched';
ok $res->count == @values, 'Rows count has well value';
while(my $v = $res->next) {
    ok $v->id > 0, 'Record identifier: ' . $v->id;
    if ($v->id > 2) {
        ok $v->value eq $values[ $v->id - 1 ] . '_suffix',
            'Record value: ' . $v->value;
    } else {
        ok $v->value eq $values[ $v->id - 1 ], 'Record value: ' . $v->value;
    }
}



my $select_file = catfile $test_dir, 'select_ids.sql.ep';
ok -r $select_file, 'select.sql is found';

my $w;
eval {
    local $SIG{__WARN__} = sub { $w = shift };
    $dbh->select(
        -f          => 'select_ids',
        ids         => [ 1, 2 ],
        -hash       => 'id',
        -item       => 'my_item_package#new',
        -iterator   => 'my_iterator_package#new',
        -die        => 1,
        -warn       => 1,
    )
};

like $@, qr{SELECT}, '-die statement';
like $w, qr{SELECT}, '-warn statement';

$res = $dbh->select(
    -f          => 'select_ids',
    ids         => [ 1, 2 ],
    -hash       => 'id',
    -item       => 'my_item_package#new',
    -iterator   => 'my_iterator_package#new'
);

ok 'HASH' eq ref $res->{fetch}, 'SELECT was done';
ok $res->count == 2, 'Rows count has well value';
ok $res->get(1)->value eq $values[0], 'First item';
ok $res->get(2)->value eq $values[1], 'Second item';

$res = $dbh->select(
    -f          => rel2abs($select_file),
    ids         => [ 1, 2 ],
    -hash       => 'id',
    -item       => 'my_item_package#new',
    -iterator   => 'my_iterator_package#new'
);
isa_ok $res => 'MyIteratorPackage', 'Repeat sql from file';
ok $res->count == 2, 'Rows count has well value';

my @a = sort { $a->id <=> $b->id } $res->all;
ok @a == $res->count, 'Rows count has well value';
is $a[0]->value, $values[0], 'First item';
is $a[1]->value, $values[1], 'Second item';


$res = $dbh->single('SELECT * FROM tbl WHERE id = <%= $id %>', id => 1);
ok $res, 'Select one exists row';
ok $res->id == 1, 'Identifier';
ok $res->value eq $values[0], 'Value';


$res = $dbh->single('SELECT * FROM tbl WHERE id = <%= $id %>', id => 5000);
ok !$res, 'No results';


$dbh->set_helper(
    foo => sub { 'foo' },
    bar => sub { $_[0]->call_helper('foo') . 'bar' },
);

$res = $dbh->single('SELECT <%= foo %> AS foo');
ok $res->foo eq 'foo', 'User helper';

$res = $dbh->single('SELECT <%= bar %> AS bar');
ok $res->bar eq 'foobar', 'User helper (call the other helper)';


$res = eval { $dbh->perform(-f => 'unknown_function') };
my $e = $@ // '';
ok $e, 'Exception';
my ($line) = $e =~ /unknown_function\.sql\.ep\s+line\s+(\d+)/;
diag $e unless ok $line, '"at line" is present';

my $fname = catfile($test_dir, 'unknown_function.sql.ep');
ok -f $fname, $fname;
open my $fh, '<', $fname;
my @lines = <$fh>;
my ($line_real) = grep { $lines[$_] =~ /UNKNOWN_FUNCTION/ } 0 .. $#lines;
$line_real++;
cmp_ok $line, '==', $line_real, 'Exception point';


package MyItemPackage;
use base 'DBIx::DR::Iterator::Item';
use Test::More;

sub value {
    my ($self) = @_;
    ok @_ == 1, 'Get item value';
    return $self->SUPER::value;
}

package MyIteratorPackage;
use base 'DBIx::DR::Iterator';
use Test::More;

sub count {
    my ($self) = @_;
    ok @_ == 1, 'Get iterator size';
    return $self->SUPER::count;
}

=head1 COPYRIGHT

 Copyright (C) 2011 Dmitry E. Oboukhov <unera@debian.org>
 Copyright (C) 2011 Roman V. Nikolaev <rshadow@rambler.ru>

 This program is free software, you can redistribute it and/or
 modify it under the terms of the Artistic License.

=cut
