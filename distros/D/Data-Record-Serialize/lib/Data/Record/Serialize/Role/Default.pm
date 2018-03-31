package Data::Record::Serialize::Role::Default;

# ABSTRACT:  Default methods for Data::Record::Serialize

use Moo::Role;

our $VERSION = '0.15';

use Hash::Util qw[ hv_store ];

use namespace::clean;

#pod =for Pod::Coverage
#pod  cleanup
#pod  send
#pod  setup
#pod  DEMOLISH
#pod
#pod =cut

#pod =method B<send>
#pod
#pod   $s->send( \%record );
#pod
#pod Encode and send the record to the associated sink.
#pod
#pod B<WARNING>: the passed hash is modified.  If you need the original
#pod contents, pass in a copy.
#pod
#pod =cut

# provide default if not already defined
sub send {

    my $self = shift;

    $self->_needs_eol
      ? $self->say( $self->encode( @_ ) )
      : $self->print( $self->encode( @_ ) );
}

# provide default if not already defined
sub setup { }

around 'setup' => sub {

    my ( $orig, $self, $data ) = @_;

    # if fields has not been set yet, set it to the names in the data
    $self->_set_fields( [ keys %$data ] )
      unless $self->has_fields;

    if ( $self->_need_types ) {

        if ( $self->default_type ) {
            $self->_set_types_from_default;
        }
        else {
            $self->_set_types_from_record( $data );
        }

        $self->_set__need_types( 0 );
    }

    $orig->( $self );

    $self->_set__run_setup( 0 );
};


before 'send' => sub {

    my ( $self, $data ) = @_;

    # can't do format or numify until we have types, which might need to
    # be done from the data, which will be done in setup.

    $self->setup( $data )
      if $self->_run_setup;

    # remove fields that won't be output
    delete @{$data}{ grep { !defined $self->_fieldh->{$_} } keys %{$data} };

    # nullify fields (set to undef) those that are zero length

    if ( defined ( my $nullify = $self->_nullify ) ) {

        $data->{$_} = undef
          for grep { defined $data->{$_} && ! length $data->{$_} }
          @$nullify;
    }

    if ( $self->_format ) {

        my $format = $self->_format;

        $data->{$_} = sprintf( $format->{$_}, $data->{$_} )
          foreach grep { defined $data->{$_} && length $data->{$_} }
          keys %{$format};
    }

    if ( $self->_numify ) {

        $_ = ( $_ || 0 ) + 0 foreach @{$data}{ @{ $self->numeric_fields } };

    }

    if ( $self->rename_fields ) {

        my $rename = $self->rename_fields;

        for my $from ( @{ $self->fields } ) {

            my $to = $rename->{$from}
              or next;

            hv_store( %$data, $to, $data->{$from} );
            delete $data->{$from};
        }

    }

};

sub DEMOLISH {

    $_[0]->close;

    return;
}

1;

#
# This file is part of Data-Record-Serialize
#
# This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=head1 NAME

Data::Record::Serialize::Role::Default - Default methods for Data::Record::Serialize

=head1 VERSION

version 0.15

=head1 DESCRIPTION

C<Data::Record::Serialize::Role::Default> provides default methods for
L<Data::Record::Serialize>.  It is applied after all of the other roles to
ensure that other roles' methods have priority.

=head1 METHODS

=head2 B<send>

  $s->send( \%record );

Encode and send the record to the associated sink.

B<WARNING>: the passed hash is modified.  If you need the original
contents, pass in a copy.

=for Pod::Coverage cleanup
 send
 setup
 DEMOLISH

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize>.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Data::Record::Serialize|Data::Record::Serialize>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
