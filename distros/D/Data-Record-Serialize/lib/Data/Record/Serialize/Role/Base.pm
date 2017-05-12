package Data::Record::Serialize::Role::Base;

use Moo::Role;

use Types::Standard qw[ ArrayRef HashRef Enum Str Bool ];

use POSIX ();
use Carp;

has types => (
    is      => 'rwp',
    trigger => 1,
    isa     => HashRef [ Enum [qw( N I S )] ] | ArrayRef,
);

sub _trigger_types {

    $_[0]->clear_numeric_fields;
    $_[0]->clear_output_types;

}

has default_type => (
    is      => 'ro',
    isa     => Enum[ qw( N I S ) ],
    default => 'S',
);

# input field names;
has fields => (
    is      => 'rwp',
    trigger => 1,
    isa     => ArrayRef [Str],
);

sub _trigger_fields {
    $_[0]->_clear_fieldh;
    $_[0]->clear_output_types;
    $_[0]->clear_output_fields;
}

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


# output field names
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

has numeric_fields => (
    is      => 'lazy',
    clearer => 1,
    builder => sub {
        my $self = shift;

        return [
            grep { $self->types->{$_} =~ /[IN]/i }
              keys %{ $self->types } ];

    },
    init_arg => undef,
);

has output_types => (
    is       => 'lazy',
    init_arg => undef,
    clearer  => 1,
    trigger  => 1,
    builder  => sub {
        my $self = shift;

        my %types;

        my @int_fields = grep { defined $self->types->{$_} } @{ $self->fields };
        @types{@int_fields} = @{ $self->types }{@int_fields};

        unless ( $self->_use_integer ) {
            $_ = 'N' foreach grep { $_ eq 'I' } values %types;
        }

        if ( defined $self->_map_types ) {

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


has _map_types => ( is => 'rwp', init_arg => undef, );

has format_fields => (
    is  => 'ro',
    isa => HashRef [Str],
);

has format_types => (
    is  => 'ro',
    isa => HashRef [Str],
);


has rename_fields => (
    is      => 'ro',
    isa     => HashRef [Str],
    default => sub { {} },
    trigger => 1,
);

sub _trigger_rename_fields {

    $_[0]->clear_output_types;

}

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
            return \%format;

        }

        return;
    },
    init_arg => undef,
);

sub BUILD {

    my $self = shift;

    my %args;

    # if we're asked to format based on types, make sure
    # we create them if needed.
    $self->_set__need_types( 1 )
      if $self->format_types && %{ $self->format_types };

    # if types is passed, set fields if it's not set.
    # convert types to hash if it's an array

    my $types;
    if ( defined( $types = $self->types ) ) {

        if ( 'HASH' eq ref $types ) {

            $self->_set_fields( [ keys %{$types} ] )
              if !defined $self->fields;
        }

        elsif ( 'ARRAY' eq ref $types ) {

            $self->_set_types( { @{$types} } );

            if ( !defined $self->fields ) {

                my @fields;
                push @fields, $types->[ 2 * $_ ] for 0 .. ( @{$types} / 2 ) - 1;

                $self->_set_fields( \@fields );
            }
        }
        else {

            croak( "types attribute must be a hash or an array\n" );

        }

	# default to string if not specified
	$self->types->{$_} = $self->default_type
	  for grep { !defined $self->types->{$_} } @{ $self->fields };
    }

    return;
}

sub _set_types_from_record {

    my ( $self, $data ) = @_;

    my %types;

    for my $field ( @{ $self->fields } ) {

        my $value = $data->{$field};
        my $def = Scalar::Util::looks_like_number( $value ) ? 'N' : 'S';

        $def = 'I'
          if $self->_use_integer
          && $def eq 'N'
          && POSIX::floor( $value ) == POSIX::ceil( $value );

        $types{$field} = $def;
    }

    $self->_set_types( \%types );

}


sub DEMOLISH {

    $_[0]->cleanup;

    return;
}

1;

