package Data::Session::Base;

no autovivification;
use strict;
use warnings;

use Hash::FieldHash ':all';

fieldhash my %cache             => 'cache';
fieldhash my %data_col_name     => 'data_col_name';
fieldhash my %data_source       => 'data_source';
fieldhash my %data_source_attr  => 'data_source_attr';
fieldhash my %dbh               => 'dbh';
fieldhash my %debug             => 'debug';
fieldhash my %deleted           => 'deleted';
fieldhash my %directory         => 'directory';
fieldhash my %driver_cless      => 'driver_class';
fieldhash my %driver_option     => 'driver_option';
fieldhash my %expired           => 'expired';
fieldhash my %file_name         => 'file_name';
fieldhash my %host              => 'host';
fieldhash my %id                => 'id';
fieldhash my %id_base           => 'id_base';
fieldhash my %id_col_name       => 'id_col_name';
fieldhash my %id_file           => 'id_file';
fieldhash my %id_class          => 'id_class';
fieldhash my %id_option         => 'id_option';
fieldhash my %id_step           => 'id_step';
fieldhash my %is_new            => 'is_new';
fieldhash my %modified          => 'modified';
fieldhash my %name              => 'name';
fieldhash my %no_flock          => 'no_flock';
fieldhash my %no_follow         => 'no_follow';
fieldhash my %password          => 'password';
fieldhash my %pg_bytea          => 'pg_bytea';
fieldhash my %pg_text           => 'pg_text';
fieldhash my %port              => 'port';
fieldhash my %query             => 'query';
fieldhash my %query_class       => 'query_class';
fieldhash my %serializer_class  => 'serializer_class';
fieldhash my %serializer_option => 'serializer_option';
fieldhash my %session           => 'session';
fieldhash my %socket            => 'socket';
fieldhash my %table_name        => 'table_name';
fieldhash my %type              => 'type';
fieldhash my %umask             => 'umask';
fieldhash my %username          => 'username';
fieldhash my %verbose           => 'verbose';

our $errstr  = '';
our $VERSION = '1.18';

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;
	$s ||= '';

	print STDERR "# $s\n";

} # End of log.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::Base> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

Provide a set of methods for all derived classes, including log().

=head1 Method: new()

This class is never used on its own.

=head1 Method: log($s)

Print the string to STDERR.

If $s is empty, use '' (the empty string), to avoid a warning message.

Lastly, the string is output preceeded by a '#', so it does not interfere with test output.
That is, log($s) emulates diag $s.

=head1 Support

Log a bug on RT: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Session>.

=head1 Author

L<Data::Session> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
