package DNSQuery::Banner;
use strict;
use warnings;

our $VERSION = '1.1.0';

sub show {
    my ($version) = @_;
    $version ||= '1.0.0';
    
    print <<'BANNER';
    ____  _   _______ ____  
   / __ \/ | / / ___// __ \ 
  / / / /  |/ /\__ \/ / / / 
 / /_/ / /|  /___/ / /_/ /  
/_____/_/ |_//____/\___\_\  
                            
BANNER
    
    print "DNS Query Tool v$version\n";
    print "Fast • Reliable • Feature-Rich\n";
    print "=" x 40 . "\n\n";
}


1;
