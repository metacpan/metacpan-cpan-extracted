package API::MikroTik::Mockup;
use Mojo::Base '-base';

use API::MikroTik::Response;
use API::MikroTik::Sentence qw(encode_sentence);
use Mojo::IOLoop;

has 'fd';
has ioloop => sub { Mojo::IOLoop->singleton };
has 'port';
has res => sub { API::MikroTik::Response->new() };
has server => sub {
    my $self = shift;

    my $opts = {address => '127.0.0.1'};
    if (defined(my $fd = $self->fd)) {
        $opts->{fd} = $fd;
    }
    else {
        $opts->{port}  = $self->port;
        $opts->{reuse} = 1;
    }

    my $serv_id = $self->ioloop->server(
        $opts => sub {
            my ($loop, $stream, $id) = @_;

            $self->{h} = $stream;

            $stream->on(
                read => sub {
                    my ($stream, $bytes) = @_;

                    my $data = $self->res->parse(\$bytes);
                    for (@$data) {
                        my $cmd = $_->{'.type'} // '';
                        warn "wrong command \"$cmd\"\n" and next
                            unless $cmd =~ s/^\//cmd_/;
                        $cmd =~ s/\//_/g;

                        eval {
                            my $resp = '';
                            $resp .= encode_sentence(@$_) for ($self->$cmd($_));
                            $stream->write($resp);
                        } or warn "unhandled command \"$cmd\": $@";
                    }
                }
            );
            $stream->on(
                close => sub { $loop->remove($_) for values %{$self->{timers}} }
            );
        }
    );

    return $serv_id;
};

sub cmd_cancel {
    my ($self, $attr) = @_;
    my $tag     = $attr->{'.tag'};
    my $cmd_tag = $attr->{'tag'};

    return ['!trap', {message => 'unknown command'}, undef, $tag]
        unless my $id = delete $self->{timers}{$cmd_tag};
    $self->ioloop->remove($id);

    return (
        ['!trap', {category => 2, message => 'interrupted'}, undef, $cmd_tag],
        _done($tag), _done($cmd_tag));
}

sub cmd_close_premature {
    my ($self, $attr) = @_;

    my $sent = encode_sentence('!re', {message => 'response'}, undef,
        $attr->{'.tag'});
    substr $sent, (length($sent) / 2), -1, '';

    $self->{h}->write($sent);
    $self->ioloop->timer(0.5 => sub { $self->{h}->close() });

    return ();
}

sub cmd_err {
    my (undef, $attr) = @_;
    my $tag = $attr->{'.tag'};
    return ['!trap', {message => 'random error', category => 0}, undef, $tag];
}

sub cmd_login {
    my (undef, $attr) = @_;
    my $tag = $attr->{'.tag'};

    return _done($tag, {ret => '098f6bcd4621d373cade4e832627b4f6'})
        unless $attr->{name};

    return _done($tag)
        if $attr->{name} eq 'test'
        && $attr->{response} eq '00119ce7e093e33497053e73f37a5d3e15';

    return ['!fatal', {message => 'cannot log in'}, undef, $tag];
}

sub cmd_nocmd {
    return ();
}

sub cmd_resp {
    my (undef, $attr) = @_;
    my $tag = $attr->{'.tag'};

    my $resp = ['!re', _gen_attr(@{$attr}{'.proplist', 'count'}), undef, $tag];
    return ($resp, $resp, _done($tag));
}

sub cmd_subs {
    my ($self, $attr) = @_;
    my $tag = $attr->{'.tag'} // 0;
    my $key = $attr->{'key'};

    $self->{timers}{$tag} = $self->ioloop->recurring(
        0.5 => sub {
            $self->{h}
                ->write(encode_sentence('!re', {key => $key}, undef, $tag));
        }
    );

    return ();
}

sub _done {
    return ['!done', $_[1], undef, $_[0]];
}

sub _gen_attr {
    my $c    = $_[1] // 0;
    my $attr = {};
    $attr->{$_} = 'attr' . ($c++) for split /,/, ($_[0] // 'prop1,prop2,prop0');
    return $attr;
}

1;

