package DBIx::HTML::ClientDB;

# Name:
#	DBIx::HTML::ClientDB.
#
# Purpose:
#	Allow caller to specify a database handle, an sql statement,
#	and a name for the menu, and from that build the HTML for the menu,
#	and the JavaScript so the menu can search the client-side database.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# V 1.00 1-Oct-2002
# -----------------
# o Original version
#
# Author:
#	Ron Savage <rons@deakin.edu.au>
#	Home page: http://www.deakin.edu.au/~rons

use strict;
use warnings;

require 5.005_62;

require Exporter;

use Carp;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Image::MagickWrapper ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.08';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_border			=> 0,
		_dbh			=> '',
		_default		=> '',
		_form_name		=> 'dbix_client_form',
		_max_width		=> 0,
		_menu_name		=> 'dbix_client_menu',
		_row_headings	=> '',
		_sql			=> '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _read_data
	{
		my($self)				= @_;
		my(@row_headings)		= split(/,/, $$self{'_row_headings'});
		$$self{'_row_headings'}	= [@row_headings];
		my($sth)				= $$self{'_dbh'} -> prepare($$self{'_sql'});
		$$self{'_data'}			= [];
		my($first)				= 1;
		my($max_width)			= 0;

		$sth -> execute();

		my($data);

		while ($data = $sth -> fetch() )
		{
			push(@{$$self{'_data'} }, [@$data]);

			if ($first)
			{
				croak(__PACKAGE__ . ". You must supply one row heading for each column in the SQL") if ($#{$data} != $#{$$self{'_row_headings'} });

				$first				= 0;
				$$self{'_default'}	= $$data[1] if (! $$self{'_default'});
			}

			for (1 .. $#{$data})
			{
				$max_width = length($$data[$_]) if (length($$data[$_]) > $max_width);
			}
		}

		$$self{'_max_width'}	= $max_width if (! $$self{'_max_width'});
		$$self{'_size'}			= $#{$$self{'_data'} } + 1;

	}	# End of _read_data.

	sub _standard_keys
	{
		sort keys %_attr_data;
	}

	sub _validate_options
	{
		my($self) = @_;

		croak(__PACKAGE__ . ". You must supply values for these parameters: dbh, form_name, menu_name, row_headings and sql") if (! $$self{'_dbh'} || ! $$self{'_form_name'} || ! $$self{'_menu_name'} || ! $$self{'_row_headings'} || ! $$self{'_sql'});

#		# Reset empty parameters to their defaults.
#		# This could be optional, depending on another option.
#
#		for my $attr_name ($self -> _standard_keys() )
#		{
#			$$self{$attr_name} = $self -> _default_for($attr_name) if (! $$self{$attr_name});
#		}

	}	# End of _validate_options.

}	# End of Encapsulated class data.

# -----------------------------------------------

sub javascript_for_client_db()
{
	my($self)	= @_;
	my(@code)	= <<EOS;

<script language = 'JavaScript'>
<!--

function dbix_client_change()
{
  var i = $$self{'_form_name'}.$$self{'_menu_name'}.selectedIndex;
EOS

	for (2 .. $#{$$self{'_row_headings'} })
	{
		push(@code, "  $$self{'_form_name'}.dbix_client_$_.value = dbix_client[i].field_$_;");
	}

	push(@code, <<EOS);
}

function dbix_client_init()
{
  $$self{'_form_name'}.$$self{'_menu_name'}.length = dbix_client.length;
  var start = 0;
  var i;
  for (i = 0; i < dbix_client.length; i++)
  {
    $$self{'_form_name'}.$$self{'_menu_name'}.options[i].value = dbix_client[i].field_0;
    $$self{'_form_name'}.$$self{'_menu_name'}.options[i].text  = dbix_client[i].field_1;
    if (dbix_client[i].field_0 == "$$self{'_default'}")
    {
      start = i;
    }
  }
  $$self{'_form_name'}.$$self{'_menu_name'}.options[start].selected = true;
  dbix_client_change();
}
EOS
	my($function)	= 'function dbix_client_Item(';
	my(@param)		= map{"field_$_"} 0 .. $#{$$self{'_row_headings'} };
	$function		.= join(', ', @param) . ')';

	push(@code, <<EOS);
$function
{
EOS

	for (0 .. $#{$$self{'_row_headings'} })
	{
		push(@code, "  this.field_$_ = field_$_;");
	}

	push(@code, <<EOS);
}
EOS

	push(@code, 'var dbix_client = new Array(' . ($#{$$self{'_data'} } + 1) . ');');

	my($s);

	for my $item (0 .. $#{$$self{'_data'} })
	{
		$s = qq|dbix_client[$item] = new dbix_client_Item("|;
		$s .= join('", "', map{$$self{'_data'}[$item][$_]} 0 .. $#{$$self{'_data'}[$item]}) . '");';

		push(@code, $s);
	}

	push(@code, <<EOS);
//-->
</script>

EOS

	join("\n", @code);

}	# End of javascript_for_client_db.

# -----------------------------------------------

sub javascript_for_client_init
{
	my($self) = @_;
	my(@code) = <<EOS;

<script language = 'JavaScript'>
<!--

dbix_client_init();

//-->
</script>

EOS

	join("\n", @code);

}	# End of javascript_for_client_init.

# -----------------------------------------------

sub javascript_for_client_on_load
{
	my($self) = @_;

	('onLoad' => 'dbix_client_init()');

}	# End of javascript_for_client_on_load.

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

	$self -> _validate_options();
	$self -> _read_data();

	return $self;

}	# End of new.

# -----------------------------------------------

sub param
{
	my($self, $id)	= @_;
	my(@result)		= ();

	for (@{$$self{'_data'} })
	{
		@result = @$_ if ($$_[0] eq $id);
	}

	@result;

}	# End of param.

# -----------------------------------------------

sub size
{
	my($self) = @_;

	$$self{'_size'};

}	# End of size.

# -----------------------------------------------

sub table
{
	my($self)	= @_;
	my(@html)	= <<EOS;
<table border = '$$self{'_border'}'>
<tr>
<th>$$self{'_row_headings'}[0]</th><td><select name = '$$self{'_menu_name'}' onChange = 'dbix_client_change()'></select></td>
</tr>
EOS

	for (2 ..$#{$$self{'_row_headings'} })
	{
		push(@html, <<EOS);
<tr>
<th>$$self{'_row_headings'}[$_]</th><td><input type = 'text' name = 'dbix_client_$_' size = '$$self{'_max_width'}' /></td>
</tr>
EOS
	}

	push(@html, <<EOS);
</table>
EOS

	join("\n", @html);

}	# End of table.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<DBIx::HTML::ClientDB> - Convert sql into a client-side db with keyed access.

=head1 Synopsis

	use DBIx::HTML::ClientDB;

	my($object) = DBIx::HTML::ClientDB -> new
	(
		dbh          => $dbh,
		row_headings => 'Unit code,Unit code,Campus name,Unit name',
		sql          => 'select unit_code, unit_code, campus_name, unit_name ' .
		                'from unit, campus where unit_campus_id = campus_id ' .
		                'order by unit_code',
	);

	print $object -> javascript_for_client_db();
	print $object -> table();
	print $object -> javascript_for_client_init();

=head1 Description

This module takes a db handle, an SQL statement and a specially-formatted
row_headings parameter, and builds an array of rows as returned by the SQL.

Then you ask for that array in HTML, ie as a table.

After a call to the table() method, you can call the size() method if
you need to check how many rows were returned by the SQL you used.

Neither the module CGI.pm, nor any of that kidney, are used by this module.
We simply output pure HTML.

However, for simplicity, this document pretends you are using CGI.pm rather
than an alternative. The sentences would become too convoluted otherwise.

The output table is formatted as N rows of 2 columns:

=over 4

=item First column

The first column contains the row headings you supply in the 'row_headings' parameter.
'row_headings' is a comma-separated list of strings you want to appear in the first
column of the table.

There must be one string in 'row_headings' for each column mentioned in the SQL.

=item Second column

The second column contains the 'current record' in the database.

=back

Now for the rows:

=over 4

=item First row

The first row contains the first prompt string in the first column.

The first row contains a HTML popup menu in the second column.

This menu is what you use to choose the 'current record' in the database.

Since two (2) SQL columns are used to build this menu, two (2) strings from
the row_headings parameter are consumed building the first row. The first of
these 2 strings appears in the first column, as explained above. The second
of these 2 strings is, much to your amazement, discarded!

This way of doing things makes it easy for you to count row_heading strings and
their corresponding SQL columns, and makes it easy for me to cross-check your
ability to count to 2 :-).

=item Other rows

Each other row contains a field in the 'current record'. The value in the first
column comes from the row_headings parameter, and the value in the second column
comes from the database.

=back

The sum result is menu-driven access to the data returned by the SQL. All this
is downloaded from your CGI script to the web client. Since changing the current
menu item updates the other fields in this table using JavaScript, no message is
sent to the web server, and hence you have maximum speed of access.

The whole point of the exercise is to give you simple code for simple access to
simple data.

See examples/test-clientdb.cgi for an example which will make all this clear.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Usage

You create an object of the class by calling the constructor, 'new'.

Now call various methods to get the HTML and JavaScript.

Lastly, display the HTML as part of a form. You don't need a submit button
because there is no need to transmit your menu selection to the CGI script.
It's all about convenient access to a small database. Of course, you can
easily use this as the basis of a more complex record-selection system.

Instead of the method javascript_for_client_init(), you can call the method
javascript_for_client_on_load() to initialize a JavaScript onLoad event handler.

Note: The HTML menu name and all JavaScript function and global variable names
have been deliberately chosen so as to not clash with other modules of mine in the
DBIx::HTML::* namespace. Hence these modules can, in theory, all be used to build a
single web page, and indeed, can (I hope) all be used to build a single form. No,
I didn't actually test it.

=head1 Options

Here, in alphabetical order, are the options accepted by the constructor,
together with their default values.

=over 4

=item border => 0

This specifies whether or not the HTML table returned by the table() method
has the border option set.

Valid values are 0 and 1.

This option is not mandatory.

=item dbh => ''

Pass in an open database handle.

This option is mandatory.

=item default => ''

Pass in the string (from SQL column 2) which is to be the default item on the
popup menu. You supply here the visible menu item, not the value associated with
that menu item.

If default is not given a value, the first menu item becomes the default.

See the discussion of the sql option for details about the menu items.

This option is not mandatory.

=item form_name => 'dbix_client_form'

The value of this parameter becomes the name of the form used in the
JavaScript, and must be the name used by you in your call to CGI's start_form()
or start_multipart_form() method.

This option is not mandatory, since it has a default value.

=item max_width => 0

When the database field values displayed in the second column of the table are
input fields, this value becomes the 'size' parameter of those input fields.

A value of 0 means the data will be scanned and a value chosen which ensures
no data is truncated in order to display the database field values.

This option is not mandatory.

=item menu_name => 'dbix_client_menu'

The value of this parameter is what you would pass into a CGI object when you
call its param() method to retrieve the user's selection.

Hence you would do something like:

	my($name)   = 'fancy_menu';
	my($object) = DBIx::HTML::ClientDB -> new(menu_name => $name, ...);
	my($q)      = CGI -> new();
	my($id)     = $q -> param($name) || '';

This option is not mandatory, since it has a default value.

=item row_headings => 'a,b,...'

Pass in a comma-separated list of strings to use in the first column of the table.

There must be one string in 'row_headings' for each column mentioned in the SQL.

Since two (2) SQL columns are used to build the menu, two (2) strings from
the row_headings parameter are consumed building the first row. The first of
these 2 strings appears in the first column, as explained above. The second
of these 2 strings is, much to your amazement, discarded!

This way of doing things makes it easy for you to count row_heading strings and
their corresponding SQL columns, and makes it easy for me to cross-check your
ability to count to 2 :-).

This option is mandatory.

=item sql => ''

Pass in the SQL used to select the data.

The SQL must select at least 2 columns. The first will be used as the value returned by
a CGI object, for example, when you call its param() method. The second value
will be used as the visible selection offered to the user on the menu.

Of course, the 2 columns selected could be the same:

	$obj -> set(sql => 'select campus_name, campus_name from campus ' .
					'order by campus_name');

But normally you would do this:

	$obj -> set(sql => 'select campus_id, campus_name from campus ' .
					'order by campus_name');

This means that the second column is used to construct visible menu items, and
when an item is selected by the user, the first column is what is returned to your
CGI script.

The question remains: After you do something like this:

	my($q)     = CGI -> new();
	my($id)    = $q -> param('dbxi_client_menu') || '';

how do you convert the value, eg campus_id, back into the database fields associated
with the visible menu item, eg campus_name.

Simple: You call the param() method of the DBIx::HTML::ClientDB class:

	my(@field) = $object -> param($id);

The param() method returns () if the value of $id is unknown.

This option is mandatory.

=back

=head1 Methods

=over 4

=item javascript_for_client_db()

Returns JavaScript, including the <script>...</script> tags, which holds your data in a
JavaScript db, and includes some JavaScript functions.

Output it somewhere suitable on your page.

=item javascript_for_client_init()

Returns JavaScript, including the <script>...</script> tags, which holds the function call
to a function which initializes the menu. The function itself is included in
the code returned by javascript_for_client_db().

Output it somewhere suitable on your page after you have output the string returned from
javascript_for_db().

Calling this method is optional. If you do not call it, then calling the method
javascript_for_client_on_load() is mandatory.

=item javascript_for_client_on_load()

Returns a string to be used as a <body> tag's onLoad event handler. It calls the
function which initializes the menu. The function itself is included in
the code returned by javascript_for_db().

Output it as part of the <body> tag. See examples/test-clientdb.cgi for an
example.

Calling this method is optional. If you do not call it, then calling the method
javascript_for_client_init() is mandatory.

=item new(%arg)

The constructor.

See the previous section for details of the parameters.

=item param($id)

Returns an array of database fields corresponding to the menu value chosen.

Call this to convert the value returned to the CGI script when the user
selected a menu item, into the database fields which appeared in the second
column of the table.

In other words, convert the first column of the SQL into the values of all the
columns corresponding to that first column.

=item size()

Return the number of rows returned by your SQL.

Call this after calling 'table'.

It will tell you whether or not your menu is empty.

=item table()

Return the HTML for the table.

=back

=head1 Sample Code

See examples/test-clientdb.cgi for a complete program.

You will need to run examples/bootstrap-menus.pl to load the 'test'
database, 'campus' and 'unit' tables, with sample data.

You'll have to patch these 2 programs vis-a-vis the db vendor, username
and password.

The sample data in bootstrap-menus.pl is simple, but is used by several
modules, so don't be too keen on changing it :-).

=head1 See Also

	CGI::Explorer
	DBIx::HTML::LinkedMenus
	DBIx::HTML::PopupRadio

=head1 Author

C<DBIx::HTML::ClientDB> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2002.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2002, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
