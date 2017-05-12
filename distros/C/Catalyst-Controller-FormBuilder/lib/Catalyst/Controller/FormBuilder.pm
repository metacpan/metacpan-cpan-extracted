package Catalyst::Controller::FormBuilder;

use strict;
use base qw/Catalyst::Controller/;
use MRO::Compat;
use mro 'c3';

our $VERSION = "0.06";

__PACKAGE__->mk_accessors(qw/_fb_setup/);

sub new {
    my $class = shift;
    my $self  = $class->next::method(@_);
    $self->__setup();
    return $self;
}

sub __setup {
    my $self   = shift;
    my $class  = ref $self;

    my $config = $self->config->{'Controller::FormBuilder'} || {};

    my $tmpl_type = $config->{template_type} || "TT";
    my $method = $config->{method_name} || 'formbuilder';
    my $action = $config->{action}
      || "Catalyst::Controller::FormBuilder::Action::$tmpl_type";

    $self->_fb_setup(
        {
            method_name => $method,
            stash_name  => $config->{stash_name} || 'formbuilder',
            obj_name    => $config->{obj_name} || 'FormBuilder',
            action      => $action,
            attr_name   => $config->{attr_name} || 'Form',
            source_type => $config->{source_type} || undef,
            template_type => $tmpl_type,
        }
    );
    no strict 'refs';
    *{"$class\::$method"} = $class->make_accessor($method);
}

sub _formbuilder {
    my $self   = shift;
    my $method = $self->_fb_setup->{method_name};
    $self->$method(@_);
}

sub create_action {
    my $self = shift;
    my %args = @_;

    my $attr_name = $self->_fb_setup->{attr_name};

    if ( exists $args{attributes}{$attr_name} ) {
        $args{_attr_params} = delete $args{attributes}{$attr_name};
        if ( my $source_type = $self->_fb_setup->{source_type} ) {
            $args{_source_type} = $source_type;
        }
        push @{ $args{attributes}{ActionClass} }, $self->_fb_setup->{action};
    }

    $self->SUPER::create_action(%args);
}

1;

__END__

# Copyright (c) 2006 Juan Camacho <formbuilder@suspenda.com>. All Rights Reserved.

=head1 NAME

Catalyst::Controller::FormBuilder - Catalyst FormBuilder Base Controller

=head1 SYNOPSIS

    package MyApp::Controller::Books;
    use base 'Catalyst::Controller::FormBuilder';

    # optional config setup
    __PACKAGE__->config(
        'Controller::FormBuilder' = {
            template_type => 'HTML::Template',    # default is 'TT' (e.g. TT2)
        }
    );

    # looks for books/edit.fb form configuration file, based on the presence of
    # the ":Form" attribute.
    sub edit : Local Form {
        my ( $self, $c, @args ) = @_;

        my $form = $self->formbuilder;

        # add email form field to fields already defined edit.fb
        $form->field( name => 'email', validate => 'EMAIL' );

        if ( $form->submitted ) {
            if ( $form->validate ) {
                return $c->response->body("VALID FORM");
            }
            else {
                $c->stash->{ERROR}          = "INVALID FORM";
                $c->stash->{invalid_fields} =
                  [ grep { !$_->validate } $form->fields ];
            }
        }
    }

    # explicitedly use books/edit.fb, otherwise books/view.fb is used
    sub view : Local Form('/books/edit') {
        my ( $self, $c ) = @_;
        $c->stash->{template} = "books/edit.tt" # TT2 template;
    }

=cut


=head1 DESCRIPTION

This base controller merges the functionality of B<CGI::FormBuilder> with
Catalyst and the following templating systems: Template Toolkit, Mason and
HTML::Template. This gives you access to all of FormBuilder's niceties,
such as controllablefield stickiness, multilingual support, and Javascript
generation. For more details, see L<CGI::FormBuilder> or the website at:

    http://www.formbuilder.org

FormBuilder usage within Catalyst is straightforward. Since Catalyst handles
page rendering, you don't call FormBuilder's C<render()> method, as you
would normally. Instead, you simply add a C<:Form> attribute to each method
that you want to associate with a form. This will give you access to a
FormBuilder C<< $self->formbuilder >> object within that controller method:

    # An editing screen for books
    sub edit : Local Form {
        my ( $self, $c ) = @_;
        $self->formbuilder->method('post');   # set form method
    }

The out-of-the-box setup is to look for a form configuration file that follows
the L<CGI::FormBuilder::Source::File> format (essentially YAML), named for the
current action url. So, if you were serving C</books/edit>, this plugin
would look for:

    root/forms/books/edit.fb

(The path is configurable.) If no source file is found, then it is assumed
you'll be setting up your fields manually. In your controller, you will
have to use the C<< $self->formbuilder >> object to create your fields,
validation, and so on.

Here is an example C<edit.fb> file:

    # Form config file root/forms/books/edit.fb
    name: books_edit
    method: post
    fields:
        title:
            label: Book Title
            type:  text
            size:  40
            required: 1
        author:
            label: Author's Name
            type:  text
            size:  80
            validate: NAME
            required: 1
        isbn:
            label: ISBN#
            type:  text
            size:  20
            validate: /^(\d{10}|\d{13})$/
            required: 1
        desc:
            label: Description
            type:  textarea
            cols:  80
            rows:  5

    submit: Save New Book

This will automatically create a complete form for you, using the
specified fields. Note that the C<root/forms> path is configurable;
this path is used by default to integrate with the C<TTSite> helper.

Within your controller, you can call any method that you would on a
normal C<CGI::FormBuilder> object on the C<< $self->formbuilder >> object.
To manipulate the field named C<desc>, simply call the C<field()>
method:

    # Change our desc field dynamically
    $self->formbuilder->field(
        name     => 'desc',
        label    => 'Book Description',
        required => 1
    );

To populate field options for C<country>, you might use something like
this to iterate through the database:

    $self->formbuilder->field(
        name    => 'country',
        options =>
          [ map { [ $_->id, $_->name ] } $c->model('MyApp::Country')->all ],
        other => 1,    # create "Other:" box
    );

This would create a select list with the last element as "Other:" to allow
the addition of more countries. See L<CGI::FormBuilder> for methods
available to the form object.

The FormBuilder methodolody is to handle both rendering and validation
of the form. As such, the form will "loop back" onto the same controller
method. Within your controller, you would then use the standard FormBuilder
submit/validate check:

    if ( $self->formbuilder->submitted && $self->formbuilder->validate ) {
        $c->forward('/books/save');
    }

This would forward to C</books/save> if the form was submitted and
passed field validation. Otherwise, it would automatically re-render the
form with invalid fields highlighted, leaving the database unchanged.

To render the form in your tt2 template for example, you can use C<render>
to get a default table-based form:

    <!-- root/src/books/edit.tt -->
    [% FormBuilder.render %]

You can also get fine-tuned control over your form layout from within
your template.

=head1 TEMPLATES

The simplest way to get your form into HTML is to reference the
C<FormBuilder.render> method, as shown above. However, frequently you
want more control.

Only Template Toolkit, Mason and HTML::Template are currently supported, but
if your templating system's stash requirements are identical to one of these,
simply choose and define it via the C<template_type> config option.  Of course,
make sure you have a View to support the template, since this module does not
render templates.

From within your template, you can reference any of FormBuilder's
methods to manipulate form HTML, JavaScript, and so forth. For example,
you might want exact control over fields, rendering them in a C<< <div> >>
instead of a table. You could do something like this:

    <!-- root/src/books/edit.tt -->
    <head>
      <title>[% formbuilder.title %]</title>
      [% formbuilder.jshead %]<!-- javascript -->
    </head>
     <body>
      [% formbuilder.start -%]
      <div id="form">
        [% FOREACH field IN formbuilder.fields -%]
        <p>
            <label>
               <span [% IF field.required %]class="required"[%END%]>[%field.label%]</span>
            </label>
          [% field.field %]
          [% IF field.invalid -%]
              <span class="error">
                  Missing or invalid entry, please try again.
              </span>
          [% END %]
          </p>
        [% END %]
        <div id="submit">[% formbuilder.submit %]</div>
        <div id="reset">[% formbuilder.reset %]</div>
        </div>
      </div>
      [% formbuilder.end -%]
    </body>

In this case, you would B<not> call C<FormBuilder.render>, since that would
only result in a duplicate form (once using the above expansion, and
a second time using FormBuilder's default rendering).

Note that the above form could become a generic C<form.tt> template
which you simply included in all your files, since there is nothing
specific to a given form hardcoded in (that's the idea, after all).

You can also get some ideas based on FormBuilder's native Template Toolkit
support at L<CGI::FormBuilder::Template::TT2>.

=head1 CONFIGURATION

You can set defaults for your forms using Catalyst's config method inside
your controller.

    __PACKAGE__->config(
        'Controller::FormBuilder' => {
            new => {
                method     => 'post',
                # stylesheet => 1,
                messages   => '/locale/fr_FR/form_messages.txt',
            },
            form_path =>
              File::Spec->catfile( $c->config->{home}, 'root', 'forms' ),
            method_name   => 'form',
            template_type => 'HTML::Template',
            stash_name    => 'form',
            obj_name      => 'FormBuilder',
            form_suffix   => 'fb',
            attr_name     => 'Form',
            source_type   => 'CGI::FormBuilder::Source::File',
        }
    );

=over

=item C<new>

This accepts the exact same options as FormBuilder's C<new()> method
(which is a lot). See L<CGI::FormBuilder> for a full list of options.

=item C<form_path>

The path to configuration files. This should be set to an absolute
path to prevent problems. By default, it is set to:

    File::Spec->catfile( $c->config->{home}, 'root', 'forms' )

This can be a colon-separated list of directories if you want to
specify multiple paths (ie, "/templates1:/template2"), or an array
ref (ie, [qw/template1 templates2/]).

=item C<form_suffix>

The suffix that configuration files have. By default, it is C<fb>.

=item C<method_name>

Accessor method name available in your controller. By default, it is
C<formbuilder>.

=item C<template_type>

Defines the Catalyst View that the stash will be prepared for. Possible
values are: HTML::Template, Mason, TT. By default, it is C<TT>.

=item C<stash_name>

Not applicable for HTML::Template view.  By default, it is C<formbuilder>.
e.g. $c->stash->{formbuilder} = $formbuilder->prepare.

=item C<obj_name>

Not applicable for HTML::Template view. By default, it is C<FormBuilder>.
e.g. $c->stash->{FormBuilder} = $formbuilder.

=item C<attr_name>

The attribute name. By default, it is C<Form>.
e.g. sub edit : Form { ... }

=item C<source_type>

The source adapter class name. By default, it is
C<CGI::FormBuilder::Source::File>. See L<CGI::FormBuilder::Source>

=back

In addition, the following FormBuilder options are automatically set for you:

=over

=item C<action>

This is set to the URL for the current action. B<FormBuilder> is designed
to handle a full request cycle, meaning both rendering and submission. If
you want to override this, simply use the C<< $self->formbuilder >> object:

    $self->formbuilder->action('/action/url');

The default setting is C<< $c->req->path >>.

=item C<cookies>

Handling these are disabled (use Catalyst).

=item C<debug>

This is set to correspond with Catalyst's debug setting.

=item C<header>

This is disabled. Instead, use Catalyst's header routines.

=item C<params>

This is set to get parameters from Catalyst, using C<< $c->req >>.
To override this, use the C<< $self->formbuilder >> object:

    $self->formbuilder->params(\%param_hashref);

Overriding this is not recommended.

=item C<source>

This determines which source file is loaded, to setup your form. By
default, this is set to the name of the action URL, with C<.fb> appended.
For example, C<edit_form()> would be associated with an C<edit_form.fb>
source file.

To override this, include the path as the argument to the method attribute:

    sub edit : Local Form('/books/myEditForm') { }

If no source file is found, then it is assumed you'll be setting up your
fields manually. In your controller, you will have to use the
C<< $self->formbuilder >> object to create your fields, validation, and so on.

=back

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Source::File>,
L<CGI::FormBuilder::Template::TT2>, L<Catalyst::Manual>,
L<Catalyst::Request>, L<Catalyst::Response>

=head1 AUTHOR

Copyright (c) 2006 Juan Camacho <formbuilder@suspenda.com>. All Rights Reserved.

Thanks to Laurent Dami and Roy-Magne Mo for suggestions.

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

