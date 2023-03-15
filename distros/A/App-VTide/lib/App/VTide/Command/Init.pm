package App::VTide::Command::Init;

# Created on: 2016-01-30 15:06:31
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;
use File::chdir;
use Path::Tiny;
use YAML::Syck;

extends 'App::VTide::Command';

our $VERSION = version->new('0.1.21');
our $NAME    = 'init';
our $OPTIONS = [
    'name|n=s',
    'dir|d=s',
    'windows|w=i',
    'force|f!',
    'verbose|v+',
];
sub details_sub { return ( $NAME, $OPTIONS )};

sub run {
    my ($self) = @_;
    my $dir    = path( $self->defaults->{dir} || '.' )->absolute;
    my $file   = $dir->path( '.vtide.yml' );
    my $count  = $self->defaults->{windows} || 4;
    my $name   = $self->defaults->{name} || $dir->basename;

    $self->hooks->run('init_name', \$name);

    my $config = {
        name    => $name,
        count   => $count,
        default => {
            restart => 0,
            wait    => 0,
        },
        editor => {
            files => {
                eg => [qw/some-file.eg/],
            },
        },
        terminals => {
            map { $_ => [] } 2 .. $count
        },
    };

    $self->hooks->run('init_config', $config);

    if ( -f $file ) {
        if ( ! $self->defaults->{force} ) {
            die "The config file '.vtide.yml' already exists wont overwrite without --force!\n";
        }
        warn "Overwritting '.vtide.yml'\n";
    }

    my $yaml = Dump( $config );
    my $now = localtime;
    $yaml =~ s/^(---\s*\n)/$1# Create by App::VTide::Command::Init $now VERSION $App::VTide::Command::Init::VERSION\n/xms;

    $file->spew($yaml);

    $self->save_session( $name, $dir );

    return;
}

sub auto_complete {
    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::Init - Initialize an session configuration file

=head1 VERSION

This documentation refers to App::VTide::Command::Init version 0.1.21

=head1 SYNOPSIS

    vtide init [(-n|--name) name] [(-d|--dir) dir] [(-w|--windows) num]
    vtide init [--help|--man]

  OPTIONS:
    -n --name[=]str Name of the project (Default is the current directory name)
    -d --dir[=]str  Use this as the current directory
    -w --windows[=]int
                    The number of tmux windows to create when starting
    -f --force      Force the overwritting of existing .vtide.yml file when found
       --help       Show this help
       --man        Show the full man page

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Initialize the configuration file

=head2 C<auto_complete ()>

NoOp.

=head2 C<details_sub ()>

Returns the commands details.

=head1 HOOKS

=head2 C<init_config ($config)>

This hook is called after the default configuration is created but
before it's saved. The variable C<$config> is a reference so modifications
to it will be written to the generated C<.vtide.yml> file.

=head2 C<init_name ($name)>

This allows the modification of the generated project name. The variable
C<$name> is a string reference so it can be modified.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
