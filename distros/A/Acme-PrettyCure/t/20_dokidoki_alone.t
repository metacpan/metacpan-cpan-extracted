use strict;
use warnings;
use utf8;
use Test2::V0;
use Encode qw(decode_utf8);

# A girl of DokiDoki who transforms alone says her message, and CureHeart calls out to the user by
# name. Every field of getpwuid used to go to sprintf, also for the messages without the name,
# which warned "Redundant argument in sprintf" (#7).

use Acme::PrettyCure;

my $user = getpwuid $>;

for my $girl ( Acme::PrettyCure->girls('DokiDoki') ) {
    my $output = '';
    my $warnings = warns {
        open my $out, '>', \$output or die $!;
        local *STDOUT = $out;
        $girl->transform;
        close $out;
    };
    is( $warnings, 0, ref($girl) . ' transforms alone without warnings' );
    my $message = $girl->message;
    $message = sprintf $message, $user if $girl->isa('Acme::PrettyCure::Girl::CureHeart');
    like( decode_utf8($output), qr/\Q$message\E/, ref($girl) . ' says the message' );
}

done_testing;
