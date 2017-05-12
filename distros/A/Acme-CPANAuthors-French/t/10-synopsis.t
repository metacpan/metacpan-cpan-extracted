#!perl
use strict;
use warnings;
use Test::More;


plan skip_all => "can't load Acme::CPANAuthors"
    unless eval "use Acme::CPANAuthors; 1";
plan tests => 9;

my $authors  = eval { Acme::CPANAuthors->new("French") };
is( $@, "", "creating a new Acme::CPANAuthors object with French authors" );
isa_ok( $authors, "Acme::CPANAuthors" );

my $number   = $authors->count;
cmp_ok( $number, ">", 0, " .. \$authors->count is a non-null number" );

my @ids      = $authors->id;
cmp_ok( ~~@ids, ">", 0, " .. \$authors->id gives a non-empty list" );
is( ~~@ids, $number, " .. \$authors->id eqals \$authors->count" );

SKIP: {
    skip "CPAN configuration not available", 4
        unless eval "Acme::CPANAuthors::Utils::_cpan_authors_file() ; 1";

    my @distros  = $authors->distributions("SAPER");
    cmp_ok( ~~@distros, ">", 0, " .. \$authors->distributions gives a non-empty list" );

    my $url      = $authors->avatar_url("VPIT");
    cmp_ok( length($url), ">", 0, " .. \$authors->avatar_url('VPIT') gives a non-empty string" );

    my $kwalitee = eval { $authors->kwalitee("BOOK") };
    SKIP: {
        skip $@, 1 if $@ =~ /Can't connect to cpants.perl.org/;
        isa_ok( $kwalitee, "HASH", " .. \$authors->kwalitee('BOOK')" );
    }

    my $name     = $authors->name("RGARCIA");
    cmp_ok( length($name), ">", 0, " .. \$authors->name('RGARCIA') gives a non-empty string" );
}
