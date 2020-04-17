package Data::Record::Serialize::Role::Base;

# ABSTRACT: Base Role for Data::Record::Serialize

use Moo::Role;

our $VERSION = '0.20';

use Data::Record::Serialize::Error { errors => [ 'fields' ] }, -all;

use Types::Standard
  qw[ ArrayRef CodeRef CycleTuple HashRef Enum Str Bool is_HashRef Undef ];

use Ref::Util qw[ is_coderef is_arrayref ];

use POSIX ();

use namespace::clean;

#pod =attr C<types>
#pod
#pod A hash or array mapping input field names to types (C<N>, C<I>,
#pod C<S>).  If an array, the fields will be output in the specified
#pod order, provided the encoder permits it (see below, however).  For example,
#pod
#pod   # use order if possible
#pod   types => [ c => 'N', a => 'N', b => 'N' ]
#pod
#pod   # order doesn't matter
#pod   types => { c => 'N', a => 'N', b => 'N' }
#pod
#pod If C<fields> is specified, then its order will override that specified
#pod here.
#pod
#pod To understand how this attribute works in concert with L</fields> and
#pod L</default_type>, please see L</Fields and their types>.
#pod
#pod =method has_types
#pod
#pod returns true if L</types> has been set.
#pod
#pod =cut

has types => (
    is  => 'rwp',
    isa => ( HashRef [ Enum [qw( N I S )] ] | CycleTuple [ Str, Enum [qw( N I S )] ] ),   # need parens for perl <= 5.12.5
    predicate => 1,
    trigger   => sub {
        $_[0]->clear_type_index;
        $_[0]->clear_output_types;
    },
);

#pod =attr C<default_type> I<type>
#pod
#pod If set, output fields whose types were not
#pod specified via the C<types> attribute will be assigned this type.
#pod To understand how this attribute works in concert with L</fields> and
#pod L</types>, please see L</Fields and their types>.
#pod
#pod =cut

has default_type => (
    is  => 'ro',
    isa => Enum [qw( N I S )] | Undef,
);

#pod =attr C<fields>
#pod
#pod Which fields to output.  It may be one of:
#pod
#pod =over
#pod
#pod =item *
#pod
#pod An array containing the input names of the fields to be output. The
#pod fields will be output in the specified order, provided the encoder
#pod permits it.
#pod
#pod =item *
#pod
#pod The string C<all>, indicating that all input fields will be output.
#pod
#pod =item *
#pod
#pod Unspecified or undefined.
#pod
#pod =back
#pod
#pod To understand how this attribute works in concert with L</types> and
#pod L</default_type>, please see L<Data::Record::Serialize/Fields and their types>.
#pod
#pod =method has_fields
#pod
#pod returns true if L</fields> has been set.
#pod
#pod =cut

has fields => (
    is      => 'rwp',
    isa     => ( ArrayRef [Str] | Enum ['all'] ),  # need parens for perl <= 5.12.5
    predicate => 1,
    clearer => 1,
    trigger => sub {
        $_[0]->_clear_fieldh;
        $_[0]->clear_output_types;
        $_[0]->clear_output_fields;
    },
);


# for quick lookup of field names
has _fieldh => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    builder  => sub {
        my $self = shift;
        my %fieldh;
        @fieldh{ @{ $self->fields } } = ( 1 ) x @{ $self->fields };
        return \%fieldh;
    },
);


#pod =method B<output_fields>
#pod
#pod   $array_ref = $s->output_fields;
#pod
#pod The names of the transformed output fields, in order of output (not
#pod obeyed by all encoders);
#pod
#pod =cut

has output_fields => (
    is      => 'lazy',
    trigger => 1,
    clearer => 1,
    builder => sub {
        my $self = shift;
        [ map { $self->rename_fields->{$_} // $_ } @{ $self->fields } ];
    },
    init_arg => undef,
);

sub _trigger_output_fields { }

has _run_setup => (
    is        => 'rwp',
    isa       => Bool,
    init_args => undef,
    default   => 1,
);

has _need_types => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
    default  => 1,
);

has _use_integer => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
    default  => 1,
    # just in case need_types isn't explicitly set...
    trigger => sub { $_[0]->_set__need_types( 1 ) },
);

has _needs_eol => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
    default  => 1,
);

has _numify => (
    is       => 'rwp',
    isa      => Bool,
    init_arg => undef,
    default  => 0,
);


#pod =attr nullify
#pod
#pod Specify which fields should be set to C<undef> if they are
#pod empty. Sinks should encode C<undef> as the C<null> value.  By default,
#pod no fields are nullified.
#pod
#pod B<nullify> may be passed:
#pod
#pod =over
#pod
#pod =item *  an array
#pod
#pod It should be a list of input field names.  These names are verified
#pod against the input fields after the first record is read.
#pod
#pod =item * a code ref
#pod
#pod The coderef is passed the object, and should return a list of input
#pod field names.  These names are verified against the input fields after
#pod the first record is read.
#pod
#pod =item * a boolean
#pod
#pod If true, all field names are added to the list. When false, the list
#pod is emptied.
#pod
#pod =back
#pod
#pod During verification, a
#pod C<Data::Record::Serialize::Error::Role::Base::fields> error is thrown
#pod if non-existent fields are specified.  Verification is I<not>
#pod performed until the next record is sent (or the L</nullified> method
#pod is called), so there is no immediate feedback.
#pod
#pod =method has_nullify
#pod
#pod returns true if L</nullify> has been set.
#pod
#pod =cut


has nullify => (
    is        => 'rw',
    isa       => ( ArrayRef [Str] | CodeRef | Bool ),  # need parens for perl <= 5.12.5
    predicate => 1,
    trigger   => sub { $_[0]->_clear_nullify },
);

#pod =method nullified
#pod
#pod   $fields = $obj->nullified;
#pod
#pod Returns a list of fields which are checked for empty values (see L</nullify>).
#pod
#pod This will return C<undef> if the list is not yet available (for example, if
#pod fields names are determined from the first output record and none has been sent).
#pod
#pod If the list of fields is available, calling B<nullified> may result in
#pod verification of the list of nullified fields against the list of
#pod actual fields.  A disparity will result in an exception of class
#pod C<Data::Record::Serialize::Error::Role::Base::fields>.
#pod
#pod =cut

sub nullified {

    my $self = shift;

    return unless $self->has_fields;

    return [ @ { $self->_nullify } ];
}


has _nullify => (
    is       => 'rwp',
    lazy     => 1,
    isa      => ArrayRef [Str],
    clearer  => 1,
    predicate => 1,
    init_arg => undef,
    builder  => sub {

        my $self = shift;

        if ( $self->has_nullify ) {

            my $nullify = $self->nullify;

            if ( is_coderef( $nullify ) ) {

                $nullify = (ArrayRef[Str])->assert_return( $nullify->( $self ) );
            }

            elsif ( is_arrayref( $nullify ) ) {
                $nullify = [ @$nullify ];
            }

            else {
                $nullify = [ $nullify ? @{$self->fields} : () ];
            }

            my $fieldh = $self->_fieldh;
            my @not_field = grep { ! exists $fieldh->{$_} } @{ $nullify };
            error( 'fields', "unknown nullify fields: ", join( ', ', @not_field ) )
              if @not_field;

            return $nullify;
        }

        # this allows encoder's to use a before or around modifier
        # applied to _build__nullify to specify a default via
        # $self->_set__nullify.
        $self->_has_nullify ? $self->_nullify : [];
    },
);


#pod =method B<numeric_fields>
#pod
#pod   $array_ref = $s->numeric_fields;
#pod
#pod The input field names for those fields deemed to be numeric.
#pod
#pod =cut

sub numeric_fields { return $_[0]->type_index->{'numeric'} }

#pod =method B<type_index>
#pod
#pod   $hash = $s->type_index;
#pod
#pod A hash, keyed off of field type or category.  The values are
#pod an array of field names.  I<Don't edit this!>.
#pod
#pod The hash keys are:
#pod
#pod =over
#pod
#pod =item C<I>
#pod
#pod =item C<N>
#pod
#pod =item C<S>
#pod
#pod =item C<numeric>
#pod
#pod C<N> and C<I>.
#pod
#pod =item C<not_string>
#pod
#pod Everything but C<S>.
#pod
#pod =back
#pod
#pod =cut

has type_index => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    clearer  => 1,
    builder  => sub {
        my $self  = shift;
        my $types = $self->types;

        my %index = map {
            my ( $type, $re ) = @$_;
            {
                $type => [ grep { $types->{$_} =~ $re } keys %{$types} ]
            }
          }
          [ S          => qr/S/i ],
          [ N          => qr/N/i ],
          [ I          => qr/I/i ],
          [ numeric    => qr/[NI]/i ],
          [ not_string => qr/^[^S]+$/ ];

        return \%index;
    },
);

#pod =method B<output_types>
#pod
#pod   $hash_ref = $s->output_types;
#pod
#pod The mapping between output field name and output field type.  If the
#pod encoder has specified a type map, the output types are the result of
#pod that mapping.
#pod
#pod =cut

has output_types => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    trigger  => 1,
    builder  => sub {
        my $self = shift;

        my %types;

        return unless $self->has_types;

        my @int_fields = grep { defined $self->types->{$_} } @{ $self->fields };
        @types{@int_fields} = @{ $self->types }{@int_fields};

        unless ( $self->_use_integer ) {
            $_ = 'N' foreach grep { $_ eq 'I' } values %types;
        }

        if ( $self->_has_map_types ) {

            $types{$_} = $self->_map_types->{ $types{$_} } foreach keys %types;

        }

        for my $key ( keys %types ) {

            my $rename = $self->rename_fields->{$key}
              or next;

            $types{$rename} = delete $types{$key};
        }

        \%types;
    },
);

sub _trigger_output_types { }

has _map_types => (
    is        => 'rwp',
    init_arg  => undef,
    predicate => 1,
);

#pod =attr C<format_fields>
#pod
#pod A hash mapping the input field names to either a C<sprintf> style
#pod format or a coderef. This will be applied prior to encoding the
#pod record, but only if the C<format> attribute is also set.  Formats
#pod specified here override those specified in C<format_types>.
#pod
#pod The coderef will be called with the value to format as its first
#pod argument, and should return the formatted value.
#pod
#pod =cut

has format_fields => (
    is  => 'ro',
    isa => HashRef [Str | CodeRef],
);

#pod =attr C<format_types>
#pod
#pod A hash mapping a field type (C<N>, C<I>, C<S>) to a C<sprintf> style
#pod format or a coderef.  This will be applied prior to encoding the
#pod record, but only if the C<format> attribute is also set.  Formats
#pod specified here may be overridden for specific fields using the
#pod C<format_fields> attribute.
#pod
#pod The coderef will be called with the value to format as its first
#pod argument, and should return the formatted value.
#pod
#pod =cut

has format_types => (
    is  => 'ro',
    isa => HashRef [Str | CodeRef],
    # we'll need to gather types
    trigger => sub { $_[0]->_set__need_types( 1 ) if keys %{ $_[1] }; },
);


#pod =attr C<rename_fields>
#pod
#pod A hash mapping input to output field names.  By default the input
#pod field names are used unaltered.
#pod
#pod =cut

has rename_fields => (
    is     => 'ro',
    isa    => HashRef [Str],
    coerce => sub {
        return $_[0] unless is_HashRef( $_[0] );

        # remove renames which do nothing
        my %rename = %{ $_[0] };
        delete @rename{ grep { $rename{$_} eq $_ } keys %rename };
        return \%rename;
    },
    default => sub { {} },
    trigger => sub {
        $_[0]->clear_output_types;
    },
);


#pod =attr C<format>
#pod
#pod If true, format the output fields using the formats specified in the
#pod C<format_fields> and/or C<format_types> options.  The default is false.
#pod
#pod =cut

has format => (
    is      => 'ro',
    isa     => Bool,
    default => 1,
);

has _format => (
    is      => 'rwp',
    lazy    => 1,
    default => sub {

        my $self = shift;


        if ( $self->format ) {

            my %format;

            # first consider types; they'll be overridden by per field
            # formats in the next step.
            if ( $self->format_types && $self->types ) {

                for my $field ( @{ $self->fields } ) {

                    my $type = $self->types->{$field}
                      or next;

                    my $format = $self->format_types->{$type}
                      or next;

                    $format{$field} = $format;
                }
            }

            if ( $self->format_fields ) {

                for my $field ( @{ $self->fields } ) {

                    my $format = $self->format_fields->{$field}
                      or next;

                    $format{$field} = $format;
                }

            }

            return \%format
              if keys %format;
        }

        return;
    },
    init_arg => undef,
);

#pod =for Pod::Coverage
#pod   BUILD
#pod
#pod =cut

sub BUILD {

    my $self = shift;

    # if types is passed, set fields if it's not set.
    # convert types to hash if it's an array

    my $types;
    if ( defined( $types = $self->types ) ) {

        if ( 'HASH' eq ref $types ) {

            $self->_set_fields( [ keys %{$types} ] )
             unless $self->has_fields;
        }

        elsif ( 'ARRAY' eq ref $types ) {

            $self->_set_types( { @{$types} } );

            if ( ! $self->has_fields ) {

                my @fields;
                push @fields, $types->[ 2 * $_ ] for 0 .. ( @{$types} / 2 ) - 1;

                $self->_set_fields( \@fields );
            }
        }
        else {
            error( '::attribute::value', "internal error" );
        }

    }

    if ( $self->has_fields ) {

        if ( ref $self->fields ) {

            # in this specific case everything can be done before the first
            # record is read.  this is kind of overkill, but at least one
            # test depended upon being able to determine types prior
            # to sending the first record, so need to do this here rather
            # than in Default::setup
            if ( $self->_need_types && defined $self->default_type ) {
                $self->_set_types_from_default;
                $self->_set__need_types( 0 );
            }
        }

        # if fields eq 'all', clear out the attribute so that it will get
        # filled in when the first record is sent.
        else {
            $self->clear_fields;
        }
    }

    return;
}

sub _set_types_from_record {

    my ( $self, $data ) = @_;

    my $types = $self->has_types ? $self->types : {};

    for my $field ( grep !defined $types->{$_}, @{ $self->fields } ) {

        my $value = $data->{$field};
        my $def = Scalar::Util::looks_like_number( $value ) ? 'N' : 'S';

        $def = 'I'
          if $self->_use_integer
          && $def eq 'N'
          && POSIX::floor( $value ) == POSIX::ceil( $value );

        $types->{$field} = $def;
    }

    $self->_set_types( $types );
}

sub _set_types_from_default {

    my $self = shift;

    my $types = $self->has_types ? $self->types : {};

    $types->{$_} = $self->default_type
      for grep { !defined $types->{$_} } @{ $self->fields };

    $self->_set_types( $types );
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

Data::Record::Serialize::Role::Base - Base Role for Data::Record::Serialize

=head1 VERSION

version 0.20

=head1 DESCRIPTION

C<Data::Record::Serialize::Role::Base> is the base role for
L<Data::Record::Serialize>.  It serves the place of a base class, except
as a role there is no overhead during method lookup

=head1 METHODS

=head2 has_types

returns true if L</types> has been set.

=head2 has_fields

returns true if L</fields> has been set.

=head2 B<output_fields>

  $array_ref = $s->output_fields;

The names of the transformed output fields, in order of output (not
obeyed by all encoders);

=head2 has_nullify

returns true if L</nullify> has been set.

=head2 nullified

  $fields = $obj->nullified;

Returns a list of fields which are checked for empty values (see L</nullify>).

This will return C<undef> if the list is not yet available (for example, if
fields names are determined from the first output record and none has been sent).

If the list of fields is available, calling B<nullified> may result in
verification of the list of nullified fields against the list of
actual fields.  A disparity will result in an exception of class
C<Data::Record::Serialize::Error::Role::Base::fields>.

=head2 B<numeric_fields>

  $array_ref = $s->numeric_fields;

The input field names for those fields deemed to be numeric.

=head2 B<type_index>

  $hash = $s->type_index;

A hash, keyed off of field type or category.  The values are
an array of field names.  I<Don't edit this!>.

The hash keys are:

=over

=item C<I>

=item C<N>

=item C<S>

=item C<numeric>

C<N> and C<I>.

=item C<not_string>

Everything but C<S>.

=back

=head2 B<output_types>

  $hash_ref = $s->output_types;

The mapping between output field name and output field type.  If the
encoder has specified a type map, the output types are the result of
that mapping.

=head1 ATTRIBUTES

=head2 C<types>

A hash or array mapping input field names to types (C<N>, C<I>,
C<S>).  If an array, the fields will be output in the specified
order, provided the encoder permits it (see below, however).  For example,

  # use order if possible
  types => [ c => 'N', a => 'N', b => 'N' ]

  # order doesn't matter
  types => { c => 'N', a => 'N', b => 'N' }

If C<fields> is specified, then its order will override that specified
here.

To understand how this attribute works in concert with L</fields> and
L</default_type>, please see L</Fields and their types>.

=head2 C<default_type> I<type>

If set, output fields whose types were not
specified via the C<types> attribute will be assigned this type.
To understand how this attribute works in concert with L</fields> and
L</types>, please see L</Fields and their types>.

=head2 C<fields>

Which fields to output.  It may be one of:

=over

=item *

An array containing the input names of the fields to be output. The
fields will be output in the specified order, provided the encoder
permits it.

=item *

The string C<all>, indicating that all input fields will be output.

=item *

Unspecified or undefined.

=back

To understand how this attribute works in concert with L</types> and
L</default_type>, please see L<Data::Record::Serialize/Fields and their types>.

=head2 nullify

Specify which fields should be set to C<undef> if they are
empty. Sinks should encode C<undef> as the C<null> value.  By default,
no fields are nullified.

B<nullify> may be passed:

=over

=item *  an array

It should be a list of input field names.  These names are verified
against the input fields after the first record is read.

=item * a code ref

The coderef is passed the object, and should return a list of input
field names.  These names are verified against the input fields after
the first record is read.

=item * a boolean

If true, all field names are added to the list. When false, the list
is emptied.

=back

During verification, a
C<Data::Record::Serialize::Error::Role::Base::fields> error is thrown
if non-existent fields are specified.  Verification is I<not>
performed until the next record is sent (or the L</nullified> method
is called), so there is no immediate feedback.

=head2 C<format_fields>

A hash mapping the input field names to either a C<sprintf> style
format or a coderef. This will be applied prior to encoding the
record, but only if the C<format> attribute is also set.  Formats
specified here override those specified in C<format_types>.

The coderef will be called with the value to format as its first
argument, and should return the formatted value.

=head2 C<format_types>

A hash mapping a field type (C<N>, C<I>, C<S>) to a C<sprintf> style
format or a coderef.  This will be applied prior to encoding the
record, but only if the C<format> attribute is also set.  Formats
specified here may be overridden for specific fields using the
C<format_fields> attribute.

The coderef will be called with the value to format as its first
argument, and should return the formatted value.

=head2 C<rename_fields>

A hash mapping input to output field names.  By default the input
field names are used unaltered.

=head2 C<format>

If true, format the output fields using the formats specified in the
C<format_fields> and/or C<format_types> options.  The default is false.

=for Pod::Coverage BUILD

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
