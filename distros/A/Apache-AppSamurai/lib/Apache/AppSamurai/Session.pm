# Apache::AppSamurai:Session - Extension/wrapper for Apache::Session providing
# the same interface as Apache::Session::Flex with the ability to use
# additional features. 

# $Id: Session.pm,v 1.9 2008/04/30 21:40:06 pauldoom Exp $

##
# Copyright (c) 2008 Paul M. Hirsch (paul@voltagenoir.org).
# All rights reserved.
#
# This program is free software; you can redistribute it and/or modify it under
# the same terms as Perl itself.
##

# Includes code from Apache::Session developed by Jeffrey William Baker
# (jwbaker@acm.org) and others.

package Apache::AppSamurai::Session;
use strict;
use warnings;

use vars qw($VERSION @ISA $incl);
$VERSION = substr(q$Revision: 1.9 $, 10, -1);

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
    if ($self->{args}->{Generate} =~ /^AppSamurai\/([\w\d\_]+?)\s*$/i) {
	$gen  = "Apache::AppSamurai::Session::Generate::$1";
    } elsif ($self->{args}->{Generate} =~ /::/) {
	$gen  = $self->{args}->{Generate};
    } else {
	$gen = "Apache::Session::Generate::$self->{args}->{Generate}";
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
    
    if (!exists $incl->{$gen}) {
        eval "require $gen" || die $@;
        eval '$incl->{$gen}->[0] = \&' . $gen . '::generate' || die $@;
        eval '$incl->{$gen}->[1] = \&' . $gen . '::validate' || die $@;
    }
    
    if (!exists $incl->{$ser}) {
        eval "require $ser" || die $@;
        eval '$incl->{$ser}->[0] = \&' . $ser . '::serialize'   || die $@;
        eval '$incl->{$ser}->[1] = \&' . $ser . '::unserialize' || die $@;
    }
    
    $self->{object_store} = new $store $self;
    $self->{lock_manager} = new $lock  $self;
    $self->{generate}     = $incl->{$gen}->[0];
    $self->{validate}     = $incl->{$gen}->[1];
    $self->{serialize}    = $incl->{$ser}->[0];
    $self->{unserialize}  = $incl->{$ser}->[1];

    return $self;
}


1; # End of Apache::AppSamurai::Session

__END__

=head1 NAME

Apache::AppSamurai::Session - Apache::AppSamurai wrapper for Apache::Session

=head1 SYNOPSIS

 use Apache::AppSamurai::Session;
 
 # Equivalent to Apache::Session::Flex use:

 tie %hash, 'Apache::AppSamurai::Session', $id, {
    Store     => 'DB_File',
    Lock      => 'Null',
    Generate  => 'MD5',
    Serialize => 'Storable'
 };
 
 # Postgress backend with AppSamurai HMAC-SHA265 generator and
 # AES (Rijndael) encrypting serializer.

 tie %hash, 'Apache::AppSamurai::Session', $id, {
    Store     => 'Postgress',
    Lock      => 'Null',
    Generate  => 'AppSamurai/HMAC_SHA',
    Serialize => 'AppSamurai/CryptBase64'
 };
 
 # Wacky setup with imaginary Thinger::Thing::File storage module
 # and very real Apache::AppSamurai::Session::Serialize::CryptBase64
 # serializer.  (This shows the alternate module syntaxes.)

 tie %hash 'Apache::AppSamurai::Session', $id, {
    Store     => 'Thinger::Thing::File',
    Lock      => 'Null',
    Generate  => 'Ranom::Garbage',
    Serialize => 'AppSamurai/CryptBase64'
 };

 # you decide!

=head1 DESCRIPTION

This module is a overload of Apache::Session which allows you to specify the
backing store, locking scheme, ID generator, and data serializer at runtime.
You do this by passing arguments in the usual Apache::Session style (see
SYNOPSIS).  You may use any of the modules included in this distribution, or
a module of your own making.

In addition to the standard Apache::Session setup, this module allows for
using modules from within of the Apache::AppSamurai::Session tree by
prefixing with I<AppSamurai/>, or using any visible Perl module by
supplying its full module name.  (Whatever the module, it still must
meet standard Apache::Session interface functionality.)

=head1 USAGE

You pass the modules you want to use as arguments to the constructor.
There are three ways to point to a module:

=over 4

=item 1)

Specify the Apache::Session name.  For instance, for
L<Apache::Session::Storage::File|Apache::Session::Storage::File>,
you would use:

    Store => 'File'

=item 2)

Specify a name under the Apache::AppSamurai::Session tree. For instance,
for
L<Apache::AppSamurai::Session::Serialize::CryptBase64|Apache::AppSamurai::Session::Serialize::CryptBase64>,
you would use:

    Serialize => 'AppSamurai/CryptBase64'

=item 3)

Specify the full Perl module name.  For instance, for Junk::Thing::Monster
to be the session generator:

    Generate => 'Junk::Thing::Monster'

=back

In addition to the arguments needed by this module, you must provide whatever
arguments are expected by the backing store and lock manager that you are
using.  Please see the documentation for those modules, and 
L<Apache::Session> for more general session storage information.

=head1 SEE ALSO

L<Apache::AppSamurai>, L<Apache::Session>

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
