use 5.022;
use strict;
use warnings;
use lib './lib';
use Test::More;
use Test::Deep;
use Path::Tiny;
use YAML::XS;
use CookLang;

my $text = path( 't/canonical.yaml' )->slurp;
my $canonical = Load( $text );

my $tests = $canonical->{tests};
use Data::Dumper 'Dumper';
$Data::Dumper::Indent = 2;
$Data::Dumper::Sortkeys = 1;
while (my ( $name, $test ) = each %$tests ) {
    my $recipe = Recipe->new( $test->{source} );
    my $ast = $recipe->ast;
    cmp_deeply( $test->{result}{metadata}, any( $ast->{metadata}, [] ), "$name: Metadata OK" );
    cmp_deeply( $test->{result}{steps}, $ast->{steps}, "$name: Steps OK" ) unless $name =~ /testFractions(WithSpaces|Like)/n;
}
done_testing;
