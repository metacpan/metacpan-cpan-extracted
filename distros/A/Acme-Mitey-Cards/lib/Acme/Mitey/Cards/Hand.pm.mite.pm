{

    package Acme::Mitey::Cards::Hand;
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
        my $args  = { ( @_ == 1 ) ? %{ $_[0] } : @_ };

        my $self = bless {}, $class;

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
            delete $args->{q[cards]};
        }
        if ( exists( $args->{q[owner]} ) ) {
            do {

                package Acme::Mitey::Cards::Mite;
                (
                    do {

                        package Acme::Mitey::Cards::Mite;
                        defined( $args->{q[owner]} ) and do {
                            ref( \$args->{q[owner]} ) eq 'SCALAR'
                              or ref( \( my $val = $args->{q[owner]} ) ) eq
                              'SCALAR';
                        }
                      }
                      or (
                        do {

                            package Acme::Mitey::Cards::Mite;
                            use Scalar::Util ();
                            Scalar::Util::blessed( $args->{q[owner]} );
                        }
                      )
                );
              }
              or require Carp
              && Carp::croak(
                q[Type check failed in constructor: owner should be Str|Object]
              );
            $self->{q[owner]} = $args->{q[owner]};
            delete $args->{q[owner]};
        }

        keys %$args
          and require Carp
          and Carp::croak( "Unexpected keys in constructor: "
              . join( q[, ], sort keys %$args ) );

        return $self;
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for cards
    *cards = sub {
        @_ > 1
          ? require Carp
          && Carp::croak("cards is a read-only attribute of @{[ref $_[0]]}")
          : (
            exists( $_[0]{q[cards]} ) ? $_[0]{q[cards]} : (
                $_[0]{q[cards]} = do {
                    my $default_value = $_[0]->_build_cards;
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
q[Type check failed in default: cards should be ArrayRef[InstanceOf["Acme::Mitey::Cards::Card"]]]
                        );
                      };
                    $default_value;
                }
            )
          );
    };

    # Accessors for owner
    *owner = sub {
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
              or require Carp
              && Carp::croak(
                q[Type check failed in accessor: value should be Str|Object]);
            $_[0]{q[owner]} = $_[1];
            $_[0];
          }
          : ( $_[0]->{q[owner]} );
    };

    1;
}
