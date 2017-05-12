package Class::Adapter::Clear;

=pod

=head1 NAME

Class::Adapter::Clear - A handy base Adapter class that makes no changes

=head1 SYNOPSIS

B<Hello World with CGI.pm the normal way>

  # Load and create the CGI
  use CGI;
  $q = new CGI;
  
  # Create the page
  print $q->header,                    # HTTP Header
        $q->start_html('hello world'), # Start the page
        $q->h1('hello world'),         # Hello World!
        $q->end_html;                  # End the page

B<Hello World with CGI.pm the Adapter'ed way>

  # Load and create the CGI
  use CGI;
  $q = new CGI;
  
  # Convert to an Adapter
  use Class::Adapter::Clear;
  $q = new Class::Adapter::Clear( $q );
  
  # Create the page
  print $q->header,                    # HTTP Header
        $q->start_html('hello world'), # Start the page
        $q->h1('hello world'),         # Hello World!
        $q->end_html;                  # End the page

B<Creating a CGI Adapter class using Class::Adapter::Clear>

  package My::CGI;
  
  use base 'Class::Adapter::Clear';
  
  # Optional - Create the thing we are decorating auto-magically
  sub new {
      my $class = shift;
  
      # Create the object we are decorating
      my $query = CGI->new(@_);
  
      # Wrap it in the Adapter
      $class->SUPER::new($query);
  }
  
  # Decorate the h1 method to change what is created
  sub h1 {
  	my $self = shift;
  	my $str  = shift;
  
    # Do something before the real method call
    if ( defined $str and $str eq 'hello world' ) {
    	$str = 'Hello World!';
    }
    
    $self->_OBJECT_->($str, @_);
  }
  
=head1 DESCRIPTION

C<Class::Adapter::Clear> provides the base class for creating one common
type of L<Class::Adapter> classes. For more power, move up to
L<Class::Adapter::Builder>.

On it's own C<Class::Adapter::Clear> passes all methods through to the same
method in the parent object with the same parameters, responds to
C<-E<gt>isa> like the parent object, and responds to C<-E<gt>can> like
the parent object.

It looks like a C<Duck>, and it quacks like a C<Duck>.

On this base, you simple implement whatever method you want to do
something special to.

  # Different method, same parameters
  sub method1 {
      my $self = shift;
      $self->_OBJECT_->method2(@_); # Call a different method
  }
  
  # Same method, different parameters
  sub method1 {
      my $self = shift;
      $self->_OBJECT_->method1( lc($_[0]) ); # Lowercase the param
  }
  
  # Same method, same parameters, tweak the result
  sub method1 {
      my $self = shift;
      my $rv = $self->_OBJECT_->method1(@_);
      $rv =~ s/\n/<br>\n/g; # Add line-break HTML tags at each newline
      return $rv;
  }

As you can see, the advantage of this full-scale I<Adapter> approach,
compared to inheritance, or function wrapping (see L<Class::Hook>), is
that you have complete and utter freedom to do anything you might need
to do, without stressing the Perl inheritance model or doing anything
unusual or tricky with C<CODE> references.

You may never need this much power. But when you need it, you B<really>
need it.

As an aside, Class::Adapter::Clear is implemented with the following
L<Class::Adapter::Builder> formula.

  use Class::Adapter::Builder
      ISA      => '_OBJECT_',
      AUTOLOAD => 1;

=head1 METHODS

=head2 new $object

As does the base L<Class::Adapter> class, the default C<new> constructor
takes a single object as argument and creates a new object which holds the
passed object.

Returns a new C<Class::Adapter::Clear> object, or C<undef> if you do not pass
in an object.

=cut

use 5.005;
use strict;
use Class::Adapter::Builder
	ISA      => '_OBJECT_',
	AUTOLOAD => 1;

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.07';
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Class-Adapter>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<Class::Adapter>, L<Class::Adapter::Builder>

=head1 COPYRIGHT

Copyright 2005 - 2011 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
