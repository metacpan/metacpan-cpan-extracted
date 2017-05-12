

#test-streaming-app.psgi
#usage: "plackup test-streaming-app.psgi"

use strict;
use warnings;
my $fh;

sub print_resp {
    my $line;
    $fh || open( $fh, "<:encoding(UTF-8)", "/var/log/syslog" );
    $line = <$fh>;
    return $line if defined($line);
    close($fh);
    $fh = undef;
}

my $app = sub {
    return sub {
        my $writer = shift->([200, [ "Content-type" => "text/plain"]]);
        while(1) {
            my $line = print_resp;
            $writer->write($line) if(defined($line));
        }
    }
}
