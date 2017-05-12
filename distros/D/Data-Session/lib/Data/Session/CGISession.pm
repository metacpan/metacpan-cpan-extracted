package Data::Session::CGISession;

our $VERSION = '1.17';

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session> - A persistent session manager

=head1 The Design of Data::Session, contrasted with CGI::Session

For background, read the docs (including the Changes files) and bug reports for both
L<Apache::Session> and L<CGI::Session>.

The interface to L<Data::Session> is not quite compatible with that of L<CGI::Session>, hence the
new namespace.

The purpose of L<Data::Session> is to be a brand-new alternative to both L<Apache::Session> and
L<CGI::Session>.

=head1 Aliases for Method Names

Aliases for method names are not supported.

In L<CGI::Session>, methods etime() and expires() were aliased to expire(). This is not supported
in L<Data::Session>.

L<Data::Session> does have an etime() method, L<Data::Session/Method: etime()>, which is different.

In L<CGI::Session>, method header() was aliased to http_header(). Only the latter method is
supported in L<Data::Session>. See L</Method: cookie()> and L</Method: http_header([@arg])>.

In L<CGI::Session>, id generators had a method generate_id() aliased to generate(). This is not
supported in L<Data::Session>.

In L<CGI::Session>, method param_dataref() was aliased to dataref(). Neither of these methods is
supported in L<Data::Session>. If you want to access the session data, use
my($hashref) = $session -> session.

=head1 Backwards-compatibility

This topic is sometimes used as a form of coercion, which is unacceptable, and sometimes leads to
a crippled design.

So, by design, L<Data::Session> is not I<exactly> backwards-compatible with L<CGI::Session>, but
does retain it's major features:

=over 4

=item o Specify the basic operating parameters with new(type => $string)

This determines the type of session object you wish to create.

Default: 'driver:File;id:MD5;serialize:DataDumper'.

And specifically, the format of that case-sensitive string is as expected. See
L<Data::Session/Specifying Session Options> for details.

=item o Retrieve the session id with the id() method

=item o Set and get parameters with the param() method

=item o Ensure session data is saved to disk with the flush() method

Call this just before your program exits.

In particular, as with L<CGI::Session>, persistent environments stop your program exiting in the way
you are used to. This matter is discussed in L<Data::Session/Trouble with Exiting>.

=back

=head1 CGI::Session::ExpireSessions is obsolete

Instead, consider using scripts/expire.pl, which ships with L<Data::Session>.

=head1 Code refs as database handles

Being able to supply a code ref as the value of the 'dbh' parameter to new() is supported.

This mechanism is used to delay creation of a database handle until it is actually needed,
which means if it is not needed it is not created.

=head1 Class 'v' Object

Calling methods on the class is not supported. You must always create an object.

The reason for this is to ensure every method call, without exception, has access to the per-object
data supplied by you, or by default, in the call to new().

=head1 The type of the Data::Session object

Controlling the capabilities of the L<Data::Session> object is determined by the 'type' parameter
passed in to new, as Data::Session -> new(type => $string).

A sample string looks like 'driver:BerkeleyDB;id:SHA1;serialize:DataDumper'.

Abbreviation of component key names ('driver', 'id', 'serialize') is not supported.

Such abbreviations were previously handled by L<Text::Abbrev>. Now, these must be named in full.

The decision to force corresponding class names to lower case is not supported.

Nevertheless, lower-cased input will be accepted. Such input is converted to the case you expect.

This affects the names of various sub-classes. See L</ID Generators>, L</Serialization Drivers> and
L</Storage Drivers>.

For example, driver:pg is now driver:Pg, which actually means L<Data::Session::Driver::Pg>, based on
the class name L<DBD::Pg>.

=head1 Exceptions

Exceptions are caught with L<Try::Tiny>. Errors cause L<Data::Session> to die.

The only exception to this is the call to new(), which can return undef. In that case, check
$Data::Session::errstr.

=head1 Global Variables

Global variables are not supported. This includes:

=over 4

=item o $CGI::Session::Driver::DBI::TABLE_NAME

=item o $CGI::Session::Driver::DBI::*::TABLE_NAME

=item o $CGI::Session::Driver::file::FileName

=item o $CGI::Session::IP_MATCH

=item o $CGI::Session::NAME

=back

=head1 ID Generators

Id generator classes have been renamed:

=over 4

=item o CGI::Session::ID::incr becomes L<Data::Session::ID::AutoIncrement>

=item o CGI::Session::ID::md5 becomes L<Data::Session::ID::MD5>

=item o CGI::Session::ID::sha becomes L<Data::Session::ID::SHA1>

=item o CGI::Session::ID::sha256 becomes L<Data::Session::ID::SHA256>

=item o CGI::Session::ID::sha512 becomes L<Data::Session::ID::SHA512>

=item o CGI::Session::ID::static becomes L<Data::Session::ID::Static>

=item o CGI::Session::ID::uuid becomes L<Data::Session::ID::UUID16> or UUID34 or UUID36 or UUD64

=back

=head1 JSON

L<Data::Session::Serialize::JSON> uses L<JSON>, not L<JSON::Syck>.

=head2 Managing Object Attributes

The light-weight L<Hash::FieldHash> is used to manage object attributes.

So, neither L<Mouse> nor L<Moose>, nor any other such class helper, is used.

=head1 Method: cookie()

Forcing the query object to have a cookie method is not supported. You may now use a query class
which does not provide a cookie method.

The logic of checking the cookie (if any) first (i.e. before checking for a form field of the same
name) is supported.

See L</Method: http_header([@arg])>.

=head1 Method: http_header([@arg])

The [] indicate an optional parameter.

Returns a HTTP header. This means it does not print the header. You have to do that, when
appropriate.

Forcing the document type to be 'text/html' when calling http_header() is not supported. You must
pass in a document type to http_header(), as $session -> http_header('-type' => 'text/html'), or
use the query object's default. Both L<CGI> and L<CGI::Simple> default to 'text/html'.

L<Data::Session> handles the case where the query object does not have a cookie() method.

The @arg parameter, if any, is passed to the query object's header() method, after the cookie
parameter, if any.

=head1 Method: load()

The new load() takes no parameters.

=head1 Method: new()

Excess versions of new() are not supported.

The new new() takes a hash of parameters.

This hash will include all options previously passed in in different parameters to new(), including
$dsn, $query, $sid, \%dsn_args and \%session_params.

=head1 Name Changes

Class name changes are discussed in L</ID Generators>, L</Serialization Drivers> and
L</Storage Drivers>.

As discussed in L<Data::Session/Method: new()>, these name changes are both the result of cleaning
up all the options to new(), and because the option names are now also method names.

=over 4

=item o DataColName becomes data_col_name

This is used in the call to new().

=item o DataSource becomes data_source

This is used in the call to new().

=item o generate_id becomes generate

This is used in various id generator classes, some of which provided generate as an alias.

=item o Handle becomes dbh

This is used in the call to new().

=item o IdColName becomes id_col_name

This is used in the call to new().

=item o IDFile becomes id_file

This is used in the call to new(), and in the '... id:AutoIncrement ...' id generator.

=item o IDIncr becomes id_step

This is used in the call to new(), and in the '... id:AutoIncrement ...' id generator.

=item o IDInit becomes id_base

This is used in the call to new(), and in the '... id:AutoIncrement ...' id generator.

=back

=head1 param()

Excess versions of param() will not be supported.

Use param($key => $value) to set and param($key) to get.

param() may be passed a hash, to set several key/value pairs in 1 call.

=head1 POD

All POD has been re-written.

=head1 Race Conditions

The race handling code in L<CGI::Session::Driver::postgresql> has been incorporated into other
L<Data::Session::Driver::*> drivers.

=head1 Serialization Drivers

Serializing classes have been renamed:

=over 4

=item o CGI::Session::Serialize::default becomes L<Data::Session::Serialize::DataDumper>

=item o CGI::Session::Serialize::freezethaw becomes L<Data::Session::Serialize::FreezeThaw>

=item o CGI::Session::Serialize::json becomes L<Data::Session::Serialize::JSON>

The latter will use L<JSON>. In the past L<JSON::Syck> was used.

=item o CGI::Session::Serialize::storable becomes L<Data::Session::Serialize::Storable>

=item o CGI::Session::Serialize::yaml becomes L<Data::Session::Serialize::YAML>

The latter uses L<YAML::Tiny>. In the past either L<YAML::Syck> or L<YAML> was used.

=back

=head1 Session ids will be mandatory

The ability to create a Perl object without a session id is not supported.

Every time a object of type L<Data::Session> is created, it must have an id.

This id is either supplied by the caller, taken from the query object, or one is generated.

See L<Data::Session/Specifying an Id> for details.

=head1 Session modification

L<CGI::Session> tracks calls to param() to set a flag if the object is modified, so as to avoid
writing the session to disk if nothing has been modified.

This includes checking if setting a param's value to the value it already has.

The behaviour is supported.

=head1 Session Parameters

L<CGI::Session> had these internal object attributes (parameters) not available to the user:

=over 4

=item o _DATA

Hashref: Keys: _SESSION_ATIME, _SESSION_CTIME, _SESSION_ID and _SESSION_REMOTE_ADDR.

=item o _DSN

Hashref.

=item o _OBJECTS

Hashref.

=item o _DRIVER_ARGS

Hashref.

=item o _CLAIMED_ID

Scalar.

=item o _STATUS

Scalar (bitmap).

=item o _QUERY

Scalar.

=back

L<Data::Session> has these internal object attributes (parameters):

=over 4

=item o _SESSION_ATIME

Scalar: Last access time.

=item o _SESSION_CTIME

Scalar: Creation time.

=item o _SESSION_ETIME

Scalar: Expiry time.

=item o _SESSION_ID

Scalar: The id.

=item o _SESSION_PTIME

Hashref: Expiry times of parameters.

=back

L<Data::Session> stores user data internally in a hashref, and the module reserves keys starting
with '_'.

Of course, it has a whole set of methods to manage state.

=head1 Session States

L<CGI::Session> objects can be one of 6 states. Every attempt has been made to simplify this design.

=head1 Storage Drivers

Classes related to DBI/DBD will use DBD::* style names, to help beginners.

Hence (with special cases):

=over 4

=item o CGI::Session::Driver::db_file becomes L<Data::Session::Driver::BerkeleyDB>

The latter no longer uses DB_File.

=item o CGI::Session::Driver::file becomes L<Data::Session::Driver::File>

=item o CGI::Session::Driver::memcached becomes L<Data::Session::Driver::Memcached>

=item o CGI::Session::Driver::mysql becomes L<Data::Session::Driver::mysql>

=item o CGI::Session::Driver::odbc becomes L<Data::Session::Driver::ODBC>

=item o CGI::Session::Driver::oracle becomes L<Data::Session::Driver::Oracle>

=item o CGI::Session::Driver::postgresql becomes L<Data::Session::Driver::Pg>

=item o CGI::Session::Driver::sqlite becomes L<Data::Session::Driver::SQLite>

=back

=head1 Tests

All tests have been re-written.

=head1 The Version of Perl

Perl 5 code will be used.

=head1 YAML

L<Data::Session::Serialize::YAML> uses L<YAML::Tiny>, not L<YAML::Syck> or L<YAML>.

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
