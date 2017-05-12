package CSS::Coverage::Deparse;
{
  $CSS::Coverage::Deparse::VERSION = '0.04';
}
use Moose;
use CSS::SAC::Selector  qw(:constants);
use CSS::SAC::Condition qw(:constants);

# taken from https://metacpan.org/source/BJOERN/CSS-SAC-0.08/lib/CSS/SAC/Writer.pm
# with tweaks to:
#     ignore namespaces
#     avoid emitting spurious *

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
#        my $string;
#        if (defined $sel->NamespaceURI) {
#            if (length $sel->NamespaceURI) {
#                $string = $dh->[_nsmap_]->{$sel->NamespaceURI} . '|';
#            } # else we don't put anything and it's in the default ns
#        }
#        else {
#            $string = '*|';
#        }
#        $string .= (defined $sel->LocalName)?$sel->LocalName:'*';
#
#        return $string;

        return $sel->LocalName || '';
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
        #if (defined $cond->NamespaceURI) {
        #    if (length $cond->NamespaceURI) {
        #        $string .= $dh->[_nsmap_]->{$cond->NamespaceURI} . '|';
        #    }
        #}
        #else {
        #    $string .= '*|';
        #}
        #$string .= (defined $cond->LocalName)?$cond->LocalName:'*';

        $string .= $cond->LocalName || '';

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

1;

__END__

=pod

=head1 NAME

CSS::Coverage::Deparse

=head1 VERSION

version 0.04

=head1 AUTHOR

Shawn M Moore <code@sartak.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
