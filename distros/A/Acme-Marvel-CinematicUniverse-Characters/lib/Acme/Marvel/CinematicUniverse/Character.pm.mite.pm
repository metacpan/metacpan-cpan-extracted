{
package Acme::Marvel::CinematicUniverse::Character;
use strict;
use warnings;
no warnings qw( once void );

our $USES_MITE = "Mite::Class";
our $MITE_SHIM = "Acme::Marvel::CinematicUniverse::Mite";
our $MITE_VERSION = "0.013000";
# Mite keywords
BEGIN {
    my ( $SHIM, $CALLER ) = ( "Acme::Marvel::CinematicUniverse::Mite", "Acme::Marvel::CinematicUniverse::Character" );
    ( *after, *around, *before, *extends, *has, *param, *signature_for, *with ) = do {
        package Acme::Marvel::CinematicUniverse::Mite;
        no warnings 'redefine';
        (
            sub { $SHIM->HANDLE_after( $CALLER, "class", @_ ) },
            sub { $SHIM->HANDLE_around( $CALLER, "class", @_ ) },
            sub { $SHIM->HANDLE_before( $CALLER, "class", @_ ) },
            sub {},
            sub { $SHIM->HANDLE_has( $CALLER, has => @_ ) },
            sub { $SHIM->HANDLE_has( $CALLER, param => @_ ) },
            sub { $SHIM->HANDLE_signature_for( $CALLER, "class", @_ ) },
            sub { $SHIM->HANDLE_with( $CALLER, @_ ) },
        );
    };
};

# Mite imports
BEGIN {
    *false = \&Acme::Marvel::CinematicUniverse::Mite::false;
    *true = \&Acme::Marvel::CinematicUniverse::Mite::true;
};

# Gather metadata for constructor and destructor
sub __META__ {
    no strict 'refs';
    my $class      = shift; $class = ref($class) || $class;
    my $linear_isa = mro::get_linear_isa( $class );
    return {
        BUILD => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::BUILD" } reverse @$linear_isa
        ],
        DEMOLISH => [
            map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
            map { "$_\::DEMOLISH" } @$linear_isa
        ],
        HAS_BUILDARGS => $class->can('BUILDARGS'),
        HAS_FOREIGNBUILDARGS => $class->can('FOREIGNBUILDARGS'),
    };
}


# Standard Moose/Moo-style constructor
sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $self  = bless {}, $class;
    my $args  = $meta->{HAS_BUILDARGS} ? $class->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %{$_[0]} : @_ };
    my $no_build = delete $args->{__no_BUILD__};

    # Attribute real_name (type: Str)
    # param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 19
    Acme::Marvel::CinematicUniverse::Mite::croak "Missing key in constructor: real_name" unless exists $args->{"real_name"}; 
    do { package Acme::Marvel::CinematicUniverse::Mite; defined($args->{"real_name"}) and do { ref(\$args->{"real_name"}) eq 'SCALAR' or ref(\(my $val = $args->{"real_name"})) eq 'SCALAR' } } or Acme::Marvel::CinematicUniverse::Mite::croak "Type check failed in constructor: %s should be %s", "real_name", "Str"; $self->{"real_name"} = $args->{"real_name"}; 

    # Attribute hero_name (type: Str)
    # param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 20
    Acme::Marvel::CinematicUniverse::Mite::croak "Missing key in constructor: hero_name" unless exists $args->{"hero_name"}; 
    do { package Acme::Marvel::CinematicUniverse::Mite; defined($args->{"hero_name"}) and do { ref(\$args->{"hero_name"}) eq 'SCALAR' or ref(\(my $val = $args->{"hero_name"})) eq 'SCALAR' } } or Acme::Marvel::CinematicUniverse::Mite::croak "Type check failed in constructor: %s should be %s", "hero_name", "Str"; $self->{"hero_name"} = $args->{"hero_name"}; 

    # Attribute intelligence (type: PositiveInt)
    # param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 21
    Acme::Marvel::CinematicUniverse::Mite::croak "Missing key in constructor: intelligence" unless exists $args->{"intelligence"}; 
    (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"intelligence"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"intelligence"} > 0 }) or Acme::Marvel::CinematicUniverse::Mite::croak "Type check failed in constructor: %s should be %s", "intelligence", "PositiveInt"; $self->{"intelligence"} = $args->{"intelligence"}; 

    # Attribute strength (type: PositiveInt)
    # param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 22
    Acme::Marvel::CinematicUniverse::Mite::croak "Missing key in constructor: strength" unless exists $args->{"strength"}; 
    (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"strength"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"strength"} > 0 }) or Acme::Marvel::CinematicUniverse::Mite::croak "Type check failed in constructor: %s should be %s", "strength", "PositiveInt"; $self->{"strength"} = $args->{"strength"}; 

    # Attribute speed (type: PositiveInt)
    # param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 23
    Acme::Marvel::CinematicUniverse::Mite::croak "Missing key in constructor: speed" unless exists $args->{"speed"}; 
    (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"speed"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"speed"} > 0 }) or Acme::Marvel::CinematicUniverse::Mite::croak "Type check failed in constructor: %s should be %s", "speed", "PositiveInt"; $self->{"speed"} = $args->{"speed"}; 

    # Attribute durability (type: PositiveInt)
    # param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 24
    Acme::Marvel::CinematicUniverse::Mite::croak "Missing key in constructor: durability" unless exists $args->{"durability"}; 
    (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"durability"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"durability"} > 0 }) or Acme::Marvel::CinematicUniverse::Mite::croak "Type check failed in constructor: %s should be %s", "durability", "PositiveInt"; $self->{"durability"} = $args->{"durability"}; 

    # Attribute energy_projection (type: PositiveInt)
    # param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 25
    Acme::Marvel::CinematicUniverse::Mite::croak "Missing key in constructor: energy_projection" unless exists $args->{"energy_projection"}; 
    (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"energy_projection"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"energy_projection"} > 0 }) or Acme::Marvel::CinematicUniverse::Mite::croak "Type check failed in constructor: %s should be %s", "energy_projection", "PositiveInt"; $self->{"energy_projection"} = $args->{"energy_projection"}; 

    # Attribute fighting_ability (type: PositiveInt)
    # param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 26
    Acme::Marvel::CinematicUniverse::Mite::croak "Missing key in constructor: fighting_ability" unless exists $args->{"fighting_ability"}; 
    (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"fighting_ability"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"fighting_ability"} > 0 }) or Acme::Marvel::CinematicUniverse::Mite::croak "Type check failed in constructor: %s should be %s", "fighting_ability", "PositiveInt"; $self->{"fighting_ability"} = $args->{"fighting_ability"}; 


    # Call BUILD methods
    $self->BUILDALL( $args ) if ( ! $no_build and @{ $meta->{BUILD} || [] } );

    # Unrecognized parameters
    my @unknown = grep not( /\A(?:durability|energy_projection|fighting_ability|hero_name|intelligence|real_name|s(?:peed|trength))\z/ ), keys %{$args}; @unknown and Acme::Marvel::CinematicUniverse::Mite::croak( "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

    return $self;
}

# Used by constructor to call BUILD methods
sub BUILDALL {
    my $class = ref( $_[0] );
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    $_->( @_ ) for @{ $meta->{BUILD} || [] };
}

# Destructor should call DEMOLISH methods
sub DESTROY {
    my $self  = shift;
    my $class = ref( $self ) || $self;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $in_global_destruction = defined ${^GLOBAL_PHASE}
        ? ${^GLOBAL_PHASE} eq 'DESTRUCT'
        : Devel::GlobalDestruction::in_global_destruction();
    for my $demolisher ( @{ $meta->{DEMOLISH} || [] } ) {
        my $e = do {
            local ( $?, $@ );
            eval { $demolisher->( $self, $in_global_destruction ) };
            $@;
        };
        no warnings 'misc'; # avoid (in cleanup) warnings
        die $e if $e;       # rethrow
    }
    return;
}

my $__XS = !$ENV{PERL_ONLY} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

# Accessors for durability
# param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 24
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "durability" => "durability" },
    );
}
else {
    *durability = sub { @_ == 1 or Acme::Marvel::CinematicUniverse::Mite::croak( 'Reader "durability" usage: $self->durability()' ); $_[0]{"durability"} };
}

# Accessors for energy_projection
# param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 25
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "energy_projection" => "energy_projection" },
    );
}
else {
    *energy_projection = sub { @_ == 1 or Acme::Marvel::CinematicUniverse::Mite::croak( 'Reader "energy_projection" usage: $self->energy_projection()' ); $_[0]{"energy_projection"} };
}

# Accessors for fighting_ability
# param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 26
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "fighting_ability" => "fighting_ability" },
    );
}
else {
    *fighting_ability = sub { @_ == 1 or Acme::Marvel::CinematicUniverse::Mite::croak( 'Reader "fighting_ability" usage: $self->fighting_ability()' ); $_[0]{"fighting_ability"} };
}

# Accessors for hero_name
# param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 20
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "hero_name" => "hero_name" },
    );
}
else {
    *hero_name = sub { @_ == 1 or Acme::Marvel::CinematicUniverse::Mite::croak( 'Reader "hero_name" usage: $self->hero_name()' ); $_[0]{"hero_name"} };
}

# Accessors for intelligence
# param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 21
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "intelligence" => "intelligence" },
    );
}
else {
    *intelligence = sub { @_ == 1 or Acme::Marvel::CinematicUniverse::Mite::croak( 'Reader "intelligence" usage: $self->intelligence()' ); $_[0]{"intelligence"} };
}

# Accessors for real_name
# param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 19
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "real_name" => "real_name" },
    );
}
else {
    *real_name = sub { @_ == 1 or Acme::Marvel::CinematicUniverse::Mite::croak( 'Reader "real_name" usage: $self->real_name()' ); $_[0]{"real_name"} };
}

# Accessors for speed
# param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 23
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "speed" => "speed" },
    );
}
else {
    *speed = sub { @_ == 1 or Acme::Marvel::CinematicUniverse::Mite::croak( 'Reader "speed" usage: $self->speed()' ); $_[0]{"speed"} };
}

# Accessors for strength
# param declaration, file lib/Acme/Marvel/CinematicUniverse/Character.pm, line 22
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "strength" => "strength" },
    );
}
else {
    *strength = sub { @_ == 1 or Acme::Marvel::CinematicUniverse::Mite::croak( 'Reader "strength" usage: $self->strength()' ); $_[0]{"strength"} };
}


# See UNIVERSAL
sub DOES {
    my ( $self, $role ) = @_;
    our %DOES;
    return $DOES{$role} if exists $DOES{$role};
    return 1 if $role eq __PACKAGE__;
    if ( $INC{'Moose/Util.pm'} and my $meta = Moose::Util::find_meta( ref $self or $self ) ) {
        $meta->can( 'does_role' ) and $meta->does_role( $role ) and return 1;
    }
    return $self->SUPER::DOES( $role );
}

# Alias for Moose/Moo-compatibility
sub does {
    shift->DOES( @_ );
}

1;
}