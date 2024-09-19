
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# The majority of this module's methods (including new) are
# inherited directly from ::base, since they involve things
# which are common, such as parameter parsing. The only methods
# that are individual to different fields are those that affect
# the rendering, such as script() and tag()

package CGI::FormBuilder::Field::radio;

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

    #
    # Get field from radio buttons or checkboxes.
    # Must cycle through all again to see which is checked. Yeesh.
    #

    $jsfunc .= <<EOJS;
    // $name: radio group or multiple checkboxes
    var $jsfield = null;
    var selected_$jsfield = 0;
    for (var loop = 0; loop < form.elements['$name'].length; loop++) {
        if (form.elements['$name']\[loop].checked) {
            $jsfield = form.elements['$name']\[loop].value;
            selected_$jsfield++;
EOJS

    # Add catch for "other" if applicable
    if ($self->other) {
        my $oth = $self->othername;
        $jsfunc .= <<EOJS;
            if ($jsfield == '$oth') $jsfield = form.elements['$oth'].value;
EOJS
    }

    $close_brace = <<EOJS;

        } // if
    } // for $name
EOJS

    # required?
    $close_brace .= <<EOJS if $self->required;
    if (! selected_$jsfield) {
        alertstr += '$alertstr';
        invalid++;
        invalid_fields.push('$jsfield');
    }
EOJS

    # indent the very last if/else tests so they're in the for loop
    $in = indent($idt += 2);

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

    my $checkbox_table = 0;  # toggle
    my $checkbox_col = 0;
    if ($self->columns > 0) {
        $checkbox_table = 1;
        my $c = $self->{_form}->class('_columns');
        $tag .= $self->{_form}->table(class => $c) . "\n";
    }

    belch "$self->{name}: No options specified for 'radio' field" unless @opt;
    for my $opt (@opt) {
        #  Divide up checkboxes in a user-controlled manner
        if ($checkbox_table) {
            $tag .= "  ".htmltag('tr')."\n" if $checkbox_col % $self->columns == 0;
            $tag .= '    '.htmltag('td') . $self->{_form}->font;
        }
        # Since our data structure is a series of ['',''] things,
        # we get the name from that. If not, then it's a list
        # of regular old data that we toname() if nameopts => 1
        my($o,$n) = optval($opt);

        # Must use defined() or else labels of "0" are lost
        unless (defined($n)) {
            $n = $attr->{labels}{$o};
            unless (defined($n)) {
                $n = $self->nameopts ? toname($o) : $o;
            }
        }

        ismember($o, @value) ? $attr->{checked} = 'checked'
                             : delete $attr->{checked};

        # reset some attrs
        $attr->{value} = $o;
        if (@opt == 1) {
            # single option checkboxes do not modify id
            $attr->{id} ||= tovar($attr->{name});
        } else {
            # all others add the current option name
            $attr->{id} = tovar($o eq $self->othername
                                  ? "_$attr->{name}" : "$attr->{name}_$o");
        }

        # Special event handling for our _other field
        if ($self->other && $self->javascript) {
            my $b = $self->othername;   # box
            if ($n eq $self->{_form}{messages}->form_other_default) {
                # turn on when they click the "_other" field
                $attr->{onclick} = "${jspre}other_on('$b')";
            } else {
                # turn off when they select any, well, others
                $attr->{onclick} = "${jspre}other_off('$b')";
            }
        }

        # Each radio/checkbox gets a human thingy with <label> around it
        $tag .= $self->add_before_option;
        $tag .= htmltag('input', $attr);
        $tag .= $checkbox_table
              ? (htmltag('/td')."\n    ".htmltag('td').$self->{_form}->font) : ' ';
        my $c = $self->{_form}->class('_option');
        $tag .= htmltag('label', for => $attr->{id}, class => $c)
              . ($self->cleanopts ? escapehtml($n) : $n)
              . htmltag('/label');
        $tag .= $self->add_after_option;

        $tag .= '<br />' if $self->linebreaks;

        if ($checkbox_table) {
            $checkbox_col++;
            $tag .= htmltag('/td');
            $tag .= "\n  ".htmltag('/tr') if $checkbox_col % $self->columns == 0;
        }
        $tag .= "\n";
    }
    $tag .= '  '.htmltag('/tr') if $checkbox_table && ($checkbox_col % $self->columns > 0);
    $tag .= '  '.htmltag('/table') if $checkbox_table;

    # add an additional tag for our _other field
    $tag .= ' ' . $self->othertag if $self->other;

    debug 2, "$self->{name}: generated tag = $tag";
    return $tag;       # always return scalar tag
}

1;

__END__

