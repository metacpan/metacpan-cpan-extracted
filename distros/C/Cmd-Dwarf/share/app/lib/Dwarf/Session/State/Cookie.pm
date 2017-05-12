package Dwarf::Session::State::Cookie;
use Dwarf::Pragma;
use parent 'HTTP::Session::State::Cookie';
use Dwarf::Accessor qw/param_name httponly/;

sub get_session_id {
    my ($self, $req) = @_;
    Carp::croak "missing req" unless $req;
    my $id = $self->SUPER::get_session_id($req);
    if (ref $self->param_name eq 'ARRAY') {
        for my $param_name (@{ $self->param_name }) {
            $id ||= $req->param($param_name);
        }
    } else {
        $id ||= $req->param($self->param_name);
    }
    return $id;
}

sub header_filter {
    my ($self, $session_id, $res) = @_;
    Carp::croak "missing session_id" unless $session_id;

    my $cookie = HTTP::Session::State::Cookie::_cookie_class()->new(
        sub {
            my %options = (
                -name   => $self->name,
                -value  => $session_id,
                -path   => $self->path,
            );
            $options{'-domain'} = $self->domain if $self->domain;
            $options{'-expires'} = $self->expires if $self->expires;
            $options{'-secure'} = $self->secure if $self->secure;
            $options{'-httponly'} = $self->httponly if $self->httponly;
            %options;
        }->()
    );
    if (Scalar::Util::blessed($res)) {
        $res->header( 'Set-Cookie' => $cookie->as_string );
        $res;
    } else {
        push @{$res->[1]}, 'Set-Cookie' => $cookie->as_string;
        $res;
    }
}

1;