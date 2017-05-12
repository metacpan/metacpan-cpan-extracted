
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Template;

=head1 NAME

CGI::FormBuilder::Template - Template adapters for FormBuilder

=head1 SYNOPSIS

    # Define a template engine

    package CGI::FormBuilder::Template::Whatever;
    use base 'Whatever::Template::Module';

    sub new {
        my $self  = shift;
        my $class = ref($self) || $self;
        my %opt   = @_;

        # override some options
        $opt{some_setting} = 0;
        $opt{another_var}  = 'Some Value';

        # instantiate the template engine
        $opt{engine} = Whatever::Template::Module->new(%opt);

        return bless \%opt, $class;
    }

    sub render {
        my $self = shift;
        my $form = shift;   # only arg is form object

        # grab any manually-set template params
        my %tmplvar = $form->tmpl_param;

        # example template manipulation
        my $html = $self->{engine}->do_template(%tmplvar);

        return $html;       # scalar HTML is returned
    }

=cut

use strict;
use warnings;
no  warnings 'uninitialized';

our $VERSION = '3.10';
warn __PACKAGE__, " is not a real module, please read the docs\n"; 
1;
__END__

=head1 DESCRIPTION

This documentation describes the usage of B<FormBuilder> templates,
as well as how to write your own template adapter.

The template engines serve as adapters between CPAN template modules
and B<FormBuilder>. A template engine is invoked by using the C<template>
option to the top-level C<new()> method:

    my $form = CGI::FormBuilder->new(
                    template => 'filename.tmpl'
               );

This example points to a filename that contains an C<HTML::Template>
compatible template to use to layout the HTML. You can also specify
the C<template> option as a reference to a hash, allowing you to
further customize the template processing options, or use other
template engines.

For example, you could turn on caching in C<HTML::Template> with
something like the following:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => {
                        filename => 'form.tmpl',
                        shared_cache => 1
                    }
               );

As mentioned, specifying a hashref allows you to use an alternate template
processing system like the C<Template Toolkit>.  A minimal configuration
would look like this:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => {
                        type => 'TT2',      # use Template Toolkit
                        template => 'form.tmpl',
                    },
               );

The C<type> option specifies the name of the engine. Currently accepted
types are:

    Builtin -  Included, default rendering if no template specified
    Div     -  Render form using <div> (no tables)
    HTML    -  HTML::Template
    Text    -  Text::Template
    TT2     -  Template Toolkit
    Fast    -  CGI::FastTemplate
    CGI_SSI -  CGI::SSI

In addition to one of these types, you can also specify a complete package name,
in which case that module will be autoloaded and its C<new()> and C<render()>
routines used. For example:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => {
                        type => 'My::Template::Module',
                        template => 'form.tmpl',
                    },
               );

All other options besides C<type> are passed to the constructor for that
templating system verbatim, so you'll need to consult those docs to see what
all the different options do. Skip down to L</"SEE ALSO">.

=head1 SUBCLASSING TEMPLATE ADAPTERS

In addition to the above included template engines, it is also possible to write
your own rendering module. If you come up with something cool, please let the
mailing list know!

To do so, you need to write a module which has a sub called C<render()>. This
sub will be called by B<FormBuilder> when C<< $form->render >> is called. This
sub can do basically whatever it wants, the only thing it has to do is return
a scalar string which is the HTML to print out. 

This is actually not hard. Here's a simple adapter which would manipulate
an C<HTML::Template> style template:

    # This file is My/HTML/Template.pm
    package My::HTML::Template;

    use CGI::FormBuilder::Template::HTML;
    use base 'CGI::FormBuilder::Template::HTML';

    sub render {
        my $self = shift;    # class object
        my $form = shift;    # $form as only argument

        # the template object (engine) lives here
        my $tmpl = $self->engine;

        # setup vars for our fields (objects)
        for ($form->field) {
            $tmpl->param($_ => $_->value);
        }

        # render output
        my $html = $tmpl->output;

        # return scalar;
        return $html;
    }
    1;  # close module

Then in B<FormBuilder>:

    use CGI::FormBuilder;
    use My::HTML::Template;   # your module

    my $tmpl = My::HTML::Template->new;

    my $form = CGI::FormBuilder->new(
                    fields   => [qw(name email)],
                    header   => 1,
                    template => $tmpl   # pass template object
               );

    # set our company from an extra CGI param
    my $co = $form->cgi_param('company');
    $tmpl->engine->param(company => $co);

    # and render like normal
    print $form->render;

That's it! For more details, the best thing to do is look through
the guts of one of the existing template engines and go from there.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template::HTML>,
L<CGI::FormBuilder::Template::Text>, L<CGI::FormBuilder::Template::TT2>,
L<CGI::FormBuilder::Template::Fast>, L<CGI::FormBuilder::Template::CGI_SSI>

=head1 REVISION

$Id: Template.pm 97 2007-02-06 17:10:39Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
