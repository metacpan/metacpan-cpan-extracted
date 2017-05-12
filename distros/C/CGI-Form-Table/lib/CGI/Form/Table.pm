
package CGI::Form::Table;

use strict;
use warnings;

=head1 NAME

CGI::Form::Table - create a table of form inputs

=head1 VERSION 

version 0.161

 $Id: /my/cs/projects/formtable/trunk/lib/CGI/Form/Table.pm 27835 2006-11-11T04:18:20.685136Z rjbs  $

=cut

our $VERSION = '0.161';

=head1 SYNOPSIS

 use CGI::Form::Table;

 my $form = CGI::Form::Table->new(
   prefix  => 'employee',
   columns => [qw(lname fname job age)]
 );

 print $form->as_html;
 print $form->javascript;

=head1 DESCRIPTION

This module simplifies the creation of an HTML table containing form inputs.
The table can be extended to include extra rows, and these rows can be removed.
Each has a unique name, and on form submission the inputs are effectively
serialized.

L<CGI::Form::Table::Reader> will use the CGI module to produce a data structure
based on the parameters submitted by a form of this type.

=head1 METHODS

=head2 C<< CGI::Form::Table->new(%arg) >>

This method constructs a new form.  The only required arguments  are
C<columns>, which names the columns that will be in the form table, and
C<prefix>, which gives the unique prefix for input fields.

If given, C<initial_rows> specifies how many rows should initially be in the
form.

Instead of C<initial_rows>, you can pass C<initial_values>, a reference to an
array of hashes providing values for the columns of each row.  For example:

 my $table = CGI::Form::Table->new(
  prefix  => "charsheet",
  columns => [ qw(ability score) ],
  initial_values => [
   { ability => 'Str', score => '18/00' },
   { ability => 'Cha', score => '11'    }
  ]
 );

C<column_header>, if passed, is a hash of text strings to use as column
headers.  The keys are column names.  Columns without C<column_header> entries
are headed by their names.

Another argument, C<column_content>, may be passed.  It must contain a hashref,
with entries providing subs to produce initial content.  The subs are passed the
form object, the row number, and the name of the column.  For example, to add a
reminder of the current row in the middle of each row, you might create a form
like this:

 my $form = CGI::Form::Table->new(
   prefix  => 'simpleform',
   columns => [qw(one two reminder three four)],
   column_content => {
     reminder => sub { $_[1] }
   }
 );

This can be useful for forms that require SELECT elements or other complicated
parts.  (The JavaScript will just copy the column value when new rows are added,
updating the name attribute.)

=cut

sub new {
 my ($class, %arg) = @_;
 return unless $arg{columns};
 return unless $arg{prefix};
 $arg{initial_rows} = 1 unless $arg{initial_rows};
 $arg{initial_rows} = @{$arg{initial_values}}
  if ($arg{initial_values} && @{$arg{initial_values}} > $arg{initial_rows});
 bless \%arg => $class;
}

=head2 C<< $form->as_html >>

This returns HTML representing the form object.  JavaScript is required to make
the form expandible/shrinkable; see the C<javascript> method.  (L</"SEE ALSO">)

=cut

sub as_html {
 my ($self) = @_;
 my $prefix = $self->{prefix};

 my $column_headers = join q{},
  map { "\t\t\t<th class='input_column'>" . $self->column_header($_) . "</th>\n" }
  @{$self->{columns}};

 my $html = <<"EOH";
<table class='cft $prefix'>
 <thead>
  <tr>
   <td class='row_number'></td>
   <td class='add button'></td>
   <td class='delete button'></td>
$column_headers
   <td class='row_number'></td>
  </tr>
 </thead>

 <tbody>
EOH

 for my $row_number (1 .. $self->{initial_rows}) {
  my $content = join q{},
   map { "<td class='input_column'>" . $self->cell_content($row_number, $_) . "</td>" }
   @{$self->{columns}};

  $html .= <<"EOH";
  <tr>
   <td class='row_number'>$row_number</td>
   <td class='add button'>
     <input type='button' onClick='cloneParentOf(this.parentNode, "$prefix")' value='+' />
    </td>
    <td class='delete button'>
    <input type='button' onClick='removeParentOf(this.parentNode, "$prefix")' value='-' />
   </td>
   $content
   <td class='row_number'>$row_number</td>
  </tr>
EOH
 }
 $html .= "\t</tbody>\n";
 $html .= "</table>\n";

 return $html;
}

=head2 C<< $form->column_header($column_name) >>

This method returns the text that should be used as the column header in the
table output.  If no header was given in the initialization of the form, the
column name is returned verbatim.  (No checking is done to ensure that the
named column actually exists.)

=cut

sub column_header {
 my ($self, $name) = @_;
 defined $self->{column_header}{$name} ? $self->{column_header}{$name} : $name;
}

=head2 C<< $form->cell_content($row, $column_name) >>

This method returns the text (HTML) that should appear in the given row and
column.  If no C<column_content> entry was given for the column, a basic input
element is generated.

=cut

sub cell_content {
 my ($self, $row, $name) = @_;

 my $content_generator =
  $self->{column_content}{$name}
  ? $self->{column_content}{$name}
  : $self->_input;
 return $content_generator->($self, $row, $name);
}

# $form->_select(\@pairs, \%arg)
#
# given a ref to a list of two-element arrayrefs (value, text), returns a
# coderef to produce a select element via column_content
sub _select {
 my ($self, $pairs, $arg) = @_;
 sub {
  my ($self, $row, $name) = @_;
  my $content  = "<select name='$self->{prefix}_${row}_$name'";
     $content .= " $_='$arg->{$_}'" for keys %$arg;
     $content .= ">";
  my $value   = $self->cell_value($row, $name);
  for (@$pairs) {
   $content .= "<option value='$_->[0]'"
    . (($value && $_->[0] && $value eq $_->[0]) ? " selected='selected'" : q{})
    . ">$_->[1]</option>\n";
  }
  $content .= "</select>\n";
  return $content;
 }
}

# $form->_input(\%arg)
#
# returns a coderef to produce an input element via column_content
sub _input {
 my ($self, $arg) = @_;
 $arg ||= {};
 sub {
  my ($self, $row, $name) = @_;
  return "<input " . ($arg->{type} ? "type='$arg->{type}'" : q{})
   . "name='$self->{prefix}_${row}_$name' value='"
   . ($self->cell_value($row,$name) || q{}) . "' />";
 }
}

=head2 C<< $form->cell_value($row, $column_name) >>

This method returns the default value for the given row and column, taken from
the C<initial_values> passed to the initializer.

=cut

sub cell_value {
 my ($self, $row, $column_name) = @_;
 return unless defined $self->{initial_values}[--$row];
 return $self->{initial_values}[$row]{$column_name};
} 

=head2 C<< $class->javascript >>

This method returns JavaScript that will make the handlers for the HTML buttons
work.  This code has been (poorly) tested in Firefox, MSIE, and WebKit-based
browsers.

=cut

sub javascript {
 my $self = shift;
return <<"EOS";
function removeParentOf(child, prefix) {
  tbody = child.parentNode.parentNode;
  if (tbody.rows.length > 1)
    tbody.removeChild(child.parentNode);
  renumberRows(tbody, prefix);
}
function cloneParentOf(child, prefix) {
  clone = child.parentNode.cloneNode( true );
  tbody = child.parentNode.parentNode;
  tbody.insertBefore( clone, child.parentNode.nextSibling );
  renumberRows(tbody, prefix);
}
function renumberRows(tbody, prefix) {
  var rowList = tbody.rows;
  for (i = 0; i < rowList.length; i++) {
    rowNumber = rowList.length - i;
    rowList[i].cells[0].firstChild.nodeValue = rowNumber;
    for (j = 0; j < rowList[i].cells.length; j++) {
      prefix_pattern = new RegExp('^' + prefix + '_\\\\d+_');

      element_types = ['button', 'input', 'select', 'textarea'];
      for (type in element_types) {
        inputs = rowList[i].cells[j].getElementsByTagName(element_types[type]);
        for (k = 0; k < inputs.length; k++) {
          if (inputs[k].name.match(prefix_pattern))
            inputs[k].name = inputs[k].name.replace(
                prefix_pattern,
                prefix + "_" + rowNumber + "_"
                );
        }
      }
    }
    var cell_count = rowList[i].cells.length;
    rowList[i].cells[cell_count - 1].firstChild.nodeValue = rowNumber;
  }
}
EOS

}

=head1 SEE ALSO

=over 4

=item * L<http://rjbs.manxome.org/hacks/js/plusminus.html>

=item * L<CGI::Form::Table::Reader>

=back

=head1 AUTHOR

Ricardo SIGNES, C<< <rjbs@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 COPYRIGHT

Copyright 2004 Ricardo SIGNES, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;


