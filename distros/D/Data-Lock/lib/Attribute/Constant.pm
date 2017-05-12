package Attribute::Constant;
use 5.008001;
use warnings;
use strict;
our $VERSION = sprintf "%d.%02d", q$Revision: 1.1 $ =~ /(\d+)/g;
use Attribute::Handlers;
use Data::Lock ();

sub UNIVERSAL::Constant : ATTR {
    my ( $pkg, $sym, $ref, $attr, $data, $phase ) = @_;
    (
          ref $ref eq 'HASH'  ? %$ref
        : ref $ref eq 'ARRAY' ? @$ref
        :                       ($$ref)
      )
      = ref $data
      ? ref $data eq 'ARRAY'
          ? @$data    # perl 5.10.x
          : $data
      : $data;        # perl 5.8.x
    Data::Lock::dlock($ref);
}

1;
__END__

=head1 NAME

Attribute::Constant - Make read-only variables via attribute

=head1 VERSION

$Id: Constant.pm,v 1.1 2013/04/03 14:37:57 dankogai Exp $

=head1 SYNOPSIS

 use Attribute::Constant;
 my $sv : Constant( $initial_value );
 my @av : Constant( @values );
 my %hv : Constant( key => value, key => value, ...);

=head1 DESCRIPTION

This module uses L<Data::Lock> to make the variable read-only.  Check
the document and source of L<Data::Lock> for its mechanism.

=head1 ATTRIBUTES

This module adds only one attribute, C<Constant>.  You give its
initial value as shown.  Unlike L<Readonly>, parantheses cannot be
ommited but it is semantically more elegant and thanks to
L<Data::Lock>, it imposes almost no performance penalty.

=head1 CAVEAT

=head2 Multi-line attributes

Multi-line attributes are not allowed in Perl 5.8.x.

  my $o : Constant(Foo->new(one=>1,two=>2,three=>3));    # ok
  my $p : Constant(Bar->new(
                            one   =>1,
                            two   =>2,
                            three =>3
                           )
                 ); # needs Perl 5.10

In which case you can use L<Data::Lock> instead:

  dlock(my $p = Bar->new(
        one   => 1,
        two   => 2,
        three => 3
    )
  );

After all, this module is a wrapper to L<Data::Lock>;

=head2 Constants from Variables

You may be surprised the following code B<DOES NOT> work as you expected:

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Attribute::Constant;
  use Data::Dumper;
  {
    package MyClass;
    sub new {
        my ( $class, %params ) = @_;
        return bless \%params, $class;
    }
  }
  my $o = MyClass->new( a => 1, b => 2 );
  my $x : Constant($o);
  print Dumper( $o, $x );

Which outputs:

  $VAR1 = bless( {
                 'a' => 1,
                 'b' => 2
               }, 'MyClass' );
  $VAR2 = undef;

Why?  Because C< $x : Constant($o) > happens B<before>
C<< $o = Myclass->new() >>.

On the other hand, the following works.

  my $y : Constant(MyClass->new(a => 1,b => 2));
  print Dumper( $o, $y );

Rule of the thumb is do not feed variables to constant because
varialbes change after the attribute invocation.

Or simply use C<Data::Lock::dlock>.

  use Data::Lock qw/dlock/;
  dlock my $z = $o;
  print Dumper( $o, $y );

=head1 SEE ALSO

L<Data::Lock>, L<constant>

=head1 AUTHOR

Dan Kogai, C<< <dankogai+cpan at gmail.com> >>

=head1 BUGS & SUPPORT

See L<Data::Lock>.

=head1 ACKNOWLEDGEMENTS

L<Readonly>

=head1 COPYRIGHT & LICENSE

Copyright 2008-2013 Dan Kogai, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.
