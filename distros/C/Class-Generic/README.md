SYNOPSIS
========

        use parent qw( Class::Generic )

        sub init
        {
            my $self = shift( @_ );
            return( $self->SUPER::init( @_ ) );
        }

        my $array = Class::Array->new( $something );
        my $array = Class::Array->new( [$something] );
        my $hash  = Class::Assoc->new;
        my $bool  = Class::Boolean->new;
        my $ex    = Class::Exception->new( message => "Oh no", code => 500 );
        my $file  = Class::File->new( '/some/where/file.txt' );
        my $finfo = Class::Finfo->new( '/some/where/file.txt' );
        my $null  = Class::NullChain->new;
        my $num   = Class::Number->new( 10 );
        my $str   = Class::Scalar->new( 'Some string' );

        # For details on the api provided, please check each of the module documentation.

VERSION
=======

        v0.1.0

DESCRIPTION
===========

This package inherits all its features from
[Module::Generic](https://metacpan.org/pod/Module::Generic){.perl-module}
and provides a generic framework of methods to inherit from and speed up
development.

METHODS
=======

See
[Module::Generic](https://metacpan.org/pod/Module::Generic){.perl-module}

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x556662ebc9d8)"}\>

SEE ALSO
========

[Class::Generic](https://metacpan.org/pod/Class::Generic){.perl-module},
[Class::Array](https://metacpan.org/pod/Class::Array){.perl-module},
[Class::Scalar](https://metacpan.org/pod/Class::Scalar){.perl-module},
[Class::Number](https://metacpan.org/pod/Class::Number){.perl-module},
[Class::Boolean](https://metacpan.org/pod/Class::Boolean){.perl-module},
[Class::Assoc](https://metacpan.org/pod/Class::Assoc){.perl-module},
[Class::File](https://metacpan.org/pod/Class::File){.perl-module},
[Class::DateTime](https://metacpan.org/pod/Class::DateTime){.perl-module},
[Class::Exception](https://metacpan.org/pod/Class::Exception){.perl-module},
[Class::Finfo](https://metacpan.org/pod/Class::Finfo){.perl-module},
[Class::NullChain](https://metacpan.org/pod/Class::NullChain){.perl-module}

COPYRIGHT & LICENSE
===================

Copyright(c) 2022 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
