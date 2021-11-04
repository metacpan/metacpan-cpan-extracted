package AnyEvent::FTP::Server::Role::Type;

use strict;
use warnings;
use 5.010;
use Moo::Role;

# ABSTRACT: Type role for FTP server
our $VERSION = '0.18'; # VERSION


has type => (
  is      => 'rw',
  default => sub { 'A' },
);


sub help_type { 'TYPE <sp> type-code (A, I)' }

sub cmd_type
{
  my($self, $con, $req) = @_;

  my $type = uc $req->args;
  $type =~ s/^\s+//;
  $type =~ s/\s+$//;

  if($type eq 'A' || $type eq 'I')
  {
    $self->type($type);
    $con->send_response(200 => "Type set to $type");
  }
  else
  {
    $con->send_response(500 => "Type not understood");
  }

  $self->done;
}

# TODO: STRU MODE

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::Role::Type - Type role for FTP server

=head1 VERSION

version 0.18

=head1 SYNOPSIS

 package AnyEvent::FTP::Server::Context::MyContext;
 
 use Moo;
 extends 'AnyEvent::FTP::Server::Context';
 with 'AnyEvent::FTP::Server::Role::Type';

=head1 DESCRIPTION

This role provides an interface for the FTP C<TYPE> command.

=head1 ATTRIBUTES

=head2 type

 my $type = $context->type;
 $context->type('A');
 $context->type('I');

The current transfer type 'A' for ASCII and I for binary.

=head1 COMMANDS

=over 4

=item TYPE

=back

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

José Joaquín Atria

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2021 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
