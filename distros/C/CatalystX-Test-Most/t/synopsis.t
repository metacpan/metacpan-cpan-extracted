use strictures;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib",
    "$FindBin::Bin/lib";

my $module = "$FindBin::Bin/../lib/CatalystX/Test/Most.pm";
open my $fh, "<", $module
    or die qq{Couldn't open "$module" to read: $!};

my $synopsis = "";
while ( <$fh> )
{
    if ( /^=head1 Synopsis/ .. /^=head\d (?!Synopsis)/
         and not /^=/ ) {
        $synopsis .= $_;
    }
}
close $fh;

ok $synopsis, "Got code out of the Synopsis space to eval";
$synopsis =~ s/\#.+\r?\n//g;
note $synopsis;

eval "$synopsis; 1";
die $@, "\n", $synopsis if $@;
