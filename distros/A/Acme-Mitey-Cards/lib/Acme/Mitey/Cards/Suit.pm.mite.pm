{

    package Acme::Mitey::Cards::Suit;
    use strict;
    use warnings;

    sub new {
        my $class = shift;
        my $args  = { ( @_ == 1 ) ? %{ $_[0] } : @_ };

        my $self = bless {}, $class;

        if ( exists( $args->{q[abbreviation]} ) ) {
            do {

                package Acme::Mitey::Cards::Mite;
                defined( $args->{q[abbreviation]} ) and do {
                    ref( \$args->{q[abbreviation]} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{q[abbreviation]} ) ) eq
                      'SCALAR';
                }
              }
              or require Carp
              && Carp::croak(
                q[Type check failed in constructor: abbreviation should be Str]
              );
            $self->{q[abbreviation]} = $args->{q[abbreviation]};
            delete $args->{q[abbreviation]};
        }
        if ( exists( $args->{q[colour]} ) ) {
            do {

                package Acme::Mitey::Cards::Mite;
                defined( $args->{q[colour]} ) and do {
                    ref( \$args->{q[colour]} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{q[colour]} ) ) eq 'SCALAR';
                }
              }
              or require Carp
              && Carp::croak(
                q[Type check failed in constructor: colour should be Str]);
            $self->{q[colour]} = $args->{q[colour]};
            delete $args->{q[colour]};
        }
        else { require Carp; Carp::croak("Missing key in constructor: colour") }
        if ( exists( $args->{q[name]} ) ) {
            do {

                package Acme::Mitey::Cards::Mite;
                defined( $args->{q[name]} ) and do {
                    ref( \$args->{q[name]} ) eq 'SCALAR'
                      or ref( \( my $val = $args->{q[name]} ) ) eq 'SCALAR';
                }
              }
              or require Carp
              && Carp::croak(
                q[Type check failed in constructor: name should be Str]);
            $self->{q[name]} = $args->{q[name]};
            delete $args->{q[name]};
        }
        else { require Carp; Carp::croak("Missing key in constructor: name") }

        keys %$args
          and require Carp
          and Carp::croak( "Unexpected keys in constructor: "
              . join( q[, ], sort keys %$args ) );

        return $self;
    }

    my $__XS = !$ENV{MITE_PURE_PERL}
      && eval { require Class::XSAccessor; Class::XSAccessor->VERSION("1.19") };

    # Accessors for abbreviation
    *abbreviation = sub {
        @_ > 1 ? require Carp
          && Carp::croak(
            "abbreviation is a read-only attribute of @{[ref $_[0]]}") : (
            exists( $_[0]{q[abbreviation]} ) ? $_[0]{q[abbreviation]} : (
                $_[0]{q[abbreviation]} = do {
                    my $default_value = $_[0]->_build_abbreviation;
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
q[Type check failed in default: abbreviation should be Str]
                        );
                      };
                    $default_value;
                }
            )
            );
    };

    # Accessors for colour
    if ($__XS) {
        Class::XSAccessor->import(
            chained => 1,
            getters => { q[colour] => q[colour] },
        );
    }
    else {
        *colour = sub {
            @_ > 1
              ? require Carp && Carp::croak(
                "colour is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]->{q[colour]};
        };
    }

    # Accessors for name
    if ($__XS) {
        Class::XSAccessor->import(
            chained => 1,
            getters => { q[name] => q[name] },
        );
    }
    else {
        *name = sub {
            @_ > 1
              ? require Carp
              && Carp::croak("name is a read-only attribute of @{[ref $_[0]]}")
              : $_[0]->{q[name]};
        };
    }

    1;
}
