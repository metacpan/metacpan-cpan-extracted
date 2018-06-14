# NAME

App::ConMenu - Very simple Menu For Console commands Platform Agnostic

# SYNOPSIS

    use App::ConMenu;
    my $menu = App::ConMenu->new();
    $menu->{fileName} = '.~/menu.yml';
    $menu->loadMenuFile();
    $menu->printMenu();
    $menu->waitForInput();
    1;

# DESCRIPTION

App::ConMenu is a very simple console menu application it allows you to display a menu of
choices then select one of those by pressing the corresponding number.  This will cause ComMenu
to execute the associated commands in the menu.yml file.

The `m.pl` in the scripts dir is a script that  creates a menu by using the module. By default
the script uses ~/.con\_menu.yml on unix type systems and <HOMEDIR>\\\_con\_menu.yml on Windows type systems. If
the files do not exist then you will be prompted to create an example version.

# LICENSE

Copyright (C) Michael Mueller.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Michael Mueller <michael@muellers.net.au>
