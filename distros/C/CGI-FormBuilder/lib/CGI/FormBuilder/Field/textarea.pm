
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

# The majority of this module's methods (including new) are
# inherited directly from ::base, since they involve things
# which are common, such as parameter parsing. The only methods
# that are individual to different fields are those that affect
# the rendering, such as script() and tag()

package CGI::FormBuilder::Field::textarea;

use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;
use CGI::FormBuilder::Field::text;
use base 'CGI::FormBuilder::Field::text';


our $VERSION = '3.10';

*render = \&tag;
sub tag {
    local $^W = 0;    # -w sucks
    my $self = shift;
    my $attr = $self->attr;

    my $jspre = $self->{_form}->jsprefix;

    my $tag   = '';
    my @value = $self->tag_value;   # sticky is different in <tag>

    delete $attr->{type};           # <textarea type="textarea"> invalid

    my $text = join "\n", @value;
    $tag .= htmltag('textarea', $attr) . escapehtml($text) . '</textarea>';

    debug 2, "$self->{name}: generated tag = $tag";
    return $tag;       # always return scalar tag
}

1;

__END__

