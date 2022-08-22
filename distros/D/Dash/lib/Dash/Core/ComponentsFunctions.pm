package Dash::Core::ComponentsFunctions;
use strict;
use warnings;
use Module::Load;
use Exporter::Auto;

sub Checklist {
    load Dash::Core::Components::Checklist;
    if ( Dash::Core::Components::Checklist->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Checklist->new(@_);
}

sub ConfirmDialog {
    load Dash::Core::Components::ConfirmDialog;
    if ( Dash::Core::Components::ConfirmDialog->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::ConfirmDialog->new(@_);
}

sub ConfirmDialogProvider {
    load Dash::Core::Components::ConfirmDialogProvider;
    if ( Dash::Core::Components::ConfirmDialogProvider->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::ConfirmDialogProvider->new(@_);
}

sub DatePickerRange {
    load Dash::Core::Components::DatePickerRange;
    if ( Dash::Core::Components::DatePickerRange->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::DatePickerRange->new(@_);
}

sub DatePickerSingle {
    load Dash::Core::Components::DatePickerSingle;
    if ( Dash::Core::Components::DatePickerSingle->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::DatePickerSingle->new(@_);
}

sub Dropdown {
    load Dash::Core::Components::Dropdown;
    if ( Dash::Core::Components::Dropdown->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Dropdown->new(@_);
}

sub Graph {
    load Dash::Core::Components::Graph;
    if ( Dash::Core::Components::Graph->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Graph->new(@_);
}

sub Input {
    load Dash::Core::Components::Input;
    if ( Dash::Core::Components::Input->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Input->new(@_);
}

sub Interval {
    load Dash::Core::Components::Interval;
    if ( Dash::Core::Components::Interval->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Interval->new(@_);
}

sub Link {
    load Dash::Core::Components::Link;
    if ( Dash::Core::Components::Link->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Link->new(@_);
}

sub Loading {
    load Dash::Core::Components::Loading;
    if ( Dash::Core::Components::Loading->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Loading->new(@_);
}

sub Location {
    load Dash::Core::Components::Location;
    if ( Dash::Core::Components::Location->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Location->new(@_);
}

sub LogoutButton {
    load Dash::Core::Components::LogoutButton;
    if ( Dash::Core::Components::LogoutButton->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::LogoutButton->new(@_);
}

sub Markdown {
    load Dash::Core::Components::Markdown;
    if ( Dash::Core::Components::Markdown->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Markdown->new(@_);
}

sub RadioItems {
    load Dash::Core::Components::RadioItems;
    if ( Dash::Core::Components::RadioItems->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::RadioItems->new(@_);
}

sub RangeSlider {
    load Dash::Core::Components::RangeSlider;
    if ( Dash::Core::Components::RangeSlider->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::RangeSlider->new(@_);
}

sub Slider {
    load Dash::Core::Components::Slider;
    if ( Dash::Core::Components::Slider->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Slider->new(@_);
}

sub Store {
    load Dash::Core::Components::Store;
    if ( Dash::Core::Components::Store->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Store->new(@_);
}

sub Tab {
    load Dash::Core::Components::Tab;
    if ( Dash::Core::Components::Tab->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Tab->new(@_);
}

sub Tabs {
    load Dash::Core::Components::Tabs;
    if ( Dash::Core::Components::Tabs->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Tabs->new(@_);
}

sub Textarea {
    load Dash::Core::Components::Textarea;
    if ( Dash::Core::Components::Textarea->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Textarea->new(@_);
}

sub Upload {
    load Dash::Core::Components::Upload;
    if ( Dash::Core::Components::Upload->can("children") ) {
        if ( ( ( scalar @_ ) % 2 ) ) {
            unshift @_, "children";
        }
    }
    return Dash::Core::Components::Upload->new(@_);
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Core::ComponentsFunctions

=head1 VERSION

version 0.11

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
