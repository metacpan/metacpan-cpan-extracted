#===============================================================================
#
#      PODNAME:  CLI::Gwrapper::wxGrid
#     ABSTRACT:  CLI::Gwrap graphical wrapper in a wxGrid
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@LucidPort.com
#      CREATED:  07/08/2013 12:08:30 PM
#===============================================================================

use 5.008;
use strict;
use warnings;

package CLI::Gwrapper::wxGrid;

use Moo;
extends 'CLI::Gwrapper::Wx::App';
with 'CLI::Gwrapper';   # this module must satisfy the Gwrapper role
use Types::Standard qw( Str Int Bool ArrayRef CodeRef InstanceOf );

use Carp;
use Scalar::Util(qw( looks_like_number ));
use Wx qw(
    :sizer
    :combobox
    :textctrl
    wxNOT_FOUND wxID_EXIT
    wxTELETYPE
);
use Wx::Event qw(
    EVT_BUTTON
    EVT_COLLAPSIBLEPANE_CHANGED
);

has 'sizer'            => (is => 'rw', isa => InstanceOf['Wx::BoxSizer']);
has 'notebook'         => (is => 'rw', isa => InstanceOf['Wx::Notebook']);
has 'Command_page'     => (is => 'rw', isa => InstanceOf['Wx::Panel']);
has 'STDOUT_page'      => (is => 'rw', isa => InstanceOf['Wx::Panel']);
has 'STDERR_page'      => (is => 'rw', isa => InstanceOf['Wx::Panel']);
has 'STDOUT_text_ctrl' => (is => 'rw', isa => InstanceOf['Wx::TextCtrl']);
has 'STDERR_text_ctrl' => (is => 'rw', isa => InstanceOf['Wx::TextCtrl']);

our $VERSION = '0.030'; # VERSION

sub BUILD {
    my ($self, $params) = @_;

    $self->_populate_window($self->panel);   # fill in all the parts

    $self->frame->Show;     # put it up on the screen
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

    $self->MainLoop;        # run the main event loop
}

sub _populate_window {
    my ($self, $parent) = @_;

    $self->notebook(Wx::Notebook->new($parent));

    my $sizer = Wx::BoxSizer->new(wxVERTICAL);
    $self->sizer($sizer);
    $sizer->Add(
        $self->notebook,
        1,                      # proportion
        wxEXPAND | wxALL,       # flags
        0,                      # border
    );

    $self->_populate_command_page;
    # add the control buttons at the bottom
    $sizer->Add(
        $self->_populate_control_h_boxsizer($parent),
        0,                      # proportion
        wxEXPAND | wxALL,       # flags
        8,                      # border
    );

    $sizer->SetSizeHints($self->frame);
    $parent->SetSizer( $sizer );

    $parent->Layout;
}

sub _populate_command_page {
    my ($self) = @_;

    my $parent = $self->_build_page('Command');
    my $sizer = Wx::BoxSizer->new(wxVERTICAL);

    $sizer->Add(
        $self->_populate_cmd_h_boxsizer($parent),
        0,                      # proportion
        wxEXPAND | wxALL,       # flags
        4,                      # border
    );
    if (my $opt_sizer = $self->_populate_args_grid($parent, 'opts')) {
        $sizer->Add(
            $opt_sizer,
            0,                      # proportion
            wxEXPAND | wxALL,       # flags
            0,                      # border
        );
    }
    if ($self->advanced
        and @{$self->advanced}) {
        my $collapser = Wx::CollapsiblePane->new(
            $parent,            # parent
            -1,                 # window ID
            'Advanced',         # collapser button label
        );
        my $pane = $collapser->GetPane;
        if (my $opt_sizer = $self->_populate_args_grid($pane, 'advanced')) {
            $pane->SetSizer($opt_sizer);
            $sizer->Add(
                $collapser,
                0,                  # proportion of 0 recommended for CollapsablePane
                wxEXPAND | wxALL,   # flags
                0,                  # border
            );
            EVT_COLLAPSIBLEPANE_CHANGED(
                $parent,
                $collapser,
                sub {
                    $self->notebook->InvalidateBestSize;
                    $self->sizer->SetSizeHints($self->frame);
                 #  $self->panel->Layout;
                },
            );
        }
    }
    $parent->SetSizer($sizer);
}

# several opt types need a TextCtrl style widget
sub _text_ctrl {
    my ($self, $opt, $parent, $sizer) = @_;

    my @opts;
    if (defined $opt->width) {
        push @opts, [$opt->width, -1];
    }
    my $text_ctrl = Wx::TextCtrl->new(
        $parent,        # parent window
        -1,             # window ID
        $opt->state || '',   # label
        [-1, -1],
        @opts,
    );

    my $hsizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $opt->widget($hsizer);

    my $vsizer = Wx::BoxSizer->new(wxVERTICAL);  # this prevents TextCtrl from expanding vertically
    $hsizer->Add(
        $vsizer,
        defined $opt->width ? 0 : 1,              # proportion
        wxALIGN_CENTER_VERTICAL,
        0,              # border
    );

    my $vsizer_opts = wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT | wxLEFT;
    if (not defined $opt->width) {
        $vsizer_opts |= wxEXPAND;
    }
    $vsizer->Add(
        $text_ctrl,
        0,                      # proportion
        $vsizer_opts,
        0,                      # border
    );
    my $label = Wx::StaticText->new(
        $parent,        # parent window
        -1,             # window ID
        $opt->name_for_display($self->verbatim),   # label
    );
    $hsizer->Add(
        $label,
        0,              # proportion
        wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT | wxRIGHT | wxLEFT,
        4,              # border
    );
#$label->SetForegroundColour(Wx::Colour->new(0,255,0));

    $sizer->Add(
        $hsizer,
        0,
        wxEXPAND | wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT | wxLEFT | wxRIGHT,
        4,
    );
    $label->SetToolTip($opt->description);
    $text_ctrl->SetToolTip($opt->description);

    $opt->retriever(
        sub {
            my $last_line = $text_ctrl->GetNumberOfLines - 1;
            my $text = '';
            for my $ii (0 .. $last_line) {
                $text .= $text_ctrl->GetLineText($ii);
            }
            return '' if not $text;
            my $name_for_CLI = $opt->name_for_CLI;
            my $joiner = $opt->joiner;
            if ($opt->type eq 'hash') {
                my @opts;
                for my $token (split (/\s+/, $text)) {
                    if (defined $token and $token ne '') {
                        if ($name_for_CLI) {
                            $token = qq[$name_for_CLI$joiner$token];
                        }
                        push @opts, $token;
                    }
                }
                return join ' ', @opts;
            }
            elsif ($opt->type eq 'incremental') {
                if (looks_like_number($text)) {
                    my $count = $text;
                    $text = "$name_for_CLI " x $count;
                }
                else {
                    $text = $name_for_CLI;
                }
            }
            if ($name_for_CLI) {
                #$text =~ s/"/\\"/g; # escape quote (TODO may need more escapes here?)
                $text = qq[$name_for_CLI$joiner$text];
            }
            return $text;
        }
    );
}

# subs to build widget and attach a retriever function to the opt
my %widget_builders = (
    check => sub {
        my ($self, $opt, $parent, $sizer) = @_;

        my $widget = Wx::CheckBox->new(
            $parent,
            -1,
            $opt->name_for_display($self->verbatim),   # label
            [-1, -1],
            [-1, -1],
            #wxALIGN_RIGHT,      # label to the left
        );
        $opt->widget($widget);
        $widget->SetValue($opt->state);
        $sizer->Add(
            $widget,
            0,
            wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT | wxLEFT | wxRIGHT,
            4,
        );
        $widget->SetToolTip($opt->description);
        $opt->retriever(
            sub {
                if ($widget->GetValue) {
                    return $opt->name_for_CLI;
                }
                return '';
            }
        );
    },
    radio => sub {
        my ($self, $opt, $parent, $sizer) = @_;

        my $hsizer = Wx::BoxSizer->new(wxHORIZONTAL);
        $opt->widget($hsizer);

        my $choice = Wx::Choice->new(
            $parent,        # parent
            -1,             # window ID
            [-1, -1],       # position
            [-1, -1],       # size
            $opt->choices,  # the choices
            0,              # style (sorted or not)
        );
        $hsizer->Add(
            $choice,
            0,              # proportion
            wxEXPAND,       # flags
            0,              # border
        );
        if (my $state = $opt->state) {
            for my $ii (0 .. $#{$opt->choices}) {
                if ($state eq $opt->choices->[$ii]) {
                    $choice->SetSelection($ii);
                    last;
                }
            }
        }

        my $label = Wx::StaticText->new(
            $parent,        # parent
            -1,             # window ID
            $opt->name_for_display($self->verbatim),   # label
        );
        $hsizer->Add(
            $label,
            0,                      # proportion
            wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT | wxLEFT,
            10,                     # border
        );
#$label->SetForegroundColour(Wx::Colour->new(0,0,255));
        $sizer->Add(
            $hsizer,
            0,
            wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT | wxLEFT | wxRIGHT,
            4,
        );
        $label->SetToolTip($opt->description);
        $choice->SetToolTip($opt->description);

        $opt->retriever(
            sub {
                my $idx = $choice->GetSelection;
                return '' if ($idx eq wxNOT_FOUND or $idx == 0);
                my $choice = $opt->choices->[$idx];
                if ((my $name_for_CLI = $opt->name_for_CLI) ne '') {
                    return "$name_for_CLI=$choice";
                }
                return $choice;
            }
        );
    },
    string => sub {
        _text_ctrl(@_);
    },
    hash => sub {
        _text_ctrl(@_);
    },
    integer => sub {
        _text_ctrl(@_);
    },
    float => sub {
        _text_ctrl(@_);
    },
    incremental => sub {
        _text_ctrl(@_);
    },
    label => sub {
        my ($self, $opt, $parent, $sizer) = @_;

        my $label = Wx::StaticText->new(
            $parent,        # parent window
            -1,             # window ID
            $opt->name_for_display($self->verbatim),   # label
        );

        $sizer->Add(
            $label,
            0,
            wxEXPAND | wxALIGN_CENTER_VERTICAL | wxALIGN_LEFT | wxLEFT | wxRIGHT,
            4,
        );
        $label->SetToolTip($opt->description);

        $opt->retriever(
            sub {
                return '';
            }
        );
    }
);

sub _build_opt_widget {
    my ($self, $opt, $parent, $sizer) = @_;

    my $type = $opt->type;
    my $builder = $widget_builders{$type}
        || carp("Unknown option type: $type\n");
    $self->$builder($opt, $parent, $sizer);
}

# the CLI command, and unnamed opts (if any)
sub _populate_cmd_h_boxsizer {
    my ($self, $parent) = @_;

    my $grid = Wx::GridSizer->new(1, 2, 0, 0);

    my $cmd = $self->command->[0]; # label
    my $long_cmd = $self->command->[1]; # label
    if ($long_cmd and
        $long_cmd ne $cmd) {
        $cmd = "$cmd ($long_cmd)";
    }
    my $label = Wx::StaticText->new(
        $parent,        # parent
        -1,             # window ID
        $cmd,           # label
    );
    $grid->Add(
        $label,
        0,                      # proportion
        wxALIGN_CENTRE_VERTICAL | wxALIGN_CENTER | wxLEFT | wxRIGHT,
        10,                     # border
    );
    $label->SetToolTip($self->description);
#$label->SetForegroundColour(Wx::Colour->new(255,0,0));

    if ($self->main_opt) {
        my $v = $self->{verbatim} || 0;
        $self->{verbatim} = 1;  # turn verbatim on for this
        $self->_build_opt_widget($self->main_opt, $parent, $grid);
        $self->{verbatim} = $v;
    }

    return $grid;
}

sub _populate_args_grid {
    my ($self, $parent, $name) = @_;

    return if (not my $opts = @{$self->$name});

    my $opts_rows = ($opts + $self->columns - 1) / $self->columns;
    my $grid = Wx::GridSizer->new($opts_rows, $self->columns, 0, 0);

    for my $opt (@{$self->{$name}}) {
        $self->_build_opt_widget($opt, $parent, $grid);
    }

    return $grid;
}

my @buttons = (
    { name => 'Execute',  cb => \&onClick_Execute,                      },
    { name => 'Help',     cb => \&onClick_Help,                         },
    { name => 'Close',    cb => \&onClick_Close,    flags => wxID_EXIT, },
);

# add Execute, Help, and Done buttons
sub _populate_control_h_boxsizer {
    my ($self, $parent) = @_;

    my $num_buttons = scalar @buttons;
    $num_buttons -- if (not $self->help);
    my $grid = Wx::GridSizer->new(1, , 0, 0);

    for my $b (@buttons) {
        next if ($b->{name} eq 'Help' and
                 not $self->help);
        my $button = Wx::Button->new(
            $parent,        # parent
            -1,             # ID
            $b->{name},     # button label
        );
        # attach callback to button press
        EVT_BUTTON(
            $parent,        # parent
            $button,        # the button
            sub {           # callback funtion
                $b->{cb}->($self, @_);
            },
        );
        $grid->Add(
            $button,
            1,              # proportion
            wxALIGN_CENTER | wxALIGN_CENTER_HORIZONTAL | wxALL,       # flags
            0,              # border
        );
    }

    return $grid;
}

# Button callbacks
sub onClick_Execute {
    my ($self, $button, $event) = @_;

    my @cmd_line = (
        $self->command->[0],    # the CLI command
    );
    if ($self->main_opt) {
        my $opt_string = $self->main_opt->retriever->();
        push @cmd_line, $opt_string if (defined $opt_string and $opt_string ne '');
    }
    for my $opt (@{$self->opts}, @{$self->advanced}) {
        my $opt_string = $opt->retriever->();
        push @cmd_line, $opt_string if (defined $opt_string and $opt_string ne '');
    }
  # printf "Execute: %s\n", join(' ', @cmd_line);
    $self->_execute_and_show(\@cmd_line, $self->persist);

    if (not $self->persist) {
        $self->frame->Close(1);
    }
}

sub onClick_Help {
    my ($self, $button, $event) = @_;

    my @cmd_line = (
        $self->command->[0],    # the CLI command
        $self->help,            # the option that invokes help
    );
  # printf "Help: %s\n", join(' ', @cmd_line);
    $self->_execute_and_show(\@cmd_line, 'persist');
}

sub onClick_Close {
    my ($self, $button, $event) = @_;

  # print "Close\n";
    $self->frame->Close(1);
}

sub _build_page {
    my ($self, $type) = @_;

    my $name = "${type}_page";
    return $self->$name if ($self->$name);

    my $panel = Wx::Panel->new($self->notebook);
    $self->$name($panel);
    $self->notebook->AddPage($panel, $type);

    return $panel;
}

sub _build_text_ctrl {
    my ($self, $type) = @_;

    my $name = "${type}_text_ctrl";
    return $self->$name if ($self->$name);

    my $panel = $self->_build_page($type);
    my $text_ctrl = Wx::TextCtrl->new(
        $panel,
        -1,         # window ID
        '',         # text
        [-1, -1],
        [-1, -1],
        wxTE_READONLY | wxTE_PROCESS_TAB | wxTE_MULTILINE | wxHSCROLL | wxTE_RICH,
    );
    $self->$name($text_ctrl);
    my $font = $text_ctrl->GetFont();
    $font = Wx::Font->new(
        $font->GetPointSize,
        wxTELETYPE,
        $font->GetStyle,
        $font->GetWeight,
        $font->GetUnderlined,
    );
    $text_ctrl->SetFont($font);

    my $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
    $sizer->Add(
        $text_ctrl,
        1,                      # proportion
        wxEXPAND | wxALL,       # flags
        0,                      # border
    );

    $panel->SetSizer( $sizer );

    return $text_ctrl;
}

sub _show_output {
    my ($self, $type, $text) = @_;

    if (my $text_ctrl = $self->{"${type}_text_ctrl"}) {
        $text_ctrl->Remove(0, $text_ctrl->GetLastPosition);
    }

    if ($text) {

        my $page = $self->_build_page($type);
        my $text_ctrl = $self->_build_text_ctrl($type);
        if ($type eq 'STDERR') {
            $text_ctrl->SetDefaultStyle(Wx::TextAttr->new(Wx::Colour->new(255,0,0)));
        }
        $text_ctrl->AppendText($text);
        $self->{"${type}_page"}->Show;
  #     print $text;
    }
    elsif ($self->{"${type}_page"}) {
        $self->{"${type}_page"}->Hide;
    }
}

sub _execute_and_show {
    my ($self, $cmd_line, $persist) = @_;

    my ($status, $output, $errors) = $self->execute_callback($cmd_line);

    if (ref $cmd_line eq 'ARRAY') {
        $cmd_line = join(' ', @{$cmd_line});
    }
    $self->frame->SetTitle(sprintf("%s (exit value => $status)", join(' ', $cmd_line)));

    $self->_show_output('STDOUT', $output);
    $self->_show_output('STDERR', $errors);
}

1;



=pod

=head1 NAME

CLI::Gwrapper::wxGrid - CLI::Gwrap graphical wrapper in a wxGrid

=head1 VERSION

version 0.030

=head1 DESCRIPTION

CLI::Gwrapper::wxGrid provides a CLI::Gwrapper role using wxperl as the
graphics engine.  The top level is a Wx::Notebook, beneath which is a row
of control buttons (Execute, Help, and Close).  Options are presented
inside a Wx::Grid on the first page of the Notebook.  STDOUT and STDERR are
written to a second and third page of the Notebook.

=head1 SEE ALSO

CLI::Gwrap

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

