use strict;
use warnings;

package Data::Delete;
$Data::Delete::VERSION = '0.06';
use Moo;
use MooX::Types::MooseLike::Base qw/HashRef Bool/;

=head1 NAME

Data::Delete - Delete keys with undefined or empty string values in a deep data structure

=head1 SYNOPSIS

    use Data::Delete;
    my $dd = Data::Delete->new;
    my $deep_data_structure = {
        id            => 4,
        last_modified => undef,
        sections      => [
            {
                content => 'h1. Ice Cream',
                class   => 'textile'
            },
            {
                content => '# Pie',
                class   => ''
            },
        ],
    };
    use Data::Dumper;
    print Dumper $dd->delete($deep_data_structure);

# results in:

    {
      id => "4",
      sections => [
        {
          content => 'h1. Ice Cream',
          class   => 'textile'
        },
        {
          content => "# Pie"
        }
      ]
    }

=head1 DESCRIPTION

A module for when you want to remove HashRef keys when the value is undefined
or an empty string.

=cut

has 'references_seen' => (
    is  => 'rw',
    isa => HashRef,
);

=head2 debug_delete

Turn on/off debugging

=cut

has 'debug_delete' => (
    is  => 'ro',
    isa => Bool,
);

=head2 will_delete_empty_string

Choose to remove empty string hash values

=cut

has 'will_delete_empty_string' => (
    is      => 'lazy',
    isa     => Bool,
    builder => sub { 1 },
);

=head1 METHODS

=head2 delete

    Signature: (HashRef|ArrayRef)
      Returns: The data structure with undefined hash values, and optionally, 
               empty string hash values removed 

=cut

sub delete {
    my ( $self, $data ) = @_;
    if ( ref($data) eq 'HASH' ) {
        return $self->_delete_hash($data);
    }
    elsif ( ref($data) eq 'ARRAY' ) {
        return $self->_delete_array($data);
    }
    else {
        die "You must pass the delete method either a HashRef or an ArrayRef";
    }
}

sub _delete_hash {
    my ( $self, $hashref ) = @_;

    # Work on a copy
    my %hashref = %{$hashref};
    $hashref = \%hashref;

    foreach my $key ( keys %{$hashref} ) {
        my $value           = $hashref->{$key};
        my $ref_value       = ref($value);
        my $references_seen = $self->references_seen;

        # Skip if we've seen this ref before
        if ( $ref_value and $references_seen->{$value} ) {
            warn "Seen referenced value: $value before" if $self->debug_delete;
            next;
        }

        # If we have a reference value then note it to avoid deep recursion
        # with circular references.
        if ($ref_value) {
            $references_seen->{$value} = 1;
            $self->references_seen($references_seen);
        }
        if ( not $ref_value ) {

            # Delete a key when the value is not defined
            if ( not defined $value ) {
                delete $hashref->{$key};
            }

            # Optionally delete an empty string value
            elsif ( length($value) == 0 ) {
                delete $hashref->{$key} if $self->will_delete_empty_string;
            }

            # Make no change
            else { }
        }

        # Defined and not the zero string
        elsif ( $ref_value eq 'HASH' ) {

            # Recurse when a value is a HashRef
            $hashref->{$key} = $self->_delete_hash($value);
        }

        # Look inside ArrayRefs for HashRefs
        elsif ( $ref_value eq 'ARRAY' ) {
            $hashref->{$key} = $self->_delete_array($value);
        }

        # Leave alone
        else { }
    }
    return $hashref;
}

sub _delete_array {
    my ( $self, $arrayref ) = @_;

    my $references_seen = $self->references_seen;
    $arrayref        = [
        map {
            if ( ref($_) ) {
                if ( ref($_) eq 'HASH' ) {
                    $self->_delete_hash($_);
                }
                elsif ( ref($_) eq 'ARRAY' ) {

                    # Skip if we've seen this ref before
                    if ( $references_seen->{$_} ) {
                        warn "Seen referenced value: $_ before"
                          if $self->debug_delete;
                        $_;
                    }
                    else {
                        $references_seen->{$_} = 1;
                        $self->references_seen($references_seen);
                        $self->_delete_array($_);
                   }
                }
            }
            else {
                $_;
            }
        } @{$arrayref}
    ];
    return $arrayref;
}

1;

=head1 AUTHORS

Mateu X Hunter C<hunter@missoula.org>

=head1 COPYRIGHT

Copyright 2015, Mateu X Hunter

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut
