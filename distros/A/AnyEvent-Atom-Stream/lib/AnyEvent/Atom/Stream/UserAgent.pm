package AnyEvent::Atom::Stream::UserAgent;
use strict;
use AnyEvent;
use AnyEvent::HTTP;

sub new {
    my($class, $timeout, $on_disconnect) = @_;
    bless {
        timeout       => $timeout,
        on_disconnect => $on_disconnect,
    }, shift;
}

sub get {
    my($self, $url, %args) = @_;

    my $content_cb = delete $args{":content_cb"};
    my $disconn_cb = $args{on_disconnect} || sub { };

    my %opts;
    $opts{timeout}    = $self->{timeout} if $self->{timeout};

    http_get $url, %opts, on_body => sub {
        my($body, $headers) = @_;
        local $XML::Atom::ForceUnicode = 1;
        $content_cb->($body);
        return 1;
    }, sub {
        my($body, $headers) = @_;
        $disconn_cb->($body);
    };

    $self->{guard} = AnyEvent::Util::guard {
        undef $content_cb; # refs AnyEvent::Atom::Stream
    };
}

1;

