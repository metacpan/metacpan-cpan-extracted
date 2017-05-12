package AnyEvent::FTP::Server::OS::UNIX;

use strict;
use warnings;
use 5.010;
use Moo;

# ABSTRACT: UNIX implementations for AnyEvent::FTP
our $VERSION = '0.09'; # VERSION


sub BUILDARGS
{
  my($class, $query) = @_;
  my($name, $pw, $uid, $gid, $quota, $comment, $gcos, $dir, $shell, $expire) = getpwnam $query;
  die "user not found" unless $name;
  
  return {
    name  => $name,
    uid   => $uid,
    gid   => $gid,
    home  => $dir,
    shell => $shell,
  }
}


has $_ => ( is => 'ro', required => 1 ) for (qw( name uid gid home shell ));


has groups => (
  is      => 'ro',
  lazy    => 1,
  default => sub {
    my $name = shift->name;
    my @groups;
    setgrent;
    my @grent;
    while(@grent = getgrent)
    {
      my($group,$pw,$gid,$members) = @grent;
      foreach my $member (split /\s+/, $members)
      {
        push @groups, $gid if $member eq $name;
      }
    }
    \@groups;
  },
);


sub jail
{
  my($self) = @_;
  chroot $self->home;
  return $self;
}


sub drop_privileges
{
  my($self) = @_;
  
  $) = join ' ', $self->gid, $self->gid, @{ $self->groups };
  $> = $self->uid;
  
  $( = $self->gid;
  $< = $self->uid;

  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AnyEvent::FTP::Server::OS::UNIX - UNIX implementations for AnyEvent::FTP

=head1 VERSION

version 0.09

=head1 SYNOPSIS

 use AnyEvent::FTP::Server::OS::UNIX;
 
 # interface using user fred
 my $unix = AnyEvent::FTP::Server::OS::UNIX->new('fred');
 $unix->jail;            # chroot
 $unix->drop_privileges; # transform into user fred

=head1 DESCRIPTION

This class provides some utility functionality for interacting with the
UNIX and UNIX like operating systems.

=head1 ATTRIBUTES

=head2 name

The user's username

=head2 uid

The user's UID

=head2 gid

The user's GID

=head2 home

The user's home directory

=head2 shell

The user's shell

=head2 groups

List of groups (as GIDs) that the user also belongs to.

=head1 METHODS

=head2 $unix-E<gt>jail

C<chroot> to the users' home directory.  Requires root and the chroot function.

=head2 $unix-E<gt>drop_privileges

Drop super user privileges

=head1 AUTHOR

Author: Graham Ollis E<lt>plicease@cpan.orgE<gt>

Contributors:

Ryo Okamoto

Shlomi Fish

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
