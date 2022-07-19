{

    package Acme::Mitey::Cards::Card::Face;
    use strict;
    use warnings;

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Acme::Mitey::Cards::Mite";
    our $MITE_VERSION = "0.007003";

    BEGIN {
        require Scalar::Util;
        *bare    = \&Acme::Mitey::Cards::Mite::bare;
        *blessed = \&Scalar::Util::blessed;
        *carp    = \&Acme::Mitey::Cards::Mite::carp;
        *confess = \&Acme::Mitey::Cards::Mite::confess;
        *croak   = \&Acme::Mitey::Cards::Mite::croak;
        *false   = \&Acme::Mitey::Cards::Mite::false;
        *guard   = \&Acme::Mitey::Cards::Mite::guard;
        *lazy    = \&Acme::Mitey::Cards::Mite::lazy;
        *ro      = \&Acme::Mitey::Cards::Mite::ro;
        *rw      = \&Acme::Mitey::Cards::Mite::rw;
        *rwp     = \&Acme::Mitey::Cards::Mite::rwp;
        *true    = \&Acme::Mitey::Cards::Mite::true;
    }

    BEGIN {
        require Acme::Mitey::Cards::Card;

        use mro 'c3';
        our @ISA;
        push @ISA, "Acme::Mitey::Cards::Card";
    }

    sub new {
        my $class = ref( $_[0] ) ? ref(shift) : shift;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $self  = bless {}, $class;
        my $args =
            $meta->{HAS_BUILDARGS}
          ? $class->BUILDARGS(@_)
          : { ( @_ == 1 ) ? %{ $_[0] } : @_ };
        my $no_build = delete $args->{__no_BUILD__};

        # Attribute: deck
        if ( exists $args->{"deck"} ) {
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed( $args->{"deck"} )
                      and $args->{"deck"}->isa(q[Acme::Mitey::Cards::Deck]);
                }
              )
              or croak "Type check failed in constructor: %s should be %s",
              "deck", "Deck";
            $self->{"deck"} = $args->{"deck"};
        }
        require Scalar::Util && Scalar::Util::weaken( $self->{"deck"} )
          if exists $self->{"deck"};

        # Attribute: reverse
        if ( exists $args->{"reverse"} ) {
            do {

                package Acme::Mitey::Cards::Mite;
                defined( $args->{"reverse"} ) and do {
                    ref( \$args->{"reverse"} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{"reverse"} ) ) eq 'SCALAR';
                }
              }
              or croak "Type check failed in constructor: %s should be %s",
              "reverse", "Str";
            $self->{"reverse"} = $args->{"reverse"};
        }

        # Attribute: suit
        croak "Missing key in constructor: suit" unless exists $args->{"suit"};
        do {
            my $coerced_value = do {
                my $to_coerce = $args->{"suit"};
                (
                    (
                        do {
                            use Scalar::Util ();
                            Scalar::Util::blessed($to_coerce)
                              and $to_coerce->isa(q[Acme::Mitey::Cards::Suit]);
                        }
                    )
                ) ? $to_coerce : (
                    do {

                        package Acme::Mitey::Cards::Mite;
                        defined($to_coerce) and do {
                            ref( \$to_coerce ) eq 'SCALAR'
                              or ref( \( my $val = $to_coerce ) ) eq 'SCALAR';
                        }
                    }
                  )
                  ? scalar(
                    do {
                        local $_ = $to_coerce;
                        do {
                            my $method = lc($_);
                            'Acme::Mitey::Cards::Suit'->$method;
                        }
                    }
                  )
                  : $to_coerce;
            };
            (
                do {
                    use Scalar::Util ();
                    Scalar::Util::blessed($coerced_value)
                      and $coerced_value->isa(q[Acme::Mitey::Cards::Suit]);
                }
              )
              or croak "Type check failed in constructor: %s should be %s",
              "suit", "Suit";
            $self->{"suit"} = $coerced_value;
        };

        # Attribute: face
        croak "Missing key in constructor: face" unless exists $args->{"face"};
        do {

            package Acme::Mitey::Cards::Mite;
            (         defined( $args->{"face"} )
                  and !ref( $args->{"face"} )
                  and $args->{"face"} =~ m{\A(?:(?:Jack|King|Queen))\z} );
          }
          or croak "Type check failed in constructor: %s should be %s", "face",
          "Character";
        $self->{"face"} = $args->{"face"};

        # Enforce strict constructor
        my @unknown = grep not(/\A(?:deck|face|reverse|suit)\z/), keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        return $self;
    }

    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        return $self->SUPER::DOES($role);
    }

    sub does {
        shift->DOES(@_);
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for face
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "face" => "face" },
        );
    }
    else {
        *face = sub {
            @_ > 1
              ? croak("face is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"face"};
        };
    }

    # Accessors for suit
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "suit" => "suit" },
        );
    }
    else {
        *suit = sub {
            @_ > 1
              ? croak("suit is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"suit"};
        };
    }

    our %SIGNATURE_FOR;

    $SIGNATURE_FOR{"face_abbreviation"} = sub {
        my $__NEXT__ = shift;

        my ( %tmp, $tmp, @head );

        @_ == 1
          or croak(
            "Wrong number of parameters in signature for %s: %s, got %d",
            "face_abbreviation", "expected exactly 1 parameters",
            scalar(@_)
          );

        @head = splice( @_, 0, 1 );

        # Parameter $head[0] (type: Defined)
        ( defined( $head[0] ) )
          or croak(
"Type check failed in signature for face_abbreviation: %s should be %s",
            "\$_[0]", "Defined"
          );

        return ( &$__NEXT__( @head, @_ ) );
    };

    $SIGNATURE_FOR{"to_string"} =
      $Acme::Mitey::Cards::Card::SIGNATURE_FOR{"to_string"};

    1;
}
