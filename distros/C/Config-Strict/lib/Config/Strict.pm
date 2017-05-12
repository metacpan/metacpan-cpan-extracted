package Config::Strict;
use warnings;
use strict;
use Data::Dumper;
use Scalar::Util qw(blessed weaken);
$Data::Dumper::Indent = 0;
use Carp qw(confess croak);

our $VERSION = '0.07';

use Declare::Constraints::Simple -All;
use Config::Strict::UserConstraints;

my %type_registry = (
    Bool     => IsOneOf( 0, 1 ),
    Num      => IsNumber,
    Int      => IsInt,
    Str      => HasLength,
    ArrayRef => IsArrayRef,
    HashRef  => IsHashRef,
    CodeRef  => IsCodeRef,
    Regexp   => IsRegex,
#    Enum     => undef,
#    Anon => undef,
);

sub register_types {
    # Allow user type registration
    my $class = shift;
    croak "No class" unless $class and not ref $class;
    croak "Invalid name-constraint pairs args (@_)" unless @_ and @_ % 2 == 0;
    my %nc = @_;
    while ( my ( $name, $constraint ) = each %nc ) {
        croak "No name"       unless $name;
        croak "No constraint" unless $constraint;
        croak "$name is already a registered type"
            if exists $type_registry{ $name }
                or $name eq 'Enum'
                or $name eq 'Anon';
#        print "Creating user type $name...\n";
        if ( _check_is_profile( $constraint ) ) {
            # Already a profile
            $type_registry{ $name } = $constraint;
        }
        else {
            # Make a profile from a bare sub
            my $made = _make_constraint( $name => $constraint );
            $type_registry{ $name } = $made;
        }
    }
}

sub _create_profile {
    my $param = shift;

    # Check parameter hash structure
    _validate_params( $param );

    my %profile = (
        # Built-in types
        (
            map {
                my $type = $_;
                map { $_ => $type_registry{ $type } }
                    _flatten( $param->{ $_ } )
                } keys %type_registry
        ),
        (
            map { $_ => IsOneOf( @{ $param->{ Enum }{ $_ } } ) }
                keys %{ $param->{ Enum } }
        ),
        # Anon types
        (
            map {
                my $sub = $param->{ Anon }{ $_ };
                $sub = _make_constraint( undef => $sub )
#                confess
#"Anon code blocks must be a Declare::Constraints::Simple profile."
#                    . " Use register_types to implement bare coderefs."
                    unless _check_is_profile( $sub );
                $_ => $sub
                } keys %{ $param->{ Anon } }
        ),
    );
    \%profile;
} ## end sub _create_profile

# Constructor
sub new {
    my $class = shift;
    my $opts  = shift;
    confess "Invalid construction arguments: @_" if @_;

    # Get the parameter hash
    croak "No 'params' key in constructor"
        unless exists $opts->{ params }
            and ( my $param = delete $opts->{ params } );

    # Get required, default values
    my $required = delete $opts->{ required } || [];
    my $default  = delete $opts->{ defaults } || {};

    # Check that options hash now empty
    confess sprintf( "Invalid option(s): %s", Dumper( $opts ) )
        if %$opts;

    # Create the configuration profile
    my $profile = _create_profile( $param );

    # Set required to all parameters if *
    $required = [ keys %$profile ] if $required eq '*';
    croak "Required parameters not an arrayref" 
        unless ref $required and ref $required eq 'ARRAY';
#        @$required == 1 and $required->[ 0 ] eq '_all';

    # Validate required and defaults
    _validate_required( $required, $profile );
    _validate_defaults( $default, $required );

    # Construct
    my $self = bless( {
            _required => { map { $_ => 1 } @$required }
            ,    # Convert to hash lookup
            _profile => $profile,
        },
        $class
    );
    $self->set( %$default );
    $self;
} ## end sub new

sub get {
    my $self = shift;
    $self->_get_check( @_ );
    my $params = $self->{ _params };
    return (
        wantarray ? ( map { $params->{ $_ } } @_ ) : $params->{ $_[ 0 ] } );
}

sub set {
    my $self = shift;
    $self->_set_check( @_ );
    my %pv = @_;
    while ( my ( $p, $v ) = each %pv ) {
        $self->{ _params }{ $p } = $v;
    }
    1;
}

sub unset {
    my $self = shift;
    $self->_unset_check( @_ );
    delete $self->{ _params }{ $_ } for @_;
}

sub param_is_set {
    my $self = shift;
    croak "No parameter passed" unless @_;
    return exists $self->{ _params }{ $_[ 0 ] };
}

sub all_set_params {
    keys %{ shift->{ _params } };
}

sub param_hash {
    %{ shift->{ _params } };
}

sub param_array {
    my $self   = shift;
    my $params = $self->{ _params };
    map { [ $_ => $params->{ $_ } ] } keys %$params;
}

sub param_exists {
    my $self = shift;
    croak "No parameter passed" unless @_;
    return exists $self->{ _profile }{ $_[ 0 ] };
}

sub all_params {
    keys %{ shift->{ _profile } };
}

sub get_profile {
    my $self = shift;
    croak "No parameter passed" unless @_;
    $self->{ _profile }{ $_[ 0 ] };
}

sub _get_check {
    my ( $self, @params ) = @_;
    my $profile = $self->{ _profile };
    _profile_check( $profile, $_ ) for @params;
}

sub _set_check {
    my ( $self, %value ) = @_;
    my $profile = $self->{ _profile };
    while ( my ( $k, $v ) = each %value ) {
        _profile_check( $profile, $k => $v );
    }
}

sub _unset_check {
    my ( $self, @params ) = @_;
    # Check against required parameters
    for ( @params ) {
        confess "$_ is a required parameter" if $self->param_is_required( $_ );
    }
    # Check against profile
    my $profile = $self->{ _profile };
    _profile_check( $profile, $_ ) for @params;
}

sub validate {
    my $self = shift;
    confess "No parameter-values pairs passed" unless @_ >= 2;
    confess "Uneven number of parameter-values pairs passed" if @_ % 2;
    my %pair = @_;
    while ( my ( $param, $value ) = each %pair ) {
        return 0
            unless $self->param_exists( $param )
                and $self->get_profile( $param )->( $value );
    }
    1;
}

sub param_is_required {
    my ( $self, $param ) = @_;
    return unless $param;
    return 1 if $self->{ _required }{ $param };
    0;
}

# Static validator from profile
sub _profile_check {
    my ( $profile, $param ) = ( shift, shift );
    confess "No parameter passed" unless defined $param;
    confess "Invalid parameter: $param doesn't exist"
        unless exists $profile->{ $param };
    if ( @_ ) {
        my $value  = shift;
        my $result = $profile->{ $param }->( $value );
        unless ( $result ) {
            # Failed validation
            confess $result->message
                if ref $result
                    and $result->isa( 'Declare::Constraints::Simple::Result' );
            confess sprintf( "Invalid value (%s) for config parameter $param",
                defined $value ? $value : 'undef' );
        }
    }
}

sub _validate_params {
    my $param = shift;
    confess "No parameters passed"
        unless defined $param
            and ref $param
            and ref $param eq 'HASH'
            and %$param;
    my $param_profile = OnHashKeys( (
            map { $_ => Or( HasLength, IsArrayRef ) }
                qw( Bool Int Num Str Regexp ArrayRef HashRef )
        ),
        Enum => IsHashRef(
            -keys   => HasLength,
            -values => IsArrayRef
        ),
        Anon => IsHashRef(
            -keys   => HasLength,
            -values => IsCodeRef
        ),
    );
    my $result = $param_profile->( $param );
    confess $result->message unless $result;
    $result;
}

sub _validate_defaults {
    my ( $default, $required ) = @_;
    for ( @$required ) {
        confess "$_ is a required parameter but isn't in the defaults"
            unless exists $default->{ $_ };
    }
    1;
}

sub _validate_required {
    my ( $required, $profile ) = @_;
    for ( @$required ) {
        confess "Required parameter '$_' not in the configuration profile"
            unless exists $profile->{ $_ };
    }
    1;
}

sub _flatten {
    my $val = shift;
    return unless defined $val;
    return ( $val ) unless ref $val;
    return @{ $val } if ref $val eq 'ARRAY';
    confess "Not a valid parameter ref: " . ref $val;
}

sub _check_is_profile {
    my ( $sub ) = @_;
    confess "Given constraint not a coderef"
        unless $sub
            and ref $sub
            and ref $sub eq 'CODE';
    my $class = blessed( $sub->( 1 ) );
#    print $class;
    return 0
        unless $class and $class eq "Declare::Constraints::Simple::Result";
    1;
}

{
    my $anon_count = 0;

    sub _make_constraint {
        my ( $name, $sub ) = @_;
#    confess "No name provided" unless $name;
        unless ( defined $name ) {
            # Anonymous constraint
            $name = sprintf( "__ANON%d__", $anon_count++ );
        }
        confess "Not a coderef"
            unless $sub and ref $sub eq 'CODE';
        # Make the constraint
        Config::Strict::UserConstraints->make_constraint( $name => $sub );
        # Return the new constraint
        my $class = 'Config::Strict::UserConstraints';
#        print "Declarations: ",Dumper( [ $class->fetch_constraint_declarations ]),"\n";
        no strict 'refs';
        my $made = ${ $class . '::CONSTRAINT_GENERATORS' }{ $name };
        use strict 'refs';
        # Sanity check
        croak "(assert) Generated constraint doesn't return a Result object"
            unless _check_is_profile( $made );
        return $made;
    }
}

1;
