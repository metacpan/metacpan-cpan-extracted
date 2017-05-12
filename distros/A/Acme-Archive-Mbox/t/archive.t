#!perl -T

use Test::More tests => 15;
use strict;

use Acme::Archive::Mbox;
use File::Temp qw/ :POSIX /;

# new
my $archive = Acme::Archive::Mbox->new();
isa_ok($archive, 'Acme::Archive::Mbox', 'Object created');

# add_data and add_file
my ($file,$contents) = ('test/file', 'aoeuidhtns'x10);
my ($file2) = 't/archive.t';

isa_ok($archive->add_data($file,$contents, uid => 1337), 'Acme::Archive::Mbox::File', 'add data');
isa_ok($archive->add_file($file2), 'Acme::Archive::Mbox::File', 'add file');
isa_ok($archive->add_file($file2, 'optional/filename'), 'Acme::Archive::Mbox::File', 'add file');

# get_files, check files
my @files = $archive->get_files();

isa_ok($files[0], 'Acme::Archive::Mbox::File', 'add_data AAM::File object');
is($files[0]->name, $file, 'add_data filename');
is($files[0]->contents, $contents, 'add_data filename');

isa_ok($files[1], 'Acme::Archive::Mbox::File', 'add_file AAM::File object');
is($files[1]->name, $file2, 'add_file filename');

isa_ok($files[2], 'Acme::Archive::Mbox::File', 'add_file AAM::File object');
is($files[2]->name, 'optional/filename', 'add_file filename');

# TODO: These tests are weak
SKIP: {
    # write
    my $tmpnam = tmpnam();
    skip "Unable to create temporary file", 3 unless $tmpnam;

    ok($archive->write($tmpnam), 'write');

    $archive = undef;
    $archive = Acme::Archive::Mbox->new();
    $archive->read($tmpnam);

    my @files = $archive->get_files();
    my ($file) = grep { $_->name eq 'test/file' } @files;

    is($file->contents, 'aoeuidhtns'x10, 'file contents');
    is($file->name, 'test/file', 'file name');
    is($file->uid, 1337, 'file uid');

    unlink $tmpnam;
}
