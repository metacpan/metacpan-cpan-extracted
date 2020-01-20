package Dash::Core::ComponentsFunctions;
use strict;
use warnings;
use Module::Load;
use Exporter::Auto;

sub Checklist {
    load Dash::Core::Components::Checklist;
    return Dash::Core::Components::Checklist->new(@_);
}

sub ConfirmDialog {
    load Dash::Core::Components::ConfirmDialog;
    return Dash::Core::Components::ConfirmDialog->new(@_);
}

sub ConfirmDialogProvider {
    load Dash::Core::Components::ConfirmDialogProvider;
    return Dash::Core::Components::ConfirmDialogProvider->new(@_);
}

sub DatePickerRange {
    load Dash::Core::Components::DatePickerRange;
    return Dash::Core::Components::DatePickerRange->new(@_);
}

sub DatePickerSingle {
    load Dash::Core::Components::DatePickerSingle;
    return Dash::Core::Components::DatePickerSingle->new(@_);
}

sub Dropdown {
    load Dash::Core::Components::Dropdown;
    return Dash::Core::Components::Dropdown->new(@_);
}

sub Graph {
    load Dash::Core::Components::Graph;
    return Dash::Core::Components::Graph->new(@_);
}

sub Input {
    load Dash::Core::Components::Input;
    return Dash::Core::Components::Input->new(@_);
}

sub Interval {
    load Dash::Core::Components::Interval;
    return Dash::Core::Components::Interval->new(@_);
}

sub Link {
    load Dash::Core::Components::Link;
    return Dash::Core::Components::Link->new(@_);
}

sub Loading {
    load Dash::Core::Components::Loading;
    return Dash::Core::Components::Loading->new(@_);
}

sub Location {
    load Dash::Core::Components::Location;
    return Dash::Core::Components::Location->new(@_);
}

sub LogoutButton {
    load Dash::Core::Components::LogoutButton;
    return Dash::Core::Components::LogoutButton->new(@_);
}

sub Markdown {
    load Dash::Core::Components::Markdown;
    return Dash::Core::Components::Markdown->new(@_);
}

sub RadioItems {
    load Dash::Core::Components::RadioItems;
    return Dash::Core::Components::RadioItems->new(@_);
}

sub RangeSlider {
    load Dash::Core::Components::RangeSlider;
    return Dash::Core::Components::RangeSlider->new(@_);
}

sub Slider {
    load Dash::Core::Components::Slider;
    return Dash::Core::Components::Slider->new(@_);
}

sub Store {
    load Dash::Core::Components::Store;
    return Dash::Core::Components::Store->new(@_);
}

sub Tab {
    load Dash::Core::Components::Tab;
    return Dash::Core::Components::Tab->new(@_);
}

sub Tabs {
    load Dash::Core::Components::Tabs;
    return Dash::Core::Components::Tabs->new(@_);
}

sub Textarea {
    load Dash::Core::Components::Textarea;
    return Dash::Core::Components::Textarea->new(@_);
}

sub Upload {
    load Dash::Core::Components::Upload;
    return Dash::Core::Components::Upload->new(@_);
}
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dash::Core::ComponentsFunctions

=head1 VERSION

version 0.06

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
