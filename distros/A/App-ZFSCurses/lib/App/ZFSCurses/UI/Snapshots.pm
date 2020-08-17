package App::ZFSCurses::UI::Snapshots;

use 5.10.1;
use strict;
use warnings;

use Curses;
use Curses::UI;
use Text::Wrap;

use App::ZFSCurses::WidgetFactory;
use App::ZFSCurses::Backend;
use App::ZFSCurses::Text;

my $factory = App::ZFSCurses::WidgetFactory->new();
my $backend = App::ZFSCurses::Backend->new();
my $text    = App::ZFSCurses::Text->new();

my $cui = Curses::UI->new(
    -color_support => 1,
    -clear_on_exit => 1,
    -mouse_support => 1
);

my $current_snapshot;
my $main_listbox;
my $main_window;
my $top_label;
my $footer;
my $widget;

=head1 NAME

App::ZFSCurses::UI::Snapshots - Draw a list of ZFS snapshots.

=cut

=head1 VERSION

Version 1.210.

=cut

our $VERSION = '1.210';

=head1 SYNOPSIS

The App::ZFSCurses::UI::Snapshots module is in charge of drawing a list of ZFS
snapshots.

=cut

=head1 METHODS

=head2 new

Create an instance of App::ZFSCurses::UI.

=cut

sub new {
    my $class = shift;
    return bless {}, $class;
}

=head2 draw_and_run

Draw and run the UI. Also perform a couple of checks before actually running
the UI which are: 1) checking whether the 'zfs' command is actually installed,
2) checking whether the user is root (required for tweaking properties).

=cut

sub draw_and_run {
    my $self = shift;

    if ( $backend->is_zfs_installed() eq -1 ) {
        $cui->error(
            -message => $text->no_zfs_command_found(),
            -title   => $text->title(),
            -tfg     => 'red',
            -fg      => 'red',
            -buttons => [ { -label => '[ Exit ]' } ]
        );

        exit(-1);
    }

    if ( $< ne 0 ) {
        my $return = $cui->error(
            -message => $text->non_root_user(),
            -title   => $text->title(),
            -tfg     => 'red',
            -fg      => 'red',
            -buttons =>
              [ { -label => '[ Continue anyway ]' }, { -label => '[ Exit ]' } ]
        );

        exit(0) if $return eq 1;
    }

    my $main = $cui->add( 'main', 'Window' );

    my $header = $main->add(
        'header', 'Label',
        -text          => $text->title_snapshots(),
        -textalignment => 'left',
        -bold          => 1,
        -fg            => 'white',
        -bg            => 'blue',
        -y             => 0,
        -width         => -1,
        -paddingspaces => 1,
    );

    $main_window = $cui->add(
        'main_window', 'Window',
        -padtop    => 2,
        -padbottom => 3
    );

    $top_label = $main_window->add(
        'top_label', 'Label',
        -text    => $text->top_label_snapshots(),
        -padleft => 1,
        -fg      => 'blue',
        -width   => -1
    );

    draw_main_listbox();
    draw_buttons();

    $footer = $main->add(
        'footer', 'Label',
        -text          => $text->footer(),
        -textalignment => 'left',
        -bold          => 1,
        -bg            => 'black',
        -fg            => 'white',
        -y             => -1,
        -width         => -1,
        -paddingspaces => 1,
    );

    $header->draw();
    $footer->draw();

    $main_window->draw();
    $main_window->focus();

    $cui->set_binding( \&exit_dialog, "\cQ" );
    $cui->mainloop;
}

=head2 exit_dialog

Callback when Ctrl+q is pressed. Draw a dialog to ask user for confirmation if
he wants to quit the program.

=cut

sub exit_dialog {
    my $return = $cui->dialog(
        -message => $text->exit_dialog(),
        -tfg     => 'red',
        -fg      => 'red',
        -buttons => [ { -label => '[ Yes ]' }, { -label => '[ No ]' } ]
    );

    exit(0) if $return eq 0;
}

=head2 show_help

Callback when F1 is pressed. Draw a dialog to print info about the selected
property.

=cut

sub show_help {
    my $selected = $main_listbox->get;

    return if !defined $selected;
    chomp $selected;

    return if $selected =~ m/^(PROPERTY)/;

    my ( $property, undef, undef ) = split /\s+/, $selected;
    my $help_message = $text->help_messages()->{$property};

    my $dialog_msg;
    if ( defined $help_message and ( $help_message ne '' ) ) {
        $dialog_msg = $help_message;
    }
    else {
        $dialog_msg = $text->no_help_found($property);
    }

    $cui->dialog(
        -title   => $text->title(),
        -message => $dialog_msg
    );
}

=head2 draw_buttons

Draw the buttons shown at the bottom left of the screen.

NOTE: There are severals of these functions. They are called when going back
and forth from one screen to another to redraw some parts of the screen such as
buttons and labels.

=cut

sub draw_buttons {
    my $buttons = [];

    push @$buttons,
      {
        -label   => '[ Properties ]',
        -onpress => \&onpress_show_snapshot_properties
      };

    push @$buttons,
      {
        -label   => '[ Destroy ]',
        -onpress => \&onpress_destroy
      }
      if $< eq 0;

    $main_window->add(
        'property_destroy_bbox',
        'Buttonbox',
        -y               => -1,
        -padleft         => 1,
        -buttonalignment => 'left',
        -fg              => 'blue',
        -buttons         => $buttons
    );
}

=head2 draw_main_listbox

Draw the main listbox.

=cut

sub draw_main_listbox {
    $main_listbox = $main_window->add(
        'main_listbox', 'Listbox',
        -y          => 3,
        -padleft    => 1,
        -padright   => 1,
        -padbottom  => 2,
        -fg         => 'blue',
        -bg         => 'black',
        -wraparound => 1,
        -values     => $backend->get_zfs_snapshots()
    );
}

=head2 draw_go_back_bbox

Draw the "Go back" button box.

=cut

sub draw_go_back_bbox {
    $main_window->add(
        'go_back_bbox',
        'Buttonbox',
        -y               => -1,
        -padleft         => 1,
        -buttonalignment => 'left',
        -fg              => 'blue',
        -buttons         => [
            {
                -label   => '[ Go back ]',
                -onpress => \&onpress_back_to_snapshots_list
            }
        ]
    );
}

=head2 draw_snapshot_properties_screen

Draw the snapshot properties screen.

=cut

sub draw_snapshot_properties_screen {
    my $snapshot = shift;

    $top_label->text( $text->top_label_properties( $snapshot, "snapshot" ) );
    $top_label->draw();

    $footer->text( $text->footer( $text->f1_help() ) );
    $footer->draw();

    $main_window->delete('property_destroy_bbox');
    draw_go_back_bbox();
    $main_window->draw();

    $cui->set_binding( \&show_help, KEY_F(1) );

    $main_listbox->values( $backend->get_zfs_properties($snapshot) );
    $main_listbox->draw();
    $main_listbox->focus();
}

=head2 onpress_show_snapshot_properties

Callback when a snapshot is selected and shown.

=cut

sub onpress_show_snapshot_properties {
    my $this     = shift;
    my $selected = $main_listbox->get;

    if ( !defined $selected ) {
        $this->root->dialog(
            -message => $text->select_snapshot(),
            -title   => $text->title()
        ) and return;
    }

    chomp $selected;

    return if $selected =~ m/^(NAME|no datasets available)/;

    my ( $snapshot, undef, undef, undef, undef ) = split /\s+/, $selected;

    $current_snapshot = $snapshot;
    draw_snapshot_properties_screen($current_snapshot);
}

=head2 onpress_destroy

Callback when a snapshot is to be destroyed.

=cut

sub onpress_destroy {
    my $this     = shift;
    my $selected = $main_listbox->get;

    if ( !defined $selected ) {
        $this->root->dialog(
            -message => $text->select_snapshot(),
            -title   => $text->title()
        ) and return;
    }

    chomp $selected;

    return if $selected =~ m/^(NAME|no datasets available)/;

    my ( $snapshot, undef, undef, undef, undef ) = split /\s+/, $selected;

    my $yesno = $cui->dialog(
        -message => $text->destroy_confirmation('snapshot', $snapshot),
        -title   => $text->title(),
        -tfg     => 'red',
        -fg      => 'red',
        -buttons => [ { -label => '[ Yes ]' }, { -label => '[ No ]' } ]
    );

    return if $yesno eq 1;

    $backend->destroy_zfs($snapshot);

    $main_listbox->values( $backend->get_zfs_snapshots() );
    $main_listbox->draw();
    $main_listbox->focus();
}

=head2 onpress_back_to_snapshots_list

Callback when the user goes back to the list of snapshots.

=cut

sub onpress_back_to_snapshots_list {
    $top_label->text( $text->top_label_snapshots() );
    $top_label->draw();

    $footer->text( $text->footer() );
    $footer->draw();

    $main_window->delete('go_back_bbox');
    draw_buttons();
    $main_window->draw();

    # Workaround found thanks to Perl Monks.
    $cui->clear_binding( '__routine_' . \&show_help );

    $main_listbox->values( $backend->get_zfs_snapshots() );
    $main_listbox->draw();
    $main_listbox->focus();
}

=head1 SEE ALSO

The L<Curses::UI> Perl module.

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) BSD License.

See the LICENSE file.

=cut

1;
