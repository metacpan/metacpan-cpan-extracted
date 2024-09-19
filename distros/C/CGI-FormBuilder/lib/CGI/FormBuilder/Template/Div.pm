
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Template::Div;

=head1 NAME

CGI::FormBuilder::Template::Div - Div HTML rendering

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new;
    $form->render;

=cut

use Carp;
use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;


our $VERSION = '3.20';

sub new {
    my $self  = shift;
    my $class = ref($self) || $self;
    my %opt   = @_ if @_ > 1;
    return bless \%opt, $class;
}

sub prepare {
    my $self = shift;
    my $form = shift;

    my @html = ();  # joined with newline

    # Opening CGI/title gunk 
    my $hd = $form->header;
    if (defined $hd) {
        push @html, $form->dtd, htmltag('head');
        push @html, htmltag('title') . $form->title . htmltag('/title')
          if $form->title;

        # stylesheet path if specified
        if ($form->{stylesheet} && $form->{stylesheet} ne 1) {
            # user-specified path
            push @html, htmltag('link', { rel  => 'stylesheet',
                                          type => 'text/css',
                                          href => $form->{stylesheet} });
        }
    }

    # JavaScript validate/head functions
    my $js = $form->script;
    push @html, $js if $js;

    # Opening HTML if so requested
    my $font = $form->font;
    my $fcls = $font ? htmltag('/font') : '';
    if (defined $hd) {
        push @html, htmltag('/head'), $form->body;
        push @html, $font if $font;
        push @html, htmltag('h3') . $form->title . htmltag('/h3')
          if $form->title;
    }

    # Include warning if noscript
    push @html, $form->noscript if $js;

    # Begin form
    my $txt = $form->text;
    push @html, $txt if $txt;
    push @html, $form->start;

    # Put id's around state tags if they exist
    if (my $st = $form->statetags) {
        push @html,
             $form->div(id => $form->idname($form->statename),
                        class => $form->class($form->statename)) .
             $st . htmltag('/div');
    }
    if (my $ke = $form->keepextras) {
        push @html,
             $form->div(id => $form->idname($form->extraname),
                        class => $form->class($form->extraname)) .
             $ke . htmltag('/div');
    }

    # Render hidden fields first
    my @unhidden;
    for my $field ($form->fieldlist) {
        push(@unhidden, $field), next if $field->type ne 'hidden';
        push @html, $field->tag;   # no label/etc for hidden fields
    }

    my $div = $form->div(id => $form->idname($form->bodyname), class => $form->class);
    my $tabn = 1;
    push @html, $div if $div;

    # Support fieldset => 'name' to organize by fieldset on the fly
    my $legend = $form->fieldsets;

    # Render regular fields in <div> for CSS happiness
    my $lastset;
    for my $field (@unhidden) {
        if (my $set = $field->fieldset) {
            # hooks (hack?) for fieldsets
            if ($set ne $lastset) {
                # close any open divs/fieldsets
                if ($lastset) {
                    push @html, htmltag('/fieldset');
                    push @html, htmltag('/div');
                } else {
                    # Catch in case we have an empty div - ie the previous
                    # element is just <div>. This workaround is needed
                    # in case the user wants to mix fields with/without
                    # fieldsets in the same form
                    if ($html[-1] =~ /^<div\b/) {
                        pop @html;
                    } else {
                        # close non-fieldset div
                        push @html, htmltag('/div');
                    }
                }

                # wrap fieldset in a <div> to allow jquery #tabs
                push @html, $form->div(id => $form->idname($form->tabname.$tabn++),
                                       class => $form->class($form->tabname));

                (my $sn = lc $set) =~ s/\W+/_/g;
                push @html, htmltag('fieldset', id => $form->idname("_$sn"),
                                                class => $form->class('_set'));
                push @html, htmltag('legend') . ($legend->{$set}||$set) . htmltag('/legend')
                  if defined $legend->{$set};

                $lastset = $set;
            }
        } elsif ($lastset) {
            # ended <fieldset> defs before form has ended
            # remaining fields are not in a fieldset
            push @html, htmltag('/div') if $div;
            push @html, htmltag('/fieldset');
            push @html, $div;
            undef $lastset;     # avoid dup </fieldset> below
        }

        debug 2, "render: attacking normal field '$field'";
        next if $field->static > 1 && ! $field->tag_value;  # skip missing static vals

        #
        # Since this was cut-and-pasted from ::Div, the variables
        # are all named for <table> elements. But, the purpose is
        # the same: rows, labels, etc.
        #
        push @html, $form->div(id => $form->idname("_$field", $form->rowname));

        my $cl = $form->class($form->{labelname});
        my $row = '  ' . $form->div(id => $form->idname("_$field", $form->labelname),
                                    class => $cl) . $font;
        if ($field->invalid) {
            $row .= $form->invalid_tag($field->label);
        } elsif ($field->required && ! $field->static) {
            $row .= $form->required_tag($field->label);
        } else {
            $row .= $field->label;
            }
        $row .= $fcls . htmltag('/div');
        push @html, $row;

        # tag plus optional errors and/or comments
        $row = '';
        if ($field->invalid) {
            $row .= ' ' . $field->message;
        }
        if ($field->comment) {
            $row .= ' ' . $field->comment unless $field->static;
        }
        $row = $field->tag . $row;
        $cl  = $form->class($form->{fieldname});
        push @html, ('  ' . $form->div(id => $form->idname("_$field", $form->fieldname),
                                       class => $cl) . $font 
                    . $row . $fcls . htmltag('/div'));
        push @html, htmltag('/div');
    }

    # Close fieldset before [Submit] if using fieldsets
    if ($lastset) {
        push @html, htmltag('/div');
        push @html, htmltag('/fieldset');
        undef $div;   # avoid dup </div> below
    }
    push @html, htmltag('/div')  if $div;   # fields

    # Throw buttons in a row
    my $reset = $form->reset;
    my $slist = $form->submits;     # arrayref
    push @html, $form->div(id => $form->idname('_controls'), class => $form->class('_controls'))
        if $reset || $slist;
    if ($reset) {
        my $row = '';
        my $c = $form->class($form->resetname);
        my %a = $c ? () : (align => 'center');
        $row .= $form->div(id => $form->idname($form->resetname, $form->rowname)) . "\n  "
              . $form->div(class => $c, %a) . $font;
        $row .= $reset;
        $row .= htmltag('/font') if $font;
        $row .= htmltag('/div') . "\n" . htmltag('/div');
        push @html, $row;
    }
    if (@$slist) {
        my $row = '';
        my $c = $form->class($form->submitname);
        my %a = $c ? () : (align => 'center');
        $row .= $form->div(id => $form->idname($form->submitname, $form->rowname)) . "\n";
        for my $button (@$slist) {
            $row .= '  '
                  . $form->div(class => $c, %a) . $font . $button;
            $row .= htmltag('/font') if $font;
            $row .= htmltag('/div') . "\n";
        }
        $row .= htmltag('/div');
        push @html, $row;
    }
    push @html, htmltag('/div') if $reset || $slist;

    # Properly nest closing tags
    push @html, htmltag('/form');   # $form->end
    push @html, htmltag('/font')   if $font && defined $hd;
    push @html, htmltag('/body'),htmltag('/html') if defined $hd;

    # Always return scalar since print() is a list function
    return $self->{output} = join("\n", @html) . "\n"
}

sub render {
    my $self = shift;
    return $self->{output};
}

1;
__END__

=head1 DESCRIPTION

This module provides default rendering for B<FormBuilder>. It is automatically
called by FormBuilder's C<render()> method if no external template is specified.
See the documentation in L<CGI::FormBuilder> for more details.

=head1 SEE ALSO

L<CGI::FormBuilder>, L<CGI::FormBuilder::Template::HTML>,
L<CGI::FormBuilder::Template::Text>, L<CGI::FormBuilder::Template::TT2>,
L<CGI::FormBuilder::Template::Fast>, L<CGI::FormBuilder::Template::CGI_SSI>

=head1 REVISION

$Id: Div.pm 68 2006-09-12 04:37:09Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

