{

    package Acme::Mitey::Cards::Deck;
    use strict;
    use warnings;

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Acme::Mitey::Cards::Mite";
    our $MITE_VERSION = "0.006012";

    BEGIN {
        *bare  = \&Acme::Mitey::Cards::Mite::bare;
        *croak = \&Acme::Mitey::Cards::Mite::croak;
        *false = \&Acme::Mitey::Cards::Mite::false;
        *lazy  = \&Acme::Mitey::Cards::Mite::lazy;
        *ro    = \&Acme::Mitey::Cards::Mite::ro;
        *rw    = \&Acme::Mitey::Cards::Mite::rw;
        *rwp   = \&Acme::Mitey::Cards::Mite::rwp;
        *true  = \&Acme::Mitey::Cards::Mite::true;
    }

    BEGIN {
        require Acme::Mitey::Cards::Set;

        use mro 'c3';
        our @ISA;
        push @ISA, "Acme::Mitey::Cards::Set";
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

        # Attribute: cards
        if ( exists $args->{"cards"} ) {
            (
                do {

                    package Acme::Mitey::Cards::Mite;
                    ref( $args->{"cards"} ) eq 'ARRAY';
                  }
                  and do {
                    my $ok = 1;
                    for my $i ( @{ $args->{"cards"} } ) {
                        ( $ok = 0, last )
                          unless (
                            do {
                                use Scalar::Util ();
                                Scalar::Util::blessed($i)
                                  and $i->isa(q[Acme::Mitey::Cards::Card]);
                            }
                          );
                    };
                    $ok;
                }
              )
              or croak "Type check failed in constructor: %s should be %s",
              "cards", "CardArray";
            $self->{"cards"} = $args->{"cards"};
        }

        # Attribute: reverse
        do {
            my $value =
              exists( $args->{"reverse"} ) ? $args->{"reverse"} : "plain";
            (
                (
                    do {

                        package Acme::Mitey::Cards::Mite;
                        defined($value) and do {
                            ref( \$value ) eq 'SCALAR'
                              or ref( \( my $val = $value ) ) eq 'SCALAR';
                        }
                    }
                )
                  && ( length($value) > 0 )
              )
              or croak "Type check failed in constructor: %s should be %s",
              "reverse", "NonEmptyStr";
            $self->{"reverse"} = $value;
        };

        # Attribute: original_cards
        if ( exists $args->{"original_cards"} ) {
            (
                do {

                    package Acme::Mitey::Cards::Mite;
                    ref( $args->{"original_cards"} ) eq 'ARRAY';
                  }
                  and do {
                    my $ok = 1;
                    for my $i ( @{ $args->{"original_cards"} } ) {
                        ( $ok = 0, last )
                          unless (
                            do {
                                use Scalar::Util ();
                                Scalar::Util::blessed($i)
                                  and $i->isa(q[Acme::Mitey::Cards::Card]);
                            }
                          );
                    };
                    $ok;
                }
              )
              or croak "Type check failed in constructor: %s should be %s",
              "original_cards", "CardArray";
            $self->{"original_cards"} = $args->{"original_cards"};
        }

        # Enforce strict constructor
        my @unknown = grep not(/\A(?:cards|original_cards|reverse)\z/),
          keys %{$args};
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

    # Accessors for original_cards
    sub original_cards {
        @_ > 1
          ? croak("original_cards is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{"original_cards"} ) ? $_[0]{"original_cards"} : (
                $_[0]{"original_cards"} = do {
                    my $default_value = $_[0]->_build_original_cards;
                    do {

                        package Acme::Mitey::Cards::Mite;
                        ( ref($default_value) eq 'ARRAY' ) and do {
                            my $ok = 1;
                            for my $i ( @{$default_value} ) {
                                ( $ok = 0, last )
                                  unless (
                                    do {
                                        use Scalar::Util ();
                                        Scalar::Util::blessed($i)
                                          and
                                          $i->isa(q[Acme::Mitey::Cards::Card]);
                                    }
                                  );
                            };
                            $ok;
                        }
                      }
                      or croak( "Type check failed in default: %s should be %s",
                        "original_cards", "CardArray" );
                    $default_value;
                }
            )
          );
    }

    # Accessors for reverse
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "reverse" => "reverse" },
        );
    }
    else {
        *reverse = sub {
            @_ > 1
              ? croak("reverse is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{"reverse"};
        };
    }

    1;
}
