{

    package Acme::Mitey::Cards::Card::Numeric;
    use strict;
    use warnings;
    no warnings qw( once void );

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Acme::Mitey::Cards::Mite";
    our $MITE_VERSION = "0.011000";

    # Mite keywords
    BEGIN {
        my ( $SHIM, $CALLER ) =
          ( "Acme::Mitey::Cards::Mite", "Acme::Mitey::Cards::Card::Numeric" );
        (
            *after, *around, *before,        *extends, *field,
            *has,   *param,  *signature_for, *with
          )
          = do {

            package Acme::Mitey::Cards::Mite;
            no warnings 'redefine';
            (
                sub { $SHIM->HANDLE_after( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_around( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_before( $CALLER, "class", @_ ) },
                sub { },
                sub { $SHIM->HANDLE_has( $CALLER, field => @_ ) },
                sub { $SHIM->HANDLE_has( $CALLER, has   => @_ ) },
                sub { $SHIM->HANDLE_has( $CALLER, param => @_ ) },
                sub { $SHIM->HANDLE_signature_for( $CALLER, "class", @_ ) },
                sub { $SHIM->HANDLE_with( $CALLER, @_ ) },
            );
          };
    }

    # Mite imports
    BEGIN {
        require Scalar::Util;
        *STRICT  = \&Acme::Mitey::Cards::Mite::STRICT;
        *bare    = \&Acme::Mitey::Cards::Mite::bare;
        *blessed = \&Scalar::Util::blessed;
        *carp    = \&Acme::Mitey::Cards::Mite::carp;
        *confess = \&Acme::Mitey::Cards::Mite::confess;
        *croak   = \&Acme::Mitey::Cards::Mite::croak;
        *false   = \&Acme::Mitey::Cards::Mite::false;
        *guard   = \&Acme::Mitey::Cards::Mite::guard;
        *lazy    = \&Acme::Mitey::Cards::Mite::lazy;
        *lock    = \&Acme::Mitey::Cards::Mite::lock;
        *ro      = \&Acme::Mitey::Cards::Mite::ro;
        *rw      = \&Acme::Mitey::Cards::Mite::rw;
        *rwp     = \&Acme::Mitey::Cards::Mite::rwp;
        *true    = \&Acme::Mitey::Cards::Mite::true;
        *unlock  = \&Acme::Mitey::Cards::Mite::unlock;
    }

    BEGIN {
        require Acme::Mitey::Cards::Card;

        use mro 'c3';
        our @ISA;
        push @ISA, "Acme::Mitey::Cards::Card";
    }

    # Standard Moose/Moo-style constructor
    sub new {
        my $class = ref( $_[0] ) ? ref(shift) : shift;
        my $meta  = ( $Mite::META{$class} ||= $class->__META__ );
        my $self  = bless {}, $class;
        my $args =
            $meta->{HAS_BUILDARGS}
          ? $class->BUILDARGS(@_)
          : { ( @_ == 1 ) ? %{ $_[0] } : @_ };
        my $no_build = delete $args->{__no_BUILD__};

        # Attribute deck (type: Deck)
        # has declaration, file lib/Acme/Mitey/Cards/Card.pm, line 9
        if ( exists $args->{"deck"} ) {
            blessed( $args->{"deck"} )
              && $args->{"deck"}->isa("Acme::Mitey::Cards::Deck")
              or croak "Type check failed in constructor: %s should be %s",
              "deck", "Deck";
            $self->{"deck"} = $args->{"deck"};
        }
        require Scalar::Util && Scalar::Util::weaken( $self->{"deck"} )
          if ref $self->{"deck"};

        # Attribute reverse (type: Str)
        # has declaration, file lib/Acme/Mitey/Cards/Card.pm, line 19
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

        # Attribute suit (type: Suit)
        # has declaration, file lib/Acme/Mitey/Cards/Card/Numeric.pm, line 13
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
            blessed($coerced_value)
              && $coerced_value->isa("Acme::Mitey::Cards::Suit")
              or croak "Type check failed in constructor: %s should be %s",
              "suit", "Suit";
            $self->{"suit"} = $coerced_value;
        };

        # Attribute number (type: CardNumber)
        # has declaration, file lib/Acme/Mitey/Cards/Card/Numeric.pm, line 20
        croak "Missing key in constructor: number"
          unless exists $args->{"number"};
        do {
            my $coerced_value = do {
                my $to_coerce = $args->{"number"};
                (
                    (
                        do {

                            package Acme::Mitey::Cards::Mite;
                            (
                                do {
                                    my $tmp = $to_coerce;
                                    defined($tmp)
                                      and !ref($tmp)
                                      and $tmp =~ /\A-?[0-9]+\z/;
                                }
                            );
                          }
                          && ( $to_coerce >= 1 )
                          && ( $to_coerce <= 10 )
                    )
                ) ? $to_coerce : (
                    do {

                        package Acme::Mitey::Cards::Mite;
                        (         defined($to_coerce)
                              and !ref($to_coerce)
                              and $to_coerce =~ m{\A(?:[Aa])\z} );
                    }
                ) ? scalar( do { local $_ = $to_coerce; 1 } ) : $to_coerce;
            };
            (
                do {

                    package Acme::Mitey::Cards::Mite;
                    (
                        do {
                            my $tmp = $coerced_value;
                            defined($tmp)
                              and !ref($tmp)
                              and $tmp =~ /\A-?[0-9]+\z/;
                        }
                    );
                  }
                  && ( $coerced_value >= 1 )
                  && ( $coerced_value <= 10 )
              )
              or croak "Type check failed in constructor: %s should be %s",
              "number", "CardNumber";
            $self->{"number"} = $coerced_value;
        };

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        # Unrecognized parameters
        my @unknown = grep not(/\A(?:deck|number|reverse|suit)\z/),
          keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        return $self;
    }

    my $__XS = !$ENV{PERL_ONLY}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for number
    # has declaration, file lib/Acme/Mitey/Cards/Card/Numeric.pm, line 20
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "number" => "number" },
        );
    }
    else {
        *number = sub {
            @_ == 1 or croak('Reader "number" usage: $self->number()');
            $_[0]{"number"};
        };
    }

    # Accessors for suit
    # has declaration, file lib/Acme/Mitey/Cards/Card/Numeric.pm, line 13
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "suit" => "suit" },
        );
    }
    else {
        *suit = sub {
            @_ == 1 or croak('Reader "suit" usage: $self->suit()');
            $_[0]{"suit"};
        };
    }

    # See UNIVERSAL
    sub DOES {
        my ( $self, $role ) = @_;
        our %DOES;
        return $DOES{$role} if exists $DOES{$role};
        return 1            if $role eq __PACKAGE__;
        if ( $INC{'Moose/Util.pm'}
            and my $meta = Moose::Util::find_meta( ref $self or $self ) )
        {
            $meta->can('does_role') and $meta->does_role($role) and return 1;
        }
        return $self->SUPER::DOES($role);
    }

    # Alias for Moose/Moo-compatibility
    sub does {
        shift->DOES(@_);
    }

    # Method signatures
    our %SIGNATURE_FOR;

    $SIGNATURE_FOR{"number_or_a"} = sub {
        my $__NEXT__ = shift;

        my ( %tmp, $tmp, @head );

        @_ == 1
          or
          croak( "Wrong number of parameters in signature for %s: got %d, %s",
            "number_or_a", scalar(@_), "expected exactly 1 parameters" );

        @head = splice( @_, 0, 1 );

        # Parameter invocant (type: Defined)
        ( defined( $head[0] ) )
          or croak(
            "Type check failed in signature for number_or_a: %s should be %s",
            "\$_[0]", "Defined" );

        do { @_ = ( @head, @_ ); goto $__NEXT__ };
    };

    $SIGNATURE_FOR{"to_string"} =
      $Acme::Mitey::Cards::Card::SIGNATURE_FOR{"to_string"};

    1;
}
