package Data::Record::Serialize::Role::Default;

# ABSTRACT:  Default methods for Data::Record::Serialize

use Moo::Role;

our $VERSION = '0.34';

use Hash::Util qw[ hv_store ];
use Ref::Util qw[ is_coderef ];

use Data::Record::Serialize::Error { errors => [ 'fields' ] }, -all;

use namespace::clean;




















# provide default if not already defined
sub send {
    my $self = shift;

    $self->_needs_eol
      ? $self->say( $self->encode( @_ ) )
      : $self->print( $self->encode( @_ ) );
}

# just in case they're not defined in preceding roles
sub setup { }
sub _map_types { }
sub _needs_eol { 1 }

around 'setup' => sub {
    my ( $orig, $self, $data ) = @_;

    # if fields has not been set yet, set it to the names in the data
    $self->_set_fields( [ keys %$data ] )
      unless $self->has_fields;

    # make sure there are no duplicate output fields
    my %dups;
    $dups{$_}++ && error( fields => "duplicate output field: $_" ) for@{$self->fields};

    if ( $self->has_default_type ) {
        $self->_set_types_from_default;
    }
    else {
        $self->_set_types_from_record( $data );
    }

    # trigger building of output_types, which also remaps types. ick.
    $self->output_types;

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
    delete @{$data}{ grep { !exists $self->_fieldh->{$_} } keys %{$data} };

    # nullify fields (set to undef) those that are zero length

    if ( defined( my $fields = $self->_nullified ) ) {
        $data->{$_} = undef
          for grep { defined $data->{$_} && !length $data->{$_} } @$fields;
    }

    if ( defined( my $fields = $self->_numified ) ) {
        $data->{$_} = ( $data->{$_} || 0 ) + 0
          for grep { defined $data->{$_} } @{$fields};
    }

    if ( defined( my $fields = $self->_stringified ) ) {
        $data->{$_} = "@{[ $data->{$_}]}"
          for grep { defined $data->{$_} } @{$fields};
    }

    if ( my $format = $self->_format ) {
        $data->{$_}
          = is_coderef( $format->{$_} )
          ? $format->{$_}( $data->{$_} )
          : sprintf( $format->{$_}, $data->{$_} )
          foreach grep { defined $data->{$_} && length $data->{$_} }
          keys %{$format};
    }


    # handle boolean
    if ( $self->_boolify ) {
        my @fields = grep { exists $data->{$_} } @{ $self->boolean_fields };

        if ( $self->_can_bool ) {
            $data->{$_} = $self->to_bool( $data->{$_} ) for @fields;
        }

        # the encoder doesn't have native boolean, must convert a
        # truthy value to 0/1;
        else {
            $data->{$_} = $data->{$_} ? 1 : 0 foreach @fields;
        }
    }

    if ( my $rename = $self->rename_fields ) {
        for my $from ( @{ $self->fields } ) {
            my $to = $rename->{$from}
              or next;

            hv_store( %$data, $to, $data->{$from} );
            delete $data->{$from};
        }
    }
};

sub DEMOLISH {
    my ( $self, $in_global_destruction ) = @_;

    # we can't make the decision about whether to pay attention during
    # Global Destruction. the objects have to do that
    $self->close( $in_global_destruction );
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

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory

=head1 NAME

Data::Record::Serialize::Role::Default - Default methods for Data::Record::Serialize

=head1 VERSION

version 0.34

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

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-data-record-serialize@rt.cpan.org  or through the web interface at: https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Record-Serialize

=head2 Source

Source is available at

  https://gitlab.com/djerius/data-record-serialize

and may be cloned from

  https://gitlab.com/djerius/data-record-serialize.git

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
