package Search::Elasticsearch::Plugin::Langdetect::API;
use vars qw($VERSION);
$VERSION = '0.06';

use Moo::Role;

use Search::Elasticsearch::Util qw(throw);
use Search::Elasticsearch::Util::API::QS qw(qs_init);
use namespace::clean;

our %API;

#===================================
sub api {
#===================================
    my $name = $_[1] || return \%API;
    return $API{$name}
        || throw( 'Internal', "Unknown api name ($name)" );
}

#===================================
%API = (
#===================================

#=== AUTOGEN - START ===

    'langdetect.detect_languages' => {
        method => "POST",
        parts  => {},
        paths  => [ [   {}, "_langdetect" ] ],
        body   => { required => 1 },
    },

    #'langdetect.detect_language' => {
    #    method => "POST",
    #    parts  => {},
    #    paths  => [ [   {}, "_langdetect" ] ],
    #    body   => { required => 1 },
    #},
);

for ( values %API ) {
    $_->{qs_handlers} = qs_init( @{ $_->{qs} } );
}

1;1;