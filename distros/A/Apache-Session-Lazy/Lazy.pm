package Apache::Session::Lazy;
use 5.006;
use strict;
use warnings;
our $VERSION = '0.05';

# Thanks for the perltie info, Merlyn.

sub TIEHASH {
  my $class = shift;
  return unless checks(@_);

  if ( $@ ) {      # whoops, there was an error
      warn( $@ );  # require'ing $class; perhaps
      return;      # it doesn't exist?
  }

  if ( ( caller(1) )[3] eq '(eval)' && defined $_[1]) { # The assumption is
      my $object = $_[0]->TIEHASH( $_[1..$#_] );        # that you are checking
      $object->DESTROY();                               # to see if a session
  }                                                     # exists.
  
  bless [@_], $class; # remember real args
}

sub FETCH {
  ## DO NOT USE shift HERE
  $_[0] = delete($_[0]->[0])->TIEHASH(@{$_[0]});
  goto &{$_[0]->can("FETCH")};
}

sub STORE {
  ## DO NOT USE shift HERE
  $_[0] = delete($_[0]->[0])->TIEHASH(@{$_[0]});
  goto &{$_[0]->can("STORE")};
}

sub DELETE   {
  $_[0] = delete($_[0]->[0])->TIEHASH(@{$_[0]});
  goto &{$_[0]->can("DELETE")};
}

sub CLEAR {

  if ( defined $_[0]->[1] && $_[0]->[1] ) {  # Why Clear An Uncreated Sesion?
    $_[0] = delete($_[0]->[0])->TIEHASH(@{$_[0]});
    goto &{$_[0]->can("CLEAR")};
  }

}

sub EXISTS {
  $_[0] = delete($_[0]->[0])->TIEHASH(@{$_[0]});
  goto &{$_[0]->can("EXISTS")};
}

sub FIRSTKEY {
  $_[0] = delete($_[0]->[0])->TIEHASH(@{$_[0]});
  goto &{$_[0]->can("FIRSTKEY")};
}

sub NEXTKEY {
  $_[0] = delete($_[0]->[0])->TIEHASH(@{$_[0]});
  goto &{$_[0]->can("NEXTKEY")};
}

sub DESTROY {

  if ( defined $_[0]->[1] && $_[0]->[1] ) {  # Why Destroy An Uncreated Sesion?
    $_[0] = delete($_[0]->[0])->TIEHASH(@{$_[0]});
    goto &{$_[0]->can("DESTROY")};
  }

}

sub checks {
  eval "require $_[0]";  # You can overload this.
  !$@;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Apache::Session::Lazy - Perl extension for opening Apache::Sessions on first read/write access.

=head1 SYNOPSIS

See L<Apache::Session>

=head1 DESCRIPTION

=head2 The Module

Apache::Session is a persistence framework which is particularly useful
for tracking session data between httpd requests.  Apache::Session is
designed to work with Apache and mod_perl, but it should work under
CGI and other web servers, and it also works outside of a web server
altogether.

Apache::Session::Lazy extends Apache::Session by opening Sessions only after they are either
modified or examined (first read or write access to the tied hash.)  It should provide
transparent access to the session hash at all times.

=head2 Uses Of Apache::Session::Lazy

Apache::Session::Lazy was designed to allow Apache::Session to achieve prevent unnecessary work
in accessing the data store, if a session is not going to be touched, and allow for session locking
to exist for the least possible amount of time, so that other access to the same session is possible.

=head1 INTERFACE

The interface for Apache::Session::Lazy is only different for tieing the Session.  You must
an additional parameter after tie %session. So the new tie will look like-

Get a new session using DBI:

 tie %session, 'Apache::Session::Lazy', 'Apache::Session::MySQL', undef,
    { DataSource => 'dbi:mysql:sessions' };
    
Restore an old session from the database:

 tie %session, 'Apache::Session::Lazy', 'Apache::Session::MySQL', $session_id,
    { DataSource => 'dbi:mysql:sessions' };

Check for a session:

 eval {  
   tie %session, 'Apache::Session::Lazy', 'Apache::Session::MySQL', $session_id,
      { DataSource => 'dbi:mysql:sessions' };
 };

=head2 SUBCLASSING

You can now subclass Apache::Session::Lazy.  This allows you to force users to use only one of the
Apache::Session interfaces by use()-ing that module, and overiding the checks subroutine:

 package My::Apache::Session::Lazy;
 use Apache::Session::Flex;
 use Apache::Session::Lazy;
 @My::Apache::Session::Lazy::ISA = Apache::Session::Lazy;

 sub checks { # This holds the parameters to be passed to Apache::Session.
   unless ( $_[0] =~ m/Apache::Session::Flex/i ) {
     die ('Please just flex it.');
   } elsif ( $_[2]->{'Generate'} ne 'ModUniqueId' ) {
     die ('Use UniqueId, it is the j33test.');
   } else {
     return 1;
   }

   return; # Just in case they're catching dies.
 }

=head1 AUTHOR

Gyan Kapur <gkapur@inboxusa.com>

With help from merlyn.

=head1 SEE ALSO

L<Apache::Session>,L<Apache::SessionX>, 
http://groups.yahoo.com/group/modperl/message/46287

=cut
