package TestApp2;

# Include some config

use Catalyst qw/
    StatusMessage
/;

# Configure Catalyst::Plugin::StatusMessage
__PACKAGE__->config(
    'Plugin::StatusMessage' => {
        session_prefix          => 'my_status_prefix',
        token_param             => 'my_mid',
        status_msg_stash_key    => 'my_status_msg',
        error_msg_stash_key     => 'my_error_msg',
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
