#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2008-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::OpenSsh::Ssh ;
$Config::Model::Backend::OpenSsh::Ssh::VERSION = '1.241';
use Mouse ;
use 5.10.1;
extends "Config::Model::Backend::OpenSsh" ;

use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;
use File::HomeDir ;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");

sub write {
    my $self = shift;
    $self->ssh_write(@_, ssh_mode => 'custom') ;
}


sub host {
    my ($self,$root,$key, $patterns,$comment)  = @_;
    $logger->debug("host: pattern @$patterns # $comment");
    my $hash_obj = $root->fetch_element('Host');

    $logger->info("ssh: load host patterns '".join("','", @$patterns)."'");
    my $hv = $hash_obj->fetch_with_id("@$patterns") ;
    $hv -> annotation($comment) if $comment ;

    $self->current_node($hv);
}

sub forward {
    my ($self, $root, $key, $args, $comment, $check)  = @_;
    $logger->debug("forward: $key @$args # $comment");
    $self->current_node = $root unless defined $self->current_node ;

    my $elt_name = $key =~ /local/i ? 'Localforward' : 'RemoteForward' ;

    my $v6 = ($args->[1] =~ m![/\[\]]!) ? 1 : 0;

    $logger->info("ssh: load $key '".join("','", @$args)."' ". ( $v6 ? 'IPv6' : 'IPv4'));

    # cleanup possible square brackets used for IPv6
    foreach (@$args) {
        s/[\[\]]+//g;
    }

    # reverse enable to assign string to port even if no bind_adress
    # is specified
    my $re = $v6 ? qr!/! : qr!:! ;
    my ($port,$bind_adr ) = reverse split $re,$args->[0] ;
    my ($host,$host_port) = split $re,$args->[1] ;

    my $fw_list = $self->current_node->fetch_element($key);
    my $size = $fw_list->fetch_size;
    # this creates a new node in the list
    my $fw_obj = $fw_list->fetch_with_id($size);

    # $fw_obj->store_element_value( GatewayPorts => 1 ) if $bind_adr ;
    $fw_obj->annotation($comment) if $comment;

    $fw_obj->store_element_value( ipv6 => 1) if $v6 ;

    $fw_obj->store_element_value( check => $check, name => 'bind_address', value => $bind_adr)
        if defined $bind_adr ;
    $fw_obj->store_element_value( check => $check, name => 'port', value => $port );
    $fw_obj->store_element_value( check => $check, name => 'host', value => $host );
    $fw_obj->store_element_value( check => $check, name => 'hostport', value => $host_port );

}

sub write_all_host_block {
    my $self = shift ;
    my $host_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    foreach my $pattern ( $host_elt->fetch_all_indexes) {
        my $block_elt = $host_elt->fetch_with_id($pattern) ;
        $logger->debug("write_all_host_block on ".$block_elt->location." mode $mode");
        my $block_data = $self->write_node_content($block_elt,'custom') ;

        # write data only if custom pattern or custom data is found this
        # is necessary to avoid writing data from /etc/ssh/ssh_config that
        # were entered as 'preset' data
        if ($block_data) {
            $result .= $self->write_line(Host => $pattern, $block_elt->annotation);
            $result .= "$block_data\n" ;
        }
    }
    return $result ;
}

sub write_forward {
    my $self = shift ;
    my $forward_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    my $v6 = $forward_elt->grab_value('ipv6') ;
    my $sep = $v6 ? '/' : ':';

    my $line = '';
    foreach my $name ($forward_elt->get_element_name() ) {
        next if $name eq 'ipv6' ;
        my $elt = $forward_elt->fetch_element($name) ;
        my $v = $elt->fetch($mode) ;
        next unless length($v);
        $line
            .=  $name =~ /bind|host$/ ? "$v$sep"
            :   $name eq 'port'       ? "$v "
            :                            $v ;
    }

    return $self->write_line($forward_elt->element_name,$line,$forward_elt->annotation) ;
}

1;

no Mouse;

# ABSTRACT: Backend for ssh configuration files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::OpenSsh::Ssh - Backend for ssh configuration files

=head1 VERSION

version 1.241

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This calls provides a backend to read and write ssh client configuration files.

=head1 STOP

The documentation provides on the reader and writer of OpenSsh configuration files.
These details are not needed for the basic usages explained in L<Config::Model::OpenSsh>.

=head1 Methods

These read/write functions are part of C<OpenSsh::Ssh> read/write backend.
They are
declared in Ssh configuration model and are called back when needed to read the
configuration file and write it back.

=head2 read (object => <ssh_root>, config_dir => ...)

Read F<ssh_config> in C<config_dir> and load the data in the
C<ssh_root> configuration tree.

=head2 write (object => <ssh_root>, config_dir => ...)

Write F<ssh_config> in C<config_dir> from the data stored in
C<ssh_root> configuration tree.

=head1 SEE ALSO

L<cme>, L<Config::Model>, L<Config::Model::OpenSsh>

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2008-2018 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
