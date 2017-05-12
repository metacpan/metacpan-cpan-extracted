#!/usr/bin/perl -w
#Copyright 1998-2001, Randall Maas.  All rights reserved.  This program is free
#software; you can redistribute it and/or modify it under the same terms as
#PERL itself.

=head1 NAME

C<CfgTie::TieRealm> -- Ties configuration variables to various HTTP servers

=head1 SYNOPSIS

Makes it easy to manage a variety of web servers thru one.

=head DESCRIPTION


=head1 Caveats

It is not able to modify the main realms configuration file.

=head1 Author

Randall Maas (L<randym@acm.org>, L<http://www.hamline.edu/~rcmaas/>)

=cut

package CfgTie::TieRealm;
use HTTPD::Realm;

use vars qw($VERSION @ISA);
$VERSION='0.41';
@ISA=qw(HTTPD::Realm);

sub TIEHASH
{
#Needs configuration file.
   return bless [], $_[0];
}

sub EXISTS
{
    $_[0]->exists($_[1]);
}

sub FIRSTKEY
{
   if (!@{$_[0]->[0]})
   {
      $_[0]->[0] = [$_[0]->list()];
   }
   my $a = @{$_[0]->[0]};
   NEXTKEY($_[0]);
}

sub NEXTKEY
{
   return scalar each @{$_[0]->[0]};
}

sub FETCH
{
   return $_[0]->realm($_[1]);
}


package CfgTie::TieRealm...
#Keys => name, users, groups, userdb, groupdb. mode, database, fields, usertype,grouptype,authentication,server,crypt,SQLdata


package CfgTie::TieRealm_groups
package CfgTie::TieRealm_users
