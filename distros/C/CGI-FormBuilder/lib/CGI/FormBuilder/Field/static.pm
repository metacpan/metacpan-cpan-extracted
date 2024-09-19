
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# static fields are a special FormBuilder type that turns any
# normal field into a hidden field with the value printed.
# As such, the code has to basically handle all field types.

package CGI::FormBuilder::Field::static;

use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field;
use base 'CGI::FormBuilder::Field';


our $VERSION = '3.20';

sub script {
    return '';        # static fields get no messages
}

*render = \&tag;
sub tag {
    local $^W = 0;    # -w sucks
    my $self = shift;
    my $attr = $self->attr;

    my $jspre = $self->{_form}->jsprefix;

    my @tag;
    my @value = $self->tag_value;   # sticky is different in <tag>
    my @opt   = $self->options;
    debug 2, "my(@opt) = \$field->options";

    # Add in our "Other:" option if applicable
    push @opt, [$self->othername, $self->{_form}{messages}->form_other_default]
             if $self->other;

    debug 2, "$self->{name}: generating $attr->{type} input type";

    # static fields are actually hidden
    $attr->{type} = 'hidden';

    # We iterate over each value - this is the only reliable
    # way to handle multiple form values of the same name
    # (i.e., multiple <input> or <hidden> fields)
    @value = (undef) unless @value; # this creates a single-element array

    for my $value (@value) {
        my $tmp = '';
 
        # setup the value
        $attr->{value} = $value;      # override
        delete $attr->{value} unless defined $value;

        # render the tag
        $tmp .= htmltag('input', $attr);

        #
        # If we have options, lookup the label instead of the true value
        # to print next to the field. This will happen when radio/select
        # lists are converted to 'static'.
        #
        for (@opt) {
            my($o,$n) = optval($_);
            if ($o eq $value) {
                $n ||= $attr->{labels}{$o} || ($self->nameopts ? toname($o) : $o);
                $value = $n;
                last;
            }
        }

        # print the value out too when in a static context
        $tmp .= $self->cleanopts ? escapehtml($value) : $value;
        push @tag, $tmp;
    }

    debug 2, "$self->{name}: generated tag = @tag";
    return join ' ', @tag;       # always return scalar tag
}

1;

__END__

