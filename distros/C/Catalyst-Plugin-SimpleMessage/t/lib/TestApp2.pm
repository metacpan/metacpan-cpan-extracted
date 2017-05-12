package TestApp2;

# Include some config

use Catalyst qw/
    SimpleMessage
/;

# Configure Catalyst::Plugin::StatusMessage
__PACKAGE__->config(
    'Plugin::SimpleMessage' => {
        session_prefix       => 'my_msg',
        stash_prefix         => 'my_msg',
        token_param          => 'my_msg'
    }
);

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
