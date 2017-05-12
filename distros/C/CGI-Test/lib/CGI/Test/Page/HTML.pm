package CGI::Test::Page::HTML;
use strict;
use warnings; 
####################################################################
# $Id: HTML.pm 411 2011-09-26 11:19:30Z nohuhu@nohuhu.org $
# $Name: cgi-test_0-104_t1 $
####################################################################
#
#  Copyright (c) 2001, Raphael Manfredi
#
#  You may redistribute only under the terms of the Artistic License,
#  as specified in the README file that comes with the distribution.

require CGI::Test::Page::Real;
use base qw(CGI::Test::Page::Real);

#
# ->new
#
# Creation routine
#
sub new
{
    my $this = bless {}, shift;
    $this->_init(@_);
    return $this;
}

#
# Attribute access
#

sub tree
{
    my $this = shift;
    return $this->{tree} || $this->_build_tree();
}

sub forms
{
    my $this = shift;
    return $this->{forms} || $this->_xtract_forms();
}

sub form_count
{
    my $this = shift;
    $this->_xtract_forms() unless exists $this->{form_count};
    return $this->{form_count};
}

#
# ->_build_tree
#
# Parse HTML content from `raw_content' into an HTML tree.
# Only called the first time an access to `tree' is requested.
#
# Returns constructed tree object.
#
sub _build_tree
{
    my $this = shift;

    require HTML::TreeBuilder;

    my $tree = HTML::TreeBuilder->new();
    $tree->ignore_unknown(0);        # Keep everything, even unknown tags
    $tree->store_comments(1);        # Useful things may hide in "comments"
    $tree->store_declarations(1);    # Store everything that we may test
    $tree->store_pis(1);             # Idem
    $tree->warn(1);                  # We want to know if there's a problem

    $tree->parse($this->raw_content);
    $tree->eof;

    return $this->{tree} = $tree;
}

#
# _xtract_forms
#
# Extract <FORMS> tags out of the tree, and for each form, build a
# CGI::Test::Form object that represents it.
# Only called the first time an access to `forms' is requested.
#
# Side effect: updates the `forms' and `form_count' attributes.
#
# Returns list ref of objects, in the order they were found.
#
sub _xtract_forms
{
    my $this = shift;
    my $tree = $this->tree;

    require CGI::Test::Form;

    #
    # The CGI::Test::Form objects we're about to create will refer back to
    # us, because they are conceptually part of this page.  Besides, their
    # HTML tree is a direct reference into our own tree.
    #

    my @forms = $tree->look_down(sub {$_[ 0 ]->tag eq "form"});
    @forms = map {CGI::Test::Form->new($_, $this)} @forms;

    $this->{form_count} = scalar @forms;
    return $this->{forms} = \@forms;
}

#
# ->delete
#
# Break circular references
#
sub delete
{
    my $this = shift;

    #
    # The following attributes are "lazy", i.e. calculated on demand.
    # Therefore, take precautions before de-referencing them.
    #

    $this->{tree} = $this->{tree}->delete if ref $this->{tree};
    if (ref $this->{forms})
    {
        foreach my $form (@{$this->{forms}})
        {
            $form->delete;
        }
        delete $this->{forms};
    }

    $this->SUPER::delete;
    return;
}

#
# (DESTROY)
#
# Dispose of HTML tree properly
#
sub DESTROY
{
    my $this = shift;
    return unless ref $this->{tree};
    $this->{tree} = $this->{tree}->delete;
    return;
}

1;

=head1 NAME

CGI::Test::Page::HTML - A HTML page reply

=head1 SYNOPSIS

 # Inherits from CGI::Test::Page::Real

=head1 DESCRIPTION

This class represents an HTTP reply containing C<text/html> data.
When testing CGI scripts, this is usually what one gets back.

=head1 INTERFACE

The interface is the same as the one described in L<CGI::Test::Page::Real>,
with the following addition:

=over 4

=item C<tree>

Returns the root of the HTML tree of the page content, as an
HTML::Element node.

=back

=head1 AUTHORS

The original author is Raphael Manfredi.

Steven Hilton was long time maintainer of this module.

Current maintainer is Alexander Tokarev F<E<lt>tokarev@cpan.orgE<gt>>.

=head1 SEE ALSO

CGI::Test::Page::Real(3), HTML::Element(3).

=cut

