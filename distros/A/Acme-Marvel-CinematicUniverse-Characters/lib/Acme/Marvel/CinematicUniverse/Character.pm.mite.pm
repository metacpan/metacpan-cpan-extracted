{
package Acme::Marvel::CinematicUniverse::Character;
our $USES_MITE = "Mite::Class";
our $MITE_SHIM = "Acme::Marvel::CinematicUniverse::Mite";
use strict;
use warnings;

BEGIN {
    *false = \&Acme::Marvel::CinematicUniverse::Mite::false;
    *true = \&Acme::Marvel::CinematicUniverse::Mite::true;
};


sub new {
    my $class = ref($_[0]) ? ref(shift) : shift;
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    my $self  = bless {}, $class;
    my $args  = $meta->{HAS_BUILDARGS} ? $class->BUILDARGS( @_ ) : { ( @_ == 1 ) ? %{$_[0]} : @_ };
    my $no_build = delete $args->{__no_BUILD__};

    # Initialize attributes
    if ( exists $args->{"real_name"} ) { do { package Acme::Marvel::CinematicUniverse::Mite; defined($args->{"real_name"}) and do { ref(\$args->{"real_name"}) eq 'SCALAR' or ref(\(my $val = $args->{"real_name"})) eq 'SCALAR' } } or require Carp && Carp::croak(sprintf "Type check failed in constructor: %s should be %s", "real_name", "Str"); $self->{"real_name"} = $args->{"real_name"};  } else { require Carp; Carp::croak("Missing key in constructor: real_name") };
    if ( exists $args->{"hero_name"} ) { do { package Acme::Marvel::CinematicUniverse::Mite; defined($args->{"hero_name"}) and do { ref(\$args->{"hero_name"}) eq 'SCALAR' or ref(\(my $val = $args->{"hero_name"})) eq 'SCALAR' } } or require Carp && Carp::croak(sprintf "Type check failed in constructor: %s should be %s", "hero_name", "Str"); $self->{"hero_name"} = $args->{"hero_name"};  } else { require Carp; Carp::croak("Missing key in constructor: hero_name") };
    if ( exists $args->{"intelligence"} ) { (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"intelligence"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"intelligence"} > 0 }) or require Carp && Carp::croak(sprintf "Type check failed in constructor: %s should be %s", "intelligence", "PositiveInt"); $self->{"intelligence"} = $args->{"intelligence"};  } else { require Carp; Carp::croak("Missing key in constructor: intelligence") };
    if ( exists $args->{"strength"} ) { (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"strength"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"strength"} > 0 }) or require Carp && Carp::croak(sprintf "Type check failed in constructor: %s should be %s", "strength", "PositiveInt"); $self->{"strength"} = $args->{"strength"};  } else { require Carp; Carp::croak("Missing key in constructor: strength") };
    if ( exists $args->{"speed"} ) { (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"speed"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"speed"} > 0 }) or require Carp && Carp::croak(sprintf "Type check failed in constructor: %s should be %s", "speed", "PositiveInt"); $self->{"speed"} = $args->{"speed"};  } else { require Carp; Carp::croak("Missing key in constructor: speed") };
    if ( exists $args->{"durability"} ) { (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"durability"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"durability"} > 0 }) or require Carp && Carp::croak(sprintf "Type check failed in constructor: %s should be %s", "durability", "PositiveInt"); $self->{"durability"} = $args->{"durability"};  } else { require Carp; Carp::croak("Missing key in constructor: durability") };
    if ( exists $args->{"energy_projection"} ) { (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"energy_projection"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"energy_projection"} > 0 }) or require Carp && Carp::croak(sprintf "Type check failed in constructor: %s should be %s", "energy_projection", "PositiveInt"); $self->{"energy_projection"} = $args->{"energy_projection"};  } else { require Carp; Carp::croak("Missing key in constructor: energy_projection") };
    if ( exists $args->{"fighting_ability"} ) { (do { package Acme::Marvel::CinematicUniverse::Mite; (do { my $tmp = $args->{"fighting_ability"}; defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/ }) } && do { package Acme::Marvel::CinematicUniverse::Mite; $args->{"fighting_ability"} > 0 }) or require Carp && Carp::croak(sprintf "Type check failed in constructor: %s should be %s", "fighting_ability", "PositiveInt"); $self->{"fighting_ability"} = $args->{"fighting_ability"};  } else { require Carp; Carp::croak("Missing key in constructor: fighting_ability") };

    # Enforce strict constructor
    my @unknown = grep not( /\A(?:durability|energy_projection|fighting_ability|hero_name|intelligence|real_name|s(?:peed|trength))\z/ ), keys %{$args}; @unknown and require Carp and Carp::croak("Unexpected keys in constructor: " . join(q[, ], sort @unknown));

    # Call BUILD methods
    $self->BUILDALL( $args ) if ( ! $no_build and @{ $meta->{BUILD} || [] } );

    return $self;
}

sub BUILDALL {
    my $class = ref( $_[0] );
    my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
    $_->( @_ ) for @{ $meta->{BUILD} || [] };
}

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

sub DOES {
    my ( $self, $role ) = @_;
    our %DOES;
    return $DOES{$role} if exists $DOES{$role};
    return 1 if $role eq __PACKAGE__;
    return $self->SUPER::DOES( $role );
}

sub does {
    shift->DOES( @_ );
}

my $__XS = !$ENV{MITE_PURE_PERL} && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

# Accessors for durability
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "durability" => "durability" },
    );
}
else {
    *durability = sub { @_ > 1 ? require Carp && Carp::croak("durability is a read-only attribute of @{[ref $_[0]]}") : $_[0]{"durability"} };
}

# Accessors for energy_projection
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "energy_projection" => "energy_projection" },
    );
}
else {
    *energy_projection = sub { @_ > 1 ? require Carp && Carp::croak("energy_projection is a read-only attribute of @{[ref $_[0]]}") : $_[0]{"energy_projection"} };
}

# Accessors for fighting_ability
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "fighting_ability" => "fighting_ability" },
    );
}
else {
    *fighting_ability = sub { @_ > 1 ? require Carp && Carp::croak("fighting_ability is a read-only attribute of @{[ref $_[0]]}") : $_[0]{"fighting_ability"} };
}

# Accessors for hero_name
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "hero_name" => "hero_name" },
    );
}
else {
    *hero_name = sub { @_ > 1 ? require Carp && Carp::croak("hero_name is a read-only attribute of @{[ref $_[0]]}") : $_[0]{"hero_name"} };
}

# Accessors for intelligence
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "intelligence" => "intelligence" },
    );
}
else {
    *intelligence = sub { @_ > 1 ? require Carp && Carp::croak("intelligence is a read-only attribute of @{[ref $_[0]]}") : $_[0]{"intelligence"} };
}

# Accessors for real_name
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "real_name" => "real_name" },
    );
}
else {
    *real_name = sub { @_ > 1 ? require Carp && Carp::croak("real_name is a read-only attribute of @{[ref $_[0]]}") : $_[0]{"real_name"} };
}

# Accessors for speed
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "speed" => "speed" },
    );
}
else {
    *speed = sub { @_ > 1 ? require Carp && Carp::croak("speed is a read-only attribute of @{[ref $_[0]]}") : $_[0]{"speed"} };
}

# Accessors for strength
if ( $__XS ) {
    Class::XSAccessor->import(
        chained => 1,
        "getters" => { "strength" => "strength" },
    );
}
else {
    *strength = sub { @_ > 1 ? require Carp && Carp::croak("strength is a read-only attribute of @{[ref $_[0]]}") : $_[0]{"strength"} };
}


1;
}