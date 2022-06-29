{

    package Acme::Mitey::Cards::Set;
    use strict;
    use warnings;

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

        # Enforce strict constructor
        my @unknown = grep not(
            do {

                package Acme::Mitey::Cards::Mite;
                ( defined and !ref and m{\A(?:cards)\z} );
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

    1;
}
