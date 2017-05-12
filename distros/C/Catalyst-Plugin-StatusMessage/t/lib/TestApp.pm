package TestApp;

# Basic tests using default plugin config

use Catalyst qw/
    StatusMessage
/;

__PACKAGE__->setup;

#
# Mock session for tests
#
# Note: Catalyst::Plugin::Session::Store::Dummy doesn't seem to save across
#       multiple requests, so we will just use this to avoid using full 
#       Test::WWW::Mechanize::Catalyst
our %fake_session;
sub session {

    return \%fake_session;
}

1;
