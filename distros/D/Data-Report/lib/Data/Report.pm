# Data::Reporter.pm -- Framework for flexible reporting
# RCS Info        : $Id: Report.pm,v 1.17 2008/08/18 09:51:23 jv Exp $
# Author          : Johan Vromans
# Created On      : Wed Dec 28 13:18:40 2005
# Last Modified By: Johan Vromans
# Last Modified On: Mon Aug 18 11:52:01 2008
# Update Count    : 265
# Status          : Unknown, Use with caution!

package Data::Report;

=head1 NAME

Data::Report - Framework for flexible reporting

=cut

$VERSION = "0.10";

=head1 SYNOPSIS

  use Data::Report;

  # Create a new reporter.
  my $rep = Data::Report::->create(type => "text"); # or "html", or "csv", ...

  # Define the layout.
  $rep->set_layout
    ([ { name => "acct", title => "Acct",        width => 6  },
       { name => "desc", title => "Description", width => 40, align => "<" },
       { name => "deb",  title => "Debet",       width => 10, align => ">" },
       { name => "crd",  title => "Credit",      width => 10, align => ">" },
     ]);

  # Start the reporter.
  $rep->start;

  # Add data, row by row.
  $rep->add({ acct => 1234, desc => "Received", deb => "242.33"                  });
  $rep->add({ acct => 5678, desc => "Paid",                      crd => "699.45" });
  $rep->add({ acct => 1259, desc => "Taxes",    deb =>  "12.00", crd => "244.00" });
  $rep->add({               desc => "TOTAL",    deb => "254.33", crd => "943.45" });

  # Finish the reporter.
  $rep->finish;

=head1 DESCRIPTION

Data::Report is a flexible, plugin-driven reporting framework. It
makes it easy to define reports that can be produced in text, HTML and
CSV. Textual ornaments like extra empty lines, dashed lines, and cell
lines can be added in a way similar to HTML style sheets.

The Data::Report framework consists of three parts:

=over 4

=item The plugins

Plugins implement a specific type of report. Standard plugins provided
are C<Data::Report::Plugin::Text> for textual reports,
C<Data::Report::Plugin::Html> for HTML reports, and
C<Data::Report::Plugin::Csv> for CSV (comma-separated) files.

Users can, and are encouraged, to develop their own plugins to handle
different styles and types of reports.

=item The base class

The base class C<Data::Report::Base> implements the functionality
common to all reporters, plus a number of utility functions the
plugins can use.

=item The factory

The actual C<Data::Report> module is a factory that creates a
reporter for a given report type by selecting the appropriate plugin
and returning an instance thereof.

=back

=cut

use strict;
use warnings;
use Carp;

=head1 BASIC METHODS

Note that except for the C<create> method, all other methods are
actually handled by the plugins and their base class.

=head2 create

Reporter objects are created using the class method C<create>. This
method takes a hash (or hashref) of arguments to initialise the
reporter object.

The actual reporter object is implemented by one of the plugin
modules, selected by the C<type> argument. Standard plugins are
provided for C<text>, C<HTML> and C<CSV> report types. The default
type is C<text>.

When looking for a plugin to support report type C<foo>, the C<create>
method will first try to load a module C<My::Package::Foo> where
C<My::Package> is the invocant class. If this module cannot be loaded,
it will fall back to C<Data::Report::Plugin::Foo>. Note that, unless
subclassed, the current class will be C<Data::Report>.

All other initialisation arguments correspond to attribute setting
methods provided by the plugins. For example, the hypothetical call

  my $rpt = Data::Report->create(foo => 1, bar => "Hello!");

is identical to:

  my $rpt = Data::Report->create;
  $rpt->set_foo(1);
  $rpt->set_bar("Hello!");

You can choose any combination at your convenience.

=cut

sub create {
    my $class = shift;
    my $args;
    if ( @_ == 1 && UNIVERSAL::isa($_[0], 'HASH') ) {
	$args = shift;
    }
    else {
	$args = { @_ };
    }

    # 'type' attribute is mandatory.
    my $type = ucfirst(lc($args->{type}));
    #croak("Missing \"type\" attribute") unless $type;
    $type = "Text" unless $type;

    # Try to load class specific plugin.
    my $plugin = $class . "::" . $type;
    $plugin =~ s/::::/::/g;

    # Strategy: load the class, and see if it exists.
    # A plugin does not necessary have to be external, if one of the
    # other classes did define the requested plugin we'll use that
    # one.

    # First, try the plugin in this invocant class.
    eval "use $plugin";

    unless ( _loaded($plugin) ) {

	# Try to load generic plugin.
	$plugin = __PACKAGE__ . "::Plugin::" . $type;
	$plugin =~ s/::::/::/g;
	eval "use $plugin";
    }
    croak("Unsupported type (Cannot load plug-in for \"$type\")\n$@")
      unless _loaded($plugin);

    # Return the plugin instance.
    # The constructor gets all args passed, including 'type'.
    $plugin->new($args);
}

sub _loaded {
    my $class = shift;
    no strict "refs";
    %{$class . "::"} ? 1 : 0;
}

=head2 start

This method indicates that all setup has been completed, and starts
the reporter. Note that no output is generated until the C<add> method
is called.

C<start> takes no arguments.

Although this method could be eliminated by automatically starting the
reporter upon the first call to C<add>, it turns out that an aplicit
C<start> makes the API much cleaner and makes it easier to catch mistakes.

=head2 add

This method adds a new entry to the report. It takes one single
argument, a hash ref of column names and the corresponding values.
Missing columns are left blank.

In addition to the column names and values, you can add the special
key C<_style> to designate a particular style for this entry. What
that means depends on the plugin that implements this reporter. For
example, the standard HTML reporter plugin prefixes the given style
with C<r_> to form the class name for the row.
The style name should be a simple name, containing letters, digits and
underscores, starting with a letter.

Example

  $rpt->add({ date   => "2006-04-31",
              amount => 1000,
              descr  => "First payment",
              _style => "plain" });

=head2 finish

This method indicates that report generation is complete. After this,
you can call C<start> again to initiate a new report.

C<finish> takes no arguments.

=head2 close

This is a convenience method. If the output stream was set up by the
reporter itself (see C<set_output>, below), the stream will be
closed. Otherwise, this method will be a no-op.

C<close> takes no arguments.

=head1 ATTRIBUTE HANDLING METHODS

=head2 get_type

The reporter type.

=head2 set_layout

This is the most important attribute, since it effectively defines the report layout.

This method takes one argument, an array reference. Each element of
the array is a hash reference that corresponds to one column in the
report. The order of elements definines the order of the columns in
the report, but see C<set_fields> below.

The following keys are possible in the hash reference:

=over 4

=item C<name>

The name of this column. The name should be a simple name, containing
letters, digits and underscores, starting with a letter.

The standard HTML reporter plugin uses the column name to form a class
name for each cell by prefixing with C<c_>. Likewise, the classes for
the table headings will be formed by prefixing the column names with
C<h_>. See L<ADVANCED EXAMPLES>, below.

=item C<title>

The title of this column. This title is placed in the column heading.

=item C<width>

The width of this column.
Relevant for textual reporters only.

By default, if a value does not fit in the given width, it will be
spread over multiple rows in a pseudo-elegant way. See also the
C<truncate> key, below.

=item C<align>

The alignment of this column. This can be either C<< < >> for
left-aligned columns, or C<< > >> to indicate a right-aligned column.

=item C<truncate>

If true, the values in this column will be truncated to fit the width
of the column.
Relevant for textual reporters only.

=back

=head2 set_style

This method can be used to set an arbitrary style (a string) whose
meaning depends on the implementing plugin. For example, a HTML plugin
could use this as the name of the style sheet to use.

The name should be a simple name, containing letters, digits and
underscores, starting with a letter.

=head2 get_style

Returns the style, or C<default> if none.

=head2 set_output

Designates the destination for the report. The argument can be

=over 4

=item a SCALAR reference

All output will be appended to the designated scalar.

=item an ARRAY reference

All output lines will be pushed onto the array.

=item a SCALAR

A file will be created with the given name, and all output will be
written to this file. To close the file, use the C<close> method described above.

=item anything else

Anything else will be considered to be a file handle, and treated as such.

=back

=head2 set_stylist

The stylist is a powerful method to control the appearance of the
report at the row and cell level. The basic idea is taken from HTML
style sheets. By using a stylist, it is possible to add extra spaces
and lines to rows and cells in a declarative way.

When used, the stylist should be a reference to a possibly anonymous
subroutine with three arguments: the reporter object, the style of a
row (as specified with C<_style> in the C<add> method), and the name
of a column as defined in the layout. For table headings, the row name
C<_head> is used.

The stylist routine will be repeatedly called by the reporter to
obtain formatting properties for rows and cells. It should return
either nothing, or a hash reference with properties.

When called with only the C<row> argument, it should return the
properties for this row.

When called with row equal to "*" and a column name, it should return
the properties for the given column.

When called with a row and a column name, it should return the
properties for the given row/column (cell).

All appropriate properties are merged to form the final set of
properties to apply.

The following row properties are recognised. Between parentheses the
backends that support them.

=over 4

=item C<skip_before>

(Text) Produce an empty line before printing the current row.

=item C<skip_after>

(Text) Produce an empty line after printing the current row, but only if
other data follows.

=item C<line_before>

(Text) Draw a line of dashes before printing the current row.

=item C<line_after>

(Text) Draw a line of dashes after printing the current row.

=item C<cancel_skip>

(Text) Cancel the effect of a pending C<skip_after>

=item C<ignore>

(All) Ignore this row. Useful for CSV backends where only the raw data
matters, and not the totals and such.

=back

The following cell properties are recognised. Between parentheses the
backends that support them.

=over 4

=item C<indent>

(Text) Indent the contents of this cell with the given amount.

=item C<wrap_indent>

(Text) Indent wrapped contents of this cell with the given amount.

=item C<truncate>

(Text) If true, truncate the contents of this cell to fit the column width.

=item C<line_before>

(Text) Draw a line in the cell before printing the current row. The value of
this property indicates the symbol to use to draw the line. If it is
C<1>, dashes are used.

=item C<line_after>

(Text) Draw a line in the cell after printing the current row. The value of
this property indicates the symbol to use to draw the line. If it is
C<1>, dashes are used.

=item C<raw_html>

(Html) Do not escape special HTML characters, allowing pre-prepared
HTML code to be placed in the output. Use with care.

=item C<ignore>

(All) Ignore this column. Note that to prevent surprising results, the
column must be ignored in all applicable styles, including the special
style C<"_head"> that controls the heading.

=item C<class>

(Html) Class name to be used for this cell. Default class name is
"h_CNAME" for table headings and "c_CNAME" for table rows, where CNAME
is the name of the column.

=back

Example:

  $rep->set_stylist(sub {
    my ($rep, $row, $col) = @_;

    unless ( $col ) {
	return { line_after => 1 } if $row eq "total";
	return;
    }
    return { line_after => 1 } if $col eq "amount";
    return;
  });

Each reporter provides a standard (dummy) stylist called
C<_std_stylist>. Overriding this method is equivalent to using
C<set_stylist>.

=head2 get_stylist

Returns the current stylist, if any.

=head2 set_topheading

Headings consist of two parts, the I<top heading>, and the I<standard
heading>. Bij default, the top heading is empty, and the standard
heading has the names of the columns with a separator line (depnendent
on the plugin used).

This method can be used to designate a subroutine that will provide
the top heading of the report.

Example:

  $rpt->set_topheading(sub {
    my $self = shift;
    $self->_print("Title line 1\n");
    $self->_print("Title line 2\n");
    $self->_print("\n");
  });

Note the use of the reporter provided C<_print> method to produce output.

When subclassing a reporter, a method C<_top_heading> can be defined
to provide the top heading. This is equivalent to an explicit call to
C<set_topheading>, but doesn't need to be repeatedly and explicitly
executed for each new reporter.

=head2 get_topheading

Returns the current top heading routine, if any.

=head2 set_heading

This method can be used to designate a subroutine that provides the
standard heading of the report.

In normal cases using this method is not necessary, since setting the
top heading will be sufficient.

Each reporter plugin provides a standard heading, implemented in a
method called C<_std_header>. This is the default value for the
C<heading> attribute. A user-defined heading can use

  $self->SUPER::_std_header;

to still get the original standard heading produced.

Example:

  $rpt->set_heading(sub {
    my $self = shift;
    $self->_print("Title line 1\n");
    $self->_print("Title line 2\n");
    $self->_print("\n");
    $self->SUPER::_std_heading;
    $self->_print("\n");
  });

Note the use of the reporter provided C<_print> method to produce output.

When subclassing a reporter, the method C<_std_heading> can be
overridden to provide a customized top heading. This is equivalent to
an explicit call to C<set_topheading>, but doesn't need to be
repeatedly and explicitly executed for each new reporter.

=head2 get_heading

Returns the current standard heading routine, if any.

=head2 set_fields

This method can be used to define what columns (fields) should be
included in the report and the order they should appear. It takes an
array reference with the names of the desired columns.

Example:

  $rpt->set_fields([qw(descr amount date)]);

=head2 get_fields

Returns the current set of selected columns.

=head2 set_width

This method defines the width for one or more columns. It takes a hash
reference with column names and widths. The width may be an absolute
number, a relative number (to increase/decrease the width, or a
percentage.

Example:

  $rpt->set_width({ amount => 10, desc => '80%' });

=head2 get_widths

Returns a hash with all column names and widths.

=head1 ADVANCED EXAMPLES

This example subclasses Data::Report with an associated plugin for
type C<text>. Note the use of overriding C<_top_heading> and
C<_std_stylist> to provide special defaults for this reporter.

  package POC::Report;

  use base qw(Data::Report);

  package POC::Report::Text;

  use base qw(Data::Report::Plugin::Text);

  sub _top_heading {
      my $self = shift;
      $self->_print("Title line 1\n");
      $self->_print("Title line 2\n");
      $self->_print("\n");
  }

  sub _std_stylist {
      my ($rep, $row, $col) = @_;

      if ( $col ) {
	  return { line_after => "=" }
	    if $row eq "special" && $col =~ /^(deb|crd)$/;
      }
      else {
	  return { line_after => 1 } if $row eq "total";
      }
      return;
  }

It can be used as follows:

  my $rep = POC::Report::->create(type => "text");

  $rep->set_layout
    ([ { name => "acct", title => "Acct",   width => 6  },
       { name => "desc", title => "Report", width => 40, align => "<" },
       { name => "deb",  title => "Debet",  width => 10, align => "<" },
       { name => "crd",  title => "Credit", width => 10, align => ">" },
     ]);

  $rep->start;

  $rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
  $rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
  $rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "special"});
  $rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "total"  });

  $rep->finish;

The output will look like:

  Title line 1
  Title line 2

  Acct                                      Report  Debet           Credit
  ------------------------------------------------------------------------
  one                                          two  three             four
  one                                          two  three             four
  one                                          two  three             four
                                                    ==========  ==========
  one                                          two  three             four
  ------------------------------------------------------------------------

This is a similar example for a HTML reporter:

  package POC::Report;

  use base qw(Data::Report);

  package POC::Report::Html;

  use base qw(Data::Report::Plugin::Html);

  sub start {
      my $self = shift;
      $self->{_title1} = shift;
      $self->{_title2} = shift;
      $self->{_title3} = shift;
      $self->SUPER::start;
  }

  sub _top_heading {
      my $self = shift;
      $self->_print("<html>\n",
		    "<head>\n",
		    "<title>", $self->_html($self->{_title1}), "</title>\n",
		    '<link rel="stylesheet" href="css/', $self->get_style, '.css">', "\n",
		    "</head>\n",
		    "<body>\n",
		    "<p class=\"title\">", $self->_html($self->{_title1}), "</p>\n",
		    "<p class=\"subtitle\">", $self->_html($self->{_title2}), "<br>\n",
		    $self->_html($self->{_title3}), "</p>\n");
  }

  sub finish {
      my $self = shift;
      $self->SUPER::finish;
      $self->_print("</body>\n</html>\n");
  }

Note that it defines an alternative C<start> method, that is used to
pass in additional parameters for title fields.

The method C<_html> is a convenience method provided by the framework.
It returns its argument with sensitive characters escaped by HTML
entities.

It can be used as follows:

  package main;

  my $rep = POC::Report::->create(type => "html");

  $rep->set_layout
    ([ { name => "acct", title => "Acct",   width => 6  },
       { name => "desc", title => "Report", width => 40, align => "<" },
       { name => "deb",  title => "Debet",  width => 10, align => "<" },
       { name => "crd",  title => "Credit", width => 10, align => ">" },
     ]);

  $rep->start(qw(Title_One Title_Two Title_Three_Left&Right));

  $rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
  $rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
  $rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "normal" });
  $rep->add({ acct => "one", desc => "two", deb => "three", crd => "four", _style => "total"  });

  $rep->finish;

The output will look like this:

  <html>
  <head>
  <title>Title_One</title>
  <link rel="stylesheet" href="css/default.css">
  </head>
  <body>
  <p class="title">Title_One</p>
  <p class="subtitle">Title_Two<br>
  Title_Three_Left&amp;Right</p>
  <table class="main">
  <tr class="head">
  <th align="left" class="h_acct">Acct</th>
  <th align="left" class="h_desc">Report</th>
  <th align="right" class="h_deb">Debet</th>
  <th align="right" class="h_crd">Credit</th>
  </tr>
  <tr class="r_normal">
  <td align="left" class="c_acct">one</td>
  <td align="left" class="c_desc">two</td>
  <td align="right" class="c_deb">three</td>
  <td align="right" class="c_crd">four</td>
  </tr>
  <tr class="r_normal">
  <td align="left" class="c_acct">one</td>
  <td align="left" class="c_desc">two</td>
  <td align="right" class="c_deb">three</td>
  <td align="right" class="c_crd">four</td>
  </tr>
  <tr class="r_normal">
  <td align="left" class="c_acct">one</td>
  <td align="left" class="c_desc">two</td>
  <td align="right" class="c_deb">three</td>
  <td align="right" class="c_crd">four</td>
  </tr>
  <tr class="r_total">
  <td align="left" class="c_acct">one</td>
  <td align="left" class="c_desc">two</td>
  <td align="right" class="c_deb">three</td>
  <td align="right" class="c_crd">four</td>
  </tr>
  </table>
  </body>
  </html>

See also the examples in C<t/09poc*.t>.

=head1 AUTHOR

Johan Vromans, C<< <jvromans at squirrel.nl> >>

=head1 BUGS

I<Disclaimer: This module is derived from actual working code, that I
turned into a generic CPAN module. During the process, some features
may have become unstable, but that will be cured in time. Also, it is
possible that revisions of the API will be necessary when new
functionality is added.>

Please report any bugs or feature requests to
C<bug-data-report at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Report>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Report          (user API)
    perldoc Data::Report::Base    (plugin writer documentation)

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Report>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Report>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Report>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2006,2008 Squirrel Consultancy, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# End of Data::Report
