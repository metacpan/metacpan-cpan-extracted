use strict;
use warnings;
use utf8;
use Test2::V0;

# The `AllStar` team is every girl that the `allstar` method transforms. DokiDoki was added to
# `allstar` but not to the team (#7).

use Acme::PrettyCure;

my %allstar = map { ref($_) => 1 } Acme::PrettyCure->girls('AllStar');
for my $girl ( Acme::PrettyCure->girls('DokiDoki') ) {
    ok( $allstar{ ref $girl }, ref($girl) . ' is in AllStar' );
}

# What `allstar` prints for DokiDoki is the transform of the team, as for the other teams.
my $printed = capture( sub { Acme::PrettyCure->allstar } );
my ( $mana, @dokidoki ) = Acme::PrettyCure->girls('DokiDoki');
my $dokidoki = capture( sub { $mana->transform(@dokidoki) } );
ok( index( $printed, $dokidoki ) >= 0, 'allstar transforms DokiDoki' );

sub capture {
    my ($code) = @_;
    my $output = '';
    open my $out, '>', \$output or die $!;
    local *STDOUT = $out;
    $code->();
    close $out;
    return $output;
}

done_testing;
