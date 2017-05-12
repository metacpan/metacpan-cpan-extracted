use strict;
use warnings;

use Test::More tests => 3;

{
    package MyApp;

    use Dancer;
    use Dancer::Plugin::Chain;
        
    my $country = chain '/country/:country' => sub {
        # silly example. Typically much more work would 
        # go on in here
        var 'site' => param('country');
    };

    my $event = chain '/event/:event' => sub {
        var 'event' => param('event');
    };

    # will match /country/usa/event/yapc
    get chain $country, $event, '/schedule' => sub {
        return sprintf "schedule of %s in %s\n", map { var $_ } qw/ event site /;
    };

    my $continent = chain '/continent/:continent' => sub {
        var 'site' => param('continent');
    };

    my $continent_event = chain $continent, $event;

    # will match /continent/europe/event/yapc
    get chain $continent_event, '/schedule' => sub {
        return sprintf "schedule of %s in %s\n", map { var $_ } qw/ event site /;
    };

    # will match /continent/asia/country/japan/event/yapc
    # and will do special munging in-between!

    get chain $continent, 
            sub { var temp => var 'site' },
            $country, 
            sub {
                var 'site' => join ', ', map { var $_ } qw/ site temp /
            },
            $event, 
            '/schedule' 
                => sub {
                    return sprintf "schedule of %s in %s\n", map { var $_ } 
                                qw/ event site /;
            };

}

use Dancer::Test;

response_content_like '/country/canada/event/yapc/schedule' 
    => qr/schedule of yapc in canada/;

response_content_like '/continent/america/event/yapc/schedule' 
    => qr/schedule of yapc in america/;

response_content_like '/continent/america/country/canada/event/yapc/schedule' 
    => qr/schedule of yapc in canada, america/;
