package BuzzSaw::UserClassifier; # -*-perl-*-
use strict;
use warnings;

# $Id: UserClassifier.pm.in 22899 2013-03-14 16:16:45Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 22899 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/UserClassifier.pm.in $
# $Date: 2013-03-14 16:16:45 +0000 (Thu, 14 Mar 2013) $

our $VERSION = '0.12.0';

use IO::File ();

use Moose;
use MooseX::Types::Moose qw(Int Str);
use Moose::Util::TypeConstraints;

subtype 'NonPersonalUsers'
  => as 'HashRef';

coerce 'NonPersonalUsers'
  => from 'Str',
  => via { _load_users($_) };

has 'people' => (
  isa     => Int,
  is      => 'ro',
  lazy    => 1,
  default => sub { (getgrnam('people'))[2] },
);

has 'nonpersonal_users' => (
  traits  => ['Hash'],
  isa     => 'NonPersonalUsers',
  is      => 'ro',
  lazy    => 1,
  coerce  => 1,
  default => sub { {} },
  handles => {
    in_nonpersonal_users => 'exists',
  },
);

no Moose;
__PACKAGE__->meta->make_immutable;

sub _load_users {
  my ($file) = @_;

  my %users;

  my $fh = IO::File->new($file)
    or die "Could not open $file: $!\n";

  while( defined(my $line = <$fh> ) ) {
    chomp $line;

    if ( $line =~ m/^\s*$/ || $line =~ m/^\#/ ) {
      next;
    }

    $line =~ s/^\s+//;
    $line =~ s/\s+$//;

    $users{$line} = 1;
  }

  return \%users;
}

sub is_user {
  my ( $self, $username ) = @_;

  my $uid = getpwnam($username);

  return (defined $uid ? 1 : 0);
}

sub is_person {
  my ( $self, $username ) = @_;

  if ( $self->is_user($username) ) {
    my $gid = (getpwnam($username))[3];

    return ( $gid == $self->people ? 1 : 0 );
  }

  return 0;
}

sub looks_like_person {
  my ( $self, $username ) = @_;

  # This is specific to UoE. Might be worth moving this list of
  # regular expressions into a list attribute.

  # student usernames are 's' followed by 7 digits
  #
  # Assume these are typos:
  #   A double 's' to start
  #   Anything starting 's' followed by 5, 6 or more than 7 digits
  #   Exactly 7 digits (but not initial 's')
  #   
  # Also matching anything which looks like a visitor account

  if ( $username =~ m/^s{1,2}[0-9]{5}/io ||
       $username =~ m/^[0-9]{7}$/o      ||
       $username =~ m/^v[0-9][a-z]+[0-9]?$/io ) {
    return 1;
  }

  return 0;
}

sub is_root {
  my ( $self, $username ) = @_;

  # matches root, r00t, r0ot, ROOT, etc
  if ( $username =~ m/^r[o0]{2}t$/io )  {
    return 1;
  }

  return 0;
}

sub is_nonpersonal {
  my ( $self, $username ) = @_;

  if ( $self->is_person($username) || $self->looks_like_person($username) ) {
    return 0;
  }

  # Check to see if the user exists (but is not a member of the
  # 'people' group as we have already seen)

  if ( $self->is_user($username) ) {
    return 1;
  }

  # Finally check to see if it is in the nonpersonal dict

  return $self->in_nonpersonal_users($username);
}

sub mangle_username {
  my ( $self, $username ) = @_;

  $username =~ s/^@@@//;

  $username = lc $username;

  if ( $username eq 'tmp' ) {
    $username = 'temp';
  }

  my @startlike = ( 'account','admin','backup','cacti','cvs',
                    'ftp','gast','guest','mysql','nagios','oracle',
                    'postgres','shoutcast','smb','spam','support',
                    'sysadm',
                    'teamspeak','newsreaderg','data','usr','team',
                    'marketing','monitoring','svn','feedback',
                    'telnet','temp','test','web','www' );

  for my $entry (@startlike) {
    if ( index($username, $entry) == 0 ) {
      $username = $entry;
      last;
    }
  }

  return $username;
}

sub classify {
  my ( $self, $username ) = @_;

  my $user_type = 'others';

  if ( $self->is_root($username) ) {
    $user_type = 'root';
  } elsif ( $self->is_person($username) ||
            $self->looks_like_person($username) ) {
    $user_type = 'real';
  } elsif ( $self->is_nonpersonal($username) ) {
    $user_type = 'nonperson';
  }

  return $user_type;
}

1;
__END__

=head1 NAME

BuzzSaw::UserClassifier - Classifies the type of a username

=head1 VERSION

This documentation refers to BuzzSaw::UserClassifier version 0.12.0

=head1 SYNOPSIS

   my $classifier = BuzzSaw::UserClassifier->new();

   my $user = "R00t";
   my $cleaned_username = $classifier->mangle_username($user);

   my $user_type = $classifier->classify($cleaned_username);

   print "Type for $user is $user_type\n";

=head1 DESCRIPTION

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 ATTRIBUTES

=over

=item people

This is the GID of the group in which your "real" users are all members.

=item nonpersonal_users

This is a reference to a hash of usernames which are considered to be
"non-personal". That is normally a list of users for running daemons,
and other system tools. It might also include names of teams, units
and other generic usernames.

This can be specified via a string in which case it is assumed to be
the name of a file which contains one username per line. This is very
useful when you have a long list of usernames.

Note that existence in this list is not the only criteria for a
username to be considered as "non-personal", see below for full
details.

=back

=head1 SUBROUTINES/METHODS

This class has the following methods:

=over

=item is_user($username)

This method returns a boolean which states whether (or not) the
specified username exists in the local passwd database.

=item is_person($username)

This method returns a boolean which states whether (or not) the
specified username is a user (see C<is_user>) AND is a member of the
group specified in the C<people> attribute.

=item looks_like_person($username)

This method returns a boolean which states whether (or not) the
username looks like a username. Currently this just does simplistic
regular expression matching to spot usernames which look like
University of Edinburgh student or visitor accounts. The intention
being that this method is used to spot usernames which are most likely
spelling mistakes (or user mistakes of some type).

=item is_root($username)

This method returns a boolean which states whether (or not) the
username looks like C<root>. This is done using a case-insensitive
match on the string C<root> and allows either or both of the C<o>
characters to be replaced with a C<0> (zero).

=item is_nonpersonal($username)

This method returns a boolean which states whether (or not) the
username is a non-personal account. If the username matches the
C<is_person> or C<looks_like_person> methods then this method returns
false. Otherwise, if the username exists in the local passwd database
then it will return true. As a final check when nothing else matches
the hash of non-personal account names will be checked. This hash
lookup is particularly useful for known daemon and team names which
are not in the passwd DB for the machine on which the checks are being
run.

=item mangle_username($username)

This method is used to clean and canonicalise the username. It will
lowercase the whole string and strip some undesirable characters. It
also makes an attempt to canonicalise certain common forms of
usernames. For example, any string starting with C<admin> will result
in C<admin> being returned (C<admin1> becomes C<admin>,
C<administrator> becomes C<admin>, etc).

=item classify($username)

This uses the previously described methods to classify the specified
username. If it matches the C<is_root> method then the string C<root>
will be returned. If it matches either of the C<is_person> or
C<looks_like_person> methods then the string C<real> will be
returned. If it matches the C<is_nonpersonal> method then the string
C<nonperson> will be returned. Finally, if nothing matches then the
string C<others> will be returned.

=item in_nonpersonal_users($username)

This method returns a boolean which states whether (or not) the
specified username exists in the non-personal users hash.

=back

=head1 DEPENDENCIES

This module is powered by L<Moose>. You will also need
L<MooseX::Types> and L<MooseX::Log::Log4perl>.

=head1 SEE ALSO

L<BuzzSaw>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2013 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
