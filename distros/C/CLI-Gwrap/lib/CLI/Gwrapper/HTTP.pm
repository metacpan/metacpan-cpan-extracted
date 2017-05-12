#===============================================================================
#
#      PODNAME:  Gwrapper::HTTP.pm
#     ABSTRACT:  provides the HTTP Gwrapper role for CLI::Gwrap
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/07/2013 05:13:03 PM
#===============================================================================

package CLI::Gwrapper::HTTP;
use 5.008;
use strict;
use warnings;

use Moo;
use Types::Standard qw( Str Bool ArrayRef CodeRef InstanceOf );
with 'CLI::Gwrapper';   # this module must satisfy the Gwrapper role
use Carp;
use IO::File;
use File::Spec;
use Readonly;
use Dancer qw( :moose );

our $VERSION = '0.030'; # VERSION

get '/gwrap' => sub {

    if (request->is_ajax) {
        return parse_ajax;
    }
    else {
        return html;
    }
}

sub title {     # required by Gwrapper role
    my ($self, $new) = @_;

    if (@_ > 1) {
        $self->frame->SetTitle($new);
        $self->{title} = $new;
    }
    return $self->{title};
}

sub run {       # required by Gwrapper role
    my ($self) = @_;

    $self->_populate_window;   # fill in all the parts
    $self->frame->Show;     # put it up on the screen
$self->frame->SetBackgroundColour(Wx::Colour->new(200,200,200));
    $self->MainLoop;        # run the main event loop
}

sub _populate_window {
    my ($self) = @_;

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $self->main_v_boxsizer($sizer);

    $sizer->Add(
        $self->_populate_cmd_h_boxsizer,
        1,                      # proportion
        wxEXPAND | wxALL,       # expand all directions
        0);                     # border
    $sizer->Add(
        $self->_populate_args_grid('opts'),
        1,                      # proportion
        wxEXPAND | wxALL,       # expand all directions
        0);                     # border
    if ($self->advanced and @{$self->advanced}) {
        # TODO CollapsablePane
        $sizer->Add(
            $self->_populate_args_grid('advanced'),
            1,                      # proportion
            wxEXPAND | wxALL,       # expand all directions
            0);                     # border
    }
    $sizer->Add(
        $self->_populate_control_h_boxsizer,
        1,                      # proportion
        wxEXPAND | wxALL,       # expand all directions
        0);                     # border

    # automatic layout
    $self->frame->SetAutoLayout( 1 );
    $self->frame->SetSizer( $sizer );
    # size the window optimally and set its minimal size
    $sizer->Fit( $self->frame );
    $sizer->SetSizeHints( $self->frame );
}

1;



=pod

=head1 NAME

Gwrapper::HTTP.pm - provides the HTTP Gwrapper role for CLI::Gwrap

=head1 VERSION

version 0.030

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
