package Dwarf::HTTP::Async;
use Dwarf::Pragma;
use AnyEvent;
use AnyEvent::HTTP ();
use HTTP::Request::Common ();
use HTTP::Request;
use HTTP::Response;

sub new { bless {}, $_[0] }

sub get    { _request(GET => @_) }
sub post   { _request(POST => @_) }
sub put    { _request(PUT => @_) }
sub delete { _request(DELETE => @_) }

sub _request {
    my $cb     = pop;
    my $method = shift;
    my $self   = shift;
    no strict 'refs';
    my $req = &{"HTTP::Request::Common::$method"}(@_);
    $self->request($req, $cb);
}

sub request {
    my($self, $request, $cb) = @_;

    my %options = (
        headers => $request->headers,
        body    => $request->content,
    );

    AnyEvent::HTTP::http_request $request->method, $request->uri, %options, sub {
        my($body, $header) = @_;
        my $res = HTTP::Response->new($header->{Status}, $header->{Reason}, [ %$header ], $body);
        $cb->($res);
    };
}

sub request_in_parallel {
    my $self = shift;

    my $cv = AnyEvent->condvar;

    my @res; 
    for my $req (@_) {
        $cv->begin;
        $self->request($req, sub {
            push @res, shift;
            $cv->end;
        });
    }

    $cv->recv;

    return @res;
};

1;
