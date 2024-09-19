
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# The majority of this module's methods (including new) are
# inherited directly from ::base, since they involve things
# which are common, such as parameter parsing. The only methods
# that are individual to different fields are those that affect
# the rendering, such as script() and tag()

package CGI::FormBuilder::Field::number;

use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field;
use base 'CGI::FormBuilder::Field';


our $VERSION = '3.20';

sub script {
    my $self = shift;
    my $name = $self->name;

    # The way script() works is slightly backwards: First the
    # type-specific JS DOM code is generated, then this is
    # passed as a string to Field->jsfield, which wraps this
    # in the generic handling.

    # Holders for different parts of JS code
    my $jsfunc  = '';
    my $jsfield = tovar($name);
    my $close_brace = '';
    my $in = indent(my $idt = 1);   # indent

    my $alertstr = escapejs($self->jsmessage);  # handle embedded '
    $alertstr .= '\n';

    if ($self->growable) {
        # special handling for growable, have to dynamically
        # find out how many have been created
        $jsfunc .= <<EOJS;
    // $name: growable text or file box
    var $jsfield = null;
    var entered_$jsfield = 0;
    var i = 0;
    while (1) {
        var growel = document.getElementById('$jsfield'+'_'+i);
        if (growel == null) break;  // last element
        $jsfield = growel.value;
        entered_$jsfield++;
        i++;
EOJS

        $close_brace = <<EOJS;

    } // while $name
EOJS

        # required?
        $close_brace .= <<EOJS if $self->required;
    if (! entered_$jsfield) {
        alertstr += '$alertstr';
        invalid++;
    }
EOJS
        # indent the very last if/else tests so they're in the while loop
        $in = indent($idt += 1);

    } else {

        # get value from text or other straight input
        # at least this part makes some sense
        $jsfunc .= <<EOJS;
    // $name: standard text, hidden, password, or textarea box
    var $jsfield = form.elements['$name'].value;
EOJS

    }

    return $self->jsfield($jsfunc, $close_brace, $in);
}

*render = \&tag;
sub tag {
    local $^W = 0;    # -w sucks
    my $self = shift;
    my $attr = $self->attr;

    my $jspre = $self->{_form}->jsprefix;

    my $tag   = '';
    my @value = $self->tag_value;   # sticky is different in <tag>
    my @opt   = $self->options;
    debug 2, "my(@opt) = \$field->options";

    # Add in our "Other:" option if applicable
    push @opt, [$self->othername, $self->{_form}{messages}->form_other_default]
             if $self->other;

    debug 2, "$self->{name}: generating $attr->{type} input type";

    # We iterate over each value - this is the only reliable
    # way to handle multiple form values of the same name
    # (i.e., multiple <input> or <hidden> fields)
    @value = (undef) unless @value; # this creates a single-element array

    # growable handling
    my $count = 0;  # for tracking the size of growable fields
    my $limit;      # for providing (optional) limits to growable fields 
    my $at_limit;   # have we reached the limit of a growable field?
    if ($self->growable && $self->growable ne 1) {
        $limit = $self->growable;
    }

    for my $value (@value) {
        if ($limit && $count == $limit) {
            belch "Number of supplied values (" . @value . ")"
                . " for '$attr->{name}' exceeds growable limit $limit - discarding excess";
            $at_limit = 1;
            last;
        }
        
        # setup the value
        $attr->{value} = $value;      # override
        delete $attr->{value} unless defined $value;

        if ($self->growable && $self->javascript) {
            # the inputs in growable fields need a unique id for fb_grow()
            $attr->{id} = tovar("$attr->{name}_$count");
            $count++;
        }

        # render the tag
        $tag .= htmltag('input', $attr);

        #
        # If we have options, lookup the label instead of the true value.
        # This code is reached if a field is marked 'static', since 
        # that is still rendered from ::text (here) but as a 'hidden'
        # field. These options would be leftover from a former select
        # or radio group that is now shown on a confirm() screen. Got it?
        #
        for (@opt) {
            my($o,$n) = optval($_);
            if ($o eq $value) {
                $n ||= $attr->{labels}{$o} || ($self->nameopts ? toname($o) : $o);
                $value = $n;
                last;
            }
        }

        if ($self->growable && $self->javascript) {
            # put linebreaks between the input tags in growable fields
            # this puts the "Additonal [label]" button on the same line
            # as the last input tag
            $tag .= '<br />' unless $count == @value;
        } else {
            $tag .= '<br />' if $self->linebreaks;
        }
    }
    # check to see if we just hit the limit
    $at_limit = 1 if $limit && $count == $limit;

    # add the "Additional [label]" button
    if ($self->growable && $self->javascript) {
        $tag .= ' ' . htmltag('input',
            id      => $self->growname,
            type    => 'button',
            onclick => "${jspre}grow('$attr->{name}')",
            value   => sprintf($self->{_form}{messages}->form_grow_default, $self->label),
            ( $at_limit ? ( disabled => 'disabled') : () ),
        );
    }

    # add an additional tag for our _other field
    $tag .= ' ' . $self->othertag if $self->other;

    debug 2, "$self->{name}: generated tag = $tag";
    return $tag;       # always return scalar tag
}

1;

__END__

