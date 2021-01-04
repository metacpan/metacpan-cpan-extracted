#! /usr/bin/perl

my $src = shift;

# Copy script.
open( my $fd, ">", $src);
open( my $fi, "<", "$src.pl" );
print { $fd } ( <$fi> );
close($fi);
undef($fi);

# Append module (docs).
open( my $fi, "<", "lib/App/Dusage.pm" );
my $skip = 1;
while ( <$fi> ) {
    if ( $skip ) {
	if ( /^=/ ) {
	    $skip = 0;
	    print $fd "\n# Documentation appended from App::Dusage.\n\n";
	}
	else {
	    next;
	}
    }
    print $fd $_;
}
close($fd);
