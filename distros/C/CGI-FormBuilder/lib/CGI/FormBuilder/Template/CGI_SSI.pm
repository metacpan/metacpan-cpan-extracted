
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Template::CGI_SSI;

=head1 NAME

CGI::FormBuilder::Template::CGI_SSI - FormBuilder interface to CGI::SSI

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields,
                    template => {
                      type => 'CGI_SSI',
                      file => "template.html",
                    },
               );

=cut

use Carp;
use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;
use CGI::SSI;
use base 'CGI::SSI';


our $VERSION = '3.10';

#
# For legacy reasons, and due to its somewhat odd interface, 
# CGI::SSI vars use a completely different naming scheme.
#
our %FORM_VARS = (
    'js-head'       =>  'jshead',
    'form-title'    =>  'title',
    'form-start'    =>  'start',
    'form-submit'   =>  'submit',
    'form-reset'    =>  'reset',
    'form-end'      =>  'end',
    'form-invalid'  =>  'invalid',
    'form-required' =>  'required',
);

our %FIELD_VARS = map { $_ => "$_-%s" } qw(
    field
    value
    label
    type
    comment
    required
    error
    invalid 
    missing
    nameopts
    cleanopts
);

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my $opt   = arghash(@_);

    $opt->{die_on_bad_params} = 0;    # force to avoid blow-ups

    my %opt2 = %$opt;
    delete $opt2{virtual};
    delete $opt2{file};
    delete $opt2{string};
    $opt->{engine} = CGI::SSI->new(%opt2);

    return bless $opt, $class;     # rebless
}

sub engine {
    return shift()->{engine};
}

sub render {
    my $self = shift;
    my $tvar = shift || puke "Missing template expansion hashref (\$form->prepare failed?)";

    while(my($to, $from) = each %FORM_VARS) {
        debug 1, "renaming attr $from to: <!--#echo var=\"$to\">";
        $tvar->{$to} = "$tvar->{$from}";
    }

    #
    # For CGI::SSI, each data struct is manually assigned
    # to a separate <!--#echo var=... -->"
    #
    my @fieldlist;
    for my $field (@{$tvar->{fields}}) {

        # Field name is usually a good idea
        my $name = $field->{name};
        debug 1, "expanding field: $name";

        # Get all values
        my @value   = @{$tvar->{field}{$name}{values}  || []};
        my @options = @{$tvar->{field}{$name}{options} || []};

        #
        # Auto-expand all of our field tags, such as field, label, value
        # comment, error, etc, etc
        #
        my %all_loop;
        while(my($key, $str) = each %FIELD_VARS) {
            my $var = sprintf $str, $name;
            $all_loop{$key} = $tvar->{field}{$name}{$key};
            $tvar->{$var}   = "$tvar->{field}{$name}{$key}";   # fuck Perl
            debug 2, "<!--#echo var=\"$var\"> = " . $all_loop{$str};
        }
    }
    # kill our previous fields list
    $tvar->{fields} = \@fieldlist;

    # loop thru each field we have and set the tmpl_param
    while(my($param, $tag) = each %$tvar) {
        $self->{engine}->set($param => $tag);
    }

    # template output
    SWITCH: {
        if($self->{virtual}) {
            return $self->engine->include(virtual=>$self->{virtual});
        }
        if($self->{file}) {
            return $self->engine->include(file=>$self->{file});
        }
        if($self->{string}) {
            return $self->engine->process($self->{string});
        }
    }
}

1;
__END__

=head1 DESCRIPTION

This engine adapts B<FormBuilder> to use C<CGI::SSI>.

You can specify any options which C<< CGI::SSI->new >>
accepts by using a hashref:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => {
                        type => 'CGI::SSI',
                        file => 'form.shtml',
                        sizefmt => 'abbrev'
                    }
                );

In addition to CGI::SSI B<new> arguments, you can also
specify C<file>, C<virtual>, or C<string> argument.

The following methods are provided (usually only used internally):

=head2 engine

Returns a reference to the C<CGI::SSI> object

=head2 prepare

Returns a hash of all the fields ready to be rendered.

=head2 render

Uses the prepared hash and expands the template, returning a string of HTML.

=head1 TEMPLATES

In your template, each of the form fields will correspond directly to
a C<< <!--#echo --> >> of the same name prefixed with "field-" in the
template. So, if you defined a field called "email", then you would
setup a variable called C<< <!--#echo var="field-email" --> >> in your template.

In addition, there are a couple special fields:

    <!--#echo var="js-head" -->     -  JavaScript to stick in <head>
    <!--#echo var="form-title" -->  -  The <title> of the HTML form
    <!--#echo var="form-start" -->  -  Opening <form> tag and internal fields
    <!--#echo var="form-submit" --> -  The submit button(s)
    <!--#echo var="form-reset" -->  -  The reset button
    <!--#echo var="form-end" -->    -  Just the closing </form> tag

Let's look at an example C<form.html> template we could use:

    <html>
    <head>
    <title>User Information</title>
    <!--#echo var="js-head" --><!-- this holds the JavaScript code -->
    </head>
    <!--#echo var="form-start" --><!-- this holds the initial form tag -->
    <h3>User Information</h3>
    Please fill out the following information:
    <!-- each of these <!--#echo -->'s corresponds to a field -->
    <p>Your full name: <!--#echo var="field-name" -->
    <p>Your email address: <!--#echo var="field-email" -->
    <p>Choose a password: <!--#echo var="field-password" -->
    <p>Please confirm it: <!--#echo var="field-confirm_password-->
    <p>Your home zipcode: <!--#echo var="field-zipcode -->
    <p>
    <!--#echo var="form-submit" --><!-- this holds the form submit button -->
    </form><!-- can also use "tmpl_var form-end", same thing -->

As you see, you get a C<< <!--#echo --> >> for each for field you define.

However, you may want even more control. That is, maybe you want
to specify every nitty-gritty detail of your input fields, and
just want this module to take care of the statefulness of the
values. This is no problem, since this module also provides
several other C<< <tmpl_var> >> tags as well:

    <!--#echo var="value-[field] -->   - The value of a given field
    <!--#echo var="label-[field] -->   - The human-readable label
    <!--#echo var="comment-[field] --> - Any optional comment
    <!--#echo var="error-[field] -->   - Error text if validation fails
    <!--#echo var="required-[field] --> - See if the field is required

This means you could say something like this in your template:

    <!--#echo var="label-email" -->:
    <input type="text" name="email" value="<!--#echo var="value-email" -->">
    <font size="-1"><i><!--#echo var="error-email" --></i></font>

And B<FormBuilder> would take care of the value stickiness for you,
while you have control over the specifics of the C<< <input> >> tag.
A sample expansion may create HTML like the following:

    Email:
    <input type="text" name="email" value="nate@wiger.org">
    <font size="-1"><i>You must enter a valid value</i></font>

Note, though, that this will only get the I<first> value in the case
of a multi-value parameter (for example, a multi-select list).
Multiple values (loops) in C<< CGI_SSI >> are not yet implemented.

For more information on templates, see L<HTML::Template>.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template>, L<HTML::Template>

=head1 REVISION

$Id: HTML.pm 97 2007-02-06 17:10:39Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
