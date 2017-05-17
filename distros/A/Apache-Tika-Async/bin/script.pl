#!perl -w
use strict;
use Apache::Tika::Server;

use Data::Dumper;

my $tika_glob = 'C:/Users/Corion/Projekte/Apache-Tika-Async/jar/tika-server-*.jar';
my $tika_path = (sort { my $ad; $a =~ /-1.(\d+)/ and $ad=$1;
                my $bd; $b =~ /-1.(\d+)/ and $bd=$1;
                $bd <=> $ad
              } glob $tika_glob)[0];
die "Tika not found in '$tika_glob'" unless $tika_path and -f $tika_path; 

my $tika= Apache::Tika::Server->new(
    jarfile => $tika_path,
    #connection_class => 'Apache::Tika::Connection::LWP',
    connection_class => 'Apache::Tika::Connection::AEHTTP',
    #java => '"C:/Program Files (x86)/Java/jre7/bin/java.exe"',
);
$tika->launch();
#my $tika= Apache::Tika->new;

my $fn= shift;

my $meta = $tika->get_meta($fn);
print "Content-Type: " . $meta->{'Content-Type'} . "\n";

print $tika->get_text($fn)->content;
#print Dumper $meta;