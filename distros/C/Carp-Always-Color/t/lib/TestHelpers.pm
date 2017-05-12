package TestHelpers;
use strict;
use warnings;

BEGIN {
    if (!eval { require IO::Pty::Easy; 1 }) {
        Test::More::plan skip_all => "IO::Pty::Easy is required for this test"
    }
}

use B;
use Exporter 'import';

our @EXPORT_OK = qw(output_like);

sub output_like {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ($script, $expected, $desc) = @_;
    my $pty = IO::Pty::Easy->new;
    my $inc = '(' . join(',', map { B::perlstring($_) } @INC) . ')';
    $script = "BEGIN { \@INC = $inc }$script";
    $pty->spawn("$^X", "-e", $script);
    Test::More::like($pty->read, $expected, $desc);
}

1;
