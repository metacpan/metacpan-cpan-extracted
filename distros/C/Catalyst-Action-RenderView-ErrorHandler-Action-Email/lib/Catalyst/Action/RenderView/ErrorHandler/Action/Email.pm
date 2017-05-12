package Catalyst::Action::RenderView::ErrorHandler::Action::Email;

use 5.010001;
use strict;
use warnings;
use Moose;

our $VERSION = '0.04';

with 'Catalyst::Action::RenderView::ErrorHandler::Action';

has 'options' => (is => 'rw', isa => 'HashRef', default => sub { [] });
has 'view' => (is => 'ro', isa => 'Str');

sub perform {
    my $self = shift;
    my $c = shift;
	
	#Add defined options field to catalyst stash
	foreach my $key (keys %{$self->{options}}) {
		$c->stash->{email}->{$key} = $self
		->{options}->{$key};
	}
	
	$c->forward( $c->view($self->view) );
}

1;
__END__

=head1 NAME

Catalyst::Action::RenderView::ErrorHandler::Action::Email - Catalyst ErrorHandler Action for Email

=head1 SYNOPSIS

	#In a configuration somewhere:
	error_handler => {
	        'actions' => [
			{
				type => 'Log',
				id => 'log-server',
				level => 'error'
			},
			{
				#Use this action
				type => 'Email',
	              		id => 'log-email',
				#Regex to ignore all request paths with PhpMyAdmin or SqlDump init. Regex is case insensitive used.
				ignorePath => '(PhpMyAdmin|SqlDump)',
				#This should be a Catalyst::View::Email::Template or Catalyst::View::Email view.
				view => 'ErrorMail',
				#This options are copied into $c->stash->{email} for accesing from the view selected above
				#For additional information look into the documentation of Catalyst::View::Email::Template
	              		options => {
				(
					#becomes $c->stash->{email}->{from} = ...
					from => 'MyApp - Homepage <homepage@domain.com>',
					to => 'you@domain.com',
					subject => 'Homepage - ErrorMail',
					#Template isn't needed, if you use the simple Catalyst::View::Email
					templates => [
						{
							template        => 'ErrorMail.tt2',
							content_type    => 'text/html',
							charset         => 'utf-8',
							encoding        => 'quoted-printable',
							#View to render the Template
							view            => 'HTMLEmail', 
						},
					]
				)}
			}
		],
		'handlers' => {
		(
	        	'5xx' => {
				template => 'error_internal.tt2',
				actions => ['log-server','log-email']
			},
			'404' => {
				template => 'error.tt2'
			},
			'fallback' =>  {
	                	static => 'root/src/error.html', 
	                	actions => ['log-email','log-email']
			}
		)}
	} 
	
	#The template may look like:
	﻿[% USE Dumper %]
	<!DOCTYPE html>
	<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
	<title>Error Report</title>
	</head>

	<body>
	<p>There was a error in yor App:</p>
	<h4>Requested path:</h4>
	<p>[% base %][% c.request.path %]</p>

	<h4>Arguments:</h4>
	[% FOREACH a IN c.request.args %]
	   <p>[% a | html %]</p>
	[% END %]

	<h4>Parameters:</h4>
	[% Dumper.dump(c.request.parameters) %]

	<h4>User Agent:</h4>
	<p>[% c.request.user_agent | html %]</p>

	<h4>Referer:</h4>
	<p>[% c.request.referer | html %]</p>

	<h4>Error messages:</h4>
	[% FOREACH e IN c.error %]
	   <p>[% e | html %]</p>
	[% END %]

	[% IF c.response.code %]
	<h4>Error code:</h4>
	<p>[% c.response.code %]</p>
	[% END %]

	</body>
	</html>


=head1 DESCRIPTION

Used by L<Catalyst::Action::RenderView::ErrorHandler> to send an Email if there
is an error in your Catalyst application.

=head1 SEE ALSO

L<Catalyst::Action::RenderView::ErrorHandler>
L<Catalyst::Action::RenderView::ErrorHandler::Action::Log>
L<Catalyst::View::Email>
L<Catalyst::View::Email::Template>

=head1 AUTHOR

Stefan Profanter, E<lt>profanter@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Stefan Profanter

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
