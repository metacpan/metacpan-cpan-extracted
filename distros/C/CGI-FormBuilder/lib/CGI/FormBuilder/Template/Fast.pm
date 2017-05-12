
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Template::Fast;

=head1 NAME

CGI::FormBuilder::Template::Fast - FormBuilder interface to CGI::FastTemplate

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new(
        fields   => \@whatever,
        template => {
            type => 'Fast',
            root => '/path/to/templates',
            # use external files
            define => {
                form           => 'form.txt',
                field          => 'field.txt',
                invalid_field  => 'invalid_field.txt',
            },
            # or define inline
            define_nofile => {
                form => '<html><head></head><body>$START_FORM
                         <table>$FIELDS</table>$SUBMIT $END_FORM</body></html>',
                # etc.
            },
        },
   );

=cut

use Carp;
use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;
use CGI::FastTemplate;
use base 'CGI::FastTemplate';


our $VERSION = '3.10';

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my $opt   = arghash(@_);

    my $t = CGI::FastTemplate->new($opt->{root});

    # turn off strict so that undef vars show up
    # as blank in the template output
    $t->no_strict;

    # define our templates
    $t->define(%{ $opt->{define} });
    $t->define_raw($opt->{define_raw});
    $t->define_nofile($opt->{define_nofile});    

    # jam $t info FB 'engine' container
    $opt->{engine} = $t;

    return bless $opt, $class;
}

sub engine {
    return shift()->{engine};
}

sub prepare {
    my $self = shift;
    my $form = shift;

    # a couple special fields
    my %tmplvar = $form->tmpl_param;

    # Go over the fields and process each one
    for my $field ($form->field) {
        # Extract value since used often
        my @value = $field->tag_value;

        # assign this field's variables
        my $ref = {
            NAME     => $field->name,
            FIELD    => $field->tag,
            VALUE    => $value[0],       # the VALUE tag can only hold first value!
            LABEL    => $field->label,
            REQUIRED => ($field->required ? 'required' : 'optional'),
            ERROR    => $field->error,
            COMMENT  => $field->comment,
        };
        $self->{engine}->assign($ref);

        # TODO: look for special templates based on field name or type?
        if ($field->invalid) {
            $self->{engine}->parse(FIELDS => '.invalid_field');
        } else {
            $self->{engine}->parse(FIELDS => '.field');
        }

        $self->{engine}->clear_href;        
    }

    # a couple special fields    
    $self->{engine}->assign({
        TITLE      => $form->title,
        JS_HEAD    => $form->script,
        START_FORM => $form->start . $form->statetags . $form->keepextras,
        SUBMIT     => $form->submit,
        RESET      => $form->reset,
        END_FORM   => $form->end,
        %tmplvar,
    });
    $self->{engine}->parse(FORM => 'form');

    return $self;
}

sub render {
    my $self = shift;
    return ${ $self->{engine}->fetch('FORM') };
}


# End of Perl code
1;
__END__

=head1 DESCRIPTION

This engine adapts B<FormBuilder> to use C<CGI::FastTemplate>. Please
read these docs carefully, as the usage differs from other template
adapters in several important ways.

You will need to define three templates: C<form>, C<field>, and
C<invalid_field>. You can use C<define> to point to external files
(which is the recommended C<CGI::FastTemplate> style), or C<define_nofile>/
C<define_raw> to define them inline. The templates in C<define_nofile>
take precedence over C<define_raw>, and both of these take precedence
over C<define>.

    my $form = CGI::FormBuilder->new(
        # ...
        template => {
            type => 'FastTemplate',
            root => '/path/to/templates',
            define => {
                form           => 'form.txt',
                field          => 'field.txt',
                invalid_field  => 'invalid_field.txt',
            },
            # or, you can define templates directly
            define_nofile => {
                form => '<html><head></head><body>$START_FORM<table>'
                        '$FIELDS</table>$SUBMIT $END_FORM</body></html>',
                # etc.
            },
        },
        # ...
    );

If you use C<define> with external templates, you will probably
also want to define your template root directory with the C<root>
parameter.

Within each of the field templates, the following variables
are available:

    $NAME         # $field->name
    $FIELD        # $field->tag   (HTML input tag)
    $VALUE        # $field->value (first value only!)
    $LABEL        # $field->label
    $COMMENT      # $field->comment
    $ERROR        # $field->error
    $REQUIRED     # $field->required ? 'required' : 'optional'

All the fields are processed in sequence; valid fields use the 
C<field> template, and invalid fields the C<invalid_field> template.
The result from each of these is appended into the C<$FIELDS>
variable, which you should use in your C<form> template. In the 
C<form> template, you also have access to these variables:

    $TITLE        # title of the form
    $START_FORM   # opening form tag
    $SUBMIT       # the submit button
    $RESET        # the reset button
    $END_FORM     # closing form tag
    $JS_HEAD      # validation JavaScript

Note that since C<CGI::FastTemplate> doesn't use anything other than 
simple scalar variables, there are no variables corrosponding to 
the lists that other engines have (e.g. C<fields> or C<options> 
lists in C<TT2> or C<Text::Template>).

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template>, L<CGI::FastTemplate>

=head1 AUTHOR

Copyright (c) 2005-2006 Peter Eichman <peichman@cpan.org>. All Rights Reserved.

Maintained as part of C<CGI::FormBuilder> by Nate Wiger <nate@wiger.org>. 

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut
