use strict;
use warnings;

package App::Rssfilter::FromYaml::Tester;

use Moose;
use Test::MockObject;

has fake_from_hash => (
    is => 'ro',
    handles => [ qw< from_hash > ],
    default => sub {
        my $fake_from_hash = Test::MockObject->new();
        $fake_from_hash->set_true( 'from_hash' );
    },
);

with 'App::Rssfilter::FromYaml';

1;
