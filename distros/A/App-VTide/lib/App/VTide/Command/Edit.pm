package App::VTide::Command::Edit;

# Created on: 2016-02-05 10:11:54
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use English qw/ -no_match_vars /;

extends 'App::VTide::Command::Run';

our $VERSION = version->new('0.1.9');
our $NAME    = 'edit';
our $OPTIONS = [
    'test|T!',
    'verbose|v+',
];
sub details_sub { return ( $NAME, $OPTIONS )};

sub run {
    my ($self) = @_;

    my ( $name ) = $self->env;
    my $cmd = $self->options->files->[0];
    print "Running $name - $cmd\n";

    my $params = $self->params( $cmd );
    $params->{edit} = $self->options->files;
    my @cmd    = $self->command( $params );

    if ( $params->{env} && ref $params->{env} eq 'HASH' ) {
        for my $env ( keys %{ $params->{env} } ) {
            my $orig = $ENV{$env};
            $ENV{$env} = $params->{env}{$env};
            $ENV{$env} =~ s/[\$]$env/$orig/xms;
        }
    }

    $self->load_env( $params->{env} );
    $self->hooks->run('edit_editing', \@cmd);
    $self->runit( @cmd );

    $params = $self->params($ENV{VTIDE_TERM});
    eval { require Term::Title; }
        and Term::Title::set_titlebar($params->{title} || 'bash');

    return;
}

sub auto_complete {
    my ($self, $auto) = @_;

    my $env = $self->options->files->[-1];
    my @files = sort keys %{ $self->config->get->{editor}{files} };

    eval {
        my $helper = $self->config->get->{editor}{helper_autocomplete};
        if ($helper) {
            my $helper_sub = eval $helper;  ## no critic
            if ($helper_sub) {
                push @files, $helper_sub->($auto, $self->options->files);
            }
            elsif ($@) {
                warn "Errored parsing '$@':\n$helper\n";
            }
            else {
                warn "Unknown error with helper sub\n";
            }
        }
        1;
    } or do { warn $@ };

    print join ' ', grep { $env ne 'vtide' && $env ne 'edit' ? /^$env/xms : 1 } @files;

    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::Edit - Run an edit command (like Run but without a terminal spec)

=head1 VERSION

This documentation refers to App::VTide::Command::Edit version 0.1.9

=head1 SYNOPSIS

    vtide edit (glob ...)
    vtide edit [--help|--man]

  OPTIONS:
   -T --test        Test the running of the terminal (shows the commands
                    that would be executed)
   -v --verbose     Show more verbose output.
      --help        Show this help
      --man         Show full documentation

=head1 DESCRIPTION

The C<edit> command allows an ad hoc access to starting the editor with lists
of files, file groups or globs. The file groups are those defined in the
local C<.vtide.yml> config (as defined in L<App::VTide::Configuration/editor>).

=head1 SUBROUTINES/METHODS

=head2 C<run ()>

Run an editor command with passed in file globs

=head2 C<auto_complete ()>

Auto completes editor file groups

=head2 C<details_sub ()>

Returns the commands details.

=head1 HOOKS

=head2 C<edit_editing ($cmd)>

Called just before execution, the command that will be executed is
passed and can be modified.

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
