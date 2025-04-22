#!perl
use lib 'lib';
use blib;

use Test2::V0 -target => 'Archive::SCS';

use Feature::Compat::Defer;
use Path::Tiny 0.125;

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');
defer { $tempdir->remove_tree; }

my $scs = Archive::SCS->new;

my $missing_archive_fail = dies { $scs->mount( $tempdir->child('none') ) };
ok $missing_archive_fail, 'no such file';
unlike $missing_archive_fail, qr/format handler/, 'no such file: unique error msg';

done_testing;
