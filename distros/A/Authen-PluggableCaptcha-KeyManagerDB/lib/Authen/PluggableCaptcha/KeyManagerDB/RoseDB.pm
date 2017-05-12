#!/usr/bin/perl
######################################################

use strict;

package Authen::PluggableCaptcha::KeyManagerDB::RoseDB;
use Rose::DB ();
use base qw(Rose::DB);

######################################################

=head1 NAME

Authen::PluggableCaptcha::KeyManagerDB::RoseDB - Base RoseDB class for sample backend

=head1 SYNOPSIS

This module handles the DB Connection

=head1 DESCRIPTION


=head1 ENVELOPE VARIABLES

Please set the following envelope variables.  Yes, this is messy. 

=over 4

=item B<'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::driver' STRING>

The driver of the database.  Default is 'Pg' (postgres).

$ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::driver'}= 'Pg';

=item B<'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::database' STRING>

The name of the database.  Default is 'keymanager'.

$ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::database'}= 'keymanager';

=item B<'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::host' STRING>

The host of the database.  Default is 'localhost'.

$ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::host'}= 'localhost';

=item B<'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::username' STRING>

The host of the username.  Default is 'username'.

$ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::username'}= 'keymanager';

=item B<'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::password' STRING>

The password of the database.  Default is 'password'.

$ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::password'}= 'keymanager';




=back

=head1 AUTHOR

Jonathan Vanasco , cpan@2xlp.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Jonathan Vanasco

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

######################################################


__PACKAGE__->use_private_registry;

__PACKAGE__->default_domain('default');
__PACKAGE__->default_type('default');
    
__PACKAGE__->register_db(
	domain   => 'default',
	type     => 'default',
	driver   => $ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::driver'} || 'Pg',
	database => $ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::database'} || 'keymanager',
	host => $ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::host'} || 'localhost',
	username => $ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::username'} || 'keymanager',
	password => $ENV{'Authen::PluggableCaptcha::KeyManagerDB::RoseDB::password'} || 'keymanager',
);

######################################################
1;