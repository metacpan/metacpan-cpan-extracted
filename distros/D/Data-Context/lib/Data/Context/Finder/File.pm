package Data::Context::Finder::File;

# Created on: 2013-10-26 20:02:08
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use namespace::autoclean;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Moose::Util::TypeConstraints;
use Path::Tiny;
use Data::Context::Util qw/do_require/;

our $VERSION = version->new('0.3');

extends 'Data::Context::Finder';

subtype 'ArrayRefStr'
    => as 'ArrayRef[Str]';

coerce 'ArrayRefStr'
    => from 'Str'
    => via { [$_] };

has path => (
    is       => 'rw',
    isa      => 'ArrayRefStr',
    coerce   => 1,
    required => 1,
);
has suffixes => (
    is      => 'rw',
    isa     => 'HashRef[HashRef]',
    default => sub {
        return {
             json => {
                 suffix => '.dc.json',
                 module => 'Data::Context::Loader::File::JSON',
             },
             js => {
                 suffix => '.dc.js',
                 module => 'Data::Context::Loader::File::JS',
             },
             yaml => {
                 suffix => '.dc.yml',
                 module => 'Data::Context::Loader::File::YAML',
             },
             xml  => {
                 suffix => '.dc.xml',
                 module => 'Data::Context::Loader::File::XML',
             },
        };
    },
);
has suffix_order => (
    is      => 'rw',
    isa     => 'ArrayRefStr',
    coerce  => 1,
    default => sub { [qw/js json yaml xml/] },
);
has default => (
    is      => 'rw',
    isa     => 'Str',
    default => '_default',
);

sub find {
    my ($self, @path) = @_;

    my $default;
    my $default_type;

    for my $search ( @{ $self->path } ) {
        for my $type ( @{ $self->suffix_order } ) {
            my $config = path(
                $search,
                @path[0 .. @path-2],
                $path[-1] . $self->suffixes->{$type}->{suffix}
            );
            if ( -e $config ) {
                my $module = $self->suffixes->{$type}->{module};
                do_require($module);
                return $module->new(
                    file => $config,
                    type => $type,
                );
            }
            next if $default;

            $config = path(
                $search,
                @path[0 .. @path - 2],
                $self->default . $self->suffixes->{$type}->{suffix}
            );
            if ( -e $config ) {
                $default = $config;
                $default_type = $type;
            }
        }
    }

    if ($default) {
        my $module = $self->suffixes->{$default_type}->{module};
        do_require($module);
        return $module->new(
            file => $default,
            type => $default_type,
        );
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::Finder::File - <One-line description of module's purpose>

=head1 VERSION

This documentation refers to Data::Context::Finder::File version 0.3


=head1 SYNOPSIS

   use Data::Context::Finder::File;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<find ( @path )>

Finds a config file matching C<@path> or C<@path[ 0 .. @path - 2 ]/_default>
if it exists and returns a L<Data::Context::Loader::File> object.

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

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
