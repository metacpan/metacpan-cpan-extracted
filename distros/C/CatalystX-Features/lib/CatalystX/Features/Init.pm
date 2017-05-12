package CatalystX::Features::Init;
$CatalystX::Features::Init::VERSION = '0.26';
use Moose;

=head1 NAME

CatalystX::Features::Init - Extend MyApp.pm initialization

=head1 VERSION

version 0.26

=head1 SYNOPSIS

Maybe:

	package MyApp::MyFeature;
	use base qw/CatalystX::Features::Init/;

Or maybe:

	package MyApp::MyFeature;
	use base qw/Catalyst/;

=head1 DESCRIPTION

WIP. Work in progress. 

This is a placeholder for an upcoming plugin for pre and post setup phases. The idea
is to have your feature run code during the application startup phase.

Right now, running C<before> and C<after> setup handlers somewhere within your feature 
may suffice. 

	before 'setup' => sub {
		...
	};

=head1 AUTHORS

	Rodrigo de Oliveira (rodrigolive), C<rodrigolive@gmail.com>

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
