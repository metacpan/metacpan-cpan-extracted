package DBIx::Quick::Converter;

use v5.16.3;
use strict;
use warnings;

use Moo::Role;

requires 'to_db';
requires 'from_db';

1;
=head1 NAME

DBIx::Quick::Converter - Role to convert fields after database recover and before inserts and updates.

=head1 SYNOPSIS

 package MyApp::DB::Converters::DateTime;
 
 use strict;
 use warnings;
 
 use Moo;

 use DateTime::Format::Pg;

 sub to_db {
 	shift;
 	my $dt = shift;
 	return undef if !$dt;
 	return DateTime::Format::Pg->new->format_datetime($dt);
 }

 sub from_db {
 	shift;
 	my $date = shift;
 	return undef if !$date;
 	return DateTime::Format::Pg->new->parse_datetime($date);
 }
 
 with 'DBIx::Quick::Converter';

=head1 DESCRIPTION

This is Moo role that must be implemented by objects sent to the C<converter> attribute of the C<field> declaration in L<DBIx::Quick>.

=head1 METHODS NEEDED TO BE IMPLEMENTED

=head2 to_db

The subroutine that transforms data into the format which you want to store in the database.

Takes one argument.

=head2 from_db

The subroutine that transforms the database data into your wanted format in perl, for example a L<DateTime> object.

Takes one argument.

=cut
