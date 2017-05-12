#!/usr/bin/perl -w 
#
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.
#
# NOTE TO DEVELOPERS: Use "XXX" to mark bugs or areas that need work
# use something like this to find how many things need work:
# find . | grep -v CVS | xargs grep XXX | wc -l
#

#
# $Id: HTML.pm,v 1.66 2003/02/05 17:18:35 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick;

use strict;
use Carp;
use Text::Iconv;
use CGI::FormMagick::L10N;

=pod 

=head1 NAME

CGI::FormMagick::HTML - HTML output routines for FormMagick

=begin testing

use strict;
use_ok('CGI::FormMagick');
use CGI;
use vars qw($fm);

$fm = new CGI::FormMagick(type => 'file', source => "t/simple.xml");
$fm->{cgi} = new CGI("");
isa_ok($fm, 'CGI::FormMagick');

our $minimalist_fieldinfo_ref = {
    validation => 'foo',
    label => 'bar',
    type => 'text',
    id => 'baz'
};

=end testing

=head1 DESCRIPTION

These are internal-use-only routines for displaying HTML output,
probably only of interest to developers of FormMagick.
=head1 DEVELOPER ROUTINES 

=head2 $self->print_page()

Prints out a page of the form, including the page header and footer, the 
fields, and the buttons.

=cut

sub print_page {
    my ($self) = @_;
    $self->print_page_header();
    $self->display_fields();
    $self->print_buttons();
    $self->print_page_footer();
}



=head2 print_buttons($fm)

print the table row containing the form's buttons

=cut

sub print_buttons {
    my $fm = shift;
    my $html_printed="0";
    print "\n";
#    print qq(    <tr>\n      <td>a</td>\n      <td>);
    my $label = $fm->localise("Previous");
#    print qq(        <input type="submit" name="Previous" value="$label">\n) 
#  	unless $fm->{page_number} == FIRST_PAGENUM() 
#        or $fm->{previousbutton} == 0;

    unless ( $fm->{page_number} == FIRST_PAGENUM() or $fm->{previousbutton} == 0) {
        print qq(    <tr>\n      <td></td>\n      <td>);
        $html_printed=1;
        print qq(        <input type="submit" name="Previous" value="$label">\n);
    }
 
    # check whether it's the last page yet
    if ($fm->is_last_page()) {
        if ($fm->{finishbutton}) {
            print qq(    <tr>\n      <td></td>\n      <td>) unless $html_printed;
            $label = $fm->localise("Finish");
            print qq(      <input type="submit" name="Finish" value="$label">\n);
        }
    } else {
        if ($fm->{nextbutton}) {
            print qq(    <tr>\n      <td></td>\n      <td>) unless $html_printed;
            $label = $fm->localise("Next");
            print qq(<input type="submit" name="Next" value="$label">\n);
        }
    }
    $label = $fm->localise("Clear this form");
    print qq(<input type="reset" value="$label">) 
  	if $fm->{resetbutton};
    print qq(</td>\n    </tr>\n) if $html_printed;
}


=pod

=head2 print_form_header($fm)

prints the header template and the form title (heading level 1)

=cut 

sub print_form_header {
    my $fm = shift;
    my $title = $fm->form->{title};

    # print out the templated headers (based on what's specified in the
    # HTML) then an h1 containing the form element's title attribute
    
    print $fm->parse_template($fm->form->{header});
    print "<h1>", $fm->localise($title), "</h1>\n";
}

=pod

=head2 print_form_footer($fm)

prints the stuff that goes at the bottom of every page of the form

=cut

sub print_form_footer {
    my $fm = shift;
  
    my $url = $fm->{cgi}->url(-relative => 1);
  
    # here's how we clear our state IDs
    print qq(<p><a href="$url">),$fm->localise('Start over again'),
          qq(</a></p>) 
  	if $fm->{startoverlink};

    # this is for debugging purposes
    $fm->debug_msg(qq(<a href="$url?checkl10n=1">Check L10N</a>));

    # print the footer template
    print $fm->parse_template($fm->form->{footer});
}


=pod

=head2 print_page_header($fm)

prints the page title (heading level 2) and description

=cut

sub print_page_header {

    my $fm = shift;
    my $title       = $fm->page->{title};
    my $description = $fm->page->{description};
    my $url = $fm->{cgi}->url(-relative => 1);
    my $enctype = $fm->get_page_enctype();

    # the level 2 heading is the page element's title heading
    print "<h2>", $fm->localise($title), "</h2>\n" if $title;
    print qq(<form method="POST" action="$url" enctype="$enctype">\n);
    print qq(  <input type="hidden" name="page" value="$fm->{page_number}">\n);
    print qq(  <input type="hidden" name="page_stack" value="$fm->{page_stack}">\n);
    print "  ",$fm->{cgi}->state_field(), "\n";	# hidden field with state ID
    print "  <table class=\"sme-noborders\">\n";
    #print "    <col width=\"250\"><col width=\"*\">\n";
    if ($description) {
	  #print '<p class="pagedescription">', $fm->localise($description), "</p>\n";
	  print "  <tr><td colspan=2><p>", $fm->localise($description), "</p></td>\n  </tr>\n";
    }
}

=pod

=head2 print_page_footer($fm)

prints the stuff that goes at the bottom of a page, mostly just the
form and table close tags and stuff.

=cut

sub print_page_footer {
    my $fm = shift;
  
    print "  </table>\n</form>\n";
}

=pod 

=head2  print_field_description($description)

prints the description of a field

=cut

sub print_field_description {
    my $fm = shift;
    my $d = shift;
    $d = $fm->localise($d);
    print qq(    <tr>\n      <td colspan=2><p>$d</p></td>\n    </tr>);
}


=pod

=head2 print_field_error($error)

prints any errors related to a field

=begin testing

my @errors = qw(FOO BAR BAZ);

$ENV{HTTP_ACCEPT_LANGUAGE} = "fr";
$fm->parse_xml();
is(ref $fm->{lexicon}, "HASH", "Lexicon is loaded");

$fm->print_field_error(\@errors);
like($_STDOUT_, qr/le foo/, "Output of print_field_error should be localised");
like($_STDOUT_, qr/le bar/, "Output of print_field_error list multiple fields");
ok($_STDOUT_ !~ /le foo\./, "Output of print_field_error shouldn't have a dot on the end");

=end testing

=cut

sub print_field_error {
    my ($fm, $e) = @_;
    my $errstr = join "<br>", map($fm->localise($_), @$e);
    print "  "; print qq(<tr><td colspan=2><div class="sme-error">$errstr</div></td></tr>); print "\n";
}

=pod

=head2 display_fields($fm)

displays the fields for a page by looping through them

=cut 

sub display_fields {
    my ($fm) = @_;

    my @definitions;

    foreach my $field ( @{$fm->page->{fields}} ) {
        my $info = $fm->gather_field_info($field);
        if ($info->{type} eq "html") {
            print qq(\n    <tr><td cols="2">$info->{content}</td></tr>\n) if $info->{content};
        } elsif ($info->{type} eq "subroutine") {
            my $output = $fm->do_external_routine($info->{src}) || "";
            print qq(\n    <tr><td cols="2">$output</td></tr>\n) if $output;
        } else {
            $fm->print_field_description($info->{description}) if $info->{description};
        
            if (($info->{type} eq "select") || ($info->{type} eq "radio")) {
                $fm->set_option_lv($info);
            }

            print qq(    <tr>\n      <td class="sme-noborders-label">) . $fm->localise($info->{label}). "\n" ;
            my $inputfield = $fm->build_inputfield($info);
            # this is to make the printed HTML look nice
            $inputfield =~ s#^\s*\n##g;
            print  qq(      <td class="sme-noborders-content">$inputfield</td>\n    </tr>\n);
        
            # display errors (if any) below the field label, taking up a whole row
            my $error = $fm->{errors}->{$info->{label}};
            $fm->print_field_error($error) if $error;
        }
    }
}

=pod

=head2 gather_field_info($field) 

Gathers various information about a field and returns it as a hashref.

=begin testing

sub plain_sub {
    return 'Vanilla';
}

sub add_1 {
    my (undef, $a) = @_;
    return $a + 1;
}

sub add_together {
    my (undef, @a) = @_;
    my $sum = 0;
    $sum += $_ foreach @a;
    return $sum;
}

{
    foreach my $expectations (
        [ '', '' ],
        [ 'plain', 'plain' ],
        [ 'plain_sub()', 'Vanilla' ],
        [ 'add_1(0)', '1' ],
        [ 'add_1(1)', '2' ],
        [ 'add_together(2, 3)', '5' ],
        [ 'add_together(2, 3, 4)', '9' ],
    ) {
        my ($input, $expected) = @$expectations;

        my %f = %$minimalist_fieldinfo_ref;
        $f{value} = $input;

        my $i = $fm->gather_field_info(\%f);
        my $actual = $i->{value};
        is(
            $actual,
            $expected,
            "gather_field_info('$input')"
        );
    }
}

=end testing 

=cut

sub gather_field_info {
    my ($fm, $fieldinfo) = @_;

    my %f = %$fieldinfo;

    # value is set to what the user filled in, if they filled
    # something in on a previous visit to this field
    if ($fm->{cgi}->param($f{id})) {
        $f{value} = $fm->{cgi}->param($f{id});

    # are we calling a subroutine to find the value?
    } elsif ($fieldinfo->{value} and $fieldinfo->{value} =~ /\(.*\)/) {
        $f{value} = $fm->do_external_routine($fieldinfo->{value}); 

    # otherwise, use value attribute or default to blank.
    } else {
        my $default = ($fieldinfo->{type} eq 'checkbox' ? 1 : "");
        if (defined $fieldinfo->{value}) {
            my  $converter = Text::Iconv->new("UTF-8", $fm->{charset} || "ISO-8859-1");
            $f{value} = $converter->convert($fieldinfo->{value});
        } else {
            $f{value} = $default;
        }
    }


    if ($f{id}) {
        $fm->debug_msg("Field name is $f{id}");
    } else {
        $fm->debug_msg("Not a field, it's a $f{type}");
    }

    return \%f;
} 

=pod

=head2 build_inputfield ($fm, $forminfo)

Builds HTML for individual form fields. $forminfo is a hashref
containing information about the field. 

=for testing
my $i = $fm->gather_field_info($minimalist_fieldinfo_ref);
ok(my $if = $fm->build_inputfield($i, CGI::FormMagick::TagMaker->new()), "build input field");

=cut

sub build_inputfield {
    my ($fm, $info) = @_;
  
    my $inputfield;		# HTML for a form input
    my $tagmaker = new CGI::FormMagick::TagMaker->new();

    my  $converter = Text::Iconv->new($fm->{charset} || "ISO-8859-1", "UTF-8");
    my $id = $converter->convert($info->{id});
    my $type = $converter->convert($info->{type});
    my $multiple = $converter->convert($info->{multiple});
    my $size = $converter->convert($info->{size});
    my $rows = $converter->convert($info->{rows}) if ($info->{rows});
    my $cols = $converter->convert($info->{cols}) if ($info->{cols});


    # value is already converted in gather_field_info IFF it came from the 
    # XML default (not user input or a subroutine, both of which 
    # should just have plain ol' Latin-1
    my $value = $info->{value};

    if ($info->{type} eq "select") {

        my @labels = map { $fm->localise($_) } @{$info->{option_labels}};

        # don't specify a size if a size wasn't given in the XML
        if ($info->{size} && $info->{size} ne "") { 
            $inputfield = $tagmaker->select_start( 
                type     => $type,
                name     => $id,
                multiple => $multiple,
                size     => $size,
            )
        } else {
            $inputfield = $tagmaker->select_start( 
                type     => $type,
                name     => $id,
                multiple => $multiple,
            )
        }	

        $inputfield = $inputfield . $tagmaker->option_group( 
            value => $info->{option_values},
            text  => \@labels,
        ) .  $tagmaker->select_end;

    # nasty hack required here to select the desired value if it's preset
        $inputfield =~ s/(<OPTION VALUE="$value")/$1 SELECTED/;

    } elsif ($info->{type} eq "radio") {
        my @labels = map { $fm->localise($_) } @{$info->{option_labels}};
        $inputfield = $tagmaker->input_group(
            type  => $type,
            name  => $id,
            value => $info->{option_values} ,
            text  => \@labels
        );
    # nasty hack required here to select the desired value if it's preset
        $inputfield =~ s/(VALUE="$info->{value}")/$1 CHECKED/;

    } elsif ($info->{type} eq "checkbox") {

        # figure out whether hte box should be checked or not
        my $user_input = $fm->{cgi}->param($id);
        my $c;
        if (defined $user_input) {
            $c = $user_input ? 1 : 0;
        } else {
            $c = $info->{checked};  # get from XML spec
        }

        $inputfield = $tagmaker->input(
            type    => $type,
            name    => $id,
            value   => $value,
            checked => $c,
        );
    } elsif ($info->{type} eq "literal") {
        $inputfield = $value;
    } elsif ($info->{type} eq "textarea") {
        $inputfield = $tagmaker->textarea(
            name    => $id,
            rows    => $rows || 5,
            cols    => $cols || 60,
        );
    } else {
        # map HTML::TagMaker's functions to the type of this field.
        my %translation_table = (
           # textarea => 'textarea',
            checkbox => 'input_field',
            text     => 'input_field',
            password => 'input_field',
	    file     => 'input_field',
        );
        my $function_name = $translation_table{$info->{type}};
        # make sure no size gets specified if the size isn't given in the XML
        if ($info->{size} && $info->{size} ne "") {
            $inputfield = $tagmaker->$function_name(
                type  => $type,
                name  => $id,
                value => $value,
                size  => $size,
            );
        } else {
            $inputfield = $tagmaker->$function_name(
                type  => $type,
                name  => $id,
                value => $value,
            );
        }
    }
    return $inputfield;
}

=pod

=head2 set_option_lv($fm, $info)

Given $info (a hashref with info about a field) figures out the option
values/labels for select or radio fields and shoves them into
$info->{option_values} and $info->{option_labels}

=cut

sub set_option_lv {
    my ($fm, $info) = @_;

    # if this is a grouped input (one with options), we'll need to
    # run the options function for it. 

    # DWIM whether the options are in a hash or an array.
    my $lv_hashref = $fm->get_option_labels_and_values($info);
    
    $info->{option_labels} = $lv_hashref->{labels};
    $info->{option_values} = $lv_hashref->{vals};

}

return 1;
