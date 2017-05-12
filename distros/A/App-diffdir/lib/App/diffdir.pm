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

our $VERSION = 0.5;

has [qw/files option/] => (
    is      => 'rw',
    default => sub {{}},
);

sub find_files {
    my ($self, $dir) = @_;
    my @files = path($dir)->children;

    while ( my $file = shift @files ) {
        if ( -d $file ) {
            push @files, $file->children;
        }
        else {
            my $base = $self->basename($dir, $file);
            push @{ $self->files->{$base} }, $dir;
        }
    }

}

sub diff {
    my ($self, $file1, $file2) = @_;

    return if !$self->option->{follow} && (-l $file1 || -l $file2);

    my $file1_q = shell_quote($file1);
    my $file2_q = shell_quote($file2);

    my $cmd  = '/usr/bin/diff';
    if ( $self->option->{'ignore-space-change'} ) {
        $cmd .= ' --ignore-space-change';
    }
    if ( $self->option->{'ignore-all-space'} ) {
        $cmd .= ' --ignore-all-space';
    }
    $cmd  .= " $file1_q $file2_q";
    my $diff
        = -s $file1 != -s $file2 ? abs( (-s $file1) - (-s $file2) )
        : $self->option->{fast}  ? 0
        :                          length ''.`$cmd`;

    if ($diff) {
        warn "$self->option->{cmd} $file1_q $file2_q\n" if $self->option->{verbose};
        return ( $diff, "$self->option->{cmd} $file1_q $file2_q" );
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

This documentation refers to App::diffdir version 0.5

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
