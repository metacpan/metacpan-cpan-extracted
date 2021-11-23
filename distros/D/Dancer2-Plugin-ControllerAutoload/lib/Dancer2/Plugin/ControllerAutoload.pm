package Dancer2::Plugin::ControllerAutoload;
use 5.006;
use strict;
use warnings;
use Dancer2::Plugin;
use File::Find;
use Cwd qw(abs_path);

=encoding utf-8

=head1 NAME

Dancer2::Plugin::ControllerAutoload - Autoload controllers

=head1 SYNOPSIS

When we C<use> the plugin in MyApp.pm it'll load all the controllers
under the C<Controller> directory, so you don't have to write one
C<use $controller> in MyApp.pm for each controller.

    # MyApp.pm
    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::ControllerAutoload;

    # MyApp/Controller/Users.pm
    package MyApp::Controller::Users;
    use Dancer2 appname => 'MyApp';

    # MyApp/Controller/Users/Thoughts.pm
    package MyApp::Controller::Users::Thoughts;
    use Dancer2 appname => 'MyApp';

=head1 DESCRIPTION

If you have these three controllers

    # MyApp/Controller/Users.pm
    package MyApp::Controller::Users;
    use Dancer2 appname => 'MyApp';

    # MyApp/Controller/Users/Thoughts.pm
    package MyApp::Controller::Users::Thoughts;
    use Dancer2 appname => 'MyApp';

    # MyApp/Controller/Services.pm
    package MyApp::Controller::Services;
    use Dancer2 appname => 'MyApp';

you'd have to load each with an C<use>

    # MyApp.pm
    package MyApp;
    use Dancer2;
    use MyApp::Controller::Users;
    use MyApp::Controller::Users::Thoughts;
    use MyApp::Controller::Services;

This plugin simplifies this process. When you C<use> the plugin, all
controllers will be loaded.

    # MyApp.pm
    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::ControllerAutoload;

A controller will be by default identified as such if it is under the
C<Controller> directory. But that's configurable. If your controller
directory is called "Contr":

    # in a config or environment file
    plugins:
        ControllerAutoload:
            controller_dir: Contr

=cut

our $VERSION = '0.01';

my (undef, $caller_filename) = caller;
$caller_filename = abs_path $caller_filename;
my @files_to_require;

sub BUILD {
    my ($self) = @_;
    my $caller_basedir = $caller_filename;
    $caller_basedir =~ s/\.pm$//;;
    my $path_part = $self->config->{controller_dir} || 'Controller';

    my $finddir = File::Spec->catdir($caller_basedir, $path_part);
    if (-d $finddir) {
        find(\&process_item, $finddir);
    }

    for my $file (@files_to_require) {
        $self->dsl->info("Loading controller $file");
        require $file;
    }
    @files_to_require = ();
}

sub process_item { # $_ is a filename like Users.pm
    return unless -f;
    return unless /\.pm$/;
    # $File::Find::name will be like /opt/systems/App/lib/App/Controller/X.pm
    push @files_to_require, $File::Find::name;
}

=head1 AUTHOR

Gil Magno, C<< <gilmagno at gilmagno.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-dancer2-plugin-controllerautoload at rt.cpan.org>, or through
the web interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer2-Plugin-ControllerAutoload>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

Also you can use github:
L<https://github.com/gilmagno/Dancer2-Plugin-ControllerAutoload>.

=head1 ACKNOWLEDGEMENTS

Angel Leyva, José Biskofski, Natanael Lizama, Uriel Lizama

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2021 by Gil Magno.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

1;
