package CGI::Test::Form::Widget::Box;
use strict;
use warnings; 
##################################################################
# $Id: Box.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
##################################################################
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.
#

use Carp;

#
# This class models a FORM box, either a radio button or a checkbox.
#

use base qw(CGI::Test::Form::Widget);

############################################################
#
# %attr
#
# Defines which HTML attributes we should look at within the node, and how
# to translate that into class attributes.
#
############################################################

my %attr = ('name'     => 'name',
            'value'    => 'value',
            'checked'  => 'is_checked',
            'disabled' => 'is_disabled',
            );

############################################################
#
# ->_init
#
# Per-widget initialization routine.
# Parse HTML node to determine our specific parameters.
#
############################################################
sub _init
{
    my $this = shift;
    my ($node) = shift;
    $this->_parse_attr($node, \%attr);
    return;
}

############################################################
#
# ->_is_successful		-- defined
#
# Is the enabled widget "successful", according to W3C's specs?
# Any ticked checkbox and radio button is.
#
############################################################
sub _is_successful
{
    my $this = shift;
    return $this->is_checked();
}

############################################################
#
# ->group_list
#
# Returns list of widgets belonging to the same group as we do.
#
############################################################
sub group_list
{
    my $this = shift;

    return $this->group->widgets_in($this->name);
}

#
# Local attribute access
#

############################################################
sub group
{
    my $this = shift;
    return $this->{group};
}
############################################################
sub is_checked
{
    my $this = shift;
    return $this->{is_checked};
}
############################################################
sub old_is_checked
{
    my $this = shift;
    $this->{old_is_checked};
}

#
# Checking shortcuts
#

############################################################
sub check
{
    my $this = shift;
    $this->set_is_checked(1);
}
############################################################
sub uncheck
{
    my $this = shift;
    $this->set_is_checked(0);
}
############################################################
sub check_tagged
{
    my $this = shift;
    my $tag  = shift;
    $this->_mark_by_tag($tag, 1);
}
############################################################
sub uncheck_tagged
{
    my $this = shift;
    my $tag  = shift;
    $this->_mark_by_tag($tag, 0);
}

#
# Attribute setting
#

############################################################
sub set_group
{
    my $this  = shift;
    my $group = shift;
    $this->{group} = $group;
}

############################################################
#
# ->set_is_checked
#
# Select or unselect box.
#
############################################################
sub set_is_checked
{
    my $this = shift;
    my ($checked) = @_;

    return if !$checked == !$this->is_checked();    # No change

    #
    # To ease redefinition, let this call _frozen_set_is_checked, which is
    # not redefinable and performs the common operation.
    #

    $this->_frozen_set_is_checked($checked);
    return;
}

############################################################
#
# ->reset_state			-- redefined
#
# Called when a "Reset" button is pressed to restore the value the widget
# had upon form entry.
#
############################################################
sub reset_state
{
    my $this = shift;

    $this->{is_checked} = delete $this->{old_is_checked}
      if exists $this->{old_is_checked};

    return;
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
sub is_box
{
    return 1;
}

#
# Predicates for the Box hierarchy
#

############################################################
sub is_radio
{
    confess "deferred";
}
############################################################
sub is_standalone
{
    my $this = shift;
    1 == $this->group->widget_count($this->name());
}

#
# ->delete
#
# Break circular refs.
#
sub delete
{
    my $this = shift;

    delete $this->{group};
    $this->SUPER::delete;

    return;
}

#
# ->_frozen_set_is_checked
#
# Frozen implementation of set_is_checked().
#
sub _frozen_set_is_checked
{
    my $this = shift;
    my ($checked) = @_;

    #
    # The first time we do this, save current status in `old_is_checked'.
    #

    $this->{old_is_checked} = $this->{is_checked}
      unless exists $this->{old_is_checked};
    $this->{is_checked} = $checked;

    return;
}

############################################################
#
# ->_mark_by_tag
#
# Lookup the box in the group whose name is the given tag, and mark it
# as specified.
#
############################################################
sub _mark_by_tag
{
    my $this = shift;
    my ($tag, $checked) = @_;

    my @boxes = grep {$_->value eq $tag} $this->group_list();

    if (@boxes == 0)
    {
        carp "no %s within the group '%s' bears the tag \"$tag\"",
          $this->gui_type(), $this->name();
    }
    else
    {
        carp "found %d %ss within the group '%s' bearing the tag \"$tag\"",
          scalar(@boxes), $this->gui_type(), $this->name()
          if @boxes > 1;

        $boxes[ 0 ]->set_is_checked($checked);
    }

    return;
}

1;

=head1 NAME

CGI::Test::Form::Widget::Box - Abstract representation of a tickable box

=head1 SYNOPSIS

 # Inherits from CGI::Test::Form::Widget

=head1 DESCRIPTION

This class is the abstract representation of a tickable box, i.e. a radio
button or a checkbox.

To simulate user checking or un-checking on a box,
use the C<check()> and C<uncheck()> routines, as described below.

=head1 INTERFACE

The interface is the same as the one described in L<CGI::Test::Form::Widget>,
with the following additions:

=head2 Attributes

=over 4

=item C<group>

The C<CGI::Test::Form::Group> object which holds all the groups of the same
widget type.

=item C<group_list>

The list of widgets belonging to the same group as we do.

=item C<is_checked>

True when the box is checked, i.e. marked with a tick.

=back

=head2 Attribute Setting

=over 4

=item C<check>

Check the box, by ticking it.

=item C<check_tagged> I<tag>

This may be called on any box, and it will locate the box whose value
attribute is I<tag> within the C<group_list>, and then check it.

If the specified I<tag> is not found, the caller will get a warning
via C<carp>.

=item C<uncheck>

Uncheck the box, by removing its ticking mark.
It is not possible to do this on a radio button: you must I<check> another
radio button of the same group instead.

=item C<uncheck_tagged> I<tag>

This may be called on any box, and it will locate the box whose value
attribute is I<tag> within the C<group_list>, and then remove its ticking mark.
It is not possible to do this on a radio button, as explained in C<uncheck>
above.

If the specified I<tag> is not found, the caller will get a warning
via C<carp>.

=back

=head2 Widget Classification Predicates

There is an additional predicate to distinguish between a checkbox and
a radio button:

=over 4

=item C<is_radio>

Returns I<true> for a radio button.

=item C<is_standalone>

Returns I<true> if the box is the sole member of its group.

Normally only useful for checkboxes: a standalone radio button,
although perfectly legal, would always remain in the checked state, and
therefore not be especially interesting...

=back

=head2 Miscellaneous Features

Although documented, those features are more targetted for
internal use...

=over 4

=item C<set_is_checked> I<flag>

Change the checked status.  Radio buttons can only be checked, i.e. the
I<flag> must be true: all other radio buttons in the same group are
immediately unchecked.

You should use the C<check> and C<uncheck> convenience routines instead
of calling this feature.

=back

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Form::Widget(3),
CGI::Test::Form::Widget::Box::Radio(3),
CGI::Test::Form::Widget::Box::Check(3).

=cut

