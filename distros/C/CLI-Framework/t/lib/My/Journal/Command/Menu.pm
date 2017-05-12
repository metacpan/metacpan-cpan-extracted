package My::Journal::Command::Menu;
use base qw( CLI::Framework::Command::Menu );

use strict;
use warnings;

sub usage_text {
    q{
    menu (My::Journal command overriding the built-in): test of overriding a built-in command...'
    }
}

sub menu_txt {
    my ($self) = @_;

    my $app = $self->get_app(); # metacommand is app-aware

    my $menu;
    $menu = "\n" . '-'x13 . "menu" . '-'x13 . "\n";
    for my $c ( $app->get_interactive_commands() ) {
        $menu .= sprintf("\t%s\n", $c)
    }
    $menu .= '-'x30 . "\n";
    return $menu;
}

#-------
1;

__END__

=pod

=head1 NAME

My::Journal::Command::Menu

=head1 PURPOSE

A demonstration and test of overriding a built-in CLIF Menu command.

=head1 NOTES

This example replaces the built-in command menu.  The particular replacement
is not particularly useful, but shows how such a replacement could be done.

Note that overriding the menu command is a special case of overriding a
built-in command and it is necessary that the overriding command inherit from
the built-in menu class, CLI::Framework::Command::Menu.

This example merely changes the menu format.

=cut
