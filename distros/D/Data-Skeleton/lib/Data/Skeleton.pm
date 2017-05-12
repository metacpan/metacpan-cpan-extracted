use strict;
use warnings;
package Data::Skeleton;
$Data::Skeleton::VERSION = '0.06';
use Moo;
use MooX::Types::MooseLike::Base qw/Str HashRef Bool/;
use Scalar::Util qw(blessed);

=head1 NAME

Data::Skeleton - Show the keys of a deep data structure

=head1 SYNOPSIS

    use Data::Skeleton;
    my $ds = Data::Skeleton->new;
    my $deep_data_structure = {
        id            => 'hablando',
        last_modified => 1,
        sections      => [
            {
                content => 'h1. Ice Cream',
                class   => 'textile'
            },
            {
                content => '# Chocolate',
                class   => 'markdown'
            },
        ],
    };
    use Data::Dumper::Concise;
    print Dumper $ds->deflesh($deep_data_structure);

# results in:

    {
      id => "",
      last_modified => "",
      sections => [
        {
          class => "",
          content => ""
        },
        {
          class => "",
          content => ""
        }
      ]
    }

=head1 DESCRIPTION

Sometimes you just want to see the "schema" of a data structure.
This modules shows only the keys with blanks for the values.

=cut

has 'value_marker' => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub { '' },
);
has 'references_seen' => (
    is => 'rw',
    isa => HashRef,
);

=head2 debug_skeleton

Turn on/off debugging

=cut

has 'debug_skeleton' => (
    is => 'ro',
    isa => Bool,
);

=head1 METHODS

=head2 deflesh

    Signature: (HashRef|ArrayRef)
      Returns: The data structure with values blanked

=cut

sub deflesh {
    my ($self, $data) = @_;
    if (ref($data) eq 'HASH') {
        return $self->_blank_hash($data);
    } elsif (ref($data) eq 'ARRAY') {
        return $self->_blank_array($data);
    } elsif (blessed($data) && eval { keys %{$data}; 1; } ) {
        return $self->_blank_hash($data);
    } else {
        die "You must pass the deflesh method one of:
    HashRef
    ArrayRef
    Object that is a blessed HashRef
";
    }
}

sub _blank_hash {
    my ($self, $hashref) = @_;
    # Work on a copy
    my %hashref = %{$hashref};
    $hashref = \%hashref;

    foreach my $key (keys %{$hashref}) {
        my $value = $hashref->{$key};
        my $ref_value = ref($value);
        my $references_seen = $self->references_seen;
        # Skip if we've seen this ref before
        if ($ref_value and $references_seen->{$value}) {
            warn "Seen referenced value: $value before" if $self->debug_skeleton;
            next;
        }
        # If we have a reference value then note it to avoid deep recursion
        # with circular references.
        if ($ref_value) {
            $references_seen->{$value} = 1;
            $self->references_seen($references_seen);
        }
        if (!$ref_value) {
            # blank a value that is not a reference
            $hashref->{$key} = $self->value_marker;
        }
        elsif ($ref_value eq 'SCALAR') {
            $hashref->{$key} = $self->value_marker;
        }
        elsif ($ref_value eq 'HASH') {
            # recurse when a value is a HashRef
            $hashref->{$key} = $self->_blank_hash($value);
        }

        # look inside ArrayRefs for HashRefs
        elsif ($ref_value eq 'ARRAY') {
            $hashref->{$key} = $self->_blank_array($value);
        }
        else {
            if (blessed($value)) {
                # Hash based objects have keys
                if (eval { keys %{$value}; 1; }) {
                    my $blanked_hash_object = $self->_blank_hash($value); #[keys %{$value}];
                    # Note that we have an object
                    # WARNING: we are altering the data structure by adding a key
                    $blanked_hash_object->{BLESSED_AS} = $ref_value;
                    $hashref->{$key} = $blanked_hash_object;
                } else {
                    $hashref->{$key} = $ref_value . ' object';
                }
            }
            else {
                # To leave value or to nuke it in this case?  Leave for now.
            }
        }
    }
    return $hashref;
}

sub _blank_array {
    my ($self, $arrayref) = @_;

    my $references_seen = $self->references_seen;
    my @ref_values =
      grep { ref($_) eq 'HASH' or ref($_) eq 'ARRAY' } @{$arrayref};
    # if no array values are a reference to either a HASH or an ARRAY then we return an empty array reference
    if (!scalar @ref_values) {
        $arrayref = [];
    }
    else {
        $arrayref = [
            map {
                if (ref($_) eq 'HASH') {
                    $self->_blank_hash($_);
                }
                elsif (ref($_) eq 'ARRAY') {
                    # Skip if we've seen this ref before
                    if ($references_seen->{$_}) {
                        warn "Seen referenced value: $_ before" if $self->debug_skeleton;
                        return $_;
                    }
                    $references_seen->{$_} = 1;
                    $self->references_seen($references_seen);
                    $self->_blank_array($_);
                }
                else {
                    $self->value_marker;
                }
              } @{$arrayref}
        ];
    }
    return $arrayref;
}

1;

=head1 AUTHORS

Mateu Hunter C<hunter@missoula.org>

=head1 COPYRIGHT

Copyright 2011-2012, Mateu Hunter

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
