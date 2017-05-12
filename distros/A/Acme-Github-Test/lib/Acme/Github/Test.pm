use 5.014; 
use warnings;

=head1 NAME

Acme::Github::Test - A test distribution for Github

=head1 SYNOPSIS

  use 5.014;
  use Acme::Github::Test;

  my $acme = Acme::Github::Test->new( 23 => 'skidoo' );
  $acme->freep;
  $acme->frobulate('barbaz');

=head1 ATTRIBUTES

The L<Acme::Github::Test> object will accept a list of initializers, but they don't do anything.

=head1 METHODS

=over 4

=item * new()

This method initializes the object.  It can take a list of hash keys and values and store them. Returns
the initialized L<Acme::Github::Test> object.

=item * freep()

This method prints the string scalar "Freep!" on standard out.  It takes no input values. Returns a true
value.

=item * frobulate()

Takes an optional scalar value as input. The value '42' is the default value for this method. Returns the
passed value or the default. (That means if you pass 0 or some other untrue scalar value, the return value 
will be false.)

=back

=head1 AUTHOR

Mark Allen C<< <mallen@cpan.org> >>

=head1 SEE ALSO

=over 4

=item * https://github.com/mrallen1/Acme-Github-Test

=item * https://speakerdeck.com/mrallen1/intro-to-git-for-the-perl-hacker

=back

=head1 LICENSE

Copyright (c) 2012 by Mark Allen

This library is free software; you can redistribute it and/or modify it
under the terms of the Perl Artistic License (version 1) or the GNU 
Public License (version 2)

=cut

package Acme::Github::Test 0.03 {

  our $VERSION = '0.03';

  sub new {
      my $class = shift;
      my @options = @_;
      my $self = { @options };
      return bless $self, $class
  }

  sub freep {
      my $self = shift;

      say "Freep!";
  }

  sub frobulate {
      my $self = shift;
      my $quux = shift // 42;

      say "$quux has been frobulated!";
      return $quux;
  }
}

1;
