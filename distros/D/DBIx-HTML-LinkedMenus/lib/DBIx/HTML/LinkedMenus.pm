package DBIx::HTML::LinkedMenus;

# Name:
#	DBIx::HTML::LinkedMenus
#
# Purpose:
#	Convert db data to 2 linked HTML popup menus.
#
# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

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
our $VERSION = '1.10';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_base_menu_name		=> 'dbix_base_menu',
		_base_prompt		=> undef,
		_base_value			=> undef,
		_base_sql			=> '',
		_dbh				=> '',
		_form_name			=> 'dbix_form',
		_linked_menu_name	=> 'dbix_linked_menu',
		_linked_prompt		=> undef,
		_linked_value		=> undef,
		_linked_sql			=> '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _read_data
	{
		my($self)		= @_;
		my($base_sth)	= $$self{'_dbh'} -> prepare($$self{'_base_sql'});
		my($linked_sth)	= $$self{'_dbh'} -> prepare($$self{'_linked_sql'});
		$$self{'_data'}	= {};
		my($base_order)	= 0;

		$base_sth -> execute();

		my($base_data, $linked_order, $linked_data);

		while ($base_data = $base_sth -> fetch() )
		{
			$base_order++;

			$linked_sth -> execute($$base_data[2]);

			$linked_order = 0;

			while ($linked_data = $linked_sth -> fetch() )
			{
				$linked_order++;

				if ($linked_order == 1)
				{
					$$self{'_data'}{$$base_data[0]}	=
					{
						link	=> {},
						order	=> $base_order,
						value	=> $$base_data[1],
					};
				}

				$$self{'_data'}{$$base_data[0]}{'link'}{$$linked_data[0]} =
				{
					order	=> $linked_order,
					value	=> $$linked_data[1],
				};
			}
		}

		$$self{'_size'} = $base_order;

	}	# End of _read_data.

	sub _standard_keys
	{
		sort keys %_attr_data;
	}

	sub _validate_options
	{
		my($self) = @_;

		croak(__PACKAGE__ . ". You must supply values for these parameters: dbh, base_sql, linked_sql, base_menu_name and linked_menu_name") if (! $$self{'_dbh'} || ! $$self{'_base_sql'} || ! $$self{'_linked_sql'} || ! $$self{'_base_menu_name'} || ! $$self{'_linked_menu_name'});

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

sub get
{
	my($self, $base_id, $link_id)	= @_;
	my(@result)						= ();

	if (exists($$self{'_data'}{$base_id}) && exists($$self{'_data'}{$base_id}{'link'}{$link_id}) )
	{
		@result = ($$self{'_data'}{$base_id}{'value'}, $$self{'_data'}{$base_id}{'link'}{$link_id}{'value'});
	}

	@result;

}	# End of get.

# -----------------------------------------------

sub html_for_base_menu
{
	my($self) = @_;

	"<select name = '$$self{'_base_menu_name'}' onChange = 'dbix_change(this, $$self{'_linked_menu_name'})'></select>";

}	# End of html_for_base_menu.

# -----------------------------------------------

sub html_for_linked_menu
{
	my($self) = @_;

	"<select name = '$$self{'_linked_menu_name'}'></select>";

}	# End of html_for_linked_menu.

# -----------------------------------------------

sub javascript_for_db()
{
	my($self)	= @_;
	my(@code)	= <<EOS;

<script language = 'JavaScript'>
<!--

function dbix_change(base_menu, linked_menu)
{
	dbix_init_menu(linked_menu, dbix_link[base_menu.selectedIndex]);
}

function dbix_init_menu(menu, list)
{
	menu.length = list.length;
	var i;
	for (i = 0; i < list.length; i++)
	{
		menu.options[i].value = list[i].id;
		menu.options[i].text  = list[i].text;
	}
	menu.options[0].selected = true;
}

function dbix_init()
{
	dbix_init_menu(document.$$self{'_form_name'}.$$self{'_base_menu_name'}, dbix_base);
	dbix_init_menu(document.$$self{'_form_name'}.$$self{'_linked_menu_name'}, dbix_link[0]);
}

function dbix_Item(id, text)
{
	this.id   = id;
	this.text = text;
}
EOS

	my(@base)		= sort{$$self{'_data'}{$a}{'order'} <=> $$self{'_data'}{$b}{'order'} } keys %{$$self{'_data'} };
	my($base_index)	= -1;

	if (defined($$self{'_base_prompt'}) && defined($$self{'_base_value'}) )
	{
		unshift @base, $$self{'_base_value'};

		$$self{'_data'}{$$self{'_base_value'} }{'value'} = $$self{'_base_prompt'};
	}

	push @code, 'var dbix_base   = new Array(' . ($#base + 1) . ');';
	push @code, 'var dbix_link   = new Array(' . ($#base + 1) . ');', '';

	my($base, @link, $link_index);

	for $base (@base)
	{
		$base_index++;

		@link		= sort{$$self{'_data'}{$base}{'link'}{$a}{'order'} <=> $$self{'_data'}{$base}{'link'}{$b}{'order'} } keys %{$$self{'_data'}{$base}{'link'} };
		$link_index	= -1;

		if (defined($$self{'_linked_prompt'}) && defined($$self{'_linked_value'}) )
		{
			unshift @link, $$self{'_linked_value'};

			$$self{'_data'}{$base}{'link'}{$$self{'_linked_value'} }{'value'} = $$self{'_linked_prompt'};
		}

		for (@link)
		{
			$link_index++;

			if ($link_index == 0)
			{
				push @code, qq|dbix_base[$base_index]    = new dbix_Item("$base", "$$self{'_data'}{$base}{'value'}");|;
				push @code, "dbix_link[$base_index]    = new Array(" . ($#link + 1) . ');';
			}

			push @code, qq|dbix_link[$base_index][$link_index] = new dbix_Item("$_", "$$self{'_data'}{$base}{'link'}{$_}{'value'}");|;
		}

		push @code, '';
	}

	push @code, <<EOS;
//-->
</script>

EOS

	join("\n", @code);

}	# End of javascript_for_db.

# -----------------------------------------------

sub javascript_for_init_menu
{
	my($self) = @_;
	my(@code) = <<EOS;

<script language = 'JavaScript'>
<!--

dbix_init();

//-->
</script>

EOS

	join("\n", @code);

}	# End of javascript_for_init_menu.

# -----------------------------------------------

sub javascript_for_on_load
{
	my($self) = @_;

	('onLoad' => 'dbix_init()');

}	# End of javascript_for_on_load.

# -----------------------------------------------

sub new
{
	my($caller, %arg)	= @_;
	my($caller_is_obj)	= ref($caller);
	my($class)			= $caller_is_obj || $caller;
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

	$self = undef if (! $$self{'_size'});

	return $self;

}	# End of new.

# -----------------------------------------------

sub size
{
	my($self) = @_;

	$$self{'_size'};

}	# End of size.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<DBIx::HTML::LinkedMenus> - Convert SQL to 2 linked HTML popup menus.

=head1 Synopsis

	use DBIx::HTML::LinkedMenus;

	my($linker) = DBIx::HTML::LinkedMenus -> new
	(
		dbh        => $dbh,
		base_sql   => 'select campus_id, campus_name, campus_id ' .
						'from campus order by campus_name',
		linked_sql => 'select unit_id, unit_code from unit where ' .
						'unit_campus_id = ? order by unit_code',
	);

	# Print as part of a form:

	print $q -> start_form...
	print $linker -> javascript_for_db();
	print $linker -> html_for_base_menu();
	print $linker -> html_for_linked_menu();
	print $linker -> javascript_for_init_menu(); # Either this...
	print $q -> end_form();

	# Alternately, print as part of a page:

	my(@on_load) = $linker -> javascript_for_on_load(); # Or these 2...

	print $q -> start_html({title => 'Linked Menus', @on_load}),
	print $q -> start_form...
	print $linker -> javascript_for_db();
	print $linker -> html_for_base_menu();
	print $linker -> html_for_linked_menu();
	print $q -> end_form();

=head1 Description

This module's constructor takes a db handle and 2 SQL statements, and executes the SQL.

The first SQL statement is used to create a pop-up menu - the base menu.

The constructor returns undef if the SQL for the base menu returns 0 items.

The second SQL statement is used to create another pop-up menu - the linked menu.

By linked I mean each item in the base menu has a corresponding set of items in the linked menu.

Eg: If the available selections on the base menu are A and B, and A is the current selection, then the linked menu
will display (say) A1, A2 and A3. Then, when the user changes the current selection on the base menu from A to B,
the javascript provided will automatically change the available selections on the linked menu to (say) B1 and B2.

Details of the SQL are explained below.

You use the methods, as above, to retrieve the JavaScript and HTML, and include them in your CGI form.

The JavaScript is in 2 parts:

=over 4

=item The data and some general functions

This is returned by the method javascript_for_db().

=item A function call to initialize the linked-menu system

This is returned by the method javascript_for_init_menu(), or by the method javascript_for_on_load().

This initialization code can be output after the other components of the
form, or it can be output as the form's onLoad event handler.

Both ways of doing this are demonstrated in the Synopsis.

Either way, it must be called.

=back

The HTML is also in 2 parts:

=over 4

=item The HTML for the base menu

This is returned by the method html_for_base_menu().

As the user of the form changes her selection on the base menu,
the available items on the linked menu change in lockstep.

The selections on the base menu are determined by the base_sql parameter.

=item The HTML for the linked menu

This is returned by the method html_for_linked_menu().

The selections on the linked menu, for each base menu selection, are determined
by the linked_sql parameter.

=back

These 2 menus are available separately so you can place them anywhere on your form.

After a call to new, you can call the 'size' method if you need to check how
many rows were returned by the base SQL you used.

Neither the module CGI.pm, nor any of that kidney, are used by this module.
We simply output pure HTML.

However, for simplicity, this document pretends you are using CGI.pm rather
than an alternative. The sentences would become too convoluted otherwise.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Usage

You create an object of the class by calling the constructor, 'new'.

Now call four (4) methods to get the HTML and the JavaScript.

Lastly, display the HTML and JavaScript as part of a form.

=head1 Constructor and initialization

C<new(...)> returns a C<DBIx::HTML::LinkedMenus> object.

Here, in alphabetical order, are the parameters accepted by the constructor,
together with their default values.

=over 4

=item base_menu_name => 'dbix_base_menu'

This parameter is optional, since it has a default value.

The value of this parameter is what you would pass into a CGI object when you
call its param() method to retrieve the user's selection on the base menu.

But don't call CGI's param(). Call our get() method, and it will return
the base and linked menu selections from the internal hash holding the data.

Examine the demo in the examples/ directory to clarify this process.

=item base_prompt

This parameter is optional.

Use this to specify a non-undef string to appear at the start of the base menu.

The default value is undef.

=item base_value

This parameter is optional.

Use this to specify a non-undef value to be returned to the CGI script when the base_prompt is selected.

The default value is undef.

=item base_sql => ''

This parameter is mandatory.

This is the SQL used to select items for the base menu.

The SQL must select three (3) columns, in this order:

=over 4

=item First column

The first column will be used as the value returned by a CGI object, for example,
when you call its param(<base_menu_name>) method.

=item Second column

The second column will be used as the visible selection offered to the user on the
base menu.

=item Third column

The third column will be used as the value plugged into the linked_sql in place
of the ? to select a set of items for the linked menu which will correspond to this base
menu item.

=back

Of course, the first 2 columns selected could be the same:

	base_sql => 'select campus_name, campus_name, campus_id ' .
				'from campus order by campus_name'

But normally you would do this:

	base_sql => 'select campus_id, campus_name, campus_id from ' .
				'campus order by campus_name'

Again: This means that the second column is used to construct visible menu items, and
when an item is selected by the user, the first column is what is returned to your
CGI script, and the third column is used to select items for the linked menu.

=item dbh => ''

Pass in an open database handle.

This parameter is mandatory.

=item form_name => 'dbix_form'

This parameter is optional, since it has a default value.

The value of this parameter becomes the name for the form used in the
JavaScript, and must be the name used by you in your call to CGI's start_form()
or start_multipart_form() method.

=item linked_menu_name => 'dbix_linked_menu'

This parameter is optional, since it has a default value.

The value of this parameter is what you would pass into a CGI object when you
call its param() method to retrieve the user's selection on the linked menu.

But don't call CGI's param(). Call our get() method, and it will return
the base and linked menu selections from the internal hash holding the data.

Examine the demo in the examples/ directory to clarify this process.

=item linked_prompt

This parameter is optional.

Use this to specify a non-undef string to appear at the start of the linked menu.

The default value is undef.

=item linked_value

This parameter is optional.

Use this to specify a non-undef value to be returned to the CGI script when the linked_prompt is selected.

The default value is undef.

=item linked_sql => ''

This parameter is mandatory.

This is the SQL used to select items for the linked menu for each
selection of the base menu.

The SQL must select two (2) columns, in this order:

=over 4

=item First column

The first column will be used as the value returned by a CGI object, for example,
when you call its param(<linked_menu_name>) method.

=item Second column

The second column will be used as the visible selection offered to the user on the
linked menu.

=back

Of course, the first 2 columns selected could be the same:

	linked_sql => 'select unit_code, unit_code from unit where ' .
				'unit_campus_id = ? order by unit_code',

But normally you would do this:

	linked_sql => 'select unit_id, unit_code from unit where ' .
				'unit_campus_id = ? order by unit_code',

Again: This means that the second column is used to construct visible menu items, and
when an item is selected by the user, the first column is what is returned to your
CGI script.

Now, notice the where clause. Each value of column three (3) returned by the base_sql
is used to select a set of items for the linked menu. The ? in the linked_sql's where
clause is where the value from the third column of the base_sql is plugged into the
linked_sql.

If a particular value of the base_sql's column three (3) does not return any items for
the linked menu, then that basic item does not appear on the base menu.

=back

=head1 Methods

=over 4

=item get($base_id, $link_id)

Returns the 2 visible menu items, (base, linked), corresponding to the 2 menu
selections.

Returns () if either $base_id or $link_id is not a key into the internal hash
holding the data.

You would normally do something like this:

	my($base_id) = $q -> param('dbix_base_menu')   || '';
	my($link_id) = $q -> param('dbix_linked_menu') || '';
	my($linker)  = ...
	my(@value)   = $linker -> get($base_id, $link_id);

=item html_for_base_menu()

Returns the HTML for a popup menu named after the base_menu_name parameter.

Output it somewhere suitable on your page.

Calling this method and outputting the HTML is mandatory.

=item html_for_linked_menu()

Returns the HTML for a popup menu named after the linked_menu_name parameter.

Output it somewhere suitable on your page.

Calling this method and outputting the HTML is mandatory.

=item javascript_for_db()

Returns JavaScript, including the <script>...</script> tags, which holds your data in a
JavaScript db, and includes some JavaScript functions.

Output it somewhere suitable on your page.

Calling this method and outputting the JavaScript is mandatory.

=item javascript_for_init_menu()

Returns JavaScript, including the <script>...</script> tags, which holds the function call
to a function which initializes the linked-menu system. The function itself is included in
the code returned by javascript_for_db().

Output it somewhere on your page after you have output the 2 pieces of HTML and after
you have output the string returned from javascript_for_db().

Calling this method is optional. If you do not call it, then calling the method
javascript_for_on_load() is mandatory.

=item javascript_for_on_load()

Returns a string to be used as a <body> tag's onLoad event handler. It calls the
function which initializes the linked-menu system. The function itself is included in
the code returned by javascript_for_db().

Output it as part of the <body> tag. See examples/test-linked-menus.cgi for an
example.

Calling this method is optional. If you do not call it, then calling the method
javascript_for_init_menu() is mandatory.

=item new(%arg)

The constructor.

See the previous section for details of the parameters.

=item size()

Returns the number of rows returned by your base SQL.

It will tell you whether or not your base menu is empty.

=back

=head1 Sample Code

See examples/test-linked-menus.cgi for a complete program.

The use of undef for the 4 parameters base_prompt, base_value, linked_prompt and linked_value
should not be confused with the use of undef in the test program.

The latter is used to indicate the first time the program is run, in which case there are no
values returned by CGI's param method. See lines 21 and 22.

Further, see line 63 of test-linked-menus.cgi for the correct way to check for these undefs.

You will need to run examples/bootstrap-menus.pl to load the 'test'
database, 'campus' and 'unit' tables, with sample data.

You'll have to patch these 2 programs vis-a-vis the db vendor, username
and password.

The sample data in bootstrap-menus.pl is simple, but is used by several
modules, so don't be too keen on changing it :-).

=head1 See Also

	CGI::Explorer
	DBIx::HTML::ClientDB
	DBIx::HTML::PopupRadio

=head1 Author

C<DBIx::HTML::LinkedMenus> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2002.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2002, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
