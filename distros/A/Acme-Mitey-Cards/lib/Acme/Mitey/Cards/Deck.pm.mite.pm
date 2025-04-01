{

    package Acme::Mitey::Cards::Deck;
    use strict;
    use warnings;
    no warnings qw( once void );

    our $USES_MITE    = "Mite::Class";
    our $MITE_SHIM    = "Acme::Mitey::Cards::Mite";
    our $MITE_VERSION = "0.013000";

    # Mite keywords
    BEGIN {
        my ( $SHIM, $CALLER ) =
          ( "Acme::Mitey::Cards::Mite", "Acme::Mitey::Cards::Deck" );
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
        require Acme::Mitey::Cards::Set;

        use mro 'c3';
        our @ISA;
        push @ISA, "Acme::Mitey::Cards::Set";
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

        # Attribute cards (type: CardArray)
        # has declaration, file lib/Acme/Mitey/Cards/Set.pm, line 11
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

        # Attribute reverse (type: NonEmptyStr)
        # has declaration, file lib/Acme/Mitey/Cards/Deck.pm, line 17
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

        # Attribute original_cards (type: CardArray)
        # has declaration, file lib/Acme/Mitey/Cards/Deck.pm, line 23
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

        # Call BUILD methods
        $self->BUILDALL($args) if ( !$no_build and @{ $meta->{BUILD} || [] } );

        # Unrecognized parameters
        my @unknown = grep not(/\A(?:cards|original_cards|reverse)\z/),
          keys %{$args};
        @unknown
          and croak(
            "Unexpected keys in constructor: " . join( q[, ], sort @unknown ) );

        return $self;
    }

    my $__XS = !$ENV{PERL_ONLY}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for original_cards
    # has declaration, file lib/Acme/Mitey/Cards/Deck.pm, line 23
    sub original_cards {
        @_ == 1
          or croak('Reader "original_cards" usage: $self->original_cards()');
        (
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
    # has declaration, file lib/Acme/Mitey/Cards/Deck.pm, line 17
    if ($__XS) {
        Class::XSAccessor->import(
            chained   => 1,
            "getters" => { "reverse" => "reverse" },
        );
    }
    else {
        *reverse = sub {
            @_ == 1 or croak('Reader "reverse" usage: $self->reverse()');
            $_[0]{"reverse"};
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

    $SIGNATURE_FOR{"deal_hand"} = sub {
        my $__NEXT__ = shift;

        my ( %out, %in, %tmp, $tmp, $dtmp, @head );

        @_ == 2 && ( ref( $_[1] ) eq 'HASH' )
          or @_ % 2 == 1 && @_ >= 1
          or
          croak( "Wrong number of parameters in signature for %s: got %d, %s",
            "deal_hand", scalar(@_), "that does not seem right" );

        @head = splice( @_, 0, 1 );

        # Parameter invocant (type: Defined)
        ( defined( $head[0] ) )
          or croak(
            "Type check failed in signature for deal_hand: %s should be %s",
            "\$_[0]", "Defined" );

        %in = ( @_ == 1 and ( ref( $_[0] ) eq 'HASH' ) ) ? %{ $_[0] } : @_;

        # Parameter count (type: Int)
        $dtmp = exists( $in{"count"} ) ? $in{"count"} : "7";
        (
            do {
                my $tmp = $dtmp;
                defined($tmp) and !ref($tmp) and $tmp =~ /\A-?[0-9]+\z/;
            }
          )
          or croak(
            "Type check failed in signature for deal_hand: %s should be %s",
            "\$_{\"count\"}", "Int" );
        $out{"count"} = $dtmp;
        delete( $in{"count"} );

        my $SLURPY = \%in;

        # Parameter args_for_hand (type: Slurpy[HashRef])
        ( ( ref($SLURPY) eq 'HASH' ) )
          or croak(
            "Type check failed in signature for deal_hand: %s should be %s",
            "\$SLURPY", "HashRef" );
        $out{"args_for_hand"} = $SLURPY;

        do {
            @_ = (
                @head,
                bless(
                    \%out,
                    "Acme::Mitey::Cards::Deck::__NAMED_ARGUMENTS__::deal_hand"
                )
            );
            goto $__NEXT__;
        };
    };

    {

        package Acme::Mitey::Cards::Deck::__NAMED_ARGUMENTS__::deal_hand;
        use strict;
        no warnings;
        sub args_for_hand { $_[0]{"args_for_hand"} }
        sub count         { $_[0]{"count"} }
        sub has_count     { exists $_[0]{"count"} }
        1;
    }

    $SIGNATURE_FOR{"discard_jokers"} = sub {
        my $__NEXT__ = shift;

        my ( %tmp, $tmp, @head );

        @_ == 1
          or
          croak( "Wrong number of parameters in signature for %s: got %d, %s",
            "discard_jokers", scalar(@_), "expected exactly 1 parameters" );

        @head = splice( @_, 0, 1 );

        # Parameter invocant (type: Defined)
        ( defined( $head[0] ) )
          or croak(
"Type check failed in signature for discard_jokers: %s should be %s",
            "\$_[0]", "Defined"
          );

        do { @_ = ( @head, @_ ); goto $__NEXT__ };
    };

    1;
}
