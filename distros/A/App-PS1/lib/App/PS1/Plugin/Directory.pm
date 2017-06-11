package App::PS1::Plugin::Directory;

# Created on: 2011-06-21 09:48:32
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Path::Tiny;

our $VERSION = 0.05;

sub directory {
    my ($self, $options) = @_;

    my $dir  = path('.')->absolute;
    my $home = path($ENV{HOME});
    my $dir_display = "$dir";
    $options->{dir_length} ||= 30;

    if ($home->subsumes($dir) ) {
        $dir_display =~ s/$home/~/xms;
    }
    if (length $dir_display > $options->{dir_length}) {
        $dir_display = '...' . substr $dir_display, -$options->{dir_length}, $options->{dir_length};
    }
    if ($options->{abreviate}) {
        $dir_display =~ s{/([^/])[^/]+/}{/$1/}g;
    }

    my $len = length $dir_display;

    my @details = ( $len, $self->colour('dir_name') . $dir_display );

    my @children = $dir->children;
    my $dir_count  = 0;
    my $file_count = 0;
    my $size       = 0;
    for my $file (@children) {
        if ( -d $file ) {
            $dir_count++;
        }
        else {
            $file_count++;
            $size += -s $file || 0;
        }
    }
    $size
        = $size > 10_000_000_000 ? sprintf "%dGiB"  , $size / 2**30
        : $size >    900_000_000 ? sprintf "%.1dGiB", $size / 2**30
        : $size >     10_000_000 ? sprintf "%dMiB"  , $size / 2**20
        : $size >        900_000 ? sprintf "%.1dMiB", $size / 2**20
        : $size >         10_000 ? sprintf "%dKiB"  , $size / 2**10
        : $size >            900 ? sprintf "%.1dKiB", $size / 2**10
        :                          $size;

    my $dir_length  = 0;
    my $file_length = 0;
    my $size_length = 0;

    if (!defined $options->{dir} || $options->{dir}) {
        $dir_length = 6 + length $dir_count;
        $dir_count  = $self->colour('dir_label') . " dir:"  . $self->colour('dir_size') . "$dir_count,";
    }
    else {
        $dir_count = '';
    }
    if (!defined $options->{file} || $options->{file}) {
        $file_length = 7 + length $file_count;
        $file_count  = $self->colour('dir_label') . " file:" . $self->colour('dir_size') . "$file_count,";
    }
    else {
        $file_count = '';
    }
    if (!defined $options->{size} || $options->{size}) {
        $size_length = 1 + length $size;
        $size        = $self->colour('dir_label') . " "      . $self->colour('dir_size') . $size;
    }
    else {
        $size = '';
    }

    my $arb = @{$self->parts} + $self->parts_size;
    if ( $details[0] + $dir_length + $file_length + $size_length + $arb < $self->cols ) {
        $details[0] += $dir_length + $file_length + $size_length;
        $details[1] .= $dir_count . $file_count . $size;
    }
    elsif ( $details[0] + $file_length + $size_length + $arb < $self->cols ) {
        $details[0] += $file_length + $size_length;
        $details[1] .= $file_count . $size;
    }
    elsif ( $details[0] + $size_length + $arb - 5 < $self->cols ) {
        $details[0] += $size_length;
        $details[1] .= $size;
    }

    return $self->surround(@details);
}

1;

__END__

=head1 NAME

App::PS1::Plugin::Directory - Current directory information

=head1 VERSION

This documentation refers to App::PS1::Plugin::Directory version 0.05.

=head1 SYNOPSIS

   use App::PS1::Plugin::Directory;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head3 C<directory ()>

Returns info about the current directory's name size files and subdirectories.

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

Copyright (c) 2011 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW, Australia 2077)
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
