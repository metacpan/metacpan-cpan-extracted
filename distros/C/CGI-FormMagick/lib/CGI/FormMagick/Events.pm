#!/usr/bin/perl -w 
#
#
# FormMagick (c) 2000-2001 Kirrily Robert <skud@cpan.org>
# Copyright (c) 2000-2002 Mitel Networks Corporation
# This software is distributed under the same licenses as Perl itself;
# see the file COPYING for details.

#
# $Id: Events.pm,v 1.13 2003/02/05 17:18:34 anoncvs_gtkglext Exp $
#

package    CGI::FormMagick;

use strict;
use Carp;

=pod 

=head1 NAME

CGI::FormMagick::Events -- pre/post form/page event handlers

=head1 SYNOPSIS

  use CGI::FormMagick;

=head1 DESCRIPTION

=head2 $fm->form_pre_event()

performs the PRE-EVENT (if any) for the form.  Usually used to do
setup for the application.

this is the routine where we call some routine that will
give us default data for the form, or otherwise
do things that need doing before the form is submitted.

=for testing
TODO: {
    local $TODO = "Write tests for Event.pm!";
    ok(0, "nothing here yet");
}

=cut

sub form_pre_event {
    my ($self) = @_;

    $self->debug_msg("This is the form pre event");

    # find out what the form pre_event action is. 
    my $pre_form_routine = $self->{xml}->{'pre-event'} || return;

    $self->do_external_routine($pre_form_routine);
}

=pod

=head2 $fm->form_post_event()

performs validation and runs the POST-EVENT (if any) otherwise just
prints out the data that the user input

Note: we need to validate EVERY ONE of the form inputs to make
sure malicious attacks don't happen.   See also "SECURITY 
CONSIDERATIONS" in the perldoc for how to get around this :-/

=cut

sub form_post_event {
    my ($self) = @_;
    $self->debug_msg("This is the form post event");
    if ($self->errors()) {
        $self->debug_msg("Looks like we've got some errors");
        #print "<h2>", localise("Validation errors"), "</h2>\n";
        #print "<p>", localise("These validation errors are probably evidence of an attempt to circumvent the data validation on this application.  Please start over again."), "</p>";
        $self->list_error_messages();
    } else {
        $self->debug_msg("Validation successful.");

        # find out what the form post_event action is. 
        my $post_form_routine = $self->{xml}->{'post-event'};

        unless ($self->do_external_routine($post_form_routine)) {
  
            # default form post-event -- print out user data
            print "<p>", localise("The following data was submitted"), "</p>\n";
  
            print "<ul>\n";
            my @params = $self->{cgi}->param;
            foreach my $param (@params) {
                my $value =  $self->{cgi}->param($param);
                print "<li>$param: $value\n";
            }
            print "</ul>\n";
        }
    }
}

=pod

=head2 $fm->page_pre_event()

Performs the PAGE PRE-EVENT (if any).

XXX NEEDS TESTS

=cut

sub page_pre_event {
    my ($self) = @_;
    $self->debug_msg("This is the page pre-event.");
    if (my $pre_page_routine = $self->page->{'pre-event'}) {
        $self->debug_msg("The pre-routine is $pre_page_routine");
        $self->do_external_routine($pre_page_routine);
    }
}

=pod

=head2 $fm->page_post_event()

Performs the PAGE POST-EVENT (if any).

XXX NEEDS TESTS

=cut

sub page_post_event {
    my ($self) = @_;
    $self->debug_msg("This is the page post-event.");
    if (my $post_page_routine = $self->page->{'post-event'}) {
      $self->debug_msg("The post-routine is $post_page_routine");
      $self->do_external_routine($post_page_routine);
    }
}


return "FALSE";  # true value

=pod

=head1 SEE ALSO

CGI::FormMagick

=cut
