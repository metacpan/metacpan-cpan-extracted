package Authen::Simple::PlugAuth;

use strict;
use warnings;
use base 'Authen::Simple::Adapter';
use PlugAuth::Client::Tiny;

# ABSTRACT: Simple PlugAuth authentication
our $VERSION = '0.03'; # VERSION


__PACKAGE__->options({
  url => {
    type     => Params::Validate::SCALAR,
    optional => 0,
  },
});



sub init
{
  my($self, $param) = @_;
  $self->SUPER::init($param);
  $self->{client} = PlugAuth::Client::Tiny->new( url => $self->url );
  $self;
}

sub check
{
  my($self, $username, $password) = @_;
  $self->{client}->auth($username, $password) ? 1 : 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Authen::Simple::PlugAuth - Simple PlugAuth authentication

=head1 VERSION

version 0.03

=head1 SYNOPSIS

 use Authen::Simple::PlugAuth;
 
 my $auth = Authen::Simple::PlugAuth->new(
   url => 'http://localhost:3000/',
 );
 
 if($auth->authenticate($username, $password)) {
   # successfull authentication
 }

=head1 DESCRIPTION

B<NOTE>: Development for this tool is winding down, and L<PlugAuth::Client::Tiny>
and modules that depend on are deprecated.  Please contact me ASAP if you depend
on this tool. This distribution may be removed from CPAN, but not before
june 30, 2018.

Authenticate against a L<PlugAuth> server through the Authen::Simple framework.

=head1 ATTRIBUTES

=head2 url

 my $url = $auth->url;

The URL of the L<PlugAuth> server to connect to.

=head1 METHODS

=head2 authenticate

 my $bool = $auth->authenticate( $username, $password )

Returns true on success and false on failure.

=head1 SEE ALSO

L<Authen::Simple>, L<PlugAuth>, L<PlugAuth::Client>.

=head1 AUTHOR

Graham Ollis <plicease@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
