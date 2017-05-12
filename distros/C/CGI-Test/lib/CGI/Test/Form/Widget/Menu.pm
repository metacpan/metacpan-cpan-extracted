package CGI::Test::Form::Widget::Menu;
use strict;
use warnings; 
##################################################################
# $Id: Menu.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
##################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

use Carp;

#
# This class models a FORM menu (either a popup or a scrollable list).
#

use base qw(CGI::Test::Form::Widget);

use Storable qw(dclone);

############################################################
#
# ->_parse_options
#
# Parse <OPTION> items held within the <SELECT> node.
# We ignore <OPTGROUP> items, since those are only there for grouping options,
# and cannot be individually selected as such.
#
# The following attributes are used to record the options:
#
#  option_labels  listref of option labels, in the order they appear
#  option_values  listref of option values, in the order they appear
#  known_values   hashref, recording valid *values*
#  selected       hashref, recording selected *values*
#  selected_count amount of selected items
#
############################################################
sub _parse_options
{
    my $this = shift;
    my ($node) = shift;

    my $labels   = $this->{option_labels} = [];
    my $values   = $this->{option_values} = [];
    my $selected = $this->{selected}      = {};
    my $known    = $this->{known_values}  = {};
    my $count    = 0;
    my %seen;

    my @nodes = $node->look_down(sub {1});
    shift @nodes;    # first node is the <SELECT> itself

    foreach my $opt (@nodes)
    {
        next if $opt->tag() eq "optgroup";
        unless ($opt->tag() eq "option")
        {
            warn "ignoring non-option tag '%s' within SELECT",
              uc($opt->tag());
            next;
        }

        #
        # The option label is normally the content of the <OPTION> tag.
        # However, if there is a LABEL= within the tag, it should be used
        # in preference to the option content, says the W3C's norm.
        #

        my $label       = $opt->attr("label") || $opt->as_text();
        my $is_selected = $opt->attr("selected");
        my $value       = $opt->attr("value");

        unless (defined $value)
        {
            warn "ignoring OPTION tag with no value: %s", $opt->starttag();
            next;
        }

        #
        # It is not really an error to have duplicate values, but is it
        # a good interface style?  The user will be faced with multiple
        # labels to choose from, some of them being handled in the same way
        # since they bear the same value...  Tough choice... Let's warn!
        #

        warn "duplicate value '%s' in OPTION for SELECT NAME=\"%s\"",
          $value, $this->name
          if $seen{$value}++;

        push @$labels, $label;
        push @$values, $value;
        $known->{$value}++;    # help them spot dups
        if ($is_selected)
        {
            $selected->{$value}++;
            $count++;
        }
    }

    #
    # A popup menu needs to have at least one item selected.  We're the
    # user agent, and we get to choose which item we'll select implicitely.
    # Use the first listed value, if any.
    #

    if ($count == 0 && $this->is_popup() && @$values)
    {
        my $first = $values->[ 0 ];
        $selected->{$first}++;
        $count++;
        warn "implicitely selecting OPTION '%s' for SELECT NAME=\"%s\"",
          $first, $this->name();
    }

    $this->{selected_count} = $count;

    return;
}

############################################################
#
# ->_is_successful		-- defined
#
# Is the enabled widget "successful", according to W3C's specs?
# Any menu with at least one selected item is.
#
############################################################
sub _is_successful
{
    my $this = shift;
    return $this->selected_count > 0;
}

############################################################
#
# ->submit_tuples		-- redefined
#
# Returns list of (name => value) tuples that should be part of the
# submitted form data.
#
############################################################
sub submit_tuples
{
    my $this = shift;

    my $name     = $this->name();
    my $selected = $this->selected();

    my @tuples =
      map {$name => $_} grep {$selected->{$_}} @{$this->option_values()};

    return @tuples;
}

#
# Attribute access
#
############################################################
sub multiple
{
    my $this = shift;
    return $this->{multiple};
}    # Set by Menu::List

############################################################
sub option_labels
{
    my $this = shift;
    return $this->{option_labels};
}
############################################################
sub option_values
{
    my $this = shift;
    return $this->{option_values};
}
############################################################
sub known_values
{
    my $this = shift;
    return $this->{known_values};
}
############################################################
sub selected
{
    my $this = shift;
    return $this->{selected};
}
############################################################
sub selected_count
{
    my $this = shift;
    return $this->{selected_count};
}
############################################################
sub old_selected
{
    my $this = shift;
    return $this->{old_selected};
}

#
# Selection shortcuts
#

############################################################
sub select
{
    my $this = shift;
    my $item = shift;
    $this->set_selected($item, 1);
}
############################################################
sub unselect
{
    my $this = shift;
    my $item = shift;
    $this->set_selected($item, 0);
}

#
# Global widget predicates
#

############################################################
sub is_read_only
{
    return 1;
}

#
# High-level classification predicates
#

############################################################
sub is_menu
{
    return 1;
}

#
# Predicates for menus
#

############################################################
sub is_popup
{
    confess "deferred";
}

############################################################
#
# ->is_selected
#
# Checks whether given value is selected.
#
############################################################
sub is_selected
{
    my $this = shift;
    my ($value) = @_;

    unless ($this->known_values->{$value})
    {
        carp "unknown value \"%s\" in $this", $value;
        return 0;
    }

    return exists $this->selected->{$value};
}

############################################################
#
# ->set_selected
#
# Change "selected" status for a menu value.
#
############################################################
sub set_selected
{
    my $this = shift;
    my ($value, $state) = @_;

    unless ($this->known_values->{$value})
    {
        carp "unknown value \"%s\" in $this", $value;
        return;
    }

    my $is_selected = $this->is_selected($value);
    return if !$is_selected == !$state;    # No change // WTF? -nohuhu

    #
    # Save selected status for all the values the first time a change is made.
    #

    $this->{old_selected} = dclone $this->{selected}
      unless exists $this->{old_selected};

    #
    # If multiple selection is not authorized, clear the selection list.
    #

    my $selected = $this->selected();
    %$selected = () unless $this->multiple();

    $selected->{$value} = 1 if $state;
    delete $selected->{$value} unless $state;
    $this->{selected_count} = scalar keys %$selected;

    return;
}

############################################################
#
# ->reset_state
#
# Called when a "Reset" button is pressed to restore the value the widget
# had upon form entry.
#
############################################################
sub reset_state
{
    my $this = shift;

    return unless exists $this->{old_selected};
    $this->{selected}       = delete $this->{old_selected};
    $this->{selected_count} = scalar keys %{$this->selected()};

    return;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Menu - Abstract representation of a menu

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget

=head1 DESCRIPTION

This class is the abstract representation of a menu from which one can choose
one or several items, i.e. either a popup menu or a scrollable list
(with possibly multiple selections).

There is an interface to query the selected items, get at the presented
labels and associated values, and naturally C<select()> or C<unselect()>
items.

=head1 INTERFACE

The interface is the same as the one described in L<CGI::Test::Form::Widget>,
with the following additions:

=head2 Attributes

=over 4

=item C<known_values>

An hash reference, recording valid menu values, as tuples
(I<value> => I<count>), with I<count> set to the number of times the same
value is re-used amongst the proposed options.

=item C<multiple>

Whether menu allows multiple selections.

=item C<option_labels>

A list reference, providing the labels to choose from, in the order in which
they appear.  The retained labels are either the content of the <OPTION>
elements, or the value of their C<label> attribute, when specified.

=item C<option_values>

A list reference, providing the underlying values that the user chooses from
when he selects labels, in the order in which they appear in the menu.

=item C<selected>

An hash reference, whose keys are the selected values.

=item C<selected_count>

The amount of currently selected items.

=back

=head2 Attribute Setting

=over 4

=item C<select> I<value>

Mark the option I<value> as selected.  If C<multiple> is false, any
previously selected value is automatically unselected.

Note that this takes a I<value>, not a I<label>.

=item C<unselect> I<value>

Unselect an option I<value>.  It is not possible to do that on a popup
menu: you must C<select> another item to unselect any previously selected one.

=back

=head2  Menu Probing

=over 4

=item C<is_selected> I<value>

Test whether an option I<value> is currently selected or not.  This is
not testing a label, but a value, which is what the script will get back
eventually: labels are there for human consumption only.

=back

=head2 Widget Classification Predicates

There is an additional predicate to distinguish between a popup menu (single
selection mandatory) from a scrolling list (multiple selection allowed, and
may select nothing).

=over 4

=item C<is_popup>

Returns I<true> for a popup menu.

=back

=head2 Miscellaneous Features

Although documented, those features are more targetted for
internal use...

=over 4

=item C<set_selected> I<value>, I<flag>

Change the selection status of an option I<value>.

You should use the C<select> and C<unselect> convenience routines instead
of calling this feature.

=back

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget(3),
CGI::Test::Form::Widget::Menu::List(3),
CGI::Test::Form::Widget::Menu::Popup(3).

=cut

