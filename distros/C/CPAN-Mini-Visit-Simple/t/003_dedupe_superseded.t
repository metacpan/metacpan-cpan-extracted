# -*- perl -*-

# t/003_dedupe_superseded.t

use 5.010;
use CPAN::Mini::Visit::Simple::Auxiliary qw(
    dedupe_superseded
);
use Test::More tests =>  2;

my $topdir = q{/minicpan/authors/id/D/DR/DROLSKY};
my (@list, $newlist_ref, $expected);

@list = (
    qq{$topdir/Class-MOP-0.82.tar.gz},
    qq{$topdir/Class-MOP-0.88.tar.gz},
    qq{$topdir/Class-MOP-0.98.tar.gz},
    qq{$topdir/Class-MOP-0.78.tar.gz},
    qq{$topdir/Sig-PackageScoped-0.04.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.13.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.14.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.01.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.16.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.16a.tar.gz},
);
$newlist_ref = dedupe_superseded(\@list);

$expected = [
  '/minicpan/authors/id/D/DR/DROLSKY/Class-MOP-0.98.tar.gz',
  '/minicpan/authors/id/D/DR/DROLSKY/Sig-PackageScoped-0.04.tar.gz',
  '/minicpan/authors/id/D/DR/DROLSKY/SmokeRunner-Multi-0.16.tar.gz',
  '/minicpan/authors/id/D/DR/DROLSKY/SmokeRunner-Multi-0.16a.tar.gz'
];
is_deeply( $newlist_ref, $expected,
    "Got expected deduped list" );

@list = (
    qq{$topdir/Class-MOP-0.82.tar.gz},
    qq{$topdir/Class-MOP-0.88.tar.gz},
    qq{$topdir/Class-MOP-0.98.tar.gz},
    qq{$topdir/Class-MOP-1.78.tar.gz},
    qq{$topdir/Sig-PackageScoped-0.04.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.13.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.14.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.01.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.16.tar.gz},
    qq{$topdir/SmokeRunner-Multi-0.16a.tar.gz},
);
$newlist_ref = dedupe_superseded(\@list);

$expected = [
  '/minicpan/authors/id/D/DR/DROLSKY/Class-MOP-1.78.tar.gz',
  '/minicpan/authors/id/D/DR/DROLSKY/Sig-PackageScoped-0.04.tar.gz',
  '/minicpan/authors/id/D/DR/DROLSKY/SmokeRunner-Multi-0.16.tar.gz',
  '/minicpan/authors/id/D/DR/DROLSKY/SmokeRunner-Multi-0.16a.tar.gz'
];
is_deeply( $newlist_ref, $expected,
    "Got expected deduped list" );
