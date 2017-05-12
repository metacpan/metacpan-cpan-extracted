package Apache2::Connection::Arp;

use strict;
use warnings;

use Apache2::RequestUtil    ();
use Apache2::RequestRec     ();
use Apache2::Connection     ();
use Apache2::ConnectionUtil ();
use Apache2::SubProcess     ();
use Apache2::Const -compile => qw( DECLINED SERVER_ERROR OK );
use Apache2::Log ();
use Config;
use constant PERLIO_IS_ENABLED => $Config{useperlio};

our $VERSION = 0.01;

=head1 NAME

Apache2::Connection::Arp - use arp to get the mac address of remote clients

=head1 SYNOPSIS

In your httpd.conf

  PerlLoadModule Apache2::Connection::Arp
  PerlSetVar arp_binary '/usr/sbin/arp'

  PerlPostReadRequestHandler Apache2::Connection::Arp

  <Location />
      SetHandler mod_perl
      PerlResponseHandler My::Handler
  </Location>

Meanwhile in a nearby mod_perl handler...

  $remote_mac = $r->connection->pnotes('remote_mac');

=cut

sub handler {
    my $r = shift;

    # don't arp every time
    return Apache2::Const::DECLINED if $r->connection->pnotes('remote_mac');

    my $cmd  = $r->dir_config('arp_binary');
    my $remote_ip = $r->connection->remote_ip;
    my ( $in_fh, $out_fh, $err_fh ) = $r->spawn_proc_prog( $cmd, [ $remote_ip ] );

     if (my $err = read_data($err_fh)) {
        $r->log->error("error executing '$cmd $remote_ip', $err");
        return Apache2::Const::SERVER_ERROR;
    }

    # you have a more preferable regex? patches welcome! :)
    my $out = read_data($out_fh);
    if (my ($remote_mac) = $out =~ m/([0-9A-Z]{1,2}:(?:[0-9A-Z]{2}:){4}[0-9A-Z][0-9A-Z])/i) {

        $r->connection->pnotes('remote_mac' => $remote_mac);
    }

    return Apache2::Const::DECLINED;
}

# http://perl.apache.org/docs/2.0/api/Apache2/SubProcess.html#Synopsis

sub read_data {
    my ($fh) = @_;
    my $data;
    if ( PERLIO_IS_ENABLED || IO::Select->new($fh)->can_read(10) ) {
        $data = <$fh>;
    }
    return defined $data ? $data : '';
}

1;

=head1 DESCRIPTION

This module grabs the mac address of the remote client and stashes it in the
connection pnotes for later retrieval.

=head1 SEE ALSO

L<Apache2::ConnectionUtil>

=head1 AUTHOR

Fred Moyer, E<lt>fred@redhotpenguin.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Fred Moyer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
