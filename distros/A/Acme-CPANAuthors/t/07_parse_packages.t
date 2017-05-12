# this test is ripped from Parse::CPAN::Packages

use strict;
use warnings;
use Test::More tests => 34;
use_ok("Acme::CPANAuthors::Utils::Packages");

my $p = Acme::CPANAuthors::Utils::Packages->new("t/data/modules/02packages.details.txt");
isa_ok( $p, "Acme::CPANAuthors::Utils::Packages" );

my @packages = sort map { $_->package } $p->packages;
is_deeply(
    \@packages,
    [   qw(Acme::Colour Acme::Colour::Old Acme::ComeFrom Acme::Comment Acme::CramCode Acme::Currency accessors accessors::chained accessors::classic )
    ]
);

is( $p->file, '02packages.details.txt', 'file' );
is( $p->url, 'http://www.perl.com/CPAN/modules/02packages.details.txt',
    'url' );
is( $p->description, 'Package names found in directory $CPAN/authors/id/',
    'description' );
is( $p->columns, 'package name, version, path', 'columns' );
is( $p->intended_for, 'Automated fetch routines, namespace documentation.',
    'intended for' );
is( $p->written_by, 'Id: mldistwatch 479 2004-01-04 13:29:05Z k ',
    'written by' );
is( $p->line_count, 23609, 'line count' );
is( $p->last_updated, 'Fri, 13 Feb 2004 13:50:21 GMT', 'last updated' );

my $m = $p->package("Acme::Colour");
is( $m->package, "Acme::Colour" );
is( $m->version, "1.00" );

my $d = $m->distribution;
is( $d->prefix,    "L/LB/LBROCARD/Acme-Colour-1.00.tar.gz" );
is( $d->dist,      "Acme-Colour" );
is( $d->version,   "1.00" );
is( $d->maturity,  "released" );
is( $d->filename,  "Acme-Colour-1.00.tar.gz" );
is( $d->cpanid,    "LBROCARD" );
is( $d->distvname, "Acme-Colour-1.00" );

is( $p->package("accessors::chained")->distribution->dist,
    "accessors", "accessors::chained lives in accessors" );

is( $p->package("accessors::classic")->distribution->dist,
    "accessors", "as does accessors::classic" );

is( $p->package("accessors::chained")->distribution,
    $p->package("accessors::classic")->distribution,
    "and they're using the same distribution object"
);

my $dist = $p->distribution('S/SP/SPURKIS/accessors-0.02.tar.gz');
is( $dist->dist, 'accessors' );
is( $dist,
    $p->package("accessors::chained")->distribution,
    "by path match by name"
);

is_deeply(
    [ map { $_->package } $dist->contains ],
    [qw( accessors accessors::chained accessors::classic )],
    "dist contains packages"
);

$d = $p->latest_distribution("Acme-Colour");
is( $d->prefix,  "L/LB/LBROCARD/Acme-Colour-1.00.tar.gz" );
is( $d->version, "1.00" );

is_deeply(
    [ sort map { $_->prefix } $p->latest_distributions ],
    [   'A/AU/AUTRIJUS/Acme-ComeFrom-0.07.tar.gz',
        'K/KA/KANE/Acme-Comment-1.02.tar.gz',
        'L/LB/LBROCARD/Acme-Colour-1.00.tar.gz',
        'S/SM/SMUELLER/Acme-Currency-0.01.tar.gz',
        'S/SP/SPURKIS/accessors-0.02.tar.gz',
        'X/XE/XERN/Acme-CramCode-0.01.tar.gz',
    ]
);

# counts
is( $p->package_count(),             scalar @packages, "package count" );
is( $p->distribution_count(),        7,                "dist count" );
is( $p->latest_distribution_count(), 6,                "latest dist count" );

#open( IN, "t/data/modules/02packages.details.txt" );
#my $details = join '', <IN>;
#close(IN);

# Try the interface which takes in the contents

#$p = Acme::CPANAuthors::Utils::Packages->new($details);
#isa_ok( $p, "Acme::CPANAuthors::Utils::Packages" );
#
#@packages = sort map { $_->package } $p->packages;
#is_deeply(
#    \@packages,
#    [   qw(Acme::Colour Acme::Colour::Old Acme::ComeFrom Acme::Comment Acme::CramCode Acme::Currency accessors accessors::chained accessors::classic )
#    ]
#);

# Try the interface which takes in a .gz

$p = Acme::CPANAuthors::Utils::Packages->new("t/data/modules/02packages.details.txt.gz");
isa_ok( $p, "Acme::CPANAuthors::Utils::Packages" );

@packages = sort map { $_->package } $p->packages;
is_deeply(
    \@packages,
    [   qw(Acme::Colour Acme::Colour::Old Acme::ComeFrom Acme::Comment Acme::CramCode Acme::Currency accessors accessors::chained accessors::classic )
    ]
);

# Try the interface which takes in gzipped contents - not supported
#
#open( IN, "t/data/modules/02packages.details.txt.gz" );
#$details = join '', <IN>;
#close(IN);
#
#$p = Acme::CPANAuthors::Utils::Packages->new($details);
#isa_ok( $p, "Acme::CPANAuthors::Utils::Packages" );
#
#@packages = sort map { $_->package } $p->packages;
#is_deeply(
#    \@packages,
#    [   qw(Acme::Colour Acme::Colour::Old Acme::ComeFrom Acme::Comment Acme::CramCode Acme::Currency accessors accessors::chained accessors::classic )
#    ]
#);
