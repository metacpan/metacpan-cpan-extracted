use strict;
use Test::More;
use Test::Exception;
use Catmandu::Util qw(is_string is_hash_ref);

my $pkg = 'Catmandu::Importer::WoSCitingArticles';

require_ok $pkg;

SKIP: {
    skip "env WOS_USERNAME, WOS_PASSWORD not defined"
        unless $ENV{WOS_USERNAME} && $ENV{WOS_PASSWORD};

    my %args = (
        username => $ENV{WOS_USERNAME},
        password => $ENV{WOS_PASSWORD},
        uid      => 'WOS:000348243500007',
    );

    $args{session_id} = $ENV{WOS_SESSION_ID} if $ENV{WOS_SESSION_ID};

    my $importer = $pkg->new(%args);

    ok is_string($importer->session_id);

    $ENV{WOS_SESSION_ID} ||= $importer->session_id;

    my $rec = $importer->first;

    ok is_hash_ref($rec);
    ok is_string($rec->{UID});
}

done_testing;
