# Copyright (c) 2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Work with Tag databases

package Data::TagDB::Base;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.15;

my %_plugin_attr_pkg_map = (
    'Data::TagDB'           => 'db_attributes',
    'Data::TagDB::Tag'      => 'tag_attributes',
    'Data::TagDB::Metadata' => 'metadata_attributes',
    'Data::TagDB::Relation' => 'relation_attributes',
);



#@returns Data::TagDB
sub db {
    my ($self) = @_;
    return $self->{db};
}


sub get {
    my ($self, @args) = @_;
    return $self->_run_plugin('get', @args);
}


sub execute {
    my ($self, @args) = @_;
    return $self->_run_plugin('execute', @args);
}

# ---- Private helpers ----

sub _run_plugin {
    my ($self, $op, $key, %opts) = @_;
    my __PACKAGE__ $db = $self->isa('Data::TagDB') ? $self : $self->db;
    my $value = ($self->{attribute_cache} //= {})->{$key};
    my $has_default = exists $opts{default};
    my $default = delete $opts{default};
    my $listas = delete $opts{listas};
    my $list = delete($opts{list}) // defined($listas);
    my $as = delete $opts{as};
    my $data;

    croak 'Stray options passed' if scalar keys %opts;

    if (!defined($value) || $op eq 'execute') {
        my ($ns, $subkey) = $key =~ /^([^#]+)#(.+)\z/;
        my $info = $db->_get_plugin_info($ns);

        croak 'No such plugin loaded' unless defined $info;

        $info = $info->{$_plugin_attr_pkg_map{ref($self)} // '<BAD_PACKAGE>'}{$subkey};

        croak 'No such attribute' unless defined $info;
        croak 'Attribute not '.$op.'-able' unless defined $info->{$op};

        {
            my ($v, %extra) = $info->{$op}->($self, $key);
            unless ($extra{no_value}) {
                $v = [$v] unless ref($v) eq 'ARRAY';
                $extra{_data} = $v;
            }
            $value = \%extra;

            unless ($op eq 'execute') {
                $self->{attribute_cache}{$key} = $value unless $extra{no_cache};
            }
        }
    }

    $data = $value->{_data};
    unless (defined $data) {
        croak 'No such value' unless $has_default;
        return @{$default} if $list;
        return $default;
    }

    unless ($list) {
        if (scalar(@{$data}) != 1) {
            croak 'Not a single-value';
        }
    }

    if (defined($as) && $as ne 'raw' && !(defined($value->{rawtype}) && $as eq $value->{rawtype})) {
        $data = [map {Data::Identifier::as($_, $as, db => $db, rawtype => $value->{rawtype})} @{$data}];
    }

    if ($list) {
        if (defined($listas)) {
            if ($listas eq 'Data::TagDB::Iterator') {
                require Data::TagDB::Iterator;
                return Data::TagDB::Iterator->from_array($data, db => $db);
            } elsif ($listas eq 'Data::TagDB::Cloudlet') {
                require Data::TagDB::Cloudlet;
                return Data::TagDB::Cloudlet->new(root => $data, db => $db);
            } else {
                ...
            }
        }

        return @{$data};
    } else {
        return $data->[0];
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::TagDB::Base - Work with Tag databases

=head1 VERSION

version v0.15

=head1 SYNOPSIS

    use Data::TagDB;

(since v0.15)

Parent package for a number of other packages.

=head1 METHODS

=head2 db

    my Data::TagDB $db = $base->db;

Returns the current L<Data::TagDB> object.

=head2 get

    my $value  = $base->get($key [, %opts ] );
    # or:
    my @values = $base->get($key [, %opts ], list => 1);

(experimental since v0.15, experimental since v0.14 as part of L<Data::TagDB::Tag>)

Gets a value from the object.

This method is mainly used to read a value using a plugin.

The format for the key is C<Package#subkey> (future versions may support additional formats).
The package given is the full perl package name of the module. The subkey is any that is exported by the plugin.

The following universal options are supported:
C<default>, C<as>, C<listas>, C<list>.

B<Note:>
This method will try to cache the values (unless asked by the plugin not to cache).
Details of the cache are subject to change.
However the cache's lifetime is limited to the tag object's lifetime.
(Which might itself be cached.)

=head2 execute

    my $value  = $base->execute($key [, %opts ] );
    # or:
    my @values = $base->execute($key [, %opts ], list => 1);

(experimental since v0.15)

Executes a plugin provided method.

This method works just like L</get>. But for the following differences:

=over

=item *

The method will be executed every time it is called.

=item *

Methods my perform writes or otherwise unsafe operations.

=item *

They are not idempotent (calling twice with exactly the same parameters is not the same as calling only once)

=item *

The result is not cached by default.

=back

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
