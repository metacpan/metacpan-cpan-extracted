package App::BCSSH::Handler::browse;
use Moo;
use Browser::Open qw(open_browser);

with 'App::BCSSH::Handler';

has browser => (is => 'ro');
has browse => (is => 'lazy', init_arg => undef);
sub _build_browse {
    my $self = shift;
    my $browser = $self->browser;
    if ($browser) {
        my @browser = ref $browser ? @$browser : $browser;
        return sub { system @browser, @_ };
    }
    else {
        return \&open_browser;
    }
}

sub handle {
    my ($self, $send, $args) = @_;
    my $urls = $args->{urls};

    for my $url (@$urls) {
        $self->browse->($url);
    }
    $send->();
}

1;
