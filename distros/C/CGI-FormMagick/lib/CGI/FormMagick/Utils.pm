#!/usr/bin/perl -w 
#
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

#
# $Id: Utils.pm,v 1.32 2003/02/05 17:18:37 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick;

use Text::Template;

use strict;
use Carp;

=pod 

=head1 NAME

CGI::FormMagick::Utils - utility routines for FormMagick

=head1 SYNOPSIS

  use CGI::FormMagick;

=head1 DESCRIPTION

=head2 debug_msg($msg)

The debug method prints out a nicely formatted debug message.  It can 
be called from your script as C<$f->debug_msg($msg)>

=begin testing

BEGIN: {
    use vars qw( $fm );
    use lib "./lib";
    use CGI::FormMagick;
}

ok($fm = CGI::FormMagick->new(type => 'file', source => "t/simple.xml"), "create fm object");
$fm->parse_xml(); # suck in structure without display()ing

=end testing


=cut

sub debug_msg {
    my $self = shift;
    my $msg = shift;
    my ($sub, $line) = (caller(1))[3,2];
    print qq(<p class="debug">$sub $line: $msg</p>) if $self->{debug};
}

=head2 $fm->get_page_by_name($name)

get a page given the name attribute.  Returns the numeric index of
the page, suitable for $wherenext.

=for testing
is($fm->get_page_by_name('Personal'), 0, "get page by name");

=cut

sub get_page_by_name {
    my ($self, $name) = @_;

    for (my $i = 0; $i < scalar(@{$self->{xml}->{pages}}); $i += 1) { 
        return $i if $self->{xml}->{pages}->[$i]->{name} eq $name;
    }
    return undef;   # if you can't find that page   
}

=pod

=head2 $fm->get_page_by_number($page_index)

Given a page index, return a hashref containing the page's data.
This is just a convenience function.

=for testing
is(ref($fm->get_page_by_number(0)), 'HASH', "get page by number");

=cut

sub get_page_by_number {
    my ($self, $pagenum) = @_;
    return $self->{xml}->{pages}->[$pagenum];
}

=pod

=head2 pop_page_stack($self)

pops the last page off the stack of pages a user's visited... used
when the user clicks "Previous"

removes the last element from the stack (modifying it in place in
$self->{page_stack}) and returns the element it removed.  eg: 

    # if the CGI "pagestack" parameter is "1,2,3,5"...
    my $page = $self->pop_page_stack();
    $self->{page_stack} will be 1,2,3
    $page will be 5

=begin testing

local $fm->{page_stack} = "0,1,2,3";
my $p = $fm->pop_page_stack();
is($p, 3, "Pop page stack return value");
is($fm->{page_stack}, "0,1,2", "Pop page stack changes stack");

local $fm->{page_stack} = "0";
$p = $fm->pop_page_stack();
is($p, 0, "Pop page stack return value");
is($fm->{page_stack}, "", "Pop page stack changes stack");

=end testing

=cut

sub pop_page_stack {
    my $self = shift;
    my @pages = split(",", $self->{page_stack});
    my $lastpage = pop(@pages);
    $self->{page_stack} = join(",", @pages);
    return $lastpage;
}

=pod

=head2 push_page_stack($newpage)

push a new page onto the page stack that keeps track of where a user
has been.

=begin testing

local $fm->{page_stack} = "0,1,2,3";
$fm->push_page_stack(4);
is($fm->{page_stack}, "0,1,2,3,4", "Push page stack changes stack");

local $fm->{page_stack} = "";
$fm->push_page_stack(0);
is($fm->{page_stack}, "0", "Push page stack changes empty stack");

=end testing

=cut

sub push_page_stack {
    my ($self, $newpage) = @_;
    $self->{page_stack} = "$self->{page_stack},$newpage";
    $self->{page_stack} =~ s/^,//;
}


=head2 $fm->parse_template($filename)

parses a Text::Template file and returns the result.  Will return undef
if the filename is invalid.

=for testing
is($fm->parse_template(), undef, "Fail gracefully if no template");

=cut

sub parse_template {
    my $self = shift;
    my $filename = shift;
    return undef unless $filename;

    if ($filename =~ /([^;]*)/) {
        $filename = $1;
    } else {
        carp "Filename $filename is tainted, can't parse template";
        return undef;
    }
    my $output = "";
    if (-e $filename) {
        my $template = new Text::Template (
            type => 'file', 
            source => $filename,
            UNTAINT => 1,
        );
        $output = $template->fill_in();
    }
    return $output;
}

=head2 is_last_page()

Figures out whether or not we're on the last page.  Used by
print_buttons() in particular to tell whether to print a Finish button,
and to tell whether to do the form post-event.

=for testing
is(@{$fm->form->{pages}}, 3, "We have three pages");
local $fm->{page_number} = 1;
ok(! $fm->is_last_page(), "It's not the last page");
local $fm->{page_number} = 3;
ok($fm->is_last_page(), "It is the last page");
local $fm->{page_number} = 99;
ok($fm->is_last_page(), "It's past the last page, but we cope OK");

=cut

sub is_last_page {
    my $self = shift;
    if ($self->{page_number} >= @{$self->form->{pages}} - 1) {
        return 1;
    } else {
        return 0;
    }
}

=pod

=head2 is_first_page()

Figures out whether or not we're on the first page.  Used mostly to
figure out whether we want to do the form pre-event.

=for testing
is(@{$fm->form->{pages}}, 3, "We have three pages");
local $fm->{page_number} = 0;
ok($fm->is_first_page(), "Is page 0 the first page");
local $fm->{page_number} = 1;
ok(!$fm->is_first_page(), "Is page 1 the first page");

=cut

sub is_first_page {
    my $self = shift;
    if ($self->{page_number} == FIRST_PAGENUM()) {
        return 1;
    } else {
        return 0;
    }
}

=head2 just_starting()

Like is_first_page, but also checks for the absence of a "page"
parameter in the CGI, which would indicate that this is the very first
page we've looked at.

=for testing
local $fm->{page_number} = 0;
local $fm->{cgi} = CGI->new("");
ok($fm->just_starting(), "Just starting");
local $fm->{page_number} = 0;
local $fm->{cgi} = CGI->new({ page => 1 });
ok(!$fm->just_starting(), "Not just starting");
local $fm->{page_number} = 0;
local $fm->{cgi} = CGI->new({ page => 0 });
ok(!$fm->just_starting(), "Not just starting even if page is 0");

=cut

sub just_starting {
    my $self = shift;
    if ($self->is_first_page() and not defined $self->{cgi}->param("page")) {
        return 1;
    } else {
        return 0;
    }
}

=head2 finished 

Figures out whether the user's finished.  This could be because they
clicked "Finish" or it could be because they were on the last page and
hit enter.

This bears the same relationship to is_last_page as just_starting does to 
is_first_page.

=begin testing

use CGI;

$cgi = CGI->new( { Finish => 1 } );
local $fm->{cgi} = $cgi;
local $fm->{page_number} = 3;
ok($fm->finished(), "User is finished (clicked Finish on last page)");

$cgi = CGI->new("");
local $fm->{cgi} = $cgi;
local $fm->{page_number} = 3;
ok($fm->finished(), "User is finished (last page, pressed enter)");

$cgi = CGI->new("");
local $fm->{cgi} = $cgi;
local $fm->{page_number} = 1;
ok(!$fm->finished(), "User is NOT finished (not last page, pressed enter)");

$cgi = CGI->new({ Previous => 1 });
local $fm->{cgi} = $cgi;
local $fm->{page_number} = 2;
ok(!$fm->finished(), "User is NOT finished (last page, didn't press enter)");

=end testing

=cut

sub finished {
    my $self = shift;
    if ($self->{cgi}->param("Finish") 
        and $self->{page_number} >= @{$self->form->{pages}}) {
        # note the difference between this test and the one in is_last_page()
        # ... it's a fencepost thing.  In the case of is_last_page we want
        # to see if we're *on* the last page, but here we want to see if
        # we're *past* it.

        return 1;
    } elsif ($self->user_pressed_enter() 
        and $self->{page_number} >= @{$self->form->{pages}}) {
        return 1;
    } else {
        return 0;
    }
}

=head2 user_pressed_enter()

A weirdness in the HTML spec and/or 
browser implementations thereof means that hitting "enter" on a 
single-text-field form will submit the form without any value
being passed.  Worse yet, at least one browser is reported to
automatically choose the first submit button on the form, in our
case "Previous", which is just WRONG but I can't see any way to
work around that.

So this routine tells you if the user just hit enter.  Returns 1 if they
did, or 0 otherwise.

=begin testing

use CGI;

my $cgi = CGI->new("");
local $fm->{cgi} = $cgi;
ok($fm->user_pressed_enter(), "User pressed enter");

$cgi = CGI->new({ Next => "foo" });
local $fm->{cgi} = $cgi;
ok(!$fm->user_pressed_enter(), "User clicked a button");

=end testing

=cut

sub user_pressed_enter {
    my $self = shift;
    unless ( $self->{cgi}->param("Previous") or
            $self->{cgi}->param("Next") or
            $self->{cgi}->param("Finish") ) {
        return 1;
    } else {
        return 0;
    }
}

=head2 $fm->form()

Gets the form we're dealing with.  With no args, returns an hashref to 
the form data structure. 


=for testing
my $form = $fm->form();
is(ref $form, "HASH", "form data structure is a hash");

=cut

sub form {
    my ($fm) = @_;
    return $fm->{xml};
}

=pod

=head2 $fm->page()

Gets the current page we're dealing with, as a hashref.

=for testing
local $fm->{page_number} = 0;
my $page = $fm->page();
is(ref $page, "HASH", "page data structure is a hash");

=cut

sub page {
    my ($fm) = @_;
    return $fm->form->{pages}->[$fm->{page_number}]
}

=pod

=head2 get_page_enctype

Returns the appropriate encoding type for this page. A page that uses
FILE fields must also use the multipart/form-data encoding type. Any other
page may use either, but the default is to use the older and more compatible
application/x-www-urlencoded.

=for testing
local $fm->{page_number} = 0;
local $fm->page->{fields}->[0]->{type} = 'text';
is($fm->get_page_enctype(), 'application/x-www-urlencoded', 
   'Detected standard enctype');
local $fm->page->{fields}->[0]->{type} = 'file';
is($fm->get_page_enctype(), 'multipart/form-data',
   'Detected multipart enctype');

=cut

sub get_page_enctype
{
    my $self = shift;
    foreach my $field (@{$self->page->{fields}}) {
	if ($field->{type} eq 'file') {
	    return 'multipart/form-data';
	}
    }
    return 'application/x-www-urlencoded';
}

=head2 $self->clear_navigation_params()

Clear out the nagivation params Next, Previous, Finish and wherenext.
Otherwise they stick around in CGI::Persistent and cause havoc next time
you try to navigate.

=begin testing

local $fm->{cgi} = CGI->new({
    Previous => 1,
    Next => 1,
    Finish => 1,
    wherenext => 1,
});

$fm->clear_navigation_params();
is($fm->{cgi}->param("Previous"), undef, "Clear Previous param");
is($fm->{cgi}->param("Next"), undef, "Clear Next param");
is($fm->{cgi}->param("Finish"), undef, "Clear Finish param");
is($fm->{cgi}->param("wherenext"), undef, "Clear wherenext param");

=end testing

=cut

sub clear_navigation_params {
    my $self = shift;

    foreach ( qw( Previous Next Finish wherenext ) ) {
        $self->{cgi}->delete($_) if defined $self->{cgi}->param($_);
    }
}



return "FALSE";     # true value

=pod

=head1 SEE ALSO

CGI::FormMagick;

=cut
