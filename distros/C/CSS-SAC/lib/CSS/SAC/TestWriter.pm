
###
# SAC Test Writer - the writer used in the tests
# Robin Berjon <robin@knowscape.com>
# 23/04/2001
###

package CSS::SAC::TestWriter;
use strict;
use vars qw($VERSION $ident $spacer);
$VERSION = '0.01';
$spacer = '  ';

use CSS::SAC::Selector      qw(:constants);
use CSS::SAC::Condition     qw(:constants);
use CSS::SAC::LexicalUnit   qw(:constants);


#---------------------------------------------------------------------#
# build the fields for an array based object
#---------------------------------------------------------------------#
use Class::ArrayObjects define => {
                                   fields => [qw(
                                                 _nsmap_
                                                 _ref_
                                               )],
                                  };
#---------------------------------------------------------------------#



### Constructor #######################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# CSS::SAC::TestWriter->new(\$stringref)
# creates a new sac doc handler
#---------------------------------------------------------------------#
sub new {
    my $class = ref($_[0])?ref(shift):shift;
    my $ref = shift;

    # prepare the object and the namespace map
    $ident = 1;
    my $self = [];
    $self->[_nsmap_] = {};
    $self->[_ref_] = $ref;

    return bless $self, $class;
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Constructor #######################################################



### Callbacks #########################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# start_document
#---------------------------------------------------------------------#
sub start_document {
    my $dh = shift;
    $dh->[_ref_] .= $spacer x $ident . "Stylesheet:\n";
    $ident++;
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# end_document
#---------------------------------------------------------------------#
sub end_document {
    my $dh = shift;
    $ident--;
    $dh->[_ref_] .= $spacer x $ident . "End.\n";
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# start_selector($sel_list)
#---------------------------------------------------------------------#
sub start_selector {
    my $dh = shift;
    my $sel_list = shift;

    $dh->[_ref_] .= $spacer x $ident . "Style Rule:\n";
    $ident++;
    $dh->[_ref_] .= $spacer x $ident . "Selector:\n";
    $ident++;
    $dh->[_ref_] .= $spacer x $ident . "Chain:\n";
    $ident++;

    my @sel_strings;
    for my $sel (@$sel_list) {
        $dh->[_ref_] .= $spacer x $ident . $dh->stringify_selector($sel) . "\n";
    }
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# end_selector($sel_list)
#---------------------------------------------------------------------#
sub end_selector {
    my $dh = shift;
    my $sel_list = shift;
    $dh->[_out_]->($dh, "\n}\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# property($name,$lu,$important)
#---------------------------------------------------------------------#
sub property {
    my $dh = shift;
    my $name = shift;
    my $lu = shift;
    my $important = shift;

    $dh->[_out_]->($dh, "\n\t$name:\t");
    while (@$lu) {
        my $val = shift @$lu;
        $dh->[_out_]->($dh, $dh->stringify_lexical_unit($val));

        if ($lu->[0]) {
            if ($lu->[0]->is_type(OPERATOR_COMMA)) {
                shift @$lu;
                $dh->[_out_]->($dh, ', ');
            }
            elsif ($lu->[0]->is_type(OPERATOR_SLASH)) {
                shift @$lu;
                $dh->[_out_]->($dh, '/');
            }
            else {
                $dh->[_out_]->($dh, ' ');
            }
        }
    }
    $dh->[_out_]->($dh, (($important)?' !important':'') . ';');
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# ignorable_at_rule($at_rule)
#---------------------------------------------------------------------#
sub ignorable_at_rule {
    my $dh = shift;
    my $at_rule = shift;

    $dh->[_out_]->($dh, "\n/* $at_rule */\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# import_style($uri,\@media)
#---------------------------------------------------------------------#
sub import_style {
    my $dh = shift;
    my $uri = shift;
    my $media = shift;

    $dh->[_out_]->($dh, "\n\@import url($uri) " . join(', ', @$media) . ";\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# namespace_declaration($prefix,$uri)
#---------------------------------------------------------------------#
sub namespace_declaration {
    my $dh = shift;
    my $prefix = shift;
    my $uri = shift;

    # we need to provide a global ns map here
    if (defined $prefix) {
        $dh->[_nsmap_]->{$uri} = $prefix;
    }

    $dh->[_out_]->($dh, "\n\@namespace" . ((defined $prefix)?" $prefix ":' ') . "url($uri);\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# start_media(\@media)
#---------------------------------------------------------------------#
sub start_media {
    my $dh = shift;
    my $media = shift;

    $dh->[_out_]->($dh, "\n\@media " . join(', ', @$media) . " {\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# end_media(\@media)
#---------------------------------------------------------------------#
sub end_media {
    my $dh = shift;
    my $media = shift;

    $dh->[_out_]->($dh, "\n}\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# comment($comment)
#---------------------------------------------------------------------#
sub comment {
    my $dh = shift;
    my $comment = shift;

    $dh->[_out_]->($dh, "/* $comment */");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# charset($charset)
#---------------------------------------------------------------------#
sub charset {
    my $dh = shift;
    my $charset = shift;

    $dh->[_out_]->($dh, "\@charset '$charset';\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# start_font_face
#---------------------------------------------------------------------#
sub start_font_face {
    my $dh = shift;

    $dh->[_out_]->($dh, "\n\@font-face {\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# end_font_face
#---------------------------------------------------------------------#
sub end_font_face {
    my $dh = shift;
    $dh->[_out_]->($dh, "\n}\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# start_page($name,$pseudo_page)
#---------------------------------------------------------------------#
sub start_page {
    my $dh = shift;
    my $name = shift;
    my $pseudo_page = shift;

    $dh->[_out_]->($dh, "\n\@page " . ((defined $name)?"$name ":'') .
                        ((defined $pseudo_page)?":$pseudo_page ":'') . "{\n");
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# end_page($name,$pseudo_page)
#---------------------------------------------------------------------#
sub end_page {
    my $dh = shift;
    my $name = shift;
    my $pseudo_page = shift;

    $dh->[_out_]->($dh, "\n}\n");
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Callbacks #########################################################



### Helpers ###########################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# stringify_selector($sel)
# returns a string of that selector
#---------------------------------------------------------------------#
sub stringify_selector {
    my $dh = shift;
    my $sel = shift;

    # child
    if ($sel->is_type(CHILD_SELECTOR)) {
        return $dh->stringify_selector($sel->AncestorSelector)
               . ' > ' .
               $dh->stringify_selector($sel->SimpleSelector);
    }

    # descendant
    elsif ($sel->is_type(DESCENDANT_SELECTOR)) {
        return $dh->stringify_selector($sel->AncestorSelector)
               . ' ' .
               $dh->stringify_selector($sel->SimpleSelector);
    }

    # direct adjacent
    elsif ($sel->is_type(DIRECT_ADJACENT_SELECTOR)) {
        return $dh->stringify_selector($sel->Selector)
               . ' + ' .
               $dh->stringify_selector($sel->SiblingSelector);
    }

    # indirect adjacent
    elsif ($sel->is_type(INDIRECT_ADJACENT_SELECTOR)) {
        return $dh->stringify_selector($sel->Selector)
               . ' ~ ' .
               $dh->stringify_selector($sel->SiblingSelector);
    }

    # conditional
    elsif ($sel->is_type(CONDITIONAL_SELECTOR)) {
        return $dh->stringify_selector($sel->SimpleSelector)
               .
               $dh->stringify_condition($sel->Condition);
    }

    # negative
    elsif ($sel->is_type(NEGATIVE_SELECTOR)) {
        return ':not(' . $dh->stringify_selector($sel->SimpleSelector) . ')';
    }

    # element
    elsif ($sel->is_type(ELEMENT_NODE_SELECTOR)) {
        my $string;
        if (defined $sel->NamespaceURI) {
            if (length $sel->NamespaceURI) {
                $string = $dh->[_nsmap_]->{$sel->NamespaceURI} . '|';
            } # else we don't put anything and it's in the default ns
        }
        else {
            $string = '*|';
        }
        $string .= (defined $sel->LocalName)?$sel->LocalName:'*';

        return $string;
    }

    # pseudo element
    elsif ($sel->is_type(PSEUDO_ELEMENT_SELECTOR)) {
        return '::' . $sel->LocalName;
    }

    # error ?
    else {
        warn "unknown selector type";
    }
}
#---------------------------------------------------------------------#



#---------------------------------------------------------------------#
# stringify_condition($sel)
# returns a string of that condition
#---------------------------------------------------------------------#
sub stringify_condition {
    my $dh = shift;
    my $cond = shift;

    # and
    if ($cond->is_type(AND_CONDITION)) {
        return $dh->stringify_condition($cond->FirstCondition)
               .
               $dh->stringify_condition($cond->SecondCondition);
    }

    # attr
    elsif (
            $cond->is_type(ATTRIBUTE_CONDITION)              or
            $cond->is_type(BEGIN_HYPHEN_ATTRIBUTE_CONDITION) or
            $cond->is_type(ONE_OF_ATTRIBUTE_CONDITION)       or
            $cond->is_type(STARTS_WITH_ATTRIBUTE_CONDITION)  or
            $cond->is_type(ENDS_WITH_ATTRIBUTE_CONDITION)    or
            $cond->is_type(CONTAINS_ATTRIBUTE_CONDITION)
          ) {
        my $string = '[';

        # the name
        if (defined $cond->NamespaceURI) {
            if (length $cond->NamespaceURI) {
                $string .= $dh->[_nsmap_]->{$cond->NamespaceURI} . '|';
            }
        }
        else {
            $string .= '*|';
        }
        $string .= (defined $cond->LocalName)?$cond->LocalName:'*';

        # the value
        if ($cond->Specified) {
            my $op = '=';
            $cond->is_type(BEGIN_HYPHEN_ATTRIBUTE_CONDITION) and $op = '|=';
            $cond->is_type(ONE_OF_ATTRIBUTE_CONDITION)       and $op = '~=';
            $cond->is_type(STARTS_WITH_ATTRIBUTE_CONDITION)  and $op = '^=';
            $cond->is_type(ENDS_WITH_ATTRIBUTE_CONDITION)    and $op = '$=';
            $cond->is_type(CONTAINS_ATTRIBUTE_CONDITION)     and $op = '*=';

            # find the right op depending on the attr type

            $string .= "$op'" . $cond->Value . "'";
        }

        $string .= ']';

        return $string;
    }

    # class
    elsif ($cond->is_type(CLASS_CONDITION)) {
        return '.' . $cond->Value;
    }

    # content
    elsif ($cond->is_type(CONTENT_CONDITION)) {
        return ":contains('" . $cond->Data . "')";
    }

    # id
    elsif ($cond->is_type(ID_CONDITION)) {
        return '#' . $cond->Value;
    }

    # lang
    elsif ($cond->is_type(LANG_CONDITION)) {
        return ":lang(" . $cond->Lang . ")";
    }

    # negative
    elsif ($cond->is_type(NEGATIVE_CONDITION)) {
        return ":not(" . $dh->stringify_condition($cond->Condition) . ")";
    }

    # only child
    elsif ($cond->is_type(ONLY_CHILD_CONDITION)) {
        return ':only-child';
    }

    # only of type
    elsif ($cond->is_type(ONLY_TYPE_CONDITION)) {
        return ':only-of-type';
    }

    # root
    elsif ($cond->is_type(IS_ROOT_CONDITION)) {
        return ':root';
    }

    # empty
    elsif ($cond->is_type(IS_EMPTY_CONDITION)) {
        return ':empty';
    }

    # pseudo-class
    elsif ($cond->is_type(PSEUDO_CLASS_CONDITION)) {
        return ':' .  $cond->Value;
    }

    # positional
    elsif ($cond->is_type(POSITIONAL_CONDITION)) {
        my $string;

        # the second part right
        if ($cond->Type) {
            $string = 'of-type';
        }
        else {
            $string = 'child';
        }

        # get the first part right
        if ($cond->Position == 1) {
            return ':first-' . $string;
        }
        elsif ($cond->Position == -1) {
            return ':last-' . $string;
        }
        else {
            $string = ':nth-' . $string;
        }

        # add the expression
        $string .= '(' . $cond->Position . ')';

        return $string;
    }
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# stringify_lexical_unit($sel)
# returns a string of that lexical unit
#---------------------------------------------------------------------#
sub stringify_lexical_unit {
    my $dh = shift;
    my $lu = shift;

    # dimensions
    if (
        $lu->is_type(CENTIMETER)    or $lu->is_type(DEGREE)     or
        $lu->is_type(DIMENSION)     or $lu->is_type(EM)         or
        $lu->is_type(EX)            or $lu->is_type(GRADIAN)    or
        $lu->is_type(HERTZ)         or $lu->is_type(INCH)       or
        $lu->is_type(KILOHERTZ)     or $lu->is_type(MILLIMETER) or
        $lu->is_type(MILLISECOND)   or $lu->is_type(PERCENTAGE) or
        $lu->is_type(PICA)          or $lu->is_type(PIXEL)      or
        $lu->is_type(POINT)         or $lu->is_type(RADIAN)     or
        $lu->is_type(SECOND)
       ) {
        return $lu->Value . $lu->DimensionUnitText;
    }

    # functions
    elsif (
            $lu->is_type(ATTR)      or $lu->is_type(COUNTER_FUNCTION)  or
            $lu->is_type(URI)       or $lu->is_type(COUNTERS_FUNCTION) or
            $lu->is_type(FUNCTION)  or $lu->is_type(RECT_FUNCTION)
          ) {
        return $lu->FunctionName . '(' . $lu->Value . ')';
    }

    # inherit
    elsif ($lu->is_type(INHERIT)) {
        return 'inherit';
    }

    # ident, number, unicoderange
    elsif ($lu->is_type(IDENT) or $lu->is_type(INTEGER) or
           $lu->is_type(REAL) or $lu->is_type(UNICODERANGE)) {
        return $lu->Value;
    }

    # string
    elsif ($lu->is_type(STRING_VALUE)) {
        return "'" . $lu->Value . "'";
    }

    # rgbcolor
    elsif ($lu->is_type(RGBCOLOR)) {
        if ($lu->FunctionName eq 'rgb') {
            return 'rgb(' . $lu->Value . ')';
        }
        else {
            return '#' . $lu->Value;
        }
    }
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Helpers ###########################################################



### Error Callbacks ###################################################
#                                                                     #
#                                                                     #


#---------------------------------------------------------------------#
# warning($warning)
#---------------------------------------------------------------------#
sub warning {
    my $eh = shift;
    my $warning = shift;

    warn "[WARN] $warning\n";
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# error($error)
#---------------------------------------------------------------------#
sub error {
    my $eh = shift;
    my $error = shift;

    warn "[ERROR] $error\n";
}
#---------------------------------------------------------------------#


#---------------------------------------------------------------------#
# fatal_error($error)
#---------------------------------------------------------------------#
sub fatal_error {
    my $eh = shift;
    my $error = shift;

    die "[FATAL] $error\n";
}
#---------------------------------------------------------------------#


#                                                                     #
#                                                                     #
### Error Callbacks ###################################################

1;

=pod

=head1 SYNOPSIS

  use CSS::SAC qw();
  use CSS::SAC::Writer ();

  ### create a doc handler using the writer
  # options can also be ioref and string (given a stringref) in which
  # case it'll write to the filehandle or to the string.
  # Yes, it also works as an ErrorHandler (though not a good one)

  my $doc_h = CSS::SAC::Writer->new({ filename => 'out.css' });
  my $sac = CSS::SAC->new({
                           DocumentHandler => $doc_h,
                           ErrorHandler    => $doc_h,
                         });

  # generate a stream of events
  $sac->parse({ filename => 'foo.css' });

=head1 DESCRIPTION

This is a simplistic SAC handler that demonstrates how one may use
CSS::SAC. More useful ones will follow. Obviously, it isn't documented
much, given that its value resides mostly in the source code :)

You can of course still use it as a way to write CSS from a SAC stream.

=head1 AUTHOR

Robin Berjon <robin@knowscape.com>

This module is licensed under the same terms as Perl itself.

=cut

