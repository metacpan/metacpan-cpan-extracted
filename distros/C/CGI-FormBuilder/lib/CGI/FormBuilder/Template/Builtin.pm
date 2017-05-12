
###########################################################################
# Copyright (c) Nate Wiger http://nateware.com. All Rights Reserved.
# Please visit http://formbuilder.org for tutorials, support, and examples.
###########################################################################

package CGI::FormBuilder::Template::Builtin;

=head1 NAME

CGI::FormBuilder::Template::Builtin - Builtin HTML rendering

=head1 SYNOPSIS

    my $form = CGI::FormBuilder->new;
    $form->render;

=cut

use Carp;
use strict;
use warnings;
no  warnings 'uninitialized';

use CGI::FormBuilder::Util;


our $VERSION = '3.10';

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

    # Put id's around state tags if so required
    my($stid, $keid);
    if (my $fn = $form->name) {
        $stid = tovar("${fn}$form->{statename}");
        $keid = tovar("${fn}$form->{extraname}");
    }

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

    # Support fieldset => 'name' to organize by fieldset on the fly
    my $legend = $form->fieldsets;

    # Get table stuff and reused calls
    my $table = $form->table(id => $form->idname($form->bodyname), class => $form->class);
    my $tabn = 1;
    push @html, $table if $table;

    # Render regular fields in table
    my $lastset;
    for my $field (@unhidden) {
        if (my $set = $field->fieldset) {
            # hooks (hack?) for fieldsets
            if ($set ne $lastset) {
                # close any open tables/fieldsets
                if ($lastset) {
                    push @html, htmltag('/table') if $table;
                    push @html, htmltag('/fieldset');
                    push @html, htmltag('/div');
                } elsif ($table) {
                    # Catch in case we have an empty table - ie the previous
                    # element is just <table>. This workaround is needed
                    # in case the user wants to mix fields with/without
                    # fieldsets in the same form
                    if ($html[-1] =~ /^<table\b/) {
                        pop @html;
                    } else {
                        # close non-fieldset table
                        push @html, htmltag('/table');
                    }
                }

                # Wrap fieldset in a <div> to allow jquery #tabs
                push @html, $form->div(id => $form->idname($form->tabname.$tabn++),
                                       class => $form->class($form->tabname));

                (my $sn = lc $set) =~ s/\W+/_/g;
                push @html, htmltag('fieldset', id => $form->idname("_$sn"),
                                                class => $form->class('_set'));
                push @html, htmltag('legend') . ($legend->{$set}||$set) . htmltag('/legend')
                  if defined $legend->{$set};

                # Wrap fields in a table
                push @html, $form->table if $table;

                $lastset = $set;
            }
        } elsif ($lastset) {
            # ended <fieldset> defs before form has ended
            # remaining fields are not in a fieldset
            push @html, htmltag('/table') if $table;
            push @html, htmltag('/fieldset');
            push @html, htmltag('/div');
            push @html, $table if $table;
            undef $lastset;     # avoid dup </fieldset> below
        }

        debug 2, "render: attacking normal field '$field'";
        next if $field->static > 1 && ! $field->tag_value;  # skip missing static vals

        if ($table) {
            push @html, $form->tr(id => $form->idname("_$field", $form->rowname));

            my $cl  = $form->class($form->labelname);
            my $row = '  ' . $form->td(id => $form->idname("_$field", $form->labelname),
                                       class => $cl) . $font;
            if ($field->invalid) {
                $row .= $form->invalid_tag($field->label);
            } elsif ($field->required && ! $field->static) {
                $row .= $form->required_tag($field->label);
            } else {
                $row .= $field->label;
            }
            $row .= $fcls . htmltag('/td');
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
            push @html, ('  ' . $form->td(id => $form->idname("_$field", $form->fieldname),
                                          class => $cl) . $font 
                        . $row . $fcls . htmltag('/td'));
            push @html, htmltag('/tr');
        } else {
            # no table
            my $row = $font;
            if ($field->invalid) {
                $row .= $form->invalid_tag($field->label);
            } elsif ($field->required && ! $field->static) {
                $row .= $form->required_tag($field->label);
            } else {
                $row .= $field->label;
            }
            $row .= $fcls;
            push @html, $row;
            push @html, $field->tag;
            push @html, $field->message if $field->invalid;
            push @html, $field->comment if $field->comment;
            push @html, '<br />' if $form->linebreaks;
        }
    }

    # Close fieldset before [Submit] if using fieldsets
    if ($lastset) {
        push @html, htmltag('/table') if $table;
        push @html, htmltag('/fieldset');
        push @html, htmltag('/div');
        undef $table;   # avoid dup </table> below
    }

    # Throw buttons in a colspan
    my $buttons = $form->reset . $form->submit;
    if ($buttons) {
        my $row = '';
        if ($table) {
            my $c = $form->class($form->{submitname});
            my %a = $c ? () : (align => 'center');
            $row .= $form->tr(id => $form->idname($form->submitname, $form->rowname)) . "\n  "
                  . $form->td(id => $form->idname($form->submitname, $form->fieldname),
                              class => $c, colspan => 2, %a) . $font;
        } else {
            # wrap in a <div> for fieldsets
            $row .= $form->div(id => $form->idname('_controls'),
                               class => $form->class('_controls'));
        }
        $row .= $buttons;
        if ($table) {
            $row .= htmltag('/font') if $font;
            $row .= htmltag('/td') . "\n" . htmltag('/tr') if $table;
        } else {
            $row .= htmltag('/div');
        }
        push @html, $row;
    }

    # Properly nest closing tags
    push @html, htmltag('/table')  if $table;
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

$Id: Builtin.pm 97 2007-02-06 17:10:39Z nwiger $

=head1 AUTHOR

Copyright (c) L<Nate Wiger|http://nateware.com>. All Rights Reserved.

This module is free software; you may copy this under the terms of
the GNU General Public License, or the Artistic License, copies of
which should have accompanied your Perl kit.

=cut

