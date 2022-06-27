{

    package Acme::Mitey::Cards::Card::Numeric;
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
        my $args  = { ( @_ == 1 ) ? %{ $_[0] } : @_ };

        my $self = bless {}, $class;

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
            delete $args->{q[deck]};
        }
        require Scalar::Util && Scalar::Util::weaken( $self->{q[deck]} );
        if ( exists( $args->{q[number]} ) ) {
            (
                do {
                    my $tmp = $args->{q[number]};
                    defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/;
                }
              )
              or require Carp
              && Carp::croak(
                q[Type check failed in constructor: number should be Int]);
            $self->{q[number]} = $args->{q[number]};
            delete $args->{q[number]};
        }
        else { require Carp; Carp::croak("Missing key in constructor: number") }
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
            delete $args->{q[reverse]};
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
            delete $args->{q[suit]};
        }
        else { require Carp; Carp::croak("Missing key in constructor: suit") }

        keys %$args
          and require Carp
          and Carp::croak( "Unexpected keys in constructor: "
              . join( q[, ], sort keys %$args ) );

        return $self;
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for deck
    if ($__XS) {
        Class::XSAccessor->import(
            chained => 1,
            getters => { q[deck] => q[deck] },
        );
    }
    else {
        *deck = sub {
            @_ > 1
              ? require Carp
              && Carp::croak("deck is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]->{q[deck]};
        };
    }

    # Accessors for number
    if ($__XS) {
        Class::XSAccessor->import(
            chained => 1,
            getters => { q[number] => q[number] },
        );
    }
    else {
        *number = sub {
            @_ > 1
              ? require Carp && Carp::croak(
                "number is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]->{q[number]};
        };
    }

    # Accessors for reverse
    *reverse = sub {
        @_ > 1
          ? require Carp
          && Carp::croak("reverse is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{q[reverse]} ) ? $_[0]{q[reverse]} : (
                $_[0]{q[reverse]} = do {
                    my $default_value = $_[0]->_build_reverse;
                    do {

                        package Acme::Mitey::Cards::Mite;
                        defined($default_value) and do {
                            ref( \$default_value ) eq 'SCALAR'
                              or ref( \( my $val = $default_value ) ) eq
                              'SCALAR';
                        }
                      }
                      or do {
                        require Carp;
                        Carp::croak(
q[Type check failed in default: reverse should be Str]
                        );
                      };
                    $default_value;
                }
            )
          );
    };

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
              : $_[0]->{q[suit]};
        };
    }

    1;
}
