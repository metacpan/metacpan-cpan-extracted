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
        }

        # Enforce strict constructor
        my @unknown = grep not(
            do {

                package Acme::Mitey::Cards::Mite;
                ( defined and !ref and m{\A(?:(?:cards|owner))\z} );
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
          : ( $_[0]{q[owner]} );
    };

    1;
}
