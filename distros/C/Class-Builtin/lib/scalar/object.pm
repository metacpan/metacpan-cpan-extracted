package scalar::object;
# use 5.010; -- works ok on 5.8
use strict;
use warnings;
use overload ();
use Class::Builtin::Scalar;

my $class = __PACKAGE__;

sub import {
    $^H{$class} = 1;
    overload::constant(
        map {
            $_ => sub { Class::Builtin::Scalar->new(shift) }
          } qw/integer float binary q/
    );
}

sub unimport {
    $^H{$class} = 0;
    overload::remove_constant( '', qw/integer float binary q qr/ );
}

sub in_effect {
    my $level = shift || 0;
    my $hinthash = ( caller($level) )[10];
    return $hinthash->{$class};
}

1;

=head1 NAME

scalar::object - automagically turns scalar constants into objects

=head1 VERSION

$Id: object.pm,v 0.2 2009/06/21 15:44:41 dankogai Exp $

=head1 SYNOPSIS

  {
     use scalar::objects;
     my $o = 42;      # $o is a Class::Builtin::Scalar object
     print 42->length # 2;
  }
  my $n = 1;       # $n is an ordinary scalar
  print $n->length # dies

=head1 EXPORT

None.  But see L<Class::Builtin>

=head1 TODO

This section itself is to do :)

=head1 SEE ALSO

L<Class::Builtin>, L<Class::Builtin::Scalar>

=head1 AUTHOR

Dan Kogai, C<< <dankogai at dan.co.jp> >>

=head1 ACKNOWLEDGEMENTS

L<autobox>, L<overload>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
