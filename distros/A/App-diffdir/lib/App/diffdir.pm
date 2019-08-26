package App::diffdir;

# Created on: 2015-03-05 19:52:53
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moo;
use strict;
use warnings;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;
use Text::Diff;

our $VERSION = 0.9;

has files => (
    is      => 'rw',
    default => sub {{}},
);
has exclude => (
    is      => 'rw',
    default => sub {[]},
);
has cmd => (
    is      => 'rw',
    default => 'diff',
);
has [qw/
    fast
    follow
    ignore_all_space
    ignore_space_change
    verbose
/] => (
    is => 'rw',
);

sub differences {
    my ($self, @dirs) = @_;

    my %found = $self->get_files(@dirs);

    for my $file (keys %found) {
        my $last_dir = $dirs[0];
        my $diff_count = 0;

        if ( ! $found{$file}{$last_dir} ) {
            $found{$file}{$last_dir} = {
                name => path( $last_dir, $file),
                diff => 'missing',
            };
        }

        for my $dir (@dirs[1 .. @dirs - 1]) {
            if ( ! $found{$file}{$dir} ) {
            $found{$file}{$dir} = {
                name => path( $dir, $file),
                diff => 'missing',
            };
                $diff_count++;
            }
            elsif ( ! -e $found{$file}{$last_dir}{name} ) {
                $found{$file}{$dir}{diff} = 'added';
                $diff_count++;
            }
            elsif ( my $diff = eval { $self->dodiff( ''.path($last_dir, $file), ''.path($dir, $file) ) } ) {
                $found{$file}{$dir}{diff} = $diff;
                $diff_count++;
            }
            warn $@ if $@;
            $last_dir = $dir;
        }

        if ( !$diff_count ) {
            delete $found{$file};
        }
    }

    return %found;
}

sub get_files {
    my ($self, @dirs) = @_;
    my %found;

    for my $dir (@dirs) {
        $dir =~ s{/$}{};
        my @found = $self->find_files($dir);
        for my $file (@found) {
            my $base = $file;
            if ( $dir ne '.' ) {
                # remove the base directory from the file name
                $base =~ s/^\Q$dir\E\/?//;
            }
            $found{$base}{$dir} = {
                name => $file,
            };
        }
    }

    return %found;
}

sub find_files {
    my ($self, $dir) = @_;
    my @files = path($dir)->children;
    my @found;

    FILE:
    while ( my $file = shift @files ) {
        next FILE if $file->basename =~ /^[.].*[.]sw[n-z]$|^[.](?:svn|bzr|git)$|CVS|RCS$|cover_db|_build|Build$|blib/;
        next FILE if $self->{exclude} && grep {$file =~ /$_/} @{ $self->{exclude} };

        push @found, $file;

        if ( -d $file ) {
            push @files, $file->children;
        }
    }

    return @found;
}

my $which_diff;
sub dodiff {
    my ($self, $file1, $file2) = @_;

    if ( ! $which_diff ) {
        $which_diff = $self->ignore_space_change || $self->ignore_all_space
            ? 'mydiff'
            : 'text';
    }

    if ( $which_diff eq 'mydiff' ) {
        return $self->mydiff($file1, $file2);
    }
    else {
        my $diff = diff($file1, $file2);
        return (length $diff, $self->cmd . " $file1 $file2") if $diff;
    }

    return;
}

sub mydiff {
    my ($self, $file1, $file2) = @_;

    return if !$self->follow && (-l $file1 || -l $file2);

    my $file1_q = shell_quote($file1);
    my $file2_q = shell_quote($file2);

    my $cmd  = '/usr/bin/diff';
    if ( $self->ignore_space_change ) {
        $cmd .= ' --ignore-space-change';
    }
    if ( $self->ignore_all_space ) {
        $cmd .= ' --ignore-all-space';
    }
    $cmd  .= " $file1_q $file2_q";
    my $diff
        = -s $file1 != -s $file2 ? abs( (-s $file1) - (-s $file2) )
        : $self->fast  ? 0
        :                          length ''.`$cmd`;

    if ($diff) {
        warn "$self->cmd $file1_q $file2_q\n" if $self->verbose;
        return ( $diff, "$self->cmd $file1_q $file2_q" );
    }

    return;
}

sub shell_quote {
    my ($text) = @_;

    if ($text =~ /[\s$|><;#]/xms) {
        $text =~ s/'/'\\''/gxms;
        $text = "'$text'";
    }

    return $text;
}

sub basename {
    my ($self, $dir, $file) = @_;
    $file =~ s{^$dir/?}{};
    return $file;
}

1;

__END__

=head1 NAME

App::diffdir - Compares two or more directories for files that differ

=head1 VERSION

This documentation refers to App::diffdir version 0.9

=head1 SYNOPSIS

   use App::diffdir;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

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

Copyright (c) 2015 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
