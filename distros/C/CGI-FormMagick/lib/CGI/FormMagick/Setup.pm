#!/usr/bin/perl -w 
#
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

#
# $Id: Setup.pm,v 1.24 2003/02/05 17:18:36 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick;

use strict;
use Carp;
use File::Basename;

=pod 

=head1 NAME

CGI::FormMagick::Setup - setup/initialisation routines for FormMagick

=head1 SYNOPSIS

  use CGI::FormMagick;

=head1 DESCRIPTION

=head2 default_xml_filename()

default source filename to the same as the perl script, with .xml 
extension

=begin testing

BEGIN: {
    use vars qw( $fm );
    use lib "./lib";
    use CGI::FormMagick;
}

ok($fm = CGI::FormMagick->new(type => 'file', source => "t/simple.xml"), "create fm object");
ok($fm2 = CGI::FormMagick->new(type => 'file', source => "t/simple.xml",
	charset => 'ISO-8859-1'), "create fm object with charset");
$fm->parse_xml(); # suck in structure without display()ing
$fm2->parse_xml(); # suck in structure without display()ing

=end testing

=cut

sub default_xml_filename {
    
      my($scriptname, $scriptdir, $extension) =
         File::Basename::fileparse($0, '\.[^\.]+');
    
      return $scriptname . '.xml';
}

=head2 parse_xml()

Parses the XML input, setting $fm->{xml} to a usable hash of the form
elements, and $fm->{lexicon} to a hash of the l10n lexicon.

The $fm->{xml} hash has the following form:

    {
        'form' => {
            'post-event' => 'submit_order',
            'title' => 'FormMagick demo application'
        },
        'pages' => [
            {
                 'post-event' => 'lookup_group_info',
                 'fields' => [
                     {
                         'type' => 'text',
                         'id' => 'firstname',
                         'validation' => 'nonblank',
                         'label' => 'first name'
                     },
                     {
                         'type' => 'text',
                         'id' => 'lastname',
                         'validation' => 'nonblank',
                         'label' => 'last name'
                     }
                     {
                         'type' => 'fragment',
                         'content' => 'This is a simple fragment'
                     }
                     {
                         'type' => 'subroutine',
                         'src' => 'fragment_subroutine_name()'
                     }
                 ],
                 'name' => 'Personal',
                 'title' => 'Personal details'
            }
        ]
    };

Note on lexicon files:
If FormMagick was given a charset argument, then the output will be encoded
in that character set. Otherwise, it will be in UTF-8.

=for testing
is(ref($fm->{xml}), "HASH", "parse_xml gives us a hash");
is($fm->{xml}->{title}, "FormMagick demo application", 
    "Picked up form title");
is(ref($fm->{xml}->{pages}), "ARRAY", 
    "parse_xml gives us an array of pages");
is(ref($fm->{xml}->{pages}->[0]), "HASH", 
    "each page is a hashref");
is($fm->{xml}->{pages}->[0]->{name}, "Personal", 
    "Picked up first page's name");
is($fm->{xml}->{pages}->[0]->{title}, "Personal details", 
    "Picked up first page's title");
is(ref($fm->{xml}->{pages}->[0]->{fields}), "ARRAY", 
    "Page's fields are an array");
is(ref($fm->{xml}->{pages}->[0]->{fields}->[0]), "HASH", 
    "Field is a hashref");
is($fm->{xml}->{pages}->[0]->{fields}->[0]->{label}, "first name", 
    "Picked up field title");
is($fm->{xml}{pages}[0]{fields}[0]{description}, "description here", 
    "Picked up field description");
print "Charset parsing tests:\n";
is(ref($fm2->{xml}), "HASH", "parse_xml gives us a hash");
is($fm2->{xml}->{title}, "FormMagick demo application", 
    "Picked up form title");
is(ref($fm2->{xml}->{pages}), "ARRAY", 
    "parse_xml gives us an array of pages");
is(ref($fm2->{xml}->{pages}->[0]), "HASH", 
    "each page is a hashref");
is($fm2->{xml}->{pages}->[0]->{name}, "Personal", 
    "Picked up first page's name");
is($fm2->{xml}->{pages}->[0]->{title}, "Personal details", 
    "Picked up first page's title");
is(ref($fm2->{xml}->{pages}->[0]->{fields}), "ARRAY", 
    "Page's fields are an array");
is(ref($fm2->{xml}->{pages}->[0]->{fields}->[0]), "HASH", 
    "Field is a hashref");
is($fm2->{xml}->{pages}->[0]->{fields}->[0]->{label}, "first name", 
    "Picked up field title");
is($fm2->{xml}{pages}[0]{fields}[0]{description}, "description here", 
    "Picked up field description");

=cut

sub parse_xml {
    my $self = shift;

    my $p;    
    if ($self->{charset})
    {
        $p = new XML::Parser (Style => 'Tree', 
                              ProtocolEncoding => $self->{charset});
    }
    else
    {
        $p = new XML::Parser (Style => 'Tree');
    }

    my $xml;

    if ($self->{inputtype} eq "file") {
        $xml = $p->parsefile($self->{source} || default_xml_filename());
    } elsif ($self->{inputtype} eq "string") {
        # Catch errors in parse_xml and save the output for debugging.
        my $result = eval { $xml = $p->parse($self->{source}) };
        unless ($result)
        {
            open OUT, ">/tmp/FormMagick_XML_$$";
            print OUT $self->{source};
            print OUT "\n\n<!--\nERRORS:\n$@\n-->\n";
            croak "Whoops, parse_xml() failed. The data and error messages were
saved to /tmp/FormMagick_XML_$$\n";
        }
    } else {
        croak 'Invalid source type specified (should be "file" or "string")';
    }

    my @dirty_form = @{$xml->[1]};

    my %form_attributes = %{$dirty_form[0]};

    my @form_elements = $self->clean_xml_array(@dirty_form[1..$#dirty_form]);

    my ($pages, $lexicon) = 
        $self->clean_page_list(\@form_elements, \%form_attributes);

    $self->{xml} = {
        %form_attributes,
        pages => $pages,
    };

    $self->{lexicon} = $lexicon;

}

=head2 clean_field_list

Given a messy field list (as seen as @page_fields in parse_xml()),
removes extraneous data and returns a clean list.

=cut

sub clean_field_list {
    my $self = shift;
    my @page_fields = @_;
    my @fields;
    field: foreach my $field (@page_fields) {
        my $field_type = $field->[0];
        my %field_attributes = %{$field->[1]};
        my @this_field = @$field;
        my @field_elements = @this_field[2..$#this_field];
        @field_elements = $self->clean_xml_array(@field_elements);

        field_element: foreach my $field_element (@field_elements) {
            if ($field_type eq 'html') {
                $field_attributes{type} = 'html';
                $field_attributes{content} = $field->[3];
            } elsif ($field_type eq 'subroutine') {
                $field_attributes{type} = 'subroutine';
            } elsif ($field_element->{type}) {
                $field_attributes{$field_element->{type}} = 
                    $field_element->{content}->[2];
            } else {
                next field_element;
            }
        }

        push @fields, \%field_attributes;
    }

    return @fields;
}


=head2 clean_page_list(\@form_elements, \%form_attributes)

Given a messy list of form elements (as seen as @form_elements in 
parse_xml()), removes extraneous data and returns: 1) a
clean list of pages in the form, and 2) a lexicon hash.

=cut

sub clean_page_list {
    my $self = $_[0];
    my @form_elements = @{$_[1]};
    my %form_attributes = %{$_[2]};
    my @form_pages;
    my @lexicons;
    form_element: foreach my $form_element (@form_elements) {
        if (not $form_element->{type}) {
            next form_element;
        } elsif ($form_element->{type} eq 'page') {
            push @form_pages, $form_element->{content};
        } elsif ($form_element->{type} eq 'lexicon') {
            push @lexicons, $form_element->{content};
        } elsif ($form_element->{type}) {
            $form_attributes{$form_element->{type}} = 
                $form_element->{content}->[2];
        }
    }

    my @pages;
    page: foreach my $page (@form_pages) {
        my %page_attributes = %{$page->[0]};
        my @this_page = @$page;
        my @page_elements = @this_page[1..$#this_page];
        @page_elements = $self->clean_xml_array(@page_elements);

        my @page_fields;
        #use Data::Dumper;
        #print Dumper @page_elements;
        page_element: foreach my $page_element (@page_elements) {
            if (not $page_element->{type}) {
                next page_element;
            } elsif ($page_element->{type} eq 'field') {
                push @page_fields, 
                        ["field", @{$page_element->{content}}];
            } elsif ($page_element->{type} eq 'html') {
                push @page_fields, 
                        ["html", @{$page_element->{content}}];
            } elsif ($page_element->{type} eq 'subroutine') {
                push @page_fields, 
                        ["subroutine", @{$page_element->{content}}];
            } elsif ($page_element->{type}) {
                $page_attributes{$page_element->{type}} = 
                    $page_element->{content}->[2];
            }
        }

        my @fields = $self->clean_field_list(@page_fields);

        push @pages, { %page_attributes, fields => \@fields };
    }

    my %lexicon = $self->get_lexicon(@lexicons);

    return \@pages, \%lexicon;
}

=head2 $self->clean_xml_array($xml)

Cleans up XML by removing superfluous stuff.  Given an array of XML,
returns a cleaner array.

=cut

sub clean_xml_array {
    my ($self, @array) = @_;
    my @clean_array;
    for (my $i=0; $i <= @array; $i+=4) {
        my ($type, $content) = @array[$i+2, $i+3];
        push @clean_array, { type => $type, content => $content };
    }
    return @clean_array;
}

=pod

=head2 initialise_sessiondir($self)

Figures out where the session tokens should be kept.

=for testing
ok( CGI::FormMagick::initialise_sessiondir("abc"), "Initialise sessiondir with name");
ok( CGI::FormMagick::initialise_sessiondir(),      "Initialise sessiondir with undef");

=cut

sub initialise_sessiondir {
    my ($sessiondir) = @_;

    # use the user-defined session handling directory (or default to
    # session-tokens) to store session tokens
    if ($sessiondir) {
        return $sessiondir;
    } else {
        return get_or_create_default_sessiondir();
    }
}

sub get_or_create_default_sessiondir {
    # It's recommended that you use a more hidden directory than this.
    # However, this is the best default we can think of:
    my $scriptdir = (File::Basename::fileparse($0, '\.[^\.]+'))[1];
    my $sessionid_dir_name = $scriptdir . "session-tokens/";

    ensure_dir_is_writable($sessionid_dir_name)
        or warn "(Expect CGI::Persistent to complain)";

    return $sessionid_dir_name;
}

sub ensure_dir_is_writable {
    my ($dir_name) = @_;

    if (not -d $dir_name) {
        mkdir($dir_name) or do {
            warn "Can't create $dir_name";
            return 0;
        }
    }

    if (not -w $dir_name) {
        warn "Can't write to $dir_name";
        return 0;
    }

    return 1;
}

return "FALSE";     # true value ;)

=pod

=head1 SEE ALSO

CGI::FormMagick

=cut
