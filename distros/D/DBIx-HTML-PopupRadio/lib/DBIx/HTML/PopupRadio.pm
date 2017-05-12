package DBIx::HTML::PopupRadio;

# Name:
#	DBIx::HTML::PopupRadio.
#
# Purpose:
#	Allow caller to specify a database handle, an sql statement,
#	and a name for the menu, and from that build the HTML for the menu.
#	Menu here means either popup menu or radio group.
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
use HTML::Entities::Interpolate;

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
our $VERSION = '1.16';

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(	# Alphabetical order.
		_dbh		=> '',
		_default	=> '',			# For popup_menu or radio_group.
		_javascript	=> '',
		_linebreak	=> 0,			# For radio_group.
		_name		=> 'dbix_menu',
		_options	=> {},
		_prompt		=> '',			# For popup_menu.
		_sql		=> '',
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _read_data
	{
		my($self)		= @_;
		my($sth)		= $$self{'_dbh'} -> prepare($$self{'_sql'});
		$$self{'_data'}	= {};
		my($order)		= 0;

		$sth -> execute();

		my($data);

		while ($data = $sth -> fetch() )
		{
			$$self{'_data'}{$$data[0]} =
			{
				order	=> $order++,
				value	=> $$data[1],
			};
		}

		$$self{'_size'} = $order;

	}	# End of _read_data.

	sub _standard_keys
	{
		sort keys %_attr_data;
	}

	sub _validate_options
	{
		my($self) = @_;

		croak(__PACKAGE__ . ". You must supply values for these parameters: dbh, name and sql") if (! $$self{'_dbh'} || ! $$self{'_name'} || ! $$self{'_sql'});

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

	# This is the size (# if items) in the menu.
	# Ie, it is the number of rows returned by the SQL.

	$$self{'_size'} = 0;

	return $self;

}	# End of new.

# -----------------------------------------------

sub param
{
	my($self, $id) = @_;

	$id ? $$self{'_data'}{$id}{'value'} : '';

}	# End of param.

# -----------------------------------------------

sub popup_menu
{
	my($self, %arg) = @_;

	# Give the user one last chance to set some parameters.

	$self -> set(%arg);
	$self -> _validate_options();
	$self -> _read_data() if (! $$self{'_data'});

	my(@html, $s);

	$s = qq|<select id="$$self{'_name'}" name="$$self{'_name'}" |;
	$s .= qq|$_="$Entitize{$$self{'_options'}{$_} }" | for sort keys %{$$self{'_options'} };
	$s .= $$self{'_javascript'} if ($$self{'_javascript'});
	$s .= '>';

	push(@html, '', $s);

	my($prompt) = $$self{'_prompt'};

	if ($prompt)
	{
		if (ref($prompt) eq 'HASH')
		{
			push @html, qq|<option value="$Entitize{$_}">$Entitize{$$prompt{$_} }</option>| for sort keys %$prompt;
		}
		else
		{
			push @html, qq|<option value="$Entitize{$prompt}">$Entitize{$prompt}</option>|;
		}
	}

	for (sort{$$self{'_data'}{$a}{'order'} <=> $$self{'_data'}{$b}{'order'} } keys %{$$self{'_data'} })
	{
		$s = qq|<option value="$Entitize{$_}"|;
		$s .= qq| selected="selected"| if (defined($$self{'_default'}) && (lc $$self{'_default'} eq lc $$self{'_data'}{$_}{'value'}) );
		$s .= qq|>$Entitize{$$self{'_data'}{$_}{'value'} }</option>|;

		push @html, $s;
	}

	push @html, '</select>', '';

	join "\n", @html;

}	# End of popup_menu.

# -----------------------------------------------

sub radio_group
{
	my($self, %arg) = @_;

	# Give the user one last chance to set some parameters.

	$self -> set(%arg);
	$self -> _validate_options();
	$self -> _read_data() if (! $$self{'_data'});

	my($count) = 0;

	my(@html, $s);

	push @html, '';

	for (sort{$$self{'_data'}{$a}{'order'} <=> $$self{'_data'}{$b}{'order'} } keys %{$$self{'_data'} })
	{
		$s = qq|<input type="radio" id="$$self{'_name'}" name="$$self{'_name'}" value="$Entitize{$_}"|;

		if ($$self{'_default'})
		{
			$s .= qq| checked="checked"| if (lc $$self{'_default'} eq lc $$self{'_data'}{$_}{'value'});
		}
		else
		{
			$count++;

			$s .= qq| checked="checked"| if ($count == 1);
		}

		$s .= qq| />$Entitize{$$self{'_data'}{$_}{'value'} }|;
		$s .= '<br />' if ($$self{'_linebreak'});

		push @html, $s;
	}

	push @html, '';

	join "\n", @html;

}	# End of radio_group.

# -----------------------------------------------

sub set
{
	my($self, %arg) = @_;

	for my $arg (keys %arg)
	{
		$$self{"_$arg"} = $arg{$arg} if (exists($$self{"_$arg"}) );
	}

}	# End of set.

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

C<DBIx::HTML::PopupRadio> - Convert sql into a popup menu or radio group.

=head1 Synopsis

	use DBIx::HTML::PopupRadio;

	my($popup_object) = DBIx::HTML::PopupRadio -> new
	(
		dbh => $dbh,
		sql => 'select campus_id, campus_name from campus order by campus_name',
	);

	$popup_object -> set(default => '1');

	my($popup_menu)  = $popup_object -> popup_menu();
	my($radio_group) = $popup_object -> radio_group();

	print $popup_menu;

=head1 Description

This module takes a db handle and an SQL statement, and builds a hash.

Then you ask for that hash in HTML, as a popup menu or as a radio group.

The reading of the db table is delayed until you actually call one of the
methods 'popup_menu' or 'radio_group'. Even then, it is delayed until any
parameters passed in to these 2 methods are processed.

After a call to one of these 2 methods, you can call the 'size' method if
you need to check how many rows were returned by the SQL you used.

Neither the module CGI.pm, nor any of that kidney, are used by this module.
We simply output pure HTML.

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Usage

You create an object of the class by calling the constructor, 'new'.

You then call 'set', if you wish, to set any options.

Now call 'popup_menu' or 'radio_group' to get the HTML.

Lastly, display the HTML as part of a form.

The method names 'popup_menu' and 'radio_group' (and 'param') were chosen to be
reminiscent of methods with the same names in the CGI.pm module. But let
me repeat, my module does not use CGI.

=head1 Options

Here, in alphabetical order, are the options accepted by the constructor,
together with their default values.

=over 4

=item dbh => ''

Pass in an open database handle.

This option is mandatory, in the call to new, set, popup_menu or radio_group.
Ie By the time you call one of the latter 2 methods, dbh must be set.

=item default => ''

Pass in the string (from SQL column 2) which is to be the default item on the popup
menu or radio group. You supply here the visible menu item, not the value associated with
that menu item.

Starting with V 1.13, a case-insensitive match is used to compare the value provided here with the
values read in from the database.

If default is not given a value, the first menu item becomes the default.

See the discussion of the sql option for details about the menu items.

This option is not mandatory.

=item javascript => ''

Pass in a string of JavaScript, eg an event handler.

By using, say, javascript => 'onChange = "replicate()"', you can change the first line of HTML output from this:

	<select id = "field01" name = "field01">

to this:

	<select id = "field01" name = "field01" onChange = "replicate()">

Here is a real sample of such a JavaScript function, which would be output elsewhere in the HTML:

	<script language="JavaScript">
	function replicate()
	{
		a_form.field02.value =
			a_form.field01.options[a_form.field01.selectedIndex].text;

		a_form.field03.value =
			a_form.field01.options[a_form.field01.selectedIndex].value;
	}
	</script>

You can see what's happening: The menu item, both visible text and corresponding value returned to your CGI script,
are being copied from the popup menu to 2 other fields in the form.

Obviously you would replace the body of this function with code of your own choosing.

Q: Since this is an onChange handler, the 2 other fields will not be initialized until
the default menu selection is changed. So, how do you initialize them before the user selects a new menu item?

A: By outputting the following Javascript further down the form, after the function, menu and other 2 fields have
been defined:

	<script language="JavaScript">replicate();</script>

What's important to note here is that no function is declared, but one is called. The JavaScript is simple executed
inline, at the time it is parsed by the browser.

This option is not mandatory.

=item linebreak => 0

Pass in 1 if you want each radio group item on a separate line, ie separated
by <br />s.

This option is not mandatory.

=item name => 'dbix_menu'

Pass in the name of the form item to use for the popup menu or radio group.

This option is not mandatory, since it has a default value. It could be unset
and then reset, but must have a value by the time you call popup_menu or
radio_group.

The value of this parameter is what you will pass into a CGI object when you
call its param() method to retrieve the user's selection.

Hence you would do something like:

	my($name)         = 'fancy_menu';
	my($popup_object) = DBIx::HTML::PopupRadio -> new(name => $name, ...);
	my($q)            = CGI -> new();
	my($id)           = $q -> param($name) || '';

=item options => {}

This is a hash ref of options you wish to set on the HTML 'select' itself.

Eg: new(name => 'a_name', options => {tabindex => 2, force => 1}, ...).

With new(name => 'a_name', ...), the select would look like:

	<select id = "a_name" name = "a_name">

With new(name => 'a_name', options => {tabindex => 2, force => 1}, ...), the select would look like:

	<select id = "a_name" name = "a_name" tabindex = "2" force = "1">

This option is not mandatory.

=item prompt => ''

Alternately, this is possible: prompt => {'x' => 'y'}.

Pass in a prompt to use as the first entry in the popup menu.

The string, in the first case, can contain a single quote but not a double quote. Eg:
prompt => "O'Connor".

The key, in the second case, can contain a single quote but not a double quote. Eg:
prompt => {"'aitch" => 'Haitch = "h"'}.

Hence we can say new(prompt => 'Choose one') or new(prompt => {'0' => 'Choose one'}).

In the first case, the string 'Choose one' is both a visible menu item and the value
passed back to the CGI script if the user selects that item.

In the second case, the string 'Choose one' is the visible menu item, and the other value,
here '0', is the one passed back to the CGI script. In particular, this works -
new(prompt => {'' => 'Choose one'}) - to return the empty string to the CGI script.

Alternately, an anonymous hash or hash reference can be used, so multiple pairs
may be passed and they will appear at the top of the list sorted in the order of the
values.  Example new(prompt => {'no change' => 'no change', 'remove' => 'remove'});

This latter mechanism allows you to put multiple selections at the top of the menu.

This option is not mandatory.

=item sql => ''

Pass in the SQL used to select the popup menu or radio group items.

This option is mandatory, in the call to new, set, popup_menu or radio_group.
Ie By the time you call one of the latter 2 methods, sql must be set.

The SQL must select 2 columns. The first will be used as the value returned by
a CGI object, for example, when you call its param() method. The second value
will be used as the visible selection offered to the user on the menu.

Of course, the 2 columns selected could be the same:

	$obj -> set(sql => 'select campus_name, campus_name from campus');

But normally you would do this:

	$obj -> set(sql => 'select campus_id, campus_name from campus');

This means that the second column is used to construct visible menu items, and
when an item is selected by the user, the first column is what is returned to your
CGI script.

The question remains: After you do something like this:

	my($q)     = CGI -> new();
	my($id)    = $q -> param('dbxi_menu') || '';

how do you convert the value, eg campus_id, back into the visible menu item, eg
campus_name.

Simple: You call the param method of the DBIx::HTML::PopupRadio class:

	my($name) = $popup_object -> param($id);

param returns the empty string if the value of $id is unknown.

=back

=head1 Methods

=over 4

=item new(%arg): The constructor

See the previous section for details of the parameters.

=item param($id): Returns visible menu item corresponding to menu value

Call this to convert the value returned to the CGI script when the user
selected a menu item, into the visible menu item selected by the user.

In other words, convert the first column of the SQL into the second column.

=item popup_menu(%arg): Return the HTML for a popup menu

popup_menu(%arg) takes the same parameters as new().

=item radio_group(%arg): Return the HTML for a radio group

radio_group(%arg) takes the same parameters as new().

=item set(%arg): Set options thus: some_option => $arg{'some_option'}

Call this to set any option after calling new().

set(%arg) takes the same parameters as new().

=item size(): Return the number of rows returned by your SQL

Call this after calling 'popup_menu' or 'radio_group'.

It will tell you whether or not your menu is empty.

=back

=head1 Sample Code

See examples/*.cgi for complete programs, both simple and complex.

You will need to run examples/bootstrap-menus.pl to load the 'test'
database, 'campus' and 'unit' tables, with sample data.

You'll have to patch these 2 programs vis-a-vis the db vendor, username
and password.

The sample data in bootstrap-menus.pl is simple, but is used by several
modules, so don't be too keen on changing it :-).

=head1 See Also

	CGI::Explorer
	DBIx::HTML::ClientDB
	DBIx::HTML::LinkedMenus

The latter 2 modules will be released after the current one.

=head1 Author

C<DBIx::HTML::PopupRadio> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2002.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2002, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
