package App::watchdo;

# Created on: 2015-03-07 08:21:28
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use warnings;
use version;
use Carp;
use List::MoreUtils qw/uniq/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use AnyEvent;
use AnyEvent::Loop;
use AnyEvent::Filesys::Notify;
use Path::Tiny;

our $VERSION = version->new('0.1.1');

has [qw/git run done/] => ( is => 'rw' );
has [qw/dirs files exclude changed/] => (
    is      => 'rw',
    default => sub {[]},
);
has wait => (
    is      => 'rw',
    default => 1,
);
has vcs => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        require VCS::Which;
        return VCS::Which->new;
    },
);

sub watch {
    my ($self) = @_;

    my $notify = AnyEvent::Filesys::Notify->new(
        dirs => [ $self->get_dirs ],
        cb   => sub {
            my @changed = @_;
            $self->changed([ @{ $self->changed }, @changed ]);

            if ( ! $self->done ) {
                $self->done( AE::timer $self->wait, 0, sub { $self->doit() } );
            }
        },
        parse_events => 1,
    );

    return AnyEvent::Loop::run();
}

sub doit {
    my ($self) = @_;
    my %files = map { $_ => 1 } $self->get_files();
    my %dirs  = map { $_ => 1 } @{ $self->dirs() };
    my %seen;

    my @monitored;
    for my $changed (@{ $self->changed() }) {
        my $path = $changed->path;
        push @monitored, $changed if (
            !$seen{$path}++
            || $files{$path}
            || $dirs{$path}
        ) && (
            ! @{ $self->exclude }
            || ! grep { $path =~ /$_/ } @{ $self->exclude }
        );
    }

    $self->run()->(@monitored) if @monitored;
    $self->done(undef);
    $self->changed([]);
}

sub get_dirs {
    my ($self) = @_;

    return uniq sort +(
        @{ $self->dirs || [] },
        map {path($_)->parent . ''}
        $self->get_files,
    );
}

sub get_files {
    my ($self) = @_;

    return ( $self->_files_from_fs, $self->_files_from_git );
}

sub _files_from_fs {
    my ($self) = @_;

    return map { -d $_ ? _recurse($_) : $_ }
        @{ $self->files };
}

sub _files_from_git {
    my ($self) = @_;

    return if !$self->git;

    my $status = $self->vcs->status('.');
    return (
        map  { chomp $_; $_ }  ## no critic
        map  { @{ $status->{$_} } }
        grep { $_ ne 'merge' }
        keys %{ $status }
    );
}

sub _recurse {
    my $dir = path(shift);
    my @files;

    for my $child ($dir->children) {
        if (-d $child) {
            push @files, _recurse($child);
        }
        else {
            push @files, $child;
        }
    }

    return @files;
}

1;

__DATA__

=head1 NAME

App::watchdo - Run a command when watched files change

=head1 VERSION

This documentation refers to App::watchdo version 0.1.1

=head1 SYNOPSIS

   watch-do [option]
   watch-do -w file1 [-w file2 ...] [--] cmd

 OPTIONS:
  cmd               Command to run when file changes
  -w --watch[=]file File to be watched for changes
  -g --git          Use git to find what to watch (ie monitor files that git see have changed)

  -v --verbose      Show more detailed option
     --version      Prints the version information
     --help         Prints this help information
     --man          Prints the full documentation for watch-do

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=over 4

=item C<doit ()>

Runs the requested command when a file has changed

=item C<get_dirs ()>

Gets the unique list of directories to look in

=item C<get_files ()>

Gets all the files to be watched

=item C<watch ()>

Runs the event loop to watch for changes in files.

=back

=head1 ATTRIBUTES

=over 4

=item C<changed>

Array of changed files

=item C<done>

Stores callback method for alerting of changed files

=item C<dirs>

Stores the directories that are being monitored

=item C<files>

Stores the files that are being monitored

=item C<exclude>

Stores a list of regexps of files that should not trigger changed events

=item C<git>

Flag for using git to find files that should be monitored

=item C<run>

The function to be called when file are changed

=item C<wait>

Time to wait for changes to settle to changed events are not filed too quickly

=back

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

Copyright (c) 2014-2016 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
