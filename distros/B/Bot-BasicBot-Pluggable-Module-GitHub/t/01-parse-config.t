#!perl -T

# Tests for channel/auth settings handling.
#
# Mock the bot store with known settings, then check we get the right info back.


# Fake bot storage; pretend to be the Store module, to some degree.
# Instantiated with a hashref of settings, stores then in the object, and
# returns them when asked for
package MockStore;
use strict;
sub new { 
    my ($class, $settings) = @_;
    return bless { settings => $settings } => $class; 
}
sub get {
    my ($self, $namespace, $key) = @_;
    return unless $namespace eq 'GitHub';
    return $self->{settings}{$key};
}


# Subclass to override fetching of config setting from store
package MockBot;
use base 'Bot::BasicBot::Pluggable::Module::GitHub';
sub get {
    my ($self,$setting) = @_;
    return $self->{_conf}{$setting};
}
sub store {
    my $self = shift;
    return $self->{_store};
}

# On with the show...
package main;
use strict;
use Bot::BasicBot::Pluggable::Module::GitHub;


package main;
use Test::More tests => 4;

my $plugin = MockBot->new;

# Set some projects for channels, then we can test we get the right info back
$plugin->{_store} = MockStore->new({
    project_for_channel => {
        '#foo' => 'someuser/foo',
        '#bar' => 'bobby/tables',
    },
    auth_for_project => {
        'bobby/tables' => 'bobby:tables',
    },
});



is($plugin->project_for_channel('#foo'), 'someuser/foo',
    'Got expected project for a channel'
);

is($plugin->project_for_channel('#fake'), undef,
    'Got undef project for non-configured channel'
);

is($plugin->auth_for_project('bobby/tables'), 'bobby:tables',
    'Got expected auth info for a project'
);
is($plugin->auth_for_project('fake/project'), undef,
    'Got undef auth info for non-configured project'
);

