package App::VTide::Command::Grep;

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

our $VERSION = version->new('0.1.20');
our $NAME    = 'grep';
our $OPTIONS = [ 'test|T!', 'verbose|v+', ];
our $LOCAL   = 1;
sub details_sub { return ( $NAME, $OPTIONS, $LOCAL ) }

sub run {
    my ($self) = @_;

    my ($name) = $self->env;
    my $cmd = $self->options->files->[0];

    my $params = $self->params($cmd);
    my ( @files, @grep, $start );
    $start = 1;
    for my $file ( @{ $self->options->files } ) {
        if ( $file eq '--' ) {
            $start = 0;
        }
        elsif ($start) {
            push @files, $file;
        }
        else {
            push @grep, $file;
        }
    }

    $params->{editor}{command} = [];
    $params->{edit} = \@files;
    my @cmd = $self->command($params);

    if ( $params->{env} && ref $params->{env} eq 'HASH' ) {
        for my $env ( keys %{ $params->{env} } ) {
            my $orig = $ENV{$env};
            $ENV{$env} = $params->{env}{$env};
            $ENV{$env} =~ s/[\$]$env/$orig/xms;
        }
    }

    $self->load_env( $params->{env} );
    $self->hooks->run( 'grepping', \@cmd );
    $self->runit( ( $params->{grep} || 'grep' ), @grep, @cmd );

    return;
}

sub auto_complete {
    my ($self) = @_;

    my $env   = $self->options->files->[-1];
    my @files = sort keys %{ $self->config->get->{editor}{files} };

    eval {
        my $helper = $self->config->get->{editor}{helper_autocomplete};
        if ($helper) {
            $helper = eval $helper;    ## no critic
            push @files, $helper->();
        }
        1;
    } or do { warn $@ };

    print join ' ', grep { $env ne 'grep' ? /^$env/xms : 1 } @files;

    return;
}

1;

__END__

=head1 NAME

App::VTide::Command::Grep - Run a grep command on vtide editor globs

=head1 VERSION

This documentation refers to App::VTide::Command::Grep version 0.1.20

=head1 SYNOPSIS

    vtide grep (glob ...) -- (grep-options)
    vtide grep [--help|--man]

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
