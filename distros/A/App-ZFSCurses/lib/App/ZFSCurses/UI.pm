package App::ZFSCurses::UI;

use 5.006;
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

my $current_dataset;
my $main_listbox;
my $main_window;
my $top_label;
my $footer;
my $widget;

=head1 NAME

App::ZFSCurses::UI - the UI drawing logic.

=cut

=head1 VERSION

Version 1.100.

=cut

our $VERSION = '1.100';

=head1 SYNOPSIS

App::ZFSCurses::UI is the meat of the application and is in charge of drawing
the components that make up the UI.

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
        -text          => $text->title(),
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
        -text    => $text->top_label_datasets(),
        -padleft => 1,
        -fg      => 'blue',
        -width   => -1
    );

    draw_main_listbox();
    draw_properties_button();

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

=head2 draw_properties_button

Draw the "Get properties" button.

NOTE: There are severals of these functions. They are called when going back
and forth from one screen to another to redraw some parts of the screen such as
buttons and labels.

=cut

sub draw_properties_button {
    $main_window->add(
        'get_property_bbox',
        'Buttonbox',
        -y               => -1,
        -padleft         => 1,
        -buttonalignment => 'left',
        -fg              => 'blue',
        -buttons         => [
            {
                -label   => '[ Get properties ]',
                -onpress => \&onpress_show_dataset_properties
            }
        ]
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
        -values     => $backend->get_zfs_datasets()
    );
}

=head2 draw_change_go_back_bbox

Draw the "Change properties" and "Go back" button box.

=cut

sub draw_change_go_back_bbox {
    my $buttons = [];

    push @$buttons,
      {
        -label   => '[ Change property ]',
        -onpress => \&onpress_change_property
      }
      if $< eq 0;

    push @$buttons,
      {
        -label   => '[ Go back ]',
        -onpress => \&onpress_back_to_datasets_list
      };

    $main_window->add(
        'change_back_bbox',
        'Buttonbox',
        -y               => -1,
        -padleft         => 1,
        -buttonalignment => 'left',
        -fg              => 'blue',
        -buttons         => $buttons
    );
}

=head2 draw_dataset_properties_screen

Draw the dataset properties screen.

=cut

sub draw_dataset_properties_screen {
    my $dataset = shift;

    $top_label->text( $text->top_label_properties($dataset) );
    $top_label->draw();

    $footer->text( $text->footer( $text->f1_help() ) );
    $footer->draw();

    $main_window->delete('get_property_bbox');
    draw_change_go_back_bbox();
    $main_window->draw();

    $cui->set_binding( \&show_help, KEY_F(1) );

    $main_listbox->values( $backend->get_zfs_properties($dataset) );
    $main_listbox->draw();
    $main_listbox->focus();
}

=head2 draw_property_change_screen

Draw the property change screen.

=cut

sub draw_property_change_screen {
    my ( $property, $value ) = @_;

    $top_label->text('');
    $top_label->draw();

    $footer->text( $text->footer() );
    $footer->draw();

    $main_window->delete('main_listbox');
    $main_window->delete('change_back_bbox');

    my $property_window = $main_window->add(
        'property_window', 'Window',
        -padleft  => 1,
        -padright => 1
    );

    $property_window->add(
        'property_label', 'Label',
        -text => $text->change_property( $current_dataset, $property, $value ),
        -fg   => 'blue',
    );

    $factory->set_container($property_window);

    $widget = $factory->make_widget( $property, $value );

    $property_window->add(
        'property_buttons',
        'Buttonbox',
        -y               => -1,
        -buttonalignment => 'left',
        -fg              => 'blue',
        -buttons         => [
            {
                -label   => '[ OK ]',
                -onpress => sub {
                    my $this      = shift;
                    my $sel_value = $widget->get;
                    $backend->set_zfs_property( $current_dataset, $property,
                        $sel_value );
                    if ( $? eq 0 ) {
                        $this->root->dialog( $text->ok_property($property) );
                    }
                    else {
                        $this->root->dialog( $text->error_property($property) );
                    }
                    onpress_back_to_properties_list();
                }
            },
            {
                -label   => '[ Cancel ]',
                -onpress => \&onpress_back_to_properties_list
            }
        ]
    );

    $property_window->draw();
    $property_window->focus();
}

=head2 onpress_show_dataset_properties

Callback when a dataset is selected and shown.

=cut

sub onpress_show_dataset_properties {
    my $this     = shift;
    my $selected = $main_listbox->get;

    if ( !defined $selected ) {
        $this->root->dialog(
            -message => $text->select_dataset(),
            -title   => $text->title()
        ) and return;
    }

    chomp $selected;

    return if $selected =~ m/^(NAME|no datasets available)/;

    my ( $dataset, undef, undef, undef, undef ) = split /\s+/, $selected;

    $current_dataset = $dataset;
    draw_dataset_properties_screen($current_dataset);
}

=head2 onpress_change_property

Callback when a property is changed.

=cut

sub onpress_change_property {
    my $this = shift;

    my $selected = $main_listbox->get;

    if ( !defined $selected ) {
        $this->root->dialog(
            -message => $text->select_property(),
            -title   => $text->title()
        ) and return;
    }

    chomp $selected;

    return if $selected =~ m/^(PROPERTY)/;

    my ( $property, $value, $source ) = split /\s+/, $selected;

    if ( $factory->is_property_ro($property) eq 0 ) {
        $this->root->dialog(
            -message => $text->property_read_only($property),
            -title   => $text->title()
        ) and return;
    }

    draw_property_change_screen( $property, $value );
}

=head2 onpress_back_to_datasets_list

Callback when the user goes back to the list of datasets.

=cut

sub onpress_back_to_datasets_list {
    $top_label->text( $text->top_label_datasets() );
    $top_label->draw();

    $footer->text( $text->footer() );
    $footer->draw();

    $main_window->delete('change_back_bbox');
    draw_properties_button();
    $main_window->draw();

    # Workaround found thanks to Perl Monks.
    $cui->clear_binding( '__routine_' . \&show_help );

    $main_listbox->values( $backend->get_zfs_datasets() );
    $main_listbox->draw();
    $main_listbox->focus();
}

=head2 onpress_back_to_properties_list

Callback when the user goes back to the list of properties.

=cut

sub onpress_back_to_properties_list {
    $main_window->delete('property_window');
    draw_main_listbox();
    draw_dataset_properties_screen($current_dataset);
}

=head1 SEE ALSO

The L<Curses::UI> Perl module.

=head1 AUTHOR

Patrice Clement <monsieurp at cpan.org>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Patrice Clement.

This is free software, licensed under the (three-clause) clause BSD License.

See the LICENSE file.

=cut

1;
