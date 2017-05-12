package AnyEvent::IMAP;
use strict;
use warnings;
use 5.010001;
our $VERSION = '0.04';

use parent qw(Object::Event);

use AnyEvent::Socket;
use AnyEvent::Handle;
use AnyEvent::TLS;
use Mail::IMAP::Util;

use Mouse;

has 'socket' => (is => 'ro');
has 'ssl' => (is => 'rw', isa => 'Bool');
has 'host' => (is => 'rw');
has 'port' => (is => 'rw');
has 'user' => (is => 'rw');
has 'pass' => (is => 'rw');
has id => (is => 'ro', default => sub { 1 });

sub connect {
    my ($self) = @_;

    if ($self->{socket}) {
        $self->disconnect("reconnect requested");
    }

    my $cv = AE::cv();
    $self->{accumulator}  = [];
    $self->{lineparts}  = [];
    $self->{socket} = AnyEvent::Handle->new(
        connect => [$self->host, $self->port],
        ($self->ssl ? (tls => 'connect') : ()),
        on_connect => sub {
            my ($handle, $host, $port, $retry) = @_;
            $self->{socket}->push_read(
                line => "\r\n", sub {
                    my ($handle, $line) = @_;
                    if ($line =~ /^\*\s+OK/) {
                        $cv->send(1, $line);
                        $self->event('connect');
                    } else {
                        $cv->send(0, $line);
                        $self->event('connect_error');
                    }
                },
            );
        },
        on_starttls => sub {
            $self->event('starttls');
        },
        on_eof => sub {
            $self->disconnect("EOF from server $self->{host}: $self->{port}");
        },
        on_error => sub {
            $self->disconnect("Error in connection to server $self->{host}: $self->{port}: $!");
        },
        on_drain => sub {
            $self->event('buffer_empty');
        },
        on_read => sub {
            $self->{socket}->push_read('regex' => qr{((?:^.+?\r\n)*)(NIC\d+)\s+([A-Z_]+)[^\r\n]+\r\n}, sub {
                my ($handle, $res) = @_;
                $self->event('recv', $res);
                my $id = $2;
                my $status = $3;
                my $ok = $status eq 'OK' ? 1 : 0;
                if (my $cv = delete $self->{cvmap}->{$id}) {
                    my @lines = split /\r\n/, $res;
                    pop @lines; # remove last line
                    if ($ok && (my $filter = delete $self->{filters}->{$id})) {
                        $res = $filter->(@lines)
                    } else {
                        $res = \@lines;
                    }
                    $cv->send($ok, $res);
                }
            });
        },
    );
    return $cv;
}

sub login {
    my $self = shift;
    my $user = imap_string_quote($self->user);
    my $pass = imap_string_quote($self->pass);
    my ($id, $cv) = $self->send_cmd("LOGIN $user $pass");
    return $cv;
}

sub disconnect {
    my ($self, $reason) = @_;
    delete $self->{con_guard};
    delete $self->{socket};
    $self->event (disconnect => $reason);
}

sub is_connected {
    my ($self) = @_;
    $self->{socket} && $self->{connected}
}

sub send_cmd {
    my ($self, $cmd, $filter) = @_;
    my $id = "NIC" . $self->{id}++;
    return unless $self->{socket};

    my $cv = AE::cv();
    my $msg = "$id $cmd\r\n";
    $self->event('send', $msg);
    $self->{socket}->push_write($msg);
    $self->{cvmap}->{$id} = $cv;
    if ($filter) {
        $self->{filters}->{$id} = $filter;
    }
    return ($id, $cv);
}

sub capability {
    my ($self) = @_;
    my ($id, $cv) = $self->send_cmd('CAPABILITY', sub {
        if ($_[0] =~ /^\*\s+CAPABILITY\s+(.*?)\s*$/) {
            return [ split(/\s+/, $1) ];
        }
        return;
    });
    return $cv;
}

sub folders {
    my ($self) = @_;
    my ($id, $cv) = $self->send_cmd('LIST "" "*"', sub {
        [map { imap_parse_tokens([$_])->[4] } @_];
    });
    return $cv;
}

sub status {
    my ($self, $folder) = @_;
    my $all_cv = AE::cv();
    my $cmd = sprintf("%s (MESSAGES RECENT UNSEEN UIDNEXT UIDVALIDITY)",
        imap_string_quote($folder));
    my ($id, $cv) = $self->send_cmd("STATUS $cmd", sub {
        +{ @{imap_parse_tokens([$_[0]])->[3]} };
    });
    return $cv;
}

sub status_multi {
    my ($self, $folders) = @_;
    my $all_cv = AE::cv();
    my %ret;
    $all_cv->begin(sub { shift->send(1, \%ret); });
    for my $folder (@$folders) {
        $all_cv->begin();
        $self->status($folder)->cb(sub {
            my ($ok, $ret) = shift->recv;
            $ret{$folder} = $ret if $ok;
            $all_cv->end();
        });
    }
    $all_cv->end;
    return $all_cv;
}

sub select {
    my ($self, $folder) = @_;
    $folder = imap_string_quote($folder);
    my ($id, $cv) = $self->send_cmd("SELECT $folder");
    return $cv;
}

sub fetch {
    my ($self, $query) = @_;
    my ($id, $cv) = $self->send_cmd("FETCH $query", sub {
        # in form: [ '*', ID, 'FETCH', [ tokens ]]
        [map { +{@{$_->[3]}} } grep { $_->[2] eq 'FETCH' } map {imap_parse_tokens([$_])} @_]
    });
    return $cv;
}

sub expunge {
    my ($self) = @_;
    my ($id, $cv) = $self->send_cmd('EXPUNGE');
    return $cv;
}

sub create_folder {
    my ($self, $folder) = @_;
    $folder = imap_string_quote($folder);
    my ($id, $cv) = $self->send_cmd("CREATE $folder");
    return $cv;
}

sub noop {
    my ($self) = @_;
    my ($id, $cv) = $self->send_cmd('NOOP');
    return $cv;
}

# TODO:
# add_flags
# copy
# search('ALL')
# get_part_body

1;
__END__

=encoding utf8

=head1 NAME

AnyEvent::IMAP - IMAP client library for AnyEvent

=head1 SYNOPSIS

    use AnyEvent::IMAP;

    my $imap = AnyEvent::IMAP->new(
        host   => 'server',
        user   => "USERID",
        pass   => 'password',
        port   => 993,
        ssl    => 1,
    );
    $imap->reg_cb(
        connect => sub {
            $imap->login()->cb(sub {
                my ($ok, $line) = shift->recv;
                ...
            }
        }
    );
    $imap->connect();

=head1 DESCRIPTION

AnyEvent::IMAP is IMAP client library for AnyEvent/Perl.

=head1 METHODS

And some methods are usable by L<Object::Event>.

=over 4

=item my $imap = AnyEvent::IMAP->new(%args);

Create a new instance with following attributes.

=over 4

=item host

=item user

=item pass

=item port

=item ssl

=back

=item my ($tag, $cv) = $imap->send_cmd($command[, $filter : CodeRef])

Send a $command to the server. You can filter the response by optional $filter.

$tag is a IMAP command tag.

$cv is a instance of L<AnyEvent::CondVar>. You can process the server response by following format.

    my ($tag, $cv) = $imap->send_cmd('LOGIN');
    $cv->cb(sub {
        my ($ok, $res) = shift->recv;
        ...
    });

First response value is $ok. It presents server status is OK or not in boolean value.
$res is a response value. You can filter it by $filter in argument.

=back

=head1 EVENTS

=over 4

=item connect

=item connect_error

=item disconnect

=item buffer_empty

=item send

=item recv

=back

=head1 AND Example code

is available in example/demo.pl

=head1 FAQ

=over 4

=item How can I decode UTF-7 folder names?

use L<Encode::IMAPUTF7>.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom AAJKLFJEF@ GMAIL COME<gt>

=head1 THANKS TO

Some of the code taken from L<Net::IMAP::Client>.

=head1 SEE ALSO

L<Net::IMAP::Client>, RFC 3501, L<AnyEvent>

=head1 LICENSE

Copyright (C) Tokuhiro Matsuno

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
