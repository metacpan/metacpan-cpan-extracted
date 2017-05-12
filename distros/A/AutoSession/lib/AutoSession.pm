#############################################################################
## Name:        AutoSession.pm
## Purpose:     AutoSession
## Author:      Graciliano M. P.
## Modified by:
## Created:     20/5/2003
## RCS-ID:      
## Copyright:   (c) 2003 Graciliano M. P.
## Licence:     This program is free software; you can redistribute it and/or
##              modify it under the same terms as Perl itself
#############################################################################

package AutoSession ;
our $VERSION = '0.01' ;

use strict qw(vars) ;
no warnings ;

 use AutoSession::TieHandle ;
 use AutoSession::Driver ;

 use overload (
 '%{}'  => '_OVER_get_hash' ,
 'fallback' => 1 ,
 ) ;
 
 use vars qw($AUTOLOAD $WITH_HPL $DEF_EXPIRE $DEF_IDSIZE) ;
 
 $DEF_EXPIRE = 60*60 ;
 $DEF_IDSIZE = 32 ;

##########
# IMPORT #
##########

sub import {
  my $class = shift ;
  if ($_[0] =~ /HPL/i) { $WITH_HPL = 1 ;}
}

############
# AUTOLOAD #
############

sub AUTOLOAD {
  my $this = shift ;
  if (! $$this->{driver}) { return ;}
  my ($sub) = ( $AUTOLOAD =~ /^\w+:+([\w:]+)/s ) ;  
  $$this->{driver}->$sub(@_) ;
}

#######
# NEW #
#######

sub new {
  my $class = shift ;
  my ( %args ) = @_ ;

  my $saver = {} ;
  my $this = \$saver ;
  
  bless($this,$class) ;
  
  $$this->{driver} = AutoSession::Driver->new(@_) ;
  
  if (! $$this->{driver}) { return undef ;}
  
  my $name = $args{name} || 'SESSION' ;
  $name =~ s/\W//gs ;
  $name = uc($name) ;
    
  $$this->{name} = $name ;
  
  $this->check_expired ;

  return( $this ) ;
}

######
# ID #
######

sub id {
  my $this = shift ;
  return $$this->{driver}->{id} ;
}

########
# NAME #
########

sub name {
  my $this = shift ;
  return $$this->{name} ;
}

##########
# DRIVER #
##########

sub driver {
  my $this = shift ;
  return uc($$this->{driver}->{type}) ;
}

#############
# DIRECTORY #
#############

sub directory {
  my $this = shift ;
  return $$this->{driver}->{dir} ;
}

############
# AUTOLOAD #
############

sub autoload {
  my $this = shift ;
  return $$this->{autoload} ;
}

##########
# EXISTS #
##########

sub exists {
  my $this = shift ;
  if ( $this->exist_id ) { return 1 ;}
  return undef ;
}

###############
# COOKIE_LINE #
###############

sub cookie_line {
  my $this = shift ;
  my $name = $this->name ;
  my $id = $this->id ;
  
  my $line = qq`Set-Cookie: AutoSession=$name:$id` ;
  return( $line ) ;
}

############
# HASH_REF #
############

sub hash_ref {
  my $this = shift ;
  return $$this->{driver}{tree} ;
}

##################
# _OVER_GET_HASH #
##################

sub _OVER_get_hash {
  my $this = shift ;
  
  if ( $$this->{driver}{closed} ) { return( {} ) ;}
  
  if ( ! $$this->{hash} ) {
    my %hash ;
    $$this->{hash} = \%hash ;
    tie(%hash, 'AutoSession::TieHandle' , $$this->{driver}) ;
    $$this->{driver}->load ;
  }

  return( $$this->{hash} ) ;
}

###########
# DESTROY #
###########

sub DESTROY {
  my $this = shift ;
  
  $this->check_expired if $$this->{driver} ;
  
  delete $$this->{driver} ;
  
  untie $$this->{hash} ;
  delete $$this->{hash} ;
}

#######
# END #
#######


1;


__END__

=head1 NAME

AutoSession - Automatically Session module for Web/CGI & scripts.

=head1 DESCRIPTION

This module implements an automatically Session that works for Web/CGI and normal scripts.

=head1 USAGE

  use AutoSession ;
  
  my $SESSION = AutoSession->new(
  name      => 'FOO' ,
  driver    => 'file' ,
  directory => '/tmp/sessions' ,
  expire    => 60*60*24 ,
  ) ;
  
  ## Ensure that the session is clean/new (withoout keys).
  ## This will delete existent keys:
  $SESSION->clean ;
  
  ## the session id:
  my $id = $SESSION->id ;
  
  ## The file path of the session (Drive file):
  my $file = $SESSION->local ;
  
  ## Create/set the keys
  $SESSION->{key1} = k1 ;
  $SESSION->{key2} = k2 ;

  ## Save and close the session.
  ## Note that when you set a key the session is atomatically saved.
  $SESSION->close ;
  
  ## Force the save: (You don't need to use it, since this is AutoSession.)
  $SESSION->save ;
  
  ## Delete session when all the work is done:
  $SESSION->delete ;


=head1 METHODS

=head2 new

Create/load the session.

B<Arguments:>

=over 10

=item id

The ID of an existent session to load.

If not paste, a new session is created.

=item idsize

The size/length of the ID.

I<Default:> 32

=item name

The name of the session. Can be used to identify the sessions when you use more than one at the same time.

** Accept only [\w].

=item driver

The DRIVER to use. Options:

  FILE
  MYSQL
  HDB

** Use HDB for generic database, since HDB works with any DB!

=item expire

Expire time of the session.

Options:

  60s  => 60 seconds
  30m  => 30 minutes
  2h   => 2 hours
  
  2d    => 2 days
  1mo   => 1 month
  1y    => 1 year
  
  60    => 60 seconds

I<Default>:

  New sessions: 1 hour
  Loading: the previous value in the session.

** If you paste the I<expire> arument when you are loading an already existent session,
you reset the expire of the session.

=item base64

Encode the data to base64 before save it.

** Good if you can't use binary data when saving.

=item directory|dir

The directory to save/load the session.

** Only when using the DRIVE file.

=back

=head2 clean|clear

Clean the session, removing all the keys.

=head2 open

Open the session if it has been closed.

=head2 close

Close the session and avoid future access/changes in the session object.

=head2 refresh

Refresh the session (only if changed).

=head2 load

Load/reload the session.

=head2 save

Save the session in the file or database.

=head2 id

Return the ID of the session.

=head2 name

Return the name of the session.

=head2 driver

Return the driver type of the session.

=head2 autoload

Return TRUE when the SESSION can be autoloaded.

B<** This method is only for when used with HPL!>

=head2 cookie_line

Return the cookie line to send to the browser.

=head2 hash_ref

Return the HASH reference inside the object. The real place where the keys are stored in the memory, since this is a tied object.

=head2 local

Return the local where the session is saved. Have a different format for the drivers:

  DRIVE:    FORMAT:
  ----------------------------------------
  FILE   => /tmp/SESSION-IDFOO.tmp       ## the file path
  MYSQL  => user@mydomain:3648/tablex    ## the DB and host
  HDB    => dbtype&user@mydomain/tablex  ## the HDB and host
  HDB    => dbtype&filepath#tablex       ## the HDB and file path (for flat DB)

=head1 EXPIRE

The expire sistem is very simple, you just set the argument I<expire> when you
create/load the session.

if the session stay more than N seconds (the expire time) without access, it's
expired (deleted).

=head1 KEYS

The keys of the session object paste through a tied HASH, that save them each time
that they are changed. And when you access them it check for updates in the session,
in case to be changed by other process.

** Note that since this is a tied hash, if you use HASH references inside a key,
changes of sub-keys can't be detected. For example:

  ## Create the key 'foo' with a HASH ref.
  $session->{foo}{bar} = 1 ;
  
  ## Reset bar, but this won't auto-save the session.
  $session->{foo}{bar} = 2 ;
  
  ## So, you need to force the auto-save:
  $session->save ;
  
  ## But normal keys auto-save the session:
  $session->{k} = 10 ;

=head1 SEE ALSO

L<HPL>, L<Apache::Session>, L<CGI::Session>.

AutoSession is the default module of the L<HPL> sessions.

=head1 AUTHOR

Graciliano M. P. <gm@virtuasites.com.br>

I will appreciate any type of feedback (include your opinions and/or suggestions). ;-P

Created for HPL. But as a external module to use it anywhere.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

