
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# The majority of this module's methods (including new) are
# inherited directly from ::base, since they involve things
# which are common, such as parameter parsing. The only methods
# that are individual to different fields are those that affect
# the rendering, such as script() and tag()

package CGI::FormBuilder::Field::select;

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

    # Get value for field from select list
    # Always assume it's multiple to guarantee we get all values
    $jsfunc .= <<EOJS;
    // $name: select list, always assume it's multiple to get all values
    var $jsfield = null;
    var selected_$jsfield = 0;
    for (var loop = 0; loop < form.elements['$name'].options.length; loop++) {
        if (form.elements['$name'].options[loop].selected) {
            $jsfield = form.elements['$name'].options[loop].value;
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

    $close_brace .= <<EOJS if $self->required;
    if (! selected_$jsfield) {
        alertstr += '$alertstr';
        invalid++;
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

    # First the top-level select
    delete $attr->{type};     # type="select" invalid
    $self->multiple ? $attr->{multiple} = 'multiple'
                    : delete $attr->{multiple};

    belch "$self->{name}: No options specified for 'select' field" unless @opt;

    # Prefix options with "-select-", unless selectname => 0
    if ($self->{_form}->smartness && ! $attr->{multiple}  # set above
        && $self->selectname ne 0)
    {
        # Use selectname if => "choose" or messages otherwise
        my $name = $self->selectname =~ /\D+/
                 ? $self->selectname
                 : $self->{_form}{messages}->form_select_default;
        unshift @opt, ['', $name]
    }

    # Special event handling for our _other field
    if ($self->other && $self->javascript) {
        my $b = $self->othername;   # box
        # w/o newlines
        $attr->{onchange} .= "if (this.selectedIndex + 1 == this.options.length) { "
                           . "${jspre}other_on('$b') } else { ${jspre}other_off('$b') }";
    }

    # render <select> tag
    $tag .= htmltag('select', $attr) . "\n";

    # Stuff for optgroups
    my $optgroups = $self->optgroups;
    my $lastgroup = '';
    my $didgroup  = 0;
    my $foundit   = 0;  # found option in list? (for "Other:")
    debug 2, "$self->{name}: rendering options: (@opt)";
    while (defined(my $opt = shift @opt)) {
        # Since our data structure is a series of ['',''] things,
        # we get the name from that. If not, then it's a list
        # of regular old data that we toname() if nameopts => 1
        my($o,$n,$g) = optval($opt);
        debug 2, "optval($opt) = ($o,$n,$g)";

        # Must use defined() or else labels of "0" are lost
        unless (defined($n)) {
            $n = $attr->{labels}{$o};
            unless (defined($n)) {
                $n = $self->nameopts ? toname($o) : $o;
            }
        }

        # If we asked for optgroups => 1, then we add an our
        # <optgroup> each time our $lastgroup changes
        if ($optgroups) {
            if ($g && $g ne $lastgroup) {
                # close previous optgroup and start a new one
                $tag .= "  </optgroup>\n" if $didgroup;
                $lastgroup = $g;
                if (UNIVERSAL::isa($optgroups, 'HASH')) {
                    # lookup by name
                    $g = exists $optgroups->{$g} ? $optgroups->{$g} : $g;
                } elsif ($self->nameopts) {
                    $g = toname($g);
                }
                $tag .= '  ' . htmltag('optgroup', label => $g) . "\n";
                $didgroup++;
            } elsif (!$g && $lastgroup) {
                # finished an optgroup but next option is not in one
                $tag .= "  </optgroup>\n" if $didgroup;
                $didgroup = 0;  # reset counter
            }
        }

        my %slct;
        if (ismember($o, @value) ||
            (! $foundit && $self->other &&  @value && ! @opt))
        {
            debug 2, "$self->{name}: found $o as member of (@value), setting 'selected'";
            %slct = (selected => 'selected');
            $foundit++;
        }
        $slct{value} = $o;

        debug 2, "$self->{name}: tag .= option $n";
        $tag .= '  '
              . htmltag('option', %slct)
              . ($self->cleanopts ? escapehtml($n) : $n)
              . "</option>\n";

    }
    $tag .= "  </optgroup>\n" if $didgroup;
    $tag .= '  </select>';

    # add an additional tag for our _other field
    $tag .= ' ' . $self->othertag if $self->other;

    debug 2, "$self->{name}: generated tag = $tag";
    return $tag;       # always return scalar tag
}

1;

__END__

