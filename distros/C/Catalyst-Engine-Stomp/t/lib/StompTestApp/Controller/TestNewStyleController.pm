package # Hide from PAUSE
  StompTestApp::Controller::TestNewStyleController;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::MessageDriven' };

has stomp_destination => (
    is => 'ro',
    isa => 'Str',
    default => '/queue/newstyle',
);

has stomp_subscribe_headers => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { +{
        selector => q{custom_header = '1' or JMSType = 'test_foo'},
    } },
);

sub testaction : Local {
    my ($self, $c, $request) = @_;

    my $response = {
        type => 'testaction_response',
        from => 'newstyle1',
    };
    $c->stash->{response} = $response;
}

sub test_foo : Local {
    my ($self, $c, $request) = @_;

    my $response = {
        type => 'test_foo_response',
        from => 'newstyle1',
    };
    $c->stash->{response} = $response;
}

1;
