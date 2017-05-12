use strict;
use warnings;
use Test::More;
use File::Spec;
use File::Path qw(make_path);
use Acme::CPANAuthors::MetaSyntactic;

plan skip_all => 'these tests are for release candidate testing'
    if !$ENV{RELEASE_TESTING};

eval "use CPAN::Common::Index::Mirror; 1"
    or plan skip_all =>
    "CPAN::Common::Index::Mirror required for testing authors list";

plan tests => 1;

# handle the CPAN::Common::Index::Mirror cache
my $cache_dir = File::Spec->catdir( File::Spec->tmpdir, "cpan-$<" );
make_path $cache_dir unless -e $cache_dir;
my $index = CPAN::Common::Index::Mirror->new( { cache => $cache_dir } );
my $cache = $index->cached_package;
if ( time - ( stat $cache )[9] > 24 * 60 * 60 ) {
    diag "Refreshing index cache (@{[ ~~ localtime +( stat $cache )[9] ]})";
    $index->refresh_index;
}
diag "Reading packages from $cache";

# get both lists
my %seen;
my @current = sort keys %{ Acme::CPANAuthors::MetaSyntactic->authors };
my @latest  = sort grep !$seen{$_}++,
    map { $_->{uri} =~ m{cpan:///distfile/([A-Z]+)/} }
    $index->search_packages( { package => qr{^Acme::MetaSyntactic::[a-z]} } );

# compare both lists
my $ok = is_deeply( \@current, \@latest, "The list is complete" );

if ( !$ok ) {
    %seen = ();
    $seen{$_}++ for @latest;
    $seen{$_}-- for @current;
    diag "The list of Acme::MetaSyntactic themes authors has changed:";
    diag( $seen{$_} > 0 ? "+ $_" : "- $_" )
        for grep $seen{$_}, sort keys %seen;
}
