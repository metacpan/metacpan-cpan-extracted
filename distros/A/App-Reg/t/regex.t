use strict;
use warnings;
use Test::More tests => 4;
use App::Reg;
use Symbol qw/gensym/;
use Capture::Tiny qw/capture_merged/;

sub try {
    my @options = @_;
    capture_merged {
        system File::Spec->catfile(qw/bin reg/), @options;
    };
}
# Anchored UTF-8 means that input was interpreted as UTF-8
like try('a', 'a'), qr/anchored utf8 ["`]/, 'UTF-8';
# But when executed with ASCII, it shouldn't mention UTF-8
like try('--ascii', 'a', 'a'), qr/anchored ["`]/, 'ASCII option';
# No colors
unlike try('--no-colors', 'a', 'a'), qr/\e/, 'No colors';
# Version should show current version
like try('--version'), qr/\b\Q$App::Reg::VERSION\E\b/, 'Version';
