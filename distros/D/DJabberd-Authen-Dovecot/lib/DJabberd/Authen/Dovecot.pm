#!/usr/bin/perl -w

package DJabberd::Authen::Dovecot;
use strict;
use base 'DJabberd::Authen';
use DJabberd::Log;

our $VERSION = '0.1';

use Socket;
use MIME::Base64;

sub set_config_socket {
    my ($self, $sock) = @_;
    $self->{sock} = $sock;
}

sub set_config_realm {
    my ($self, $realm) = @_;
    $self->{realm} = $realm;
}

sub finalize {
    my $self = shift;
    $self->{realm} ||= '';
    $self->{sock} ||="/var/run/dovecot/auth-client";
}

sub can_retrieve_cleartext { 0 }

sub check_cleartext {
    my $self = shift;
    my $cb = shift;
    my %args = @_;
    my $user=$args{username};
    my $pass=$args{password};
    my $ch=encode_base64("\0$user\0$pass");
    my $auth;
    socket($auth,PF_UNIX,SOCK_STREAM,0);
    connect($auth,scalar(sockaddr_un($self->{sock})));
    my $cpid="CPID\t$$\n";
    my $data;
    sysread($auth,$data,1024);
    my @data=split("\n",$data);
    while(my $l=shift(@data)) {
	if($l eq "DONE") {
	    syswrite($auth,"VERSION\t1\t1\n");
	    syswrite($auth,$cpid);
	    syswrite($auth,"AUTH\t1\tPLAIN\tservice=xmpp\tresp=$ch");
	    sysread($auth,$data,1024);
	    @data=split("\n",$data);
	} elsif($l =~/^FAIL/) {
	    @data=();
	    $cb->reject();
	} elsif($l =~/^OK/) {
	    @data=();
	    $cb->accept();
	}
    }
    close($auth);
    return 1;
}

1;

__END__

=head1 NAME

DJabberd::Authen::Dovecot - Dovecot SASL authentificator for DJabberd.

It uses PLAIN AUTH only.

=head1

Usage:

  <Plugin DJabberd::Authen::Dovecot>
    Realm djabberd
    Socket /usr/local/var/dovecot/auth-client
  </Plugin>

If not specified Realm is empty and Socket is /var/run/dovecot/auth-client

=head1 COPYRIGHT

This module is Copyright (c) 2013 Ruslan N. Marchenko.
All rights reserved.

You may distribute under the terms of either the GNU General Public
License or the Artistic License, as specified in the Perl README file.

=head1 WARRANTY

This is free software. IT COMES WITHOUT WARRANTY OF ANY KIND.

=head1 WEBSITE

Visit:

http://danga.com/djabberd/

=head1 AUTHORS

Ruslan N. Marchenko <me@ruff.mobi>
