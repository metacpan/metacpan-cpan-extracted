#!perl
use strict;
use warnings;
use lib 'lib', 't/lib';
use blib;
use Feature::Compat::Defer;

use Path::Tiny 0.119;
use Test::More;
use TestArchiveSCS;

can_test_cli() or plan skip_all => 'Cannot test cli';

my $tempdir = Path::Tiny->tempdir('Archive-SCS-test-XXXXXX');
defer { $tempdir->remove_tree; }

# Relative path traversal, dir name is ..

my $cwe24 = $tempdir->child('cwe24.scs');
{
  my $mem = Archive::SCS::InMemory->new;
  $mem->add_entry('', { dirs => ['..'], files => [] });
  $mem->add_entry('..', { dirs => ['cwe24'], files => [] });
  $mem->add_entry('../cwe24', { dirs => [], files => [] });
  create_hashfs1 $cwe24, $mem;
}

like scs_archive(-r => -x => "", -o => "$tempdir/cwe24-dir", -m => "$cwe24"),
  qr{ insecure path }, 'CWE-24: not traversed';
ok ! $tempdir->child('cwe24')->exists, 'CWE-24: not extracted';

# Relative path traversal, file name contains /../

my $cwe27 = $tempdir->child('cwe27.scs');
{
  my $mem = Archive::SCS::InMemory->new;
  $mem->add_entry('', { dirs => [], files => ['subdir/../../cwe27'] });
  $mem->add_entry('subdir/../../cwe27', '');
  create_hashfs1 $cwe27, $mem;
}

like scs_archive(-r => -x => "", -o => "$tempdir/cwe27-dir", -m => "$cwe27"),
  qr{ insecure path }, 'CWE-27: not traversed';
ok ! $tempdir->child('cwe27')->exists, 'CWE-27: not extracted';

# Absolute path traversal

my $cwe37 = $tempdir->child('cwe37.scs');
{
  my $mem = Archive::SCS::InMemory->new;
  $mem->add_entry('', { dirs => [], files => ['/tmp/Archive-SCS-cwe37'] });
  $mem->add_entry('/tmp/Archive-SCS-cwe37', '');
  create_hashfs1 $cwe37, $mem;
}

path($_)->exists and die "Error: $_ exists" for '/tmp/Archive-SCS-cwe37';

like scs_archive(-r => -x => "", -o => "$tempdir", -m => "$cwe37"),
  qr{ insecure path }, 'CWE-37: not traversed';
ok ! path('/tmp/Archive-SCS-cwe37')->exists, 'CWE-37: not extracted';

done_testing;
