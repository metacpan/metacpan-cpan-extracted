package Acme::Dot;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.10';

my ( $call_pack, $call_pack2 );

sub import {
    $call_pack  = ( caller(0) )[0];
    $call_pack2 = ( caller(1) )[0];
    my $code = "package $call_pack;\n" . <<'    END_OF_CODE';
    use overload "." => sub { 
            my ( $obj, $stuff ) = @_;
            @_ = ( $obj, @{ $stuff->{data} } );
            goto &{ $obj->can( $stuff->{name} ) };
        },
        fallback => 1;
    END_OF_CODE
    eval $code;
}

CHECK {

    # At this point, everything is ready, and $call_pack2 contains
    # the calling package's calling package.
    no strict;
    if ($call_pack2) {
        my $code = "package $call_pack2;\n" . <<'        END_OF_CODE';
        *AUTOLOAD = sub { 
            $AUTOLOAD =~ /.*::(.*)/;
            return if $1 eq "DESTROY";
            return { data => \@_, name => $1 };
        }
        END_OF_CODE
        eval $code;
    }
}

1;
__END__

=head1 NAME

Acme::Dot - Call methods with the dot operator

=head1 SYNOPSIS

  package Foo;
  use Acme::Dot;
  sub new { bless {}, shift }
  sub hello { print "Hi there! (@_)\n" }

  package main;
  my $x = new Foo;
  $x.hello(1,2,3); # Calls the method

  $y = "Hello";
  sub world { return " World!"}
  print $y.world(); # Behaves as normal

=head1 DESCRIPTION

This module, when imported into a class, allows objects of that class to have
methods called using the dot operator as in Ruby, Python and other OO
languages.

However, since it doesn't use source filters or any other high magic, it only
affects the class it was imported into; objects of other classes and ordinary
scalars can use concatenation as normal.

=head1 BUGS

May cause warnings about useless use of concatenation.  If anyone is really
worried about this, it may get fixed.

Occasionally has problems distinguishing between methods and subroutines. But
then, don't we all? This may be fixed in the next release.

=head1 LICENSE

Copyright (c) 2004 by Curtis "Ovid" Poe.  All rights reserved.  This program is
free software; you may redistribute it and/or modify it under the same terms as
Perl itself.

=head1 MAINTAINER

Curtis "Ovid" Poe, E<lt>1napc-pmetsuilbup@yahoo.comE<gt>

Reverse the name to email me.

=head1 ORIGINAL AUTHOR

Simon Cozens, C<simon@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
