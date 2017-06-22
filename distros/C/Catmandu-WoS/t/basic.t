use strict;
use Test::More;
use Test::Exception;
use Catmandu::Util qw(is_string is_hash_ref);

my $pkg = 'Catmandu::Importer::WoS';

require_ok $pkg;

SKIP: {
    skip "env WOK_USERNAME, WOK_PASSWORD not defined"
        unless $ENV{WOK_USERNAME} && $ENV{WOK_PASSWORD};

    my $importer = $pkg->new(
        username => $ENV{WOK_USERNAME},
        password => $ENV{WOK_PASSWORD},
        query    => 'TS=(cadmium OR lead)'
    );

    ok is_string($importer->session_id);

    my $rec = $importer->first;

    ok is_hash_ref($rec);
    ok is_string($rec->{UID});
}

done_testing;
