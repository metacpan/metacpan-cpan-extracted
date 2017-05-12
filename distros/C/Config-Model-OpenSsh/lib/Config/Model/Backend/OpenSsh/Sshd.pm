#
# This file is part of Config-Model-OpenSsh
#
# This software is Copyright (c) 2014 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
package Config::Model::Backend::OpenSsh::Sshd ;
$Config::Model::Backend::OpenSsh::Sshd::VERSION = '1.237';
use Mouse ;
extends "Config::Model::Backend::OpenSsh" ;

use Carp ;
use IO::File ;
use Log::Log4perl;
use File::Copy ;
use File::Path ;

my $logger = Log::Log4perl::get_logger("Backend::OpenSsh");


sub _host {
    my ($self,$root,$patterns,$comment)  = @_;
    $logger->debug("host: pattern @$patterns # $comment");
    my $hash_obj = $root->fetch_element('Host');

    $logger->info("ssh: load host patterns '".join("','", @$patterns)."'");

    $self->current_node = $hash_obj->fetch_with_id("@$patterns");
}

sub _forward {
    my ($self,$root,$key,$args,$comment)  = @_;
    $logger->debug("forward: $key @$args # $comment");
    $self->current_node($root) unless defined $self->current_node ;

    my $elt_name = $key =~ /local/i ? 'Localforward' : 'RemoteForward' ;
    my $size = $self->current_node->fetch_element($key)->fetch_size;

    $logger->info("ssh: load $key '".join("','", @$args)."'");

    my $v6 = ($args->[1] =~ m![/\[\]]!) ? 1 : 0;

    # cleanup possible square brackets used for IPv6
    foreach (@$args) {s/[\[\]]+//g;}

    # reverse enable to assign string to port even if no bind_adress
    # is specified
    my $re = $v6 ? qr!/! : qr!:! ; 
    my ($port,$bind_adr ) = reverse split $re,$args->[0] ;
    my ($host,$host_port) = split $re,$args->[1] ;

    my $load_str = '';
    $load_str .= "GatewayPorts=1 " if $bind_adr ;

    $load_str .= "$key:$size ";

    $load_str .= 'ipv6=1 ' if $v6 ;

    $load_str .= "bind_address=$bind_adr " if defined $bind_adr ;
    $load_str .= "port=$port host=$host hostport=$host_port";

    $self->current_node -> load($load_str) ;
}

sub match {
    my ($self,$root, $key, $pairs,$comment) = @_ ;
    $logger->debug("match: @$pairs # $comment");
    my $list_obj = $root->fetch_element('Match');

    # create new match block
    my $nb_of_elt = $list_obj->fetch_size;
    my $block_obj = $list_obj->fetch_with_id($nb_of_elt) ;
    $block_obj->annotation($comment) ;

    while (@$pairs) {
       my $criteria = shift @$pairs;
       my $pattern  = shift @$pairs;
       $block_obj->load(qq!Condition $criteria="$pattern"!);
    }

    $self->current_node( $block_obj->fetch_element('Settings') );
}


# now the write part
sub write {
    my $self = shift;
    $self->ssh_write(@_) ;
}

sub _write_line {
    return sprintf("%-20s %s\n",@_) ;
}

sub write_all_match_block {
    my $self = shift ;
    my $match_elt = shift ;
    my $mode = shift || '';

    my $result = '';
    foreach my $elt ($match_elt->fetch_all($mode) ) {
	$result .= $self->write_match_block($elt,$mode) ;
    }

    return $result ;
}

sub write_match_block {
    my $self = shift ;
    my $match_elt = shift ;
    my $mode = shift || '';

    my $match_line ;
    my $match_body ;

    foreach my $name ($match_elt->get_element_name() ) {
	my $elt = $match_elt->fetch_element($name) ;

	if ($name eq 'Settings') {
	    $match_body .= $self->write_node_content($elt,$mode)."\n" ;
	}
	elsif ($name eq 'Condition') {
	    $match_line = $self->write_line( 
                Match => $self->write_match_condition($elt,$mode) ,
                $match_elt -> annotation
            ) ;
	}
	else {
	    die "write_match_block: unexpected element: $name";
	}
    }

    return $match_line.$match_body ;
}

sub write_match_condition {
    my $self = shift ;
    my $cond_elt = shift ;
    my $mode = shift || '';

    my $result = '' ;

    foreach my $name ($cond_elt->get_element_name() ) {
	my $elt = $cond_elt->fetch_element($name) ;
	my $v = $elt->fetch($mode) ;
	$result .= " $name $v" if defined $v;
    }

    return $result ;
}

no Mouse;

1;

# ABSTRACT: Backend for sshd configuration files

__END__

=pod

=encoding UTF-8

=head1 NAME

Config::Model::Backend::OpenSsh::Sshd - Backend for sshd configuration files

=head1 VERSION

version 1.237

=head1 SYNOPSIS

None

=head1 DESCRIPTION

This calls provides a backend to read and write sshd client configuration files.

=head1 STOP

The documentation provides on the reader and writer of OpenSsh configuration files.
These details are not needed for the basic usages explained in L<Config::Model::OpenSsh>.

=head1 Methods

These read/write functions are part of C<OpenSsh::Sshd> read/write backend. 
They are 
declared in sshd configuration model and are called back when needed to read the 
configuration file and write it back.

=head2 read (object => <sshd_root>, config_dir => ...)

Read F<sshd_config> in C<config_dir> and load the data in the 
C<sshd_root> configuration tree.

=head2 write (object => <sshd_root>, config_dir => ...)

Write F<sshd_config> in C<config_dir> from the data stored in  
C<sshd_root> configuration tree.

=head1 SEE ALSO

L<cme>, L<Config::Model>,

=head1 AUTHOR

Dominique Dumont

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Dominique Dumont.

This is free software, licensed under:

  The GNU Lesser General Public License, Version 2.1, February 1999

=cut
