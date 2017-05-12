# -*- perl -*-

# Copyright (c) 2009 AdCopy
# Author: Jeff Weisberg
# Created: 2009-Oct-28 15:37 (EDT)
# Function: end-programmer convenience object
#
# $Id: Request.pm,v 1.1 2010/11/01 18:42:00 jaw Exp $

package AC::MrGamoo::Submit::Request;
use AC::MrGamoo::Submit::TieIO;
use AC::Misc;
use AC::Daemon;
use AC::ISOTime;
use strict;


sub new {
    my $class = shift;
    my $c     = shift;

    my $me = bless {
        file	=> $c->{file},
        config	=> $c->{content}{config},
        initres	=> $c->{initres},
        @_,
    }, $class;

    $AC::MrGamoo::User::R = $me;
    return $me;
}


# get config param
sub config {
    my $me = shift;
    my $k  = shift;

    return $me->{config}{$k};
}

# get result of init block
sub initvalue {
    my $me = shift;

    return $me->{initres};
}

# let user output a key+value via $R->output(...)
sub output {
    my $me = shift;
    $me->{func_output}->( @_ ) if $me->{func_output};
}
# and indicate progress via $R->progress
sub progress {
    my $me = shift;
    $me->{func_progress}->( @_ ) if $me->{func_progress};
}


sub redirect_io {
    my $me = shift;

    tie *STDOUT, 'AC::MrGamoo::Submit::TieIO', $me->{eu_print_stdout};
    tie *STDERR, 'AC::MrGamoo::Submit::TieIO', $me->{eu_print_stderr};
}

sub print_stderr {
    my $me = shift;

    $me->{eu_print_stderr}->( @_ ) if $me->{eu_print_stderr};
}

sub print {
    my $me = shift;

    $me->{eu_print_stdout}->( @_ ) if $me->{eu_print_stdout};
}

*print_stdout = \&print;


1;
