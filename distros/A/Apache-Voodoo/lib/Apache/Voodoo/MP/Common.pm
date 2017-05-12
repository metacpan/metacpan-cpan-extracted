package Apache::Voodoo::MP::Common;

$VERSION = "3.0200";

use strict;
use warnings;

use Time::HiRes;

sub new {
	my $class = shift;
	my $self = {};

	bless $self,$class;
	return $self;
}

sub set_request {
	my $self = shift;

	$self->{r} = shift;

	$self->{request_id} = Time::HiRes::time;

	delete $self->{'cookiejar'};
}

sub request_id { return $_[0]->{request_id}; }

sub dir_config { shift()->{r}->dir_config(@_); }
sub filename   { shift()->{r}->filename(); }
sub flush      { shift()->{r}->rflush(); }
sub method     { shift()->{r}->method(@_); }
sub print      { shift()->{r}->print(@_); }
sub uri        { shift()->{r}->uri(); }

sub is_get     { return ($_[0]->{r}->method eq "GET"); }
sub get_app_id { return $_[0]->{r}->dir_config("ID"); }
sub site_root  { return $_[0]->{r}->dir_config("SiteRoot") || "/"; }

sub remote_ip {
	return $_[0]->{r}->connection->remote_ip();
}

sub remote_host {
	return $_[0]->{r}->connection->remote_host();
}

sub server_url {
	my $self = shift;

	my $s = $self->{r}->subprocess_env('https');
	my ($url,$p) = (defined($s) && $s eq "on")?('https',443):('http',80);

	$url .= '://'. $self->{r}->server->server_hostname();
	my $port = $self->{r}->server->port();
	if ($port && $port ne $p) {
		$url .= ":$p";
	}
	return $url."/";
}

sub if_modified_since {
	my $self  = shift;
	my $mtime = shift;

	$self->{r}->update_mtime($mtime);
	$self->{r}->set_last_modified;
	return $self->{r}->meets_conditions;
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
