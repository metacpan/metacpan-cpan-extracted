{

    package Acme::Mitey::Cards::Hand;
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

        # Attribute: owner
        if ( exists $args->{"owner"} ) {
            do {

                package Acme::Mitey::Cards::Mite;
                (
                    do {

                        package Acme::Mitey::Cards::Mite;
                        defined( $args->{"owner"} ) and do {
                            ref( \$args->{"owner"} ) eq 'SCALAR'
                              or ref( \( my $val = $args->{"owner"} ) ) eq
                              'SCALAR';
                        }
                      }
                      or (
                        do {

                            package Acme::Mitey::Cards::Mite;
                            use Scalar::Util ();
                            Scalar::Util::blessed( $args->{"owner"} );
                        }
                      )
                );
              }
              or croak "Type check failed in constructor: %s should be %s",
              "owner", "Str|Object";
            $self->{"owner"} = $args->{"owner"};
        }

        # Enforce strict constructor
        my @unknown = grep not(/\A(?:cards|owner)\z/), keys %{$args};
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

    # Accessors for owner
    sub owner {
        @_ > 1
          ? do {
            do {

                package Acme::Mitey::Cards::Mite;
                (
                    do {

                        package Acme::Mitey::Cards::Mite;
                        defined( $_[1] ) and do {
                            ref( \$_[1] ) eq 'SCALAR'
                              or ref( \( my $val = $_[1] ) ) eq 'SCALAR';
                        }
                      }
                      or (
                        do {

                            package Acme::Mitey::Cards::Mite;
                            use Scalar::Util ();
                            Scalar::Util::blessed( $_[1] );
                        }
                      )
                );
              }
              or croak( "Type check failed in %s: value should be %s",
                "accessor", "Str|Object" );
            $_[0]{"owner"} = $_[1];
            $_[0];
          }
          : ( $_[0]{"owner"} );
    }

    1;
}
