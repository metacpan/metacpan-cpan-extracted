package CGI::Session::MembersArea;

# Name:
#	CGI::Session::MembersArea.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Reference:
#	Object Oriented Perl
#	Damian Conway
#	Manning
#	1-884777-79-1
#	P 114
#
# Note:
#	o Tab = 4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 2004 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
use warnings;
no warnings 'redefine';

use Carp;
use DBI;

require 5.005_62;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use CGI::Session::MembersArea ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '2.06';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_dsn						=> 'dbi:mysql:myadmin',
		_form_field_width			=> 50,
		_form_resource				=> 'my_resource',
		_form_password				=> 'my_password',
		_form_username				=> 'my_username',
		_password					=> '',
		_query						=> '',
		_resource_name_column		=> 'user_resource_name',
		_resource_password_column	=> 'user_resource_password',
		_resource_username_column	=> 'user_resource_username',
		_session_full_name_column	=> 'user_full_name',
		_session_key_name_column	=> 'user_full_name_key',
		_session_password_column	=> 'user_password',
		_session_table				=> 'user',
		_username					=> '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}

}	# End of encapsulated class data.

# -----------------------------------------------

sub clean_user_data
{
	my($self, $data, $max_length, $integer) = @_;
	$data = '' if (! defined($data) || ($data !~ /^([^`\x00-\x1F\x7F-\x9F]+)$/) || (length($1) == 0) || (length($1) > $max_length) );
	$data = '' if ($data =~ /<script\s*>.+<\s*\/?\s*script\s*>/i);	# http://www.perl.com/pub/a/2002/02/20/css.html.
	$data = '' if ($data =~ /<(.+)\s*>.*<\s*\/?\s*\1\s*>/i);		# Ditto, but much more strict.
	$data =~ s/^\s+//;
	$data =~ s/\s+$//;
	$data = 0 if ($integer && (! $data || ($data !~ /^[0-9]+$/) ) );

	$data;

}	# End of clean_user_data.

# -----------------------------------------------

sub DESTROY
{
	my($self) = @_;

	$$self{'_dbh'} -> disconnect() if ($$self{'_dbh'});

}	# End of DESTROY.

# -----------------------------------------------
# Return values:
# o $profile
# o undef

sub init
{
	my($self) = @_;

	my($my_resource) = $self -> clean_user_data( ($$self{'_query'} -> param($$self{'_form_resource'}) || ''), $$self{'_form_field_width'});
	my($my_username) = $self -> clean_user_data( ($$self{'_query'} -> param($$self{'_form_username'}) || ''), $$self{'_form_field_width'});
	my($my_password) = $self -> clean_user_data( ($$self{'_query'} -> param($$self{'_form_password'}) || ''), $$self{'_form_field_width'});

	my($profile);

	if ($my_username && $my_password)
	{
		$profile = $self -> load_profile($my_resource, $my_username, $my_password);
	}

	$profile;

}	# End of init.

# -----------------------------------------------

sub load_profile
{
	my($self, $resource, $username, $password) = @_;
	my($sql) = "select * from $$self{'_session_table'} where $$self{'_resource_name_column'} = ? and $$self{'_session_key_name_column'} = ? and $$self{'_session_password_column'} = ?";
	my($sth) = $$self{'_dbh'} -> prepare($sql);

	$sth -> execute($resource, lc $username, $password);

	my($profile) = $sth -> fetchrow_hashref();

	$sth -> finish();

	if ($profile && $$profile{$$self{'_session_key_name_column'} })
	{
		$profile =
		{
			full_name	=> $$profile{$$self{'_session_full_name_column'} },
			resource	=> $$profile{$$self{'_resource_name_column'} },
			username	=> $$profile{$$self{'_resource_username_column'} },
			password	=> $$profile{$$self{'_resource_password_column'} },
		};
	}
	else
	{
		$profile = undef;
	}

	$profile;

}	# End of load_profile.

# -----------------------------------------------

sub new
{
	my($class, %arg)	= @_;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	Carp::croak(__PACKAGE__ . ". You must specify values for the parameters 'dsn', 'username' and 'query'") if (! ($$self{'_dsn'} && $$self{'_username'} && $$self{'_query'}) );

	$$self{'_dbh'} = DBI -> connect
	(
		$$self{'_dsn'}, $$self{'_username'}, $$self{'_password'},
		{
			AutoCommit			=> 1,
			PrintError			=> 0,
			RaiseError			=> 1,
			ShowErrorStatement	=> 1,
		}
	);

	Carp::croak(__PACKAGE__ . " Cannot log on to database using DSN '$$self{'_dsn'}'") if (! $$self{'_dbh'});

	return $self;

}	# End of new.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<CGI::Session::MembersArea> - A resource guardian based on CGI::Session

=head1 Synopsis

This module does not have to be used in a module derived from CGI::Application, but this
synopsis assumes that that is in fact what you are trying to do.

	use CGI::Application;
	use CGI::Session::MembersArea;
	use DBIx::Admin::DatabaseModel;

	our @ISA = qw/CGI::Application/;

	sub setup
	{
	  my($self) = @_;
	  ...
	  $self -> param(database => '');
	  $self -> param(guardian => '');
	  $self -> param(profile => '');
	  $self -> mode_param(\&setup_mode);

	}	# End of setup.

	sub setup_mode
	{
	  ...
	  $self -> param(guardian => CGI::Session::MembersArea -> new
	  (
	    username  => 'root',
	    password  => 'pass',
	    query     => $self -> query(),
	  ) );

	  $self -> param(profile => $self -> param('guardian') -> init() );

	  if ($self -> param('profile') )
	  {
	    $self -> param
	    (
	      database => DBIx::Admin::DatabaseModel -> new
	      (
	        dsn      => $self -> param('my_dsn'),
	        username => $$profile{'username'},
	        password => $$profile{'password'},
	      )
	    );

	    $self -> param('database') -> param(profile => $self -> param('profile') );
	  }

	}	# End of sub setup_mode.

=head1 Description

C<CGI::Session::MembersArea> is a pure Perl module.

It implements an idea from the CGI::Session CookBook, in the section called Member's Area.

It uses a database as a guardian to control access to resources. These resources are
usually other databases, but don't have to be.

When a user supplies their name and password via a CGI form, this module uses 3 items:

=over 4

=item Resource name

=item User name

=item Password

=back

to determine whether or not that user is allowed access to the resource.

If you don't want the user to have to input a resource name, just change the CGI object
like this, to force the resource to always have the same name:

	$q -> param(my_resource => 'Some value');

This module uses these 3 items when it searches a database table, called 'user' by
default.

If that user is found in the database, the user's profile is returned by C<sub init()>.
The profile is defined below.

It is assumed the program using this module will also use CGI::Session, in which case
the program can save the profile to some database via the CGI::Session object, as in the
synopsis.

See the section of this document called Resources (as it happens), which contains the URI
of a database administration package (myadmin.cgi) which uses this module.

The guardian database contains a single table called, by default, 'user'. This table is
assumed to be in a database called, by default, 'myadmin'. Of course, the table could even
be in one of the databases being protected.

Because there are, normally, 2 or more databases involved, great care must be taken to
ensure you are clear in your mind as to which database is being referred to by any
particular piece of code.

When I refer to the database called 'myadmin', I will always call it the guardian database.

Here is the structure of the 'user' table:

=over 4

=item user_id

Not used. Typically an auto-incrementing row number.

=item user_full_name

The name of the user who might be permitted access to the resource, typically entered by
the user in a CGI form.

The value entered by the user of the CGI script is extracted from the query object.

The name of the CGI form variable used here can be changed by a parameter to the constructor. This parameter is
called 'form_username'.

=item user_full_name_key

A lower-case version of the user_full_name column, used when searching the 'user' table.

=item user_password

The password of the user who might be permitted access to the resource, typically entered by
the user in a CGI form.

Or, even better, some digest (eg: MD5) of their password.

The value entered by the user of the CGI script is extracted from the query object.

The name of the CGI form variable used here can be changed by a parameter to the constructor. This parameter is
called 'form_password'.

The password is typically hashed after the user enters it in a CGI form. You can use the
Javascript::MD5 module to convert user input into an MD5 digest. That way, the password
itself is never transmitted across the network - only the MD5 digest is transmitted when
the form is submitted.

This password - digest or not - is used when searching the 'user' table.

=item user_resource_name

A convenient string, used when searching the 'user' table, typically the name of the database
being protected by the guardian database.

The value entered by the user of the CGI script is extracted from the query object.

The name of the CGI form variable used here can be changed by a parameter to the constructor. This parameter is
called 'form_resource'.

=item user_resource_username

This is the username which gives access to the resource.

=item user_resource_password

This is the password which gives access to the resource.

=back

Parameters to the constructor allow you to use different column names for the 'user' table,
and even allow you to rename the 'user' table.

From the synopsis it should be clear that the username and password used to connect to
the guardian database 'myadmin' are embedded in the code, and hence are never transmitted
across the network.

Only the password of the user whose details are stored in the 'user' table is transmitted,
and even then you should be sending only a digest (eg: MD5) of that password.

Lastly, from the definition of the 'user' table it should be clear that the username and the
password of the resource itself are stored in the guardian database 'myadmin', and are used
by the code (see the synopsis - look for DBIx::Admin::DatabaseModel -> new(...) ) to connect
to the protected resource. Hence the resource's username and password are also never
transmitted across the network.

See the /examples directory for a program and data file which can be used to populate a
demonstration 'user' table.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<CGI::Session::MembersArea> object.

This is the class's contructor.

Usage: CGI::Session::MembersArea -> new().

This method takes a set of parameters. Only some of these parameters are mandatory.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

=over 4

=item dsn

This is the DSN used to connect to the guardian database 'myadmin'.

Note: Where I say 'This is the DSN', what this really means is that the value of the
parameter is the DSN. 'dsn' is the name of the parameter.

The default value is 'dbi:mysql:myadmin'.

This parameter is mandatory.

=item form_field_width

This is the maximum number of characters to accept in a CGI form field.

The default value is 50.

This parameter is optional.

=item form_resource

This is the name of the CGI form field containing the name of the resource.

The default value is 'my_resource'.

This parameter is optional.

=item form_password

This is the name of the CGI form field containing the user's password.

The Javascript::MD5 module replaces the value of such a field with the MD5 digest of the
value, so it is the digest which is transmitted across the network when the form is
submitted.

The default value is 'my_password'.

This parameter is optional.

=item form_username

This is the name of the CGI form field containing the user's name.

The default value is 'my_username'.

This parameter is optional.

=item password

This is the password of the guardian database 'myadmin'.

The default value is ''.

This parameter is optional.

=item query

This is the object managing the CGI form fields.

Typically it is a CGI object, but can be any compatible object, ie one with a C<param()>
method.

The default value is ''.

This parameter is mandatory.

=item resource_name_column

This is the name of the column in the 'user' table which contains the name of the
resource being protected.

The default value is 'user_resource_name'.

This parameter is optional.

=item resource_password_column

This is the name of the column in the 'user' table which contains the password of the
resource being protected.

The default value is 'user_resource_password'.

This parameter is optional.

=item resource_username_column

This is the name of the column in the 'user' table which contains the username of the
resource being protected.

The default value is 'user_resource_username'.

This parameter is optional.

=item session_full_name_column

This is the name of the column in the 'user' table which contains the name of the user who might
be permitted access to the resource

The default value is 'user_full_name'.

This parameter is optional.

=item session_key_name_column

This is the name of the column in the 'user' table which contains the lower case version
of the name of the user who might be permitted access to the resource

The value in this column is matched against the lc(value) taken from the CGI form field
called, by default, 'my_username'.

The default value is 'user_full_name_key'.

This parameter is optional.

=item session_password_column

This is the name of the column in the 'user' table which contains the password (or digest
thereof) of the user who might be permitted access to the resource

The value in this column is matched against the value taken from the CGI form field
called, by default, 'my_password'.

The default value is 'user_password'.

This parameter is optional.

=item session_table

This is the name of table in the guardian database which holds details of users who might
be permitted access to resources.

The default value is 'user'.

This parameter is optional.

=item username

This is the username of the guardian database 'myadmin'.

The default value is ''.

This parameter is mandatory.

=back

=head1 Method: clean_user_data($data, $max_length, $integer)

The method returns a cleaned-up version of $data.

You do not normally call this method.

Method C<init()> calls clean_user_data for each of the CGI form fields, which are called,
by default, 'my_resource', 'my_password' and 'my_username'.

This helps protect against malicious users attempting the input invalid data.

The parameters are:

=over

=item $data

The string to be cleaned.

See the source for details of the cleaning process.

Invalid data causes $data to be set to the empty string. But if the $integer flag is
set, invalid data causes $data to be set to 0.

=item $max_length

The maximum acceptable length of $data.

=item $integer

A Boolean flag, set to 1 to indicate that $data must contain only digits.

=back

=head1 Method: init()

You call this after calling new(), and it uses the query object to obtain CGI form fields,
cleans them, and uses them to see if the user is allowed access to the protected resource.

Return values:

=over 4

=item $profile, a hash ref

If the user's CGI form data is valid, their 'profile' is loaded from the guardian
database 'myadmin'.

And what is this profile? It is defined by the code in method C<load_profile()>.

Here is the process:

=over 4

=item Use an SQL select to search the 'user' table

=item Try to match on the lower case version of the user's name

=item Try to match on the user's password

=item Try to match on the name of the resource

=item If all 3 items match, generate the profile

The profile is a hash ref with these keys:

=over 4

=item full_name

The full name of the user.

This comes from the column of the user table called 'user_full_name'.

Use the C<new()> parameter 'session_full_name_column' if you change the name of this column.

The value associated with this key in the profile can be used to display the name of the
person who is logged in.

=item resource

The name of the resource.

This comes from the column of the user table called 'user_resource_name'.

Use the C<new()> parameter 'resource_name_column' if you change the name of this column.

=item username

The username of the resource.

This comes from the column of the user table called 'user_resource_username'.

Use the C<new()> parameter 'resource_username_column' if you change the name of this column.

=item password

The password of the resource.

This comes from the column of the user table called 'user_resource_password'.

Use the C<new()> parameter 'resource_password_column' if you change the name of this column.

=back

=item If less the 3 items match, the user will not be found in the guardian database

=back

=item undef

This indicates the user could not be found in the guardian database.

The most likely reason for this is that the CGI form fields have the wrong names or values.

=back

=head1 Method: load_profile($resource, $username, $password)

The method returns a hash ref which contains a user's profile, or it returns undef.

You do not normally call this method.

Method C<init()> calls C<load_profile()>.

=head1 Example code

See the examples/ directory in the distro.

There are 2 demo files:

=over 4

=item myadmin-init.txt

This is test data for the next program.

=item myadmin-init.pl

This creates 2 tables in the 'myadmin' database: 'sessions' and 'user'.

It then populates the 'user' table with the test data.

Edit it to suit your circumstances.

=back

=head1 Related Modules

=over 4

=item CGI::Session

=item DBIx::Admin::Application

This is part of myadmin.cgi V 2.01.

=item DBIx::Admin::DatabaseModel

This is part of myadmin.cgi V 2.01.

=item Javascript::MD5

=back

=head1 Resources

myadmin.cgi V 2.01: A pure Perl, vendor-independent, database administration tool.

This program contains a demonstration of how to use C<CGI::Session::MembersArea>.

myadmin.cgi V 2.01 is the first public version of a replacement for myadmin.cgi V 1.16
(which was released on 04-Feb-2002).

New version - V 2.01: http://savage.net.au/Perl-tutorials.html#tut_41

Stable version - V 1.16 (MySQL only, no sessions): http://savage.net.au/Perl-tutorials.html#tut_35

=head1 Author

C<CGI::Session::MembersArea> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2004.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2004, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
