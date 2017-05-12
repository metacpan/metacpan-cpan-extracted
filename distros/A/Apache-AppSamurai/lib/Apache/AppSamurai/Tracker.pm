# Apache::AppSamurai:Tracker - Special case override for Apache::Session
#  used for flexible, persistent, IPC tracking of events.  Useful for
#  brute force detection and other fun "stuff"

# $Id: Tracker.pm,v 1.11 2008/04/30 21:40:06 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

# Includes code from Apache::Session developed by Jeffrey William Baker
# (jwbaker@acm.org) and others.

package Apache::AppSamurai::Tracker;
use strict;
use warnings;

use vars qw($VERSION @ISA $incl);
$VERSION = substr(q$Revision: 1.11 $, 10, -1);

use Apache::Session;

@ISA = qw( Apache::Session );
$incl = {};

sub populate {
    my $self = shift;

    # Allow standard Apache::Session syntax, special AppSamurai/<ITEM>
    # syntax, or specifying a full module path.
    my ($store, $lock, $gen, $ser);
    if ($self->{args}->{Store} =~ /^AppSamurai\/([\w\d\_]+?)\s*$/i) {
	$store = "Apache::AppSamurai::Session::Store::$1";
    } elsif ($self->{args}->{Store} =~ /::/) {
	$store = $self->{args}->{Store};
    } else {
	$store = "Apache::Session::Store::$self->{args}->{Store}";
    }
    if ($self->{args}->{Lock} =~ /^AppSamurai\/([\w\d\_]+?)\s*$/i) {
	$lock = "Apache::AppSamurai::Session::Lock::$1";
    } elsif ($self->{args}->{Lock} =~ /::/) {
	$lock = $self->{args}->{Lock};
    } else {
	$lock  = "Apache::Session::Lock::$self->{args}->{Lock}";
    }
    if ($self->{args}->{Serialize} =~ /^AppSamurai\/([\w\d\_]+?)\s*$/i) {
	$ser  = "Apache::AppSamurai::Session::Serialize::$1";
    } elsif ($self->{args}->{Serialize} =~ /::/) {
	$ser  = $self->{args}->{Serialize};
    } else {
	$ser = "Apache::Session::Serialize::$self->{args}->{Serialize}";
    }

    if (!exists $incl->{$store}) {
        eval "require $store" || die $@;
        $incl->{$store} = 1;
    }
    
    if (!exists $incl->{$lock}) {
        eval "require $lock" || die $@;
        $incl->{$lock} = 1;
    }
    
    if (!exists $incl->{$ser}) {
        eval "require $ser" || die $@;
        eval '$incl->{$ser}->[0] = \&' . $ser . '::serialize'   || die $@;
        eval '$incl->{$ser}->[1] = \&' . $ser . '::unserialize' || die $@;
    }
    
    $self->{object_store} = new $store $self;
    $self->{lock_manager} = new $lock  $self;
    $self->{serialize}    = $incl->{$ser}->[0];
    $self->{unserialize}  = $incl->{$ser}->[1];

    # Generate is not used!  A fixed ID needs to be passed in at all times
    $self->{generate}     = \&generate;
    # Basic sanity check on passed in ID
    $self->{validate}     = \&validate;

    return $self;
}

# Just plug the static "Name" value from the config in
sub generate {
    my $session = shift;

    if ($session->{args}->{Name}) {
	$session->{data}->{_session_id} = $session->{args}->{Name};
    } else {
	die "$session - Must pass in Name value! (No generator functionality supported)";
    }
}

# Just make sure it looks non-threatening
sub validate {
    my $session = shift;
    unless ($session->{data}->{_session_id} =~ /^([\w\d\_\-\.]+)$/) {
	die "Invalid ID value";
    }
    return $1;
}

1; # End of Apache::AppSamurai::Tracker

__END__

=head1 NAME

Apache::AppSamurai::Tracker - Apache::AppSamurai scratch-pad/tracking storage

=head1 SYNOPSIS

 use Apache::AppSamurai::Tracker;
  
 tie %hash, 'Apache::AppSamurai::Tracker', $id, {
    Store     => 'Apache::Session::Store::DB_File',
    Lock      => 'Null',
 };
  
 # Postgress backend with session ID passed in directly
 # and Baes64 encoding
 
 tie %hash, 'Apache::AppSamurai::Tracker', $id, {
    Store     => 'Apache::Session::Store::Postgres',
    Lock      => 'Null',
 };
 
 # you decide!

=head1 DESCRIPTION

This module is a subclass of L<Apache::Session|Apache::Session> that can
be used to share non-sensitive information between multiple Apache server
processes.  Its main use is to provide storage of IP login failures and other
non-session data for L<Apache::AppSamurai|Apache::AppSamurai>.

The normal Apache::Session C<Generate> option is not used.  Each tracker
uses a set session ID.  For instance, "IPFailures" is used for the IP failure
tracking feature in Apache::AppSamurai.

The Apache::Session C<Serialize> type is hard set to Base64.  This allows
for storage in files or inside a database.

The C<Store> and C<Lock> options are still used and relevant, as are any
configuration options for the specific sub-modules that are used.

=head1 USAGE

You pass the modules you want to use as arguments to the constructor.  For
normal Apache::Session sub modules, the Apache::Session::Whatever part is
appended for you: you should not supply it.  (Apache::AppSamurai::Tracker
supports the same extended module syntax as
L<Apache::AppSamurai::Session|Apache::AppSamurai::Session>,
though in most cases, the standard Apache::Sesssion types should suffice.)

For example, if you wanted to use MySQL as the backing store, you should give
the argument C<Store => 'MySQL'>, and not 
C<Store => 'Apache::Session::Store::MySQL'>.  There are two modules that you
need to specify.  Store is the backing store to use.  Lock is the locking
scheme.

There are many modules included in the Apache::Session distribution that can
be used directly with this module.

Please see L<Apache::Session> for more information.

=head1 SEE ALSO

L<Apache::AppSamurai>, L<Apache::AppSamurai::Session>,
L<Apache::Session>

=head1 AUTHOR

Paul M. Hirsch, C<< <paul at voltagenoir.org> >>

=head1 BUGS

See L<Apache::AppSamurai> for information on bug submission and tracking.

=head1 SUPPORT

See L<Apache::AppSamurai> for support information.

=head1 ACKNOWLEDGEMENTS

This module is based partially on code written by
Jeffrey William Baker <jwbaker@acm.org> and the Apache::Session
authors.

=head1 COPYRIGHT & LICENSE

Copyright 2008 Paul M. Hirsch, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
