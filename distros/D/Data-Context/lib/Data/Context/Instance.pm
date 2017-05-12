package Data::Context::Instance;

# Created on: 2012-04-09 05:58:42
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use namespace::autoclean;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util;
use List::MoreUtils qw/pairwise/;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Hash::Merge;
use Clone qw/clone/;
use Data::Context::Util qw/lol_path lol_iterate do_require/;
use Class::Inspector;
use Moose::Util::TypeConstraints qw/duck_type/;

our $VERSION = version->new('0.2');

has path => (
    is       => 'rw',
    isa      => 'Str',
    required => 1,
);
has loader => (
    is       => 'rw',
    isa      => 'Data::Context::Loader',
    required => 1,
);
has dc => (
    is       => 'rw',
    isa      => 'Data::Context',
    required => 1,
    weak_ref => 1,
    handles => [qw/log/],
);
has raw => (
    is  => 'rw',
    isa => 'Any',
);
has actions => (
    is      => 'rw',
    isa     => 'HashRef[HashRef]',
    default => sub {{}},
);
has merger => (
    is      => 'rw',
    isa     => duck_type( [qw/merge/] ),
    builder => '_merger',
    handles => [qw/merge/],
);

sub init {
    my ($self) = @_;

    return $self if !$self->changed;

    my $raw = $self->loader->load();

    # merge in any inherited data
    if ( $raw->{PARENT} ) {
        $self->raw({});
        my $parent = $self->dc->get_instance( $raw->{PARENT} )->init;
        $raw = $self->merge( $raw, $parent->raw );
    }

    # save complete raw data
    $self->raw($raw);

    # get data actions
    my $count = 0;
    lol_iterate(
        $raw,
        sub {
            my ($data, $path) = @_;
            $self->process_data(\$count, $data, $path);
        }
    );

    return $self;
}

sub changed {
    my ($self) = @_;

    # considered changed if not data has been read
    return 1 if !$self->raw;

    # considered changed if this file has changed
    return 1 if $self->loader->changed;

    if ( $self->raw->{PARENT} ) {
        my $parent = $self->dc->get_instance( $self->raw->{PARENT} );

        # considered changed if the parent instance has changed
        return $parent->changed;
    }

    # when all else fails the data is considered unchanged
    return 0;
}

sub get_data {
    my ( $self, $vars ) = @_;
    $self->init;

    my $data = clone $self->raw;
    my @events;

    # process the data in order
    for my $path ( _sort_optional( $self->actions ) ) {
        my ($value, $replacer) = lol_path( $data, $path );
        my $module = $self->actions->{$path}{module};
        my $method = $self->actions->{$path}{method};

        if ( $module->can($method) ) {
            my $new = $module->$method( $value, $vars, $path, $self );

            if ( blessed($new) && $new->isa('AnyEvent::CondVar') ) {
                push @events, [ $replacer, $new ];
            }
            else {
                $replacer->($new);
            }
        }
        else {
            $self->log->error("Can't call $method on $module from config " . $self->path . '!');
        }
    }

    for my $event ( @events ) {
        $event->[0]->($event->[1]->recv);
    }

    return $data;
}

sub process_data {
    my ( $self, $count, $data, $path ) = @_;
    confess "No path supplied!" if ! defined $path;

    if ( !ref $data ) {
        if ( defined $data && $data =~ /^\# (.*) \#$/xms ) {
            my $data_path = $1;
            do_require( $self->dc->action_class );
            $self->actions->{$path} = {
                module => $self->dc->action_class,
                method => 'expand_vars',
                found  => $$count++,
                path   => $data_path,
            };
        }
    }
    elsif ( ref $data eq 'HASH' && ( $data->{MODULE} || $data->{METHOD} ) ) {
        $self->actions->{$path} = {
            module => $data->{MODULE} || $self->dc->action_class,
            method => $data->{METHOD} || $self->dc->action_method,
            order  => $data->{ORDER},
            found  => $$count++,
        };
        if ( ! defined $self->actions->{$path}{method} ) {
            confess "Can't find method for '$path'!\n" . Dumper $data;
        }
        do_require( $self->actions->{$path}{module} );
    }

    return;
}

sub _sort_optional {
    my ($hash) = @_;

    my @sorted = sort {
        return $hash->{$a}->{found} <=> $hash->{$b}->{found} if ! defined $hash->{$a}->{order} && ! defined $hash->{$b}->{order};
        return $hash->{$b}->{order} >= 0 ? 1 : -1            if !defined $hash->{$a}->{order};
        return $hash->{$a}->{order} >= 0 ? -1 : 1            if !defined $hash->{$b}->{order};
        return -1                                            if $hash->{$a}->{order} >= 0 && $hash->{$b}->{order} < 0;
        return  1                                            if $hash->{$a}->{order} < 0 && $hash->{$b}->{order} >= 0;
        return $hash->{$a}->{order} <=> $hash->{$b}->{order};
    } keys %$hash;

    return @sorted;
}

sub _merger {
    return Hash::Merge->new('LEFT_PRECEDENT');
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Data::Context::Instance - The in memory instance of a data context config file

=head1 VERSION

This documentation refers to Data::Context::Instance version 0.2.

=head1 SYNOPSIS

   use Data::Context::Instance;

   # create a new object
   my $dci = Data::Context::Instance->new(
        path => 'dir/file',
        file => Path::Tiny::path('path/to/dir/file.dc.js'),
        type => 'js',
        dc   => $dc,
   );

   # Initialise the object (done by get normally)
   $dci->init;

   # get the data (with the context of $vars)
   my $data = $dci->get_data($vars);

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 C<init()>

Initialises the instance ie it reads the config file and merges in the parent if found

=head2 C<changed ()>

Returns true if any of the files that go into this instance have changed (or
if they haven't yet been processed) and returns false if this instance is still
valid.

=head2 C<get_data ( $vars )>

Returns the data from the config file processed with the context of $vars

=head2 C<process_data( $count, $data, $path )>

This does the magic of processing the data, and in the future handling of the
data event loop.

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

Copyright (c) 2012 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
