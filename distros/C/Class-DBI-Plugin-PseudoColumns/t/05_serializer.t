use strict;
use Test::More;

BEGIN {
    for my $module (qw/DBD::SQLite Storable MIME::Base64/) {
        eval "use $module";
        if ($@) {
            plan skip_all => "needs $module for testing";
        }
    }
    plan tests => 9;
}

package Music::CD;

use base 'Class::DBI';
use File::Temp qw/tempfile/;

use Class::DBI::Plugin::PseudoColumns;

my (undef, $DB) = tempfile();
my @DSN = ("dbi:SQLite:dbname=$DB", '', '', { AutoCommit => 1 });

END { unlink $DB if -e $DB }

__PACKAGE__->set_db(Main => @DSN);
__PACKAGE__->table('cd');
__PACKAGE__->columns(All => qw/cdid artist title year reldate properties/);
__PACKAGE__->pseudo_columns(properties => qw/asin tag/);
__PACKAGE__->serializer(properties => sub {
    MIME::Base64::encode_base64(Storable::nfreeze(shift))
});
__PACKAGE__->deserializer(properties => sub {
    Storable::thaw(MIME::Base64::decode_base64(shift))
});

sub CONSTRUCT {
    shift->db_Main->do(qq{
        CREATE TABLE cd (
            cdid int UNSIGNED auto_increment,
            artist varchar(255),
            title varchar(255),
            year int,
            reldate date,
            properties text,
            PRIMARY KEY(cdid)
        )
    });
}

package main;

Music::CD->CONSTRUCT;

my $row = Music::CD->create({
    cdid    => '1',
    artist  => 'foo',
    title   => 'bar',
    year    => '2006',
    reldate => '2006-01-01',
    asin    => 'ABCDEFG',
    tag     => [qw/FOO BAR BAZ/],
});

is($row->cdid, 1, "cmp for cdid()");
is($row->artist, 'foo', "cmp for artist()");
is($row->title, 'bar', "cmp for title()");
is($row->year, 2006, "cmp for year()");
is($row->reldate, '2006-01-01', "cmp for reldate()");
is($row->asin, 'ABCDEFG', "create() - cmp for asin");
is_deeply($row->tag, [qw/FOO BAR BAZ/], "create() - cmp for tag");

$row->asin('NIPOTAN');
$row->tag([qw/A B C D E/]);
$row->update;
is($row->asin, 'NIPOTAN', "update() - cmp for asin");
is_deeply($row->tag, [qw/A B C D E/], "update() - cmp for tag");
