{   package DJabberd::Plugin::Balancer;
    our $VERSION = '0.1';
    use strict;
    use warnings;
    use base qw(DJabberd::Plugin);

    sub register {
        my ($self, $vhost) = @_;
        # here we just re-bless $vhost
        bless $vhost, 'DJabberd::Plugin::Balancer::VHost';
    }
};
{   package DJabberd::Plugin::Balancer::VHost;
    use strict;
    use warnings;
    use base qw(DJabberd::VHost);

    sub register_jid {
        my ($self, $jid, $conn, $cb) = @_;
        my $fullstr = $jid->as_string;

        if (exists $self->{jid2sock}{$fullstr}) {
            $cb->error("conflict");

        } else {
            # XXX: $jid doesn't provide a sane API, but
            # we are going to get inside anyway.
            my $res = $jid->resource;
            $res .= '#'.$conn->{id};
            $jid->[DJabberd::JID::RES()] = $res;
            $jid->[DJabberd::JID::AS_STRING()] = undef;
            $jid->[DJabberd::JID::AS_BSTRING()] = undef;
            $jid->[DJabberd::JID::AS_STREXML()] = undef;

            $self->{balancejid}{$fullstr} ||= [];
            push @{$self->{balancejid}{$fullstr}}, $jid->as_string;

            return $self->SUPER::register_jid($jid, $conn, $cb);
        }
    }

    sub find_jid {
        my ($self, $jid) = @_;
        my $fullstr = $jid;

        if (exists $self->{balancejid}{$fullstr}) {
            my $item = int(rand(scalar(@{$self->{balancejid}{$fullstr}})));
            return $self->SUPER::find_jid($self->{balancejid}{$fullstr}[$item]);
        } else {
            return $self->SUPER::find_jid($jid);
        }
    }

    sub unregister_jid {
        my ($self, $jid, $conn) = @_;
        my $fullstr = $jid->as_string;
        my $balancejid = $fullstr;
        if ($balancejid =~ s/#[^#]+$//) {
            if (exists $self->{balancejid}{$balancejid}) {
                @{$self->{balancejid}{$balancejid}} =
                  grep { $fullstr ne $_ }
                    @{$self->{balancejid}{$balancejid}};
            }
        }
        return $self->SUPER::unregister_jid($jid, $conn);
    }

};

__PACKAGE__

__END__

=head1 NAME

DJabberd::Plugin::Balancer - Load balancing djabberd plugin

=head1 SYNOPSIS

  <VHost ...>
    <Plugin DJabberd::Plugin::Balancer/>
    ...
  </VHost>

=head1 DESCRIPTION

This is a simple load balancer plugin for djabberd that works by
distributing all the messages for a single fully qualified JID through
several clients.

Every time a client binds to a resource, this plugin will record that
trial and return a different resource, including a sufix in the #999
format. The original JID will be saved as a load balancing
endpoint. Other clients then can try to bind to the same resource, and
will also be assigned different JIDs, but all that will be recorded.

If some client, on the other hand, tries to bind to the resource of
another real client (already with the #999 sufix), the bind will be
denied.

When a message arrives for the load-balancing-endpoint JID, it will be
dispatched randomly through all the clients that tried to bind to that
resource.

Messages to the real JIDs will be delivered normally, iq stanzas will
work as expected, since when sending that, the client will send using
the JID assigned by the server.

=head1 DIFFERENCES

Unlike the default behaviour, on a real-JID conflict, the new
connection will be dropped, and not the old one.

=head1 COPYRIGHT

This module was created by "Daniel Ruoso" <daniel@ruoso.com>.
It is licensed under both the GNU GPL and the Artistic License.

=cut

