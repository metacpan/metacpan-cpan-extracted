package AnyEvent::FTP::Server::Role::Help;

use strict;
use warnings;
use 5.010;
use Moo::Role;

# ABSTRACT: Help role for FTP server
our $VERSION = '0.19'; # VERSION


my %cmds;

sub help_help { 'HELP [<sp> command]' }

sub cmd_help
{
  my($self, $con, $req) = @_;

  my $topic = $req->args;
  $topic =~ s/^\s+//;
  $topic =~ s/\s+$//;
  $topic = lc $topic;

  if($topic eq '')
  {
    my $class = ref $self;
    unless(defined $cmds{$class})
    {
      no strict 'refs';
      $cmds{$class} = [
        sort map { my $x = $_; $x =~ s/^cmd_//; uc $x } grep /^cmd_/, keys %{$class . '::'}
      ];
    }

    $con->send_response(214, [
      'The following commands are recognized:',
      join(' ', @{ $cmds{$class} }),
      'Direct comments to devnull@bogus',
    ]);
  }
  elsif($self->can("cmd_$topic"))
  {
    my $method = "help_$topic";
    if($self->can("help_$topic"))
    {
      $con->send_response(214 => 'Syntax: ' . $self->$method)
    }
    else
    {
      $con->send_response(502 => uc($topic) . " is a command without help");
    }
  }
  else
  {
    $con->send_response(502 => 'Unknown command');
  }

  $self->done;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::Role::Help - Help role for FTP server

=head1 VERSION

version 0.19

=head1 SYNOPSIS

Create a context:

 package AnyEvent::FTP::Server::Context::EchoContext;
 
 use Moo;
 
 extends 'AnyEvent::FTP::Server::Context';
 with 'AnyEvent::FTP::Server::Role::Help';
 
 # implement the non-existent echo command
 sub help_echo { 'ECHO <SP> text' }
 
 sub cmd_echo
 {
   my($self, $con, $req) = @_;
   $con->send_response(211 => $req->args);
   $self->done;
 }
 
 1;

Start a server with that context:

 % aeftpd --context EchoContext
 ftp://dfzcgohteq:igdcphxled@localhost:59402

Then connect to that server and test the C<HELP> command:

 % telnet localhost 59402
 Trying 127.0.0.1...
 Connected to localhost.
 Escape character is '^]'.
 220 aeftpd dev
 help
 214-The following commands are recognized:
 214-ECHO HELP
 214 Direct comments to devnull@bogus
 help help
 214 Syntax: HELP [<sp> command]
 help echo
 214 Syntax: ECHO <SP> text
 help bogus
 502 Unknown command
 quit
 221 Goodbye
 Connection closed by foreign host.

=head1 DESCRIPTION

This role provides a standard FTP C<HELP> command.  It finds any FTP commands (C<cmd_*>) you
have defined in your context class and the associated usage functions (C<help_*>) and implements
the C<HELP> command for you.

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
