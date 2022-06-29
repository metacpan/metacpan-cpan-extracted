{

    package Acme::Mitey::Cards::Deck;
    use strict;
    use warnings;

    BEGIN {
        require Acme::Mitey::Cards::Set;

        use mro 'c3';
        our @ISA;
        push @ISA, q[Acme::Mitey::Cards::Set];
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
        if ( exists( $args->{q[cards]} ) ) {
            (
                do {

                    package Acme::Mitey::Cards::Mite;
                    ref( $args->{q[cards]} ) eq 'ARRAY';
                  }
                  and do {
                    my $ok = 1;
                    for my $i ( @{ $args->{q[cards]} } ) {
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
              or require Carp
              && Carp::croak(
q[Type check failed in constructor: cards should be ArrayRef[InstanceOf["Acme::Mitey::Cards::Card"]]]
              );
            $self->{q[cards]} = $args->{q[cards]};
        }
        if ( exists( $args->{q[original_cards]} ) ) {
            (
                do {

                    package Acme::Mitey::Cards::Mite;
                    ref( $args->{q[original_cards]} ) eq 'ARRAY';
                  }
                  and do {
                    my $ok = 1;
                    for my $i ( @{ $args->{q[original_cards]} } ) {
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
              or require Carp
              && Carp::croak(
q[Type check failed in constructor: original_cards should be ArrayRef[InstanceOf["Acme::Mitey::Cards::Card"]]]
              );
            $self->{q[original_cards]} = $args->{q[original_cards]};
        }
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
        else {
            my $value = do {
                my $default_value = "plain";
                do {

                    package Acme::Mitey::Cards::Mite;
                    defined($default_value) and do {
                        ref( \$default_value ) eq 'SCALAR'
                          or ref( \( my $val = $default_value ) ) eq 'SCALAR';
                    }
                  }
                  or do {
                    require Carp;
                    Carp::croak(
                        q[Type check failed in default: reverse should be Str]);
                  };
                $default_value;
            };
            $self->{q[reverse]} = $value;
        }

        # Enforce strict constructor
        my @unknown = grep not(
            do {

                package Acme::Mitey::Cards::Mite;
                (         defined
                      and !ref
                      and m{\A(?:(?:cards|original_cards|reverse))\z} );
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

    # Accessors for original_cards
    *original_cards = sub {
        @_ > 1 ? require Carp
          && Carp::croak(
            "original_cards is a read-only attribute of @{[ref $_[0]]}") : (
            exists( $_[0]{q[original_cards]} ) ? $_[0]{q[original_cards]} : (
                $_[0]{q[original_cards]} = do {
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
                      or do {
                        require Carp;
                        Carp::croak(
q[Type check failed in default: original_cards should be ArrayRef[InstanceOf["Acme::Mitey::Cards::Card"]]]
                        );
                      };
                    $default_value;
                }
            )
            );
    };

    # Accessors for reverse
    if ($__XS) {
        Class::XSAccessor->import(
            chained => 1,
            getters => { q[reverse] => q[reverse] },
        );
    }
    else {
        *reverse = sub {
            @_ > 1
              ? require Carp && Carp::croak(
                "reverse is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]{q[reverse]};
        };
    }

    1;
}
