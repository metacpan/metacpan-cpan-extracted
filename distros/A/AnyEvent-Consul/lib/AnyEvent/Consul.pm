package AnyEvent::Consul;
$AnyEvent::Consul::VERSION = '0.005';
# ABSTRACT: Make async calls to Consul via AnyEvent

use warnings;
use strict;

use Consul 0.016;
use AnyEvent::HTTP qw(http_request);
use Hash::MultiValue;
use Carp qw(croak);

sub new {
    shift;
    Consul->new(@_,
        request_cb => sub {
            my ($self, $req) = @_;
            http_request($req->method, $req->url,
                body => $req->content,
                headers => $req->headers->as_hashref,
                timeout => $self->timeout,
                sub {
                    my ($rdata, $rheaders) = @_;
                    my $rstatus = delete $rheaders->{Status};
                    my $rreason = delete $rheaders->{Reason};
                    delete $rheaders->{$_} for grep { m/^[A-Z]/ } keys %$rheaders;
                    $req->callback->(Consul::Response->new(
                        status  => $rstatus,
                        reason  => $rreason,
                        headers => Hash::MultiValue->from_mixed($rheaders),
                        content => defined $rdata ? $rdata : "",
                        request => $req,
                    ));
                },
            );
            return;
        },
    );
}

sub acl     { shift->new(@_)->acl     }
sub agent   { shift->new(@_)->agent   }
sub catalog { shift->new(@_)->catalog }
sub event   { shift->new(@_)->event   }
sub health  { shift->new(@_)->health  }
sub kv      { shift->new(@_)->kv      }
sub session { shift->new(@_)->session }
sub status  { shift->new(@_)->status  }

1;

=pod

=encoding UTF-8

=for markdown [![Build Status](https://secure.travis-ci.org/robn/AnyEvent-Consul.png)](http://travis-ci.org/robn/AnyEvent-Consul)

=head1 NAME

AnyEvent::Consul - Make async calls to Consul via AnyEvent

=head1 SYNOPSIS

    use AnyEvent;
    use AnyEvent::Consul;
    
    my $cv = AE::cv;
    
    my $kv = AnyEvent::Consul->kv;

    # do some blocking op to discover the current index
    $kv->get("mykey", cb => sub { 
        my ($v, $meta) = @_;
    
        # now set up a long-poll to watch a key we're interested in
        $kv->get("mykey", index => $meta->index, cb => sub {
            my ($v, $meta) = @_;
            say "mykey changed to ".$v->value;
            $cv->send;
        });
    });
    
    # make the change
    $kv->put("mykey" => "newval");
    
    $cv->recv;

=head1 DESCRIPTION

AnyEvent::Consul is a thin wrapper around L<Consul> to connect it to
L<AnyEvent::HTTP> for asynchronous operation.

It takes the same arguments and methods as L<Consul> itself, so see the
documentation for that module for details. The important difference is that you
must pass the C<cb> option to the endpoint methods to enable their asynchronous
mode.

There's also a C<on_error> argument. If you pass in a coderef for this
argument, it will be called with a single string arg whenever something goes
wrong internally (usually a HTTP failure). Use it to safely log or cleanup
after the error.

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/robn/AnyEvent-Consul/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/robn/AnyEvent-Consul>

  git clone https://github.com/robn/AnyEvent-Consul.git

=head1 AUTHORS

=over 4

=item *

Robert Norris <rob@eatenbyagrue.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Robert Norris.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
