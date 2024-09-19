
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Template::TT2;

=head1 NAME

CGI::FormBuilder::Template::TT2 - FormBuilder interface to Template Toolkit

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields,
                    template => {
                        type => 'TT2',
                        template => 'form.tmpl',
                        variable => 'form',
                    }
               );

=cut

use Carp;
use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;
use Template;


our $VERSION = '3.20';

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my $opt   = arghash(@_);

    $opt->{engine} = Template->new($opt->{engine} || {})
            || puke $Template::ERROR unless UNIVERSAL::isa($opt->{engine}, 'Template');

    return bless $opt, $class;
}

sub engine {
    return shift()->{engine};
}

sub render {
    my $self = shift;
    my $tvar = shift || puke "Missing template expansion hashref (\$form->prepare failed?)";

    my $tt2template = $self->{template}
        || puke "Template Toolkit template not specified";
    my $tt2data = $self->{data} || {};
    my $tt2var  = $self->{variable};      # optional var for nesting

    if ($tt2var) {
        $tt2data->{$tt2var} = $tvar;
    } else {
        $tt2data = { %$tt2data, %$tvar };
    }
    my $tt2output;  # growing a scalar is so C-ish

    $self->{engine}->process($tt2template, $tt2data, \$tt2output)
        || puke $self->{engine}->error();

    # string HTML output
    return $tt2output;
}

1;
__END__

=head1 DESCRIPTION

This engine adapts B<FormBuilder> to use C<Template Toolkit>.  To do so, 
specify the C<template> option as a hashref which includes the C<type>
option set to C<TT2> and the C<template> option set to the name of the
template you want processed. You can also add C<variable> as an option
(among others) to denote the variable name that you want the form data
to be referenced by:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => {
                        type => 'TT2',
                        template => 'userinfo.tmpl',
                        variable => 'form',
                    }
               );

The following methods are provided (usually only used internally):

=head2 engine

Returns a reference to the C<Template> object

=head2 prepare

Returns a hash of all the fields ready to be rendered.

=head2 render

Uses the prepared hash and expands the template, returning a string of HTML.

=head1 TEMPLATES

The template might look something like this:

    <html>
    <head>
      <title>[% form.title %]</title>
      [% form.jshead %]
    </head>
    <body>
      [% form.start %]
      <table>
        [% FOREACH field = form.fields %]
        <tr valign="top">
          <td>
            [% field.required
                  ? "<b>$field.label</b>"
                  : field.label
            %]
          </td>
          <td>
            [% IF field.invalid %]
            Missing or invalid entry, please try again.
        <br/>
        [% END %]

        [% field.field %]
      </td>
    </tr>
        [% END %]
        <tr>
          <td colspan="2" align="center">
            [% form.submit %] [% form.reset %]
          </td>
        </tr>
      </table>
      [% form.end %]
    </body>
    </html>

By default, the Template Toolkit makes all the form and field
information accessible through simple variables.

    [% jshead %]  -  JavaScript to stick in <head>
    [% title  %]  -  The <title> of the HTML form
    [% start  %]  -  Opening <form> tag and internal fields
    [% submit %]  -  The submit button(s)
    [% reset  %]  -  The reset button
    [% end    %]  -  Closing </form> tag
    [% fields %]  -  List of fields
    [% field  %]  -  Hash of fields (for lookup by name)

You can specify the C<variable> option to have all these variables
accessible under a certain namespace.  For example:

    my $form = CGI::FormBuilder->new(
        fields => \@fields,
        template => {
             type => 'TT2',
             template => 'form.tmpl',
             variable => 'form'
        },
    );

With C<variable> set to C<form> the variables are accessible as:

    [% form.jshead %]
    [% form.start  %]
    etc.

You can access individual fields via the C<field> variable.

    For a field named...  The field data is in...
    --------------------  -----------------------
    job                   [% form.field.job   %]
    size                  [% form.field.size  %]
    email                 [% form.field.email %]

Each field contains various elements.  For example:

    [% myfield = form.field.email %]

    [% myfield.label    %]  # text label
    [% myfield.field    %]  # field input tag
    [% myfield.value    %]  # first value
    [% myfield.values   %]  # list of all values
    [% myfield.option   %]  # first value
    [% myfield.options  %]  # list of all values
    [% myfield.required %]  # required flag
    [% myfield.invalid  %]  # invalid flag

The C<fields> variable contains a list of all the fields in the form.
To iterate through all the fields in order, you could do something like
this:

    [% FOREACH field = form.fields %]
    <tr>
     <td>[% field.label %]</td> <td>[% field.field %]</td>
    </tr>
    [% END %]

If you want to customise any of the Template Toolkit options, you can
set the C<engine> option to contain a reference to an existing
C<Template> object or hash reference of options which are passed to
the C<Template> constructor.  You can also set the C<data> item to
define any additional variables you want accessible when the template
is processed.

    my $form = CGI::FormBuilder->new(
        fields => \@fields,
        template => {
             type => 'TT2',
             template => 'form.tmpl',
             variable => 'form',
             engine   => {
                  INCLUDE_PATH => '/usr/local/tt2/templates',
             },
             data => {
                  version => 1.23,
                  author  => 'Fred Smith',
             },
        },
    );

For further details on using the Template Toolkit, see C<Template> or
L<http://www.template-toolkit.org>

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template>, L<Template>

=head1 REVISION

$Id: TT2.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

Template Tookit support is largely due to a huge patch from Andy Wardley.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
