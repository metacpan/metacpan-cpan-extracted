package App::ConMenu;
use 5.10.0;
use strict;
use warnings;
use Carp qw(croak);
use YAML::Tiny;
use Term::ANSIScreen qw(cls);
our $VERSION = "1.00";


sub new  {
    my $type = shift;
    my $self = {};
    return bless $self, $type;
}

# load the yaml file you should have
# set filename by now.
sub loadMenuFile {
    my $self = shift;
    $self->{fileName} or croak ("No yaml file Name set");
    my $yaml;
    $yaml = YAML::Tiny -> read($self->{fileName});
    $self->{'menu'}= $yaml;
    return $yaml;
}

sub execute {
    my $self = shift;
    my $commandStructure = shift;
    my $commands = $commandStructure->{'commands'};
    foreach my $command (@$commands)
    {
        print `$command`;
    }
    return 1; # return 1 so that testing knows we got this far.
}

sub printMenu {
    my $self = shift;
    my $menuItemsUnsorted = $self->{'menu'}->[0];
    my @menuItems = sort { {$a} cmp {$b} } keys(%$menuItemsUnsorted);
    $self->{menuItems} = \@menuItems;
    cls();
    my $i=1;
    my @menuItemsNumerical = map { '['. $i++.'] '.$_ } @menuItems;
    say join("\n", @menuItemsNumerical);
    say 'Choose a menu item by pressing the corresponding number';
    say 'q to exit';
}

sub waitForInput {
    my $self = shift;
    my $selection = <>;
    if ($selection =~ /[0-9]+/){
        if ($selection  > scalar ($self->{menuItems}) or $selection < 1 ){
            say 'Error no such menu item';
            exit;
        }
    } else {
        exit;
    }
    my $menuItems = $self->{menuItems};
    $self->execute($self->{menu}->[0]->{$menuItems->[$selection -1]})
}

# create a default file to get people going.
sub createDefaultFile{
    my $self = shift;
    my $fileName = shift;
    my $menu = {
        'Menu option 1' => {
            'commands'    => [
                'ls'
            ],
            'working_dir' => './'
        },
        'Menu Option 2' => {
            'commands'    => [
                'dir'
            ],
            'working_dir' => './'
        }

    };
    my $yaml = YAML::Tiny->new($menu);
    $yaml->write($fileName);

}


1;
__END__

=encoding utf-8

=head1 NAME

App::ConMenu - Very simple Menu For Console commands Platform Agnostic

=head1 SYNOPSIS

    use App::ConMenu;
    my $menu = App::ConMenu->new();
    $menu->{fileName} = '.~/menu.yml';
    $menu->loadMenuFile();
    $menu->printMenu();
    $menu->waitForInput();
    1;


=head1 DESCRIPTION

App::ConMenu is a very simple console menu application it allows you to display a menu of
choices then select one of those by pressing the corresponding number.  This will cause ComMenu
to execute the associated commands in the menu.yml file.

The C<m.pl> in the scripts dir is a script that  creates a menu by using the module. By default
the script uses ~/.con_menu.yml on unix type systems and <HOMEDIR>\_con_menu.yml on Windows type systems. If
the files do not exist then you will be prompted to create an example version.

=head1 LICENSE

Copyright (C) Michael Mueller.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Michael Mueller E<lt>michael@muellers.net.auE<gt>

=cut

