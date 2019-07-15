package Mock::App::Git::Workflow::Repository;

# Created on: 2014-09-05 04:34:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use strict;
use warnings;
use version;
use Carp qw/carp croak cluck confess longmess/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use base qw/Exporter/;

our $VERSION     = version->new(1.1.4);
our @EXPORT_OK   = qw//;
our %EXPORT_TAGS = ();
#our @EXPORT      = qw//;
my $git;

sub new {
    my $class = shift;
    my %param = @_;
    my $self  = \%param;
    $self->{data} = [];

    bless $self, $class;

    return $git = $self;
}

sub git {
    return $git || __PACKAGE__->new;
}

sub mock_add {
    my $self = shift;
    confess "Data not Hashes!\n" . Dumper(\@_) if @_ && ref $_[0] ne 'HASH';
    push @{ $self->{data} }, @_;
}

sub mock_reset {
    my $self = shift;
    @{ $self->{data} } = ();
}

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my $called =  $AUTOLOAD;
    $called =~ s/.*:://;
    $called =~ s/_/-/g;

    return if $called eq 'DESTROY';

    my $cmd = "git $called " . (join ' ', @_);
    if ( !@{ $self->{data} } ) {
        confess "No data setup for `$cmd`\n\t# ".(join "\n\t# ", reverse @{ $self->{ran} })."\n\t";
    }
    push @{ $self->{ran} }, $cmd;

    confess "Data not set up correctly! Not an ARRAY of HASHes\n" if ref $self->{data}    ne "ARRAY";
    confess "Data not set up correctly! Not an Array of Hashes\n" if ref $self->{data}[0] ne "HASH";
    my ($action, $return) = each %{ shift @{ $self->{data} } };

    # sanity check
    if ($action ne $called) {
        confess "Expected mock data for '$called' but got data for '$action'!\n"
            . Dumper($cmd, $return)
            . "\t# "
            . (join "\n\t# ", reverse @{ $self->{ran} })
            . "\n\t";
    }

    if (wantarray) {
        if ( !$return || !ref $return || ref $return ne 'ARRAY' ) {
            confess "Returning Mock for `$cmd` with scalar value when expecting an array\n" . Dumper($return), "\t";
        }
        return @$return;
    }
    else {
        #cluck "Returning mock for `$cmd`\n" . Dumper($return), "\t";
        return $return;
    }
}

1;

__END__

=head1 NAME

Mock::App::Git::Workflow::Repository - Mock of a git repository

=head1 VERSION

This documentation refers to Mock::App::Git::Workflow::Repository version 1.1.4

=head1 SYNOPSIS

   use Mock::App::Git::Workflow::Repository;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<new ()>

Create a new Mock::App::Git::Workflow::Repository

=head2 C<git ()>

return the last created Mock::App::Git::Workflow::Repository

=head2 C<mock_add (@data)>

push data to be returned when methods are called

=head2 C<mock_reset ()>

Clear out any mock data, useful if tests have added too much data

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

Copyright (c) 2014 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
