{

    package Acme::Mitey::Cards::Card::Face;
    use strict;
    use warnings;

    BEGIN {
        require Acme::Mitey::Cards::Card;

        use mro 'c3';
        our @ISA;
        push @ISA, q[Acme::Mitey::Cards::Card];
    }

    sub new {
        my $class = shift;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $self  = bless {}, $class;
        my $args =
            $meta->{HAS_BUILDARGS}
          ? $class->BUILDARGS(@_)
          : { ( @_ == 1 ) ? %{ $_[0] } : @_ };
        my $no_build = delete $args->{__no_BUILD__};

        # Initialize attributes
        if ( exists( $args->{q[deck]} ) ) {
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $args->{q[deck]} )
                      and $args->{q[deck]}->isa(q[Acme::Mitey::Cards::Deck]);
                }
              )
              or require Carp
              && Carp::croak(
q[Type check failed in constructor: deck should be InstanceOf["Acme::Mitey::Cards::Deck"]]
              );
            $self->{q[deck]} = $args->{q[deck]};
        }
        require Scalar::Util && Scalar::Util::weaken( $self->{q[deck]} );
        if ( exists( $args->{q[face]} ) ) {
            do {

                package Acme::Mitey::Cards::Mite;
                (         defined( $args->{q[face]} )
                      and !ref( $args->{q[face]} )
                      and $args->{q[face]} =~ m{\A(?:(?:Jack|King|Queen))\z} );
              }
              or require Carp
              && Carp::croak(
q[Type check failed in constructor: face should be Enum["Jack","Queen","King"]]
              );
            $self->{q[face]} = $args->{q[face]};
        }
        else { require Carp; Carp::croak("Missing key in constructor: face") }
        if ( exists( $args->{q[reverse]} ) ) {
            do {

                package Acme::Mitey::Cards::Mite;
                defined( $args->{q[reverse]} ) and do {
                    ref( \$args->{q[reverse]} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{q[reverse]} ) ) eq 'SCALAR';
                }
              }
              or require Carp
              && Carp::croak(
                q[Type check failed in constructor: reverse should be Str]);
            $self->{q[reverse]} = $args->{q[reverse]};
        }
        if ( exists( $args->{q[suit]} ) ) {
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $args->{q[suit]} )
                      and $args->{q[suit]}->isa(q[Acme::Mitey::Cards::Suit]);
                }
              )
              or require Carp
              && Carp::croak(
q[Type check failed in constructor: suit should be InstanceOf["Acme::Mitey::Cards::Suit"]]
              );
            $self->{q[suit]} = $args->{q[suit]};
        }
        else { require Carp; Carp::croak("Missing key in constructor: suit") }

        # Enforce strict constructor
        my @unknown = grep not(
            do {

                package Acme::Mitey::Cards::Mite;
                ( defined and !ref and m{\A(?:(?:deck|face|reverse|suit))\z} );
            }
          ),
          keys %{$args};
        @unknown
          and require Carp
          and Carp::croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        # Call BUILD methods
        !$no_build and @{ $meta->{BUILD} || [] } and $self->BUILDALL($args);

        return $self;
    }

    sub BUILDALL {
        $_->(@_) for @{ $Mite::META{ ref( $_[0] ) }{BUILD} || [] };
    }

    sub __META__ {
        no strict 'refs';
        require mro;
        my $class      = shift;
        my $linear_isa = mro::get_linear_isa($class);
        return {
            BUILD => [
                map { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                map { "$_\::BUILD" } reverse @$linear_isa
            ],
            DEMOLISH => [
                map   { ( *{$_}{CODE} ) ? ( *{$_}{CODE} ) : () }
                  map { "$_\::DEMOLISH" } reverse @$linear_isa
            ],
            HAS_BUILDARGS => $class->can('BUILDARGS'),
        };
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for face
    if ($__XS) {
        Class::XSAccessor->import(
            chained => 1,
            getters => { q[face] => q[face] },
        );
    }
    else {
        *face = sub {
            @_ > 1
              ? require Carp
              && Carp::croak("face is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{q[face]};
        };
    }

    # Accessors for suit
    if ($__XS) {
        Class::XSAccessor->import(
            chained => 1,
            getters => { q[suit] => q[suit] },
        );
    }
    else {
        *suit = sub {
            @_ > 1
              ? require Carp
              && Carp::croak("suit is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{q[suit]};
        };
    }

    1;
}
