package Catalyst::View::Component::ESI;

use strict;
use Moose::Role;
 
requires 'process';

use LWP::UserAgent;

=head1 NAME

Catalyst::View::Component::ESI - Include ESI in your templates

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

  package MyApp::View::TT;
  use Moose;

  extends 'Catalyst::View::TT';
  with 'Catalyst::View::Component::ESI';

  __PACKAGE__->config( LWP_OPTIONS => { option1 => 1} );

Then, somewhere in your templates:

  <esi:include src="http://www.google.com/"/>

=head1 DESCRIPTION

C<Catalyst::View::Component::ESI> allows you to include external content in your
templates. It's implemented as a 
L<Moose::Role|Moose::Role>, so using L<Moose|Moose> in your view is required.

Configuration file example:

  <View::TT>
    <LWP_OPTIONS>
      option1 value
    </LWP_OPTIONS>
	pass_cookies 1
  </View::TT>

=cut

has '_ua' => (is => 'rw', isa => 'LWP::UserAgent', lazy_build => 1);

sub _build__ua {
	my $self = shift;
	
	my %options;
	%options = %{$self->config->{LWP_OPTIONS}} if ($self->config->{LWP_OPTIONS});
	my $ua = LWP::UserAgent->new( %options );
	return $ua;
}


=head2 process

Change esi-tags, to become the content of that page.

=cut

around 'process' => sub {
	my $orig = shift;
	my $self = shift;
	my ($c) = @_;
	my $ret = $self->$orig(@_);
	my $body = $c->res->body;

	while ($body =~ qr#(<esi:include src="([^"]+)"[^>]*/>)#) {
		my $esi = $1;
		my $url = $2;
		
		my %options;
		# TODO: Have configurable url rewrite rules
		if (($self->config->{pass_cookies})&&($c->request->headers->{cookie})) {
			$options{cookie} = $c->request->headers->{cookie};
		}
		
		my $cont = $self->_ua->get($url,%options)->content;
		
		# TODO: Fix content, and take out the things not supposed to be there?
		# I think that it's all supposed to be there. ESI doesn't parse the result
		
		$body =~ s/\Q$esi\E/$cont/g;
	}
	
	$c->res->body($body);
	return $ret;
};

1;

=head1 SEE ALSO

L<Catalyst>

=head1 AUTHOR

BjE<oslash>rn-Olav Strand E<lt>bo@startsiden.noE<gt>

=head1 LICENSE

Copyright 2009 by ABC Startsiden AS, BjE<oslash>rn-Olav Strand <bo@startsiden.no>.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

