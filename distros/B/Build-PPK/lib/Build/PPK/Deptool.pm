package Build::PPK::Deptool;

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Carp;

sub new {
    my ( $class, %opts ) = @_;

    return bless {
        'dist_index' => $class->load_index( $opts{'dist_index'} ),
        'prog_index' => $class->load_index( $opts{'prog_index'} )
    }, $class;
}

sub load_index {
    my ( $class, $file ) = @_;
    my %index;

    open( my $fh, '<', $file ) or die("Unable to open $file: $!");

    while ( my $line = readline($fh) ) {
        chomp $line;

        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next if $line =~ /^#/;

        my ( $target, $data ) = split /\s*:\s*/, $line, 2;
        my @deps = split /\s+/, $data;

        $index{$target} = \@deps;
    }

    close $fh;

    return \%index;
}

sub fetch_dist {
    my ( $self, %args ) = @_;
    my $url = $self->{'dist_index'}->{ $args{'dist'} }->[0];

    die("Could not find URL for dependency $args{'dist'}") unless $url;

    my %HANDLERS = (
        qr(^git://) => sub {
            require Build::PPK::Deptool::Git;

            return Build::PPK::Deptool::Git->fetch_dist(@_);
        },

        qr(^http://) => sub {
            require Build::PPK::Deptool::HTTP;

            return Build::PPK::Deptool::HTTP->fetch_dist(@_);
        },

        qr(^cpan://) => sub {
            require Build::PPK::Deptool::CPAN;

            return Build::PPK::Deptool::CPAN->fetch_dist(@_);
        }
    );

    foreach my $pattern ( keys %HANDLERS ) {
        next unless $url =~ $pattern;

        my %fetch_args = (
            'url'  => $url,
            'dist' => $args{'dist'},
            'path' => $args{'path'}
        );

        $args{'callback'}->(%fetch_args) if $args{'callback'};

        return $HANDLERS{$pattern}->(%fetch_args);
    }

    confess("Could not find an appropriate handler to fetch dependency $url");
}

sub targets {
    my ($self) = @_;

    return sort keys %{ $self->{'prog_index'} };
}

sub target_deps {
    my ( $self, %args ) = @_;
    my %deps;

    foreach my $target ( @{ $args{'targets'} } ) {
        foreach my $dep ( @{ $self->{'prog_index'}->{$target} } ) {
            $deps{$dep} = 1;
        }
    }

    return sort keys %deps;
}

1;
