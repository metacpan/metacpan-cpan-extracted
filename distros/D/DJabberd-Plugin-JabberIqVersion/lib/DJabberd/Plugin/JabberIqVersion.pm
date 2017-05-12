package DJabberd::Plugin::JabberIqVersion;

use warnings;
use strict;
use base 'DJabberd::Plugin';
our $logger = DJabberd::Log->get_logger();
use DJabberd;

=head1 NAME

DJabberd::Plugin::JabberIqVersion - Add support for "XEP 0092, Software version" to DJabberd

=head1 VERSION

Version 0.40

=cut
use vars qw($VERSION);
$VERSION = '0.40';

=head1 SYNOPSIS

 <Vhost example.com>
     ...
         <Plugin DJabberd::Plugin::JabberIqVersion>
                OS Gnu/Windows
                Name PerlJabberServer Professional 
                Version Gold
         </Plugin>
     ...
 </VHost>

=cut

=head2 set_config_version($self, $val)

Configure the <version/> returned by module.

=cut

sub set_config_version {
    my ($self, $val) = @_;
    $self->{version} = $val;
}

=head2 set_config_os($self, $val)

Configure the <os/> returned by module.

=cut

sub set_config_os {
    my ($self, $val) = @_;
    $self->{os} = $val;
}

=head2 set_config_name($self, $val)

Configure the <name/> returned by module.

=cut

sub set_config_name {
    my ($self, $val) = @_;
    $self->{name} = $val;
}

=head2 finalize($self)

Fill default value. name is set to Djabberd, and version to the
server version. Os is not filled, for the moment.

=cut

sub finalize {
    my ($self) = @_;
    $self->{name} ||= 'DJabberd';
    $self->{version} ||= $DJabberd::VERSION;

    my ($sysname, $nodename, $release, $version, $machine) = POSIX::uname();
    $self->{os} ||= "$sysname $release";
}



=head2 register($self, $vhost)

Register the vhost with the module.

=cut

sub register {
    my ($self, $vhost) = @_;
    my $private_cb = sub {
        my ($vh, $cb, $iq) = @_;
        unless ($iq->isa("DJabberd::IQ") and defined $iq->to) {
            $cb->decline;
            return;
        }
        unless ($iq->to eq $vhost->{server_name}) {
            $cb->decline;
            return;
        }
        
        if ($iq->signature eq 'get-{jabber:iq:version}query') {
            $self->_get_version($vh, $iq);
            $cb->stop_chain;
            return;
        }
        $cb->decline;
    };
    $vhost->register_hook("switch_incoming_client",$private_cb);
    $vhost->register_hook("switch_incoming_server",$private_cb);
    $vhost->add_feature("jabber:iq:version");

}

sub _get_version {
    my ($self, $vhost, $iq) = @_;
    
    $logger->info("Get version from : " . $iq->from_jid);
    $iq->send_reply('result', qq(<query xmlns="jabber:iq:version">) 
                                  . "<name>" . $self->{name} . "</name>"
                                  . ( $self->{os} ? "<os>" . $self->{os} . "</os>" : "" )
                                  . "<version>" . $self->{version} . "</version>"
                                  . qq(</query>) );
 
}

=head1 AUTHOR

Michael Scherer, C<< <misc@zarb.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-djabberd-plugin-jabberiqversion@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DJabberd-Plugin-JabberIqVersion>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006 Michael Scherer, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; 
