package # Hide from PAUSE
  StompTestApp::Controller::TestNewStyleController2;
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
        selector => q{custom_header = '2' or JMSType = 'test_bar'},
    } },
);

sub testaction : Local {
    my ($self, $c, $request) = @_;

    my $response = {
        type => 'testaction_response',
        from => 'newstyle2',
    };
    $c->stash->{response} = $response;
}

sub test_bar : Local {
    my ($self, $c, $request) = @_;

    my $response = {
        type => 'test_bar_response',
        from => 'newstyle2',
    };
    $c->stash->{response} = $response;
}

1;
