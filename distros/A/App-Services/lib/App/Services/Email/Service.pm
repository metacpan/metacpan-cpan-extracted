package App::Services::Email::Service;
{
  $App::Services::Email::Service::VERSION = '0.002';
}

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;

use common::sense;
use Carp qw(confess);

with 'App::Services::Logger::Role';

use Net::SMTP;

has msg => (
	is       => 'rw',
	isa      => Str,
	required => 1,

);

has recipients => (
	is       => 'rw',
	isa      => ArrayRef [Str],
	required => 1,
);

has timeout => (
	is      => 'rw',
	isa     => Int,
	default => sub { 60 },
);

has mailhost => (
	is       => 'rw',
	isa      => Str,
	required => 1,
);

has from => (
	is      => 'rw',
	isa     => Str,
	required => 1,
);

has subject => (
	is      => 'rw',
	isa     => Str,
	required => 1,
);

has debug => (
	is      => 'rw',
	isa     => Str,
	default => sub { 0 },
);

sub send {
	my $s = shift or confess;
	
	my $smtp = Net::SMTP->new(
		Host => $s->mailhost,
		Debug => $s->debug,
	);

	$smtp->mail( $s->from );
	$smtp->to( @{ $s->recipients } );

	$smtp->data();
	$smtp->datasend( "To: " . join( ',', @{ $s->recipients } ) . "\n" );
	$smtp->datasend( "Subject: " . $s->subject . "\n");
	$smtp->datasend("\n");
	$smtp->datasend( $s->msg );

	$smtp->dataend();

	$smtp->quit;

}

no Moo;

1;

__END__

=pod

=head1 NAME

App::Services::Email::Service

=head1 VERSION

version 0.002

=head1 AUTHOR

Sean Blanton <sean@blanton.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Sean Blanton.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
