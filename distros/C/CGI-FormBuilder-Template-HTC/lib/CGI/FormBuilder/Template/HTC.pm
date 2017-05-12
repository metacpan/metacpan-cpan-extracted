package CGI::FormBuilder::Template::HTC;
$VERSION = '0.02';
use strict;
use warnings;
use Data::Dumper;
use Carp qw(croak carp);


use CGI::FormBuilder::Util;
use HTML::Template::Compiled;

sub engine_class { 'HTML::Template::Compiled' }

sub new {
    my ($class, @opts) = @_;
    my $opt = arghash(@opts);
    bless $opt, $class;
    $opt->{engine} = $opt->engine_class()->new(%$opt);
    return $opt;
}

sub engine {
    return $_[0]->{engine};
}

sub render {
    my $self = shift;
    my $tvar = shift
        || puke "Missing template expansion hashref (\$form->prepare failed?)";

    my $htc_data = $self->{data} || {};
    my $htc_var  = $self->{variable};     # optional var for nesting

    if ($htc_var) {
        $htc_data->{$htc_var} = $tvar;
    }
    else {
        $htc_data = { %$htc_data, %$tvar };
    }
    my $htc_output;                       # growing a scalar is so C-ish

    $self->{engine}->param(%$htc_data);
    my $output = $self->{engine}->output();

    # string HTML output
    return $output;
} ## end sub render

1;

__END__

=pod

=head1 NAME

CGI::FormBuilder::Template::HTC

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new(
        fields   => \@fields,
        template => {
            type     => 'HTC',
            filename => 'form.tmpl',
            variable => 'form',
            # other HTC options
        },
        data => {
            # other parameters for the template object
        },
    );

=head1 DESCRIPTION

This engine adapts FormBuilder to use L<HTML::Template::Compiled>. It
works similar to L<CGI::FormBuilder::Template::TT2>, not like
L<CGI::FormBuilder::Template::HTML>, because HTC can use the dot-syntax
for accessing hash-keys.

=head1 METHODS

=over 4

=item engine

Returns the L<HTML::Template::Compiled> object.

=item render

Uses the prepared hash and expands the template, returning a string of HTML.

=item new

=item engine_class

Returns the class of the template engine (C<HTML::Template::Compiled>)

=back

=head1 TEMPLATES

The template might look something like this (this is HTC syntax):

    <html>
    <head>
      <title>[%= form.title %]</title>
      [%= form.jshead %]
    </head>
    <body>
      [%= form.start %]
      <table>
        [%loop form.fields %]
        <tr valign="top">
          <td>
            [%if required %]
                <b>[%= label %]</b>
            [%else %]
                [%= label %]
            [%/if %]
          </td>
          <td>
            [%if invalid %]
            Missing or invalid entry, please try again.
            <br/>
            [%/if %]

        [%= field %]
      </td>
    </tr>
        [%/loop %]
        <tr>
          <td colspan="2" align="center">
            [%= form.submit %] [%= form.reset %]
          </td>
        </tr>
      </table>
      [%= form.end %]
    </body>
    </html>

By default, all the form and field information are accessible through simple variables.

    [%= jshead %]  -  JavaScript to stick in <head>
    [%= title  %]  -  The <title> of the HTML form
    [%= start  %]  -  Opening <form> tag and internal fields
    [%= submit %]  -  The submit button(s)
    [%= reset  %]  -  The reset button
    [%= end    %]  -  Closing </form> tag
    [%= fields %]  -  List of fields
    [%= field  %]  -  Hash of fields (for lookup by name)

You can specify the variable option to have all these variables
accessible under a certain namespace. For example:

    my $form = CGI::FormBuilder->new(
        fields => \@fields,
        template => {
             type => 'HTC',
             filename => 'form.tmpl',
             variable => 'form'
        },
    );

With variable set to form the variables are accessible as:

    [%= form.jshead %]
    [%= form.start  %]
    etc.

You can access individual fields via the field variable.

    For a field named...  The field data is in...
    --------------------  -----------------------
    job                   [%= form.field.job   %]
    size                  [%= form.field.size  %]
    email                 [%= form.field.email %]

Each field contains various elements. For example:

    [%with form.field.email %]

    [%= label    %]  # text label
    [%= field    %]  # field input tag
    [%= value    %]  # first value
    [%= values   %]  # list of all values
    [%= option   %]  # first value
    [%= options  %]  # list of all values
    [%= required %]  # required flag
    [%= invalid  %]  # invalid flag

    [%/with %]

The fields variable contains a list of all the fields in the form.
To iterate through all the fields in order, you could do something like this:

    [%loop form.fields %]
    <tr>
     <td>[%= label %]</td> <td>[%= field %]</td>
    </tr>
    [%/loop %]

If you want to customise any of the HTC options, you can
add options to the C<template> option. You can also set the data
item to define any additional
variables you want accesible when the template is processed.

    my $form = CGI::FormBuilder->new(
        fields   => \@fields,
        template => {
            type     => 'HTC',
            filename => 'form.tmpl',
            variable => 'form',
            # other HTC options
            cache_dir => '/path/to/cachedir',
        },
        data => {
              version => 1.23,
              author  => 'Fred Smith',
        },
    );

For further details on using the Template Toolkit, see 

=head1 SEE ALSO

=over 4

=item L<CGI::FormBuilder>

=item L<CGI::FormBuilder::Template::TT2>

=item L<CGI::FormBuilder::Template::HTML>

=item L<HTML::Template::Compiled>

=back

=head1 AUTHOR

Tina Mueller

=head1 CREDITS

Nate Wiger, who is the author of L<CGI::FormBuilder>. I copied more or less
the whole documentation and some of the tests.

pfuschi from perl-community.de for the idae

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Tina Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut

