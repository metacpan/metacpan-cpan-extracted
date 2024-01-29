# Copyright (c) 2023-2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2023-2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Extractor for identifiers from URIs

package Data::URIID::Future;

use strict;
use warnings;
use v5.10;

use Carp;
use JSON;
use Encode;
use URI;

use parent 'Future';

our $VERSION = v0.05;




sub _get_uri {
    my ($self, $uri) = @_;
    return URI->new($uri) unless ref $uri;
    return $uri if eval {$uri->isa('URI')};
    return $self->_get_uri($self->$uri());
}

sub get_json {
    my ($pkg, %opts) = @_;
    my $ua = $opts{extractor}->_ua;
    my @predepends = @{$opts{predepends}//[]};

    push(@predepends, $opts{elder}) if defined $opts{elder};

    if ($ua->isa('LWP::UserAgent')) {
        return $pkg->new(sub {
                my ($self) = @_;
                if (defined($opts{elder}) && defined(my $answer = eval {$opts{elder}->get})) {
                    return $self->done($answer);
                }
                my $uri = $self->_get_uri($opts{uri});
                return undef unless defined $uri;
                my $msg = $ua->get($uri, 'Accept' => 'application/json');
                return undef unless $msg->is_success;
                my $val = $msg->decoded_content(ref => 1, charset => 'none');
                $self->done(from_json(decode($msg->content_charset, $$val)));
            }, @predepends);
    } elsif ($ua->isa('Mojo::UserAgent')) {
        state $ioloop = eval {Mojo::IOLoop->singleton} // return $pkg->new->die($@);
        return $pkg->new(sub {
                my ($self) = @_;
                if (defined($opts{elder}) && defined(my $answer = eval {$opts{elder}->get})) {
                    return $self->done($answer);
                }
                my $uri = $self->_get_uri($opts{uri});
                return undef unless defined $uri;
                my $x = 1001; # we use 1001 and --$x here instead of 1000 and $x-- as that confuses parsers.
                my $tx = $ua->build_tx(GET => $uri->as_string => {'Accept-Language' => join(', ', map {sprintf('%s; q=%.3f', $_, --$x/1000)} $opts{extractor}->language_tags)});
                my $done;
                my $is_running;
                $self->{__PACKAGE__.'_tx'} = $tx;
                $ua->start($tx, sub {
                        my ($ua, $tx) = @_;
                        my $err = $tx->error;
                        $done = 1;
                        $ioloop->stop unless $is_running;
                        if (!$err || $err->{code}) {
                            if (defined(my $json = eval {$tx->res->json})) {
                                $self->done($json)
                            } else {
                                $self->die($@ || 'No JSON response');
                            }
                        } else {
                            $self->fail($err->{message})
                        }
                    });
                $self->{__PACKAGE__.'_await'} = sub {
                    return if $is_running = $ioloop->is_running;
                    $ioloop->start until $done;
                };
            }, @predepends);
    }

    return $pkg->new->die('Unsupported user agent');
}

sub new {
    my ($xxx, @args) = @_;
    my $self = $xxx->SUPER::new();

    $self->{__PACKAGE__.'_predepends'} = [];

    if (ref $xxx) {
        push(@{$self->{__PACKAGE__.'_predepends'}}, $xxx);
    }

    while (my $arg = shift(@args)) {
        if (ref $arg) {
            if (eval {$arg->isa('Data::URIID')}) {
                $self->{__PACKAGE__.'_extractor'} = $arg;
            } elsif (eval {$arg->isa('Data::URIID::Future')}) {
                push(@{$self->{__PACKAGE__.'_predepends'}}, $arg);
            } else {
                $self->{__PACKAGE__.'_body'} = $arg;
            }
        } else {
            croak 'Bad argument';
        }
    }

    return $self;
}


sub add_predepend {
    my ($self, @predepends) = @_;
    push(@{$self->{__PACKAGE__.'_predepends'}}, @predepends);
}


sub combine {
    my ($pkg, @others) = @_;
    if (scalar(@others) == 1) {
        return $others[0];
    } elsif (scalar(@others) == 0) {
        return undef;
    }

    return $pkg->wait_all(@others);
}

sub await {
    my ($self) = @_;
    my $fine;

    return $self if $self->is_ready;

    $_->await foreach @{$self->{__PACKAGE__.'_predepends'}};
    $fine ||= eval { $_->await foreach $self->pending_futures; 1; };

    if (defined(my $body = delete $self->{__PACKAGE__.'_body'})) {
        eval { $self->$body() };
        $self->die($@) if $@;
    }

    if (defined(my $waiter = $self->{__PACKAGE__.'_await'})) {
        $fine ||= eval {$self->$waiter(); 1; };
    }

    return $self if $self->is_ready; # re-check to see if the above was all that was needed.
    return $self->die('No way to wait '.$self) unless $fine;
    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::URIID::Future - Extractor for identifiers from URIs

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use Data::URIID::Future;

    my $extractor = Data::URIID->new;
    my $future    = Data::URIID::Future->get_json(extractor => $extractor, uri => $uri);

B<Warning:> This is an module is for internal use only.

=head1 METHODS

=head2 get_json

    my Future $future = Data::URIID::Future->get_json(extractor => $extractor, uri => $uri);

Returns a future requesting JSON data via GET from an L<URI>.
The C<$uri> must be an L<URI> object or a code reference that will return an URI.

=head2 add_predepend

    my Data::URIID::Future $future;
    $future->add_predepend(@predepends);

This adds pre dependencies to the future. Those dependencies must be ready
before this future can be resolved.

This call only has an effect on futures that are not yet ready.

=head2 combine

    my Future $future = Data::URIID::Future->combine(@others);

This method allowed to combine a list of futures in the same manner as L<Future/"wait_all"> does.
However the following rules apply to it's return value:

If C<@others> is empty C<undef> is returned.
If C<@others> contain exactly one element that element is returned.
Otherwise C<combine> returns a new future.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2023-2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
