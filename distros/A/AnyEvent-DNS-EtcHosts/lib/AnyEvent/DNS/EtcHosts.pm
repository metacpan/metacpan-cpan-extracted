package AnyEvent::DNS::EtcHosts;

=head1 NAME

AnyEvent::DNS::EtcHosts - Use /etc/hosts before DNS

=head1 SYNOPSIS

  use AnyEvent::DNS::EtcHosts;

  use AnyEvent::DNS;
  my $cv = AE::cv;
  AnyEvent::DNS::any 'example.com', sub {
      say foreach map { $_->[4] } grep { $_->[1] =~ /^(a|aaaa)$/ } @_;
      $cv->send;
  };

  use AnyEvent::Socket;
  my $cv = AE::cv;
  AnyEvent::Socket::resolve_sockaddr $domain, $service, $proto, $family, undef, sub {
      say foreach map { format_address((AnyEvent::Socket::unpack_sockaddr($_->[3]))[1]) } @_;
      $cv->send;
  };

=head1 DESCRIPTION

AnyEvent::DNS::EtcHosts changes AnyEvent::DNS behavior. The F</etc/hosts> file
is searched before DNS, so it is possible to override DNS entries.

The DNS lookups are emulated. This resolver returns the standard DNS reply
based on F</etc/hosts> file rather than real DNS.

You can choose different file by changing C<PERL_ANYEVENT_HOSTS> environment
variable.

This module also disables original L<AnyEvent::Socket>'s helper function which
reads F</etc/hosts> file after DNS entry was not found. It prevents to read
this file twice.

The L<AnyEvent::Socket> resolver searches IPv4 and IPv6 addresses separately.
If you don't want to check the addresses in DNS, both IPv4 and IPv6 addresses
should be placed in F</etc/hosts> or the protocol family should be set
explicitly for C<resolve_sockaddr> function.

=for readme stop

=cut


use 5.008_001;
use strict;
use warnings;

our $VERSION = '0.0103';

use base 'AnyEvent::DNS';

use AnyEvent ();
use AnyEvent::Socket ();

use constant DEBUG => $ENV{PERL_ANYEVENT_DNS_ETCHOSTS_DEBUG};
use if DEBUG, 'Data::Dumper';


our $GUARD;


=head1 IMPORTS

=head2 use AnyEvent::DNS::EtcHosts %args;

  use AnyEvent::DNS::EtcHosts server => '8.8.8.8';

  $ perl -MAnyEvent::DNS::EtcHosts script.pl

Enables this module globally. Additional arguments will be passed to
L<AnyEvent::DNS> constructor.

=cut

sub import {
    my ($class, %args) = @_;
    $GUARD = $class->register(%args);
}


=head2 no AnyEvent::DNS::EtcHosts;

Disables this module globally.

=cut

sub unimport {
    my ($class) = @_;
    undef $GUARD;
}


=head1 METHODS

=head2 register

  require AnyEvent::DNS::EtcHosts;

  $guard = AnyEvent::DNS::EtcHosts->register(%args);

  undef $guard;

Enables this module in lexical scope. The module will be disabled out of
scope. Additional arguments will be passed to L<AnyEvent::DNS> constructor.

If you want to use AnyEvent::DNS::EtcHosts in lexical scope only, you should
use C<require> rather than C<use> keyword, because C<import> method enables
AnyEvent::DNS::EtcHosts globally.

=cut

sub register {
    my ($class, %args) = @_;

    my $old_resolver = $AnyEvent::DNS::RESOLVER;

    $AnyEvent::DNS::RESOLVER = do {
        my $resolver = AnyEvent::DNS::EtcHosts->new(
            untaint         => 1,
            max_outstanding => $ENV{PERL_ANYEVENT_MAX_OUTSTANDING_DNS} || 1,
            %args
        );
        if (not $args{server}) {
            $ENV{PERL_ANYEVENT_RESOLV_CONF}
                ? $resolver->_load_resolv_conf_file($ENV{PERL_ANYEVENT_RESOLV_CONF})
                : $resolver->os_config;
        }
        $resolver;
    };

    # Overwrite original helper function only if exists
    my $old_helper = do {
        \&AnyEvent::Socket::_load_hosts_unless
            if ((prototype 'AnyEvent::Socket::_load_hosts_unless')||'') eq '&$@';
    };

    if ($old_helper) {
        no warnings 'redefine';
        *AnyEvent::Socket::_load_hosts_unless = sub (&$@) {
            my ($cont, $cv, @dns) = @_;
            $cv->end;
        };
    }

    return AnyEvent::Util::guard {
        $AnyEvent::DNS::RESOLVER = $old_resolver;
        no warnings 'redefine';
        *AnyEvent::Socket::_load_hosts_unless = $old_helper if $old_helper;
    };
}


# Helper functions taken from AnyEvent::Socket 7.05

our %HOSTS;          # $HOSTS{$nodename}[$ipv6] = [@aliases...]
our @HOSTS_CHECKING; # callbacks to call when hosts have been loaded
our $HOSTS_MTIME;

sub _parse_hosts($) {
   %HOSTS = ();

   for (split /\n/, $_[0]) {
      s/#.*$//;
      s/^[ \t]+//;
      y/A-Z/a-z/;

      my ($addr, @aliases) = split /[ \t]+/;
      next unless @aliases;

      if (my $ipv4 = AnyEvent::Socket::parse_ipv4 $addr) {
         ($ipv4) = $ipv4 =~ /^(.*)$/s if AnyEvent::TAINT;
         push @{ $HOSTS{$_}[0] }, $ipv4
            for @aliases;
      } elsif (my $ipv6 = AnyEvent::Socket::parse_ipv6 $addr) {
         ($ipv6) = $ipv6 =~ /^(.*)$/s if AnyEvent::TAINT;
         push @{ $HOSTS{$_}[1] }, $ipv6
            for @aliases;
      }
   }
}

# helper function - unless dns delivered results, check and parse hosts, then call continuation code
sub _load_hosts_unless(&$@) {
   my ($cont, $cv, @dns) = @_;

   if (@dns) {
      $cv->end;
   } else {
      my $etc_hosts = length $ENV{PERL_ANYEVENT_HOSTS} ? $ENV{PERL_ANYEVENT_HOSTS}
                      : AnyEvent::WIN32                ? "$ENV{SystemRoot}/system32/drivers/etc/hosts"
                      :                                  "/etc/hosts";

      push @HOSTS_CHECKING, sub {
         $cont->();
         $cv->end;
      };

      unless ($#HOSTS_CHECKING) {
         # we are not the first, so we actually have to do the work
         require AnyEvent::IO;

         AnyEvent::IO::aio_stat ($etc_hosts, sub {
            if ((stat _)[9] ne ($HOSTS_MTIME||0)) {
               AE::log 8 => "(re)loading $etc_hosts.";
               $HOSTS_MTIME = (stat _)[9];
               # we might load a newer version of hosts,but that's a harmless race,
               # as the next call will just load it again.
               AnyEvent::IO::aio_load ($etc_hosts, sub {
                  _parse_hosts $_[0];
                  (shift @HOSTS_CHECKING)->() while @HOSTS_CHECKING;
               });
            } else {
               (shift @HOSTS_CHECKING)->() while @HOSTS_CHECKING;
            }
         });
      }
   }
}


=head2 request

  $resolver->request($req, $cb->($res))

This is wrapper for L<AnyEvent::DNS>->request method.

=cut

sub request {
    my ($self, $req, $cb) = @_;
    warn "req = ". Dumper $req if DEBUG;

    my $node = my $domain = $req->{qd}[0][0];
    $node =~ s/^_[a-z0-9-]*\._[a-z0-9-]*\.// if ($req->{qd}[0][1] eq 'srv');

    my $type = $req->{qd}[0][1];

    my (@ipv4, @ipv6, @srv);

    my $cv = AE::cv;

    $cv->begin;
    _load_hosts_unless {
        if (exists $HOSTS{$node}) {
            if ($type =~ /^([*]|srv)$/) {
                push @srv, $node
            }
            if (ref $HOSTS{$node} eq 'ARRAY') {
                if ($type =~ /^([*]|a)$/ and exists $HOSTS{$node}[0]) {
                    push @ipv4, @{ $HOSTS{$node}[0] }
                }
                if ($type =~ /^([*]|aaaa)$/ and exists $HOSTS{$node}[1]) {
                    push @ipv6, @{ $HOSTS{$node}[1] }
                }
            }
        }

        if (@ipv4 or @ipv6 or @srv) {
            my $res = {
                id => int rand(0xffff),
                op => 'query',
                rc => 'noerror',
                qr => 1,
                aa => '',
                tc => '',
                rd => $req->{rd},
                ra => 1,
                ad => '',
                cd => '',
                qd => $req->{qd},
                an => [
                    (map { [ $domain, 'srv', 'in', 0, 0, 0, 0, $_ ] } @srv),
                    (map { [ $node, 'a', 'in', 0, AnyEvent::Socket::format_ipv4 $_ ] } @ipv4),
                    (map { [ $node, 'aaaa', 'in', 0, AnyEvent::Socket::format_ipv6 $_ ] } @ipv6),
                ],
                ns => [],
                ar => [],
            };

            warn "res = ". Dumper $res if DEBUG;

            return $cb->($res);
        }

        return $self->SUPER::request($req, sub {
            my ($res) = @_;
            warn "SUPER::request res = ". Dumper $res if DEBUG;
            $cb->($res);
        });

    } $cv;

    return;
}


1;


=for readme continue

=head1 SEE ALSO

L<AnyEvent::DNS>,
L<AnyEvent::Socket>.

=head1 BUGS

This module might be incompatible with further versions of L<AnyEvent> module.

If you find the bug or want to implement new features, please report it at
L<https://github.com/dex4er/perl-AnyEvent-DNS-EtcHosts/issues>

The code repository is available at
L<http://github.com/dex4er/perl-AnyEvent-DNS-EtcHosts>

=head1 AUTHORS

Piotr Roszatycki <dexter@cpan.org>

Helper functions taken from AnyEvent::Socket 7.05 by
Marc Lehmann <schmorp@schmorp.de>

=head1 LICENSE

Copyright (c) 2013-2014 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>
