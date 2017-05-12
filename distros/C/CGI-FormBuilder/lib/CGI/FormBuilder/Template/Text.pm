
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Template::Text;

=head1 NAME

CGI::FormBuilder::Template::Text - FormBuilder interface to Text::Template

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new(
                    fields   => \@fields,
                    template => {
                        type => 'Text',
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
use Text::Template;


our $VERSION = '3.10';

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my $opt   = arghash(@_);

    my $tt_engine = $opt->{engine} || {};
    unless (UNIVERSAL::isa($tt_engine, 'Text::Template')) {
        $tt_engine->{&tt_param_name('type',%$tt_engine)}   ||= $opt->{TYPE} || 'FILE';
        $tt_engine->{&tt_param_name('source',%$tt_engine)} ||= $opt->{template} || $opt->{source} ||
            puke "Text::Template source not specified, use the 'template' option";
        $tt_engine->{&tt_param_name('delimiters',%$tt_engine)} ||= [ '<%','%>' ];
        $opt->{engine} = Text::Template->new(%$tt_engine) || puke $Text::Template::ERROR;
    }

    return bless $opt, $class;
}

sub engine {
    return shift()->{engine};
}

# This sub helps us to support all of Text::Template's argument naming conventions
sub tt_param_name {
    my ($arg, %h) = @_;
    my ($key) = grep { exists $h{$_} } ($arg, "\u$arg", "\U$arg", "-$arg", "-\u$arg", "-\U$arg");
    return $key || $arg;
}

sub render {
    my $self = shift;
    my $tvar = shift || puke "Missing template expansion hashref (\$form->prepare failed?)";

    my $tt_data;
    if (ref $self->{data} eq 'ARRAY') {
        $tt_data = $self->{data};
    } else {
        $tt_data = [ $self->{data} ];
    }
    my $tt_var  = $self->{variable};      # optional var for nesting

    if ($tt_var) {
        push @$tt_data, { $tt_var => $tvar };
    } else {
        push @$tt_data, $tvar;
    }

    my $tt_fill_in = $self->{fill_in} || {};
    my $tt_fill_in_hash = $tt_fill_in->{&tt_param_name('hash',%$tt_fill_in)} || {};
    if (ref($tt_fill_in_hash) eq 'ARRAY') {
        push @$tt_fill_in_hash, @$tt_data;
    } else {
        $tt_fill_in_hash = [ $tt_fill_in_hash, @$tt_data ];
    }

    $tt_fill_in_hash = {} unless @$tt_fill_in_hash;
    $tt_fill_in->{&tt_param_name('hash',%$tt_fill_in)} = $tt_fill_in_hash;

    my $tt_output = $self->{engine}->fill_in(%$tt_fill_in)
        || puke "Text::Template expansion failed: $Text::Template::ERROR";

    return $tt_output;
}

1;
__END__

=head1 DESCRIPTION

This engine adapts B<FormBuilder> to use C<Text::Template>. Usage is very
similar to Template Toolkit:

    my $form = CGI::FormBuilder->new(
                    fields => \@fields,
                    template => {
                        type => 'Text',           # use Text::Template
                        template => 'form.tmpl',
                    }
               );

The default options passed into C<< Text::Template->new() >> with this
calling form are:

    TYPE   => 'FILE'
    SOURCE => 'form.tmpl'
    DELIMITERS => ['<%','%>']

As these params are passed for you, your template will look very similar to
ones used by Template Toolkit and C<HTML::Mason> (the Text::Template default
delimiters are C<{> and C<}>, but using alternative delimiters speeds it up by
about 25%, and the C<< <% >> and C<< %> >> delimiters are good,
familiar-looking alternatives).

The following methods are provided (usually only used internally):

=head2 engine

Returns a reference to the C<Text::Template> object

=head2 prepare

Returns a hash of all the fields ready to be rendered.

=head2 render

Uses the prepared hash and expands the template, returning a string of HTML.

=head1 TEMPLATES

    <% $jshead %>  -  JavaScript to stick in <head>
    <% $title  %>  -  The <title> of the HTML form
    <% $start  %>  -  Opening <form> tag and internal fields
    <% $submit %>  -  The submit button(s)
    <% $reset  %>  -  The reset button
    <% $end    %>  -  Closing </form> tag
    <% $fields %>  -  List of fields
    <% $field  %>  -  Hash of fields (for lookup by name)

Note that you refer to variables with a preceding C<$>, just like in Perl.
Like Template Toolkit, you can specify a variable to place fields under:

    my $form = CGI::FormBuilder->new(
        fields => \@fields,
        template => {
             type => 'Text',
             template => 'form.tmpl',
             variable => 'form'
        },
    );

Unlike Template Toolkit, though, these will not be placed in OO-style,
dot-separated vars. Instead, a hash will be created which you then reference:

    <% $form{jshead} %>
    <% $form{start}  %>
    etc.

And field data is in a hash-of-hashrefs format:

    For a field named...  The field data is in...
    --------------------  -----------------------
    job                   <% $form{field}{job}   %]
    size                  <% $form{field}{size}  %]
    email                 <% $form{field}{email} %]

Since C<Text::Template> looks so much like Perl, you can access individual
elements and create variables like so:

    <%
        my $myfield = $form{field}{email};
        $myfield->{label};      # text label
        $myfield->{field};      # field input tag
        $myfield->{value};      # first value
        $myfield->{values};     # list of all values
        $myfield->{options};    # list of all options
        $myfield->{required};   # required flag
        $myfield->{invalid};    # invalid flag
        $myfield->{error};      # error string if invalid
    %>

    <%
        for my $field (@{$form{fields}}) {
            $OUT .= "<tr>\n<td>" . $field->{label} . "</td> <td>" 
                                 . $field->{field} . "</td>\n<tr>";
        }
    %>

In addition, when using the engine option, you supply an existing
Text::Template object or a hash of parameters to be passed to C<new()>.
For example, you can ask for different delimiters yourself:

    my $form = CGI::FormBuilder->new(
        fields => \@fields,
        template => {
             type => 'Text',
             template => 'form.tmpl',
             variable => 'form',
             engine   => {
                DELIMITERS => [ '[@--', '--@]' ],
             },
             data => {
                  version => 1.23,
                  author  => 'Fred Smith',
             },
        },
    );

If you pass a hash of parameters, you can override the C<TYPE> and C<SOURCE> parameters,
as well as any other C<Text::Template> options. For example, you can pass in a string
template with C<< TYPE => STRING >> instead of loading it from a file. You must
specify B<both> C<TYPE> and C<SOURCE> if doing so.  The good news is this is trivial:

    my $form = CGI::FormBuilder->new(
        fields => \@fields,
        template => {
             type => 'Text',
             variable => 'form',
             engine   => {
                  TYPE => 'STRING',
                  SOURCE => $string,
                  DELIMITERS => [ '[@--', '--@]' ],
             },
             data => {
                  version => 1.23,
                  author  => 'Fred Smith',
             },
        },
    );

If you get the crazy idea to let users of your application pick the template file
(strongly discouraged) and you're getting errors, look at the C<Text::Template>
documentation for the C<UNTAINT> feature.

Also, note that C<Text::Template>'s C<< PREPEND => 'use strict;' >> option is not
recommended due to the dynamic nature for C<FormBuilder>.  If you use it, then you'll
have to declare each variable that C<FormBuilder> puts into your template with
C<< use vars qw($jshead' ... etc); >>

If you're really stuck on this, though, a workaround is to say:

    PREPEND => 'use strict; use vars qw(%form);'

and then set the option C<< variable => 'form' >>. That way you can have strict Perl
without too much hassle, except that your code might be exhausting to look at :-).
Things like C<$form{field}{your_field_name}{field}> end up being all over the place,
instead of the nicer short forms.

Finally, when you use the C<data> template option, the keys you specify will be available
to the template as regular variables. In the above example, these would be
C<< <% $version %> >> and C<< <% $author %> >>. And complex datatypes are easy:

    data => {
            anArray => [ 1, 2, 3 ],
            aHash => { orange => 'tangy', chocolate => 'sweet' },
    }

This becomes the following in your template:

    <%
        @anArray;    # you can use $myArray[1] etc.
        %aHash;      # you can use $myHash{chocolate} etc.
    %>

For more information, please consult the C<Text::Template> documentation.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template>, L<Text::Template>

=head1 REVISION

$Id: Text.pm 100 2007-03-02 18:13:13Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

Text::Template support is due to huge contributions by Jonathan Buhacoff.
Thanks man.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
