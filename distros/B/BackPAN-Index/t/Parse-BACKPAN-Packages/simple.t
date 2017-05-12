#!perl
use strict;
use warnings;
use Test::More tests => 84;
use lib 't/lib';
use TestUtils;
use_ok("Parse::BACKPAN::Packages");

my $p = new_pbp();

my $file = $p->file("authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz");
is( $file->prefix, "authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz" );
is( $file->date,   1014330111 );
is( $file->size,   3031 );
is( $file->url,
    "http://backpan.perl.org/authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz"
);

my @acme_colours = $p->releases("Acme-Colour");
is( $acme_colours[0]->cpanid,    "LBROCARD" );
is( $acme_colours[0]->date,      "1014330111" );
is( $acme_colours[0]->dist,      "Acme-Colour" );
is( $acme_colours[0]->distvname, "Acme-Colour-0.16" );
is( $acme_colours[0]->filename,  "Acme-Colour-0.16.tar.gz" );
is( $acme_colours[0]->maturity,  "released" );
is( $acme_colours[0]->prefix,
    "authors/id/L/LB/LBROCARD/Acme-Colour-0.16.tar.gz" );
is( $acme_colours[0]->version, "0.16" );

is( $acme_colours[1]->version, "0.17" );
is( $acme_colours[2]->version, "0.18" );
is( $acme_colours[3]->version, "0.19" );
is( $acme_colours[4]->version, "0.20" );
is( $acme_colours[5]->version, "1.00" );
is( $acme_colours[6]->version, "1.01" );
is( $acme_colours[7]->version, "1.02" );

is( $acme_colours[-1]->cpanid,    "LBROCARD" );
is( $acme_colours[-1]->date,      "1213106995" );
is( $acme_colours[-1]->dist,      "Acme-Colour" );
is( $acme_colours[-1]->distvname, "Acme-Colour-1.06" );
is( $acme_colours[-1]->filename,  "Acme-Colour-1.06.tar.gz" );
is( $acme_colours[-1]->maturity,  "released" );
is( $acme_colours[-1]->prefix,
    "authors/id/L/LB/LBROCARD/Acme-Colour-1.06.tar.gz" );
is( $acme_colours[-1]->version, "1.06" );

my @noone = $p->distributions_by('NONEXISTENTAUTHOR');
is( scalar @noone, 0, 'No distributions for new author' );

my @bogus = $p->distributions_by();
is( scalar @bogus, 0, 'No distributions for missing author' );

my @acmes = $p->distributions_by('LBROCARD');
foreach my $dist (
    'Acme-Colour',                'Buffy',
    'CPAN-IndexPod',              'CPAN-Metadata-RDF',
    'CPAN-Unpack',                'CPAN-WWW-Testers',
    'CPAN-WWW-Testers-Generator', 'Data-Page',
    'DateTime-Stringify',         'Devel-ebug',
    'Functional',                 'Games-GuessWord',
    'GraphViz',                   'HTML-Fraction',
    'HTTP-Server-Simple-Kwiki',   'Haul',
    'Image-Imlib2',               'Image-WorldMap',
    'Java-JVM-Classfile',         'Language-Functional',
    'MP3-ID3Lib',                 'Mac-EyeTV',
    'MealMaster',                 'Messaging-Courier',
    'Module-Packaged',            'Net-Amazon-AWIS',
    'Net-Amazon-SimpleQueue',     'Net-DPAP-Client',
    'Net-OpenDHT',                'OpenFrame-Segment-Apache',
    'OpenFrame-Segment-Apache2',  'PPI-Metric-Basic',
    'Parse-BACKPAN-Packages',     'Parse-CPAN-Authors',
    'Parse-CPAN-Packages',        'Search-Mousse',
    'String-Koremutake',          'Template-Plugin-Page',
    'Test-Expect',                'Test-WWW-Mechanize-Catalyst',
    'Tie-GHash',                  'Tree-Ternary_XS',
    'WWW-Gazetteer',              'WWW-Gazetteer-Calle',
    'WWW-Gazetteer-FallingRain',  'WWW-Gazetteer-Getty',
    'WWW-Mechanize-Timed',        'WWW-Search-Google',
    'XML-asData',
    )
{
    ok( scalar( grep { $_ eq $dist } @acmes ), "LBROCARD has $dist" );
}

my @pmisons = $p->distributions_by('PMISON');
foreach my $dist ( 'File-Type', 'File-Find-Rule-Type', ) {
    ok( scalar( grep { $_ eq $dist } @pmisons ), "PMISON has $dist" );
}

my @authors = $p->authors;
ok( scalar(@authors) > 2500 );
foreach my $author ( 'LBROCARD', 'PMISON', ) {
    ok( scalar( grep { $_ eq $author } @authors ), "$author is an author" );
}

#use Data::Dumper; warn Dumper \@authors;
# use YAML; warn Dump \@acmes;

