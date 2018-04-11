package Class::Adapter::Clear;
# ABSTRACT: A handy base Adapter class that makes no changes

#pod =pod
#pod
#pod =head1 SYNOPSIS
#pod
#pod B<Hello World with CGI.pm the normal way>
#pod
#pod   # Load and create the CGI
#pod   use CGI;
#pod   $q = new CGI;
#pod   
#pod   # Create the page
#pod   print $q->header,                    # HTTP Header
#pod         $q->start_html('hello world'), # Start the page
#pod         $q->h1('hello world'),         # Hello World!
#pod         $q->end_html;                  # End the page
#pod
#pod B<Hello World with CGI.pm the Adapter'ed way>
#pod
#pod   # Load and create the CGI
#pod   use CGI;
#pod   $q = new CGI;
#pod   
#pod   # Convert to an Adapter
#pod   use Class::Adapter::Clear;
#pod   $q = new Class::Adapter::Clear( $q );
#pod   
#pod   # Create the page
#pod   print $q->header,                    # HTTP Header
#pod         $q->start_html('hello world'), # Start the page
#pod         $q->h1('hello world'),         # Hello World!
#pod         $q->end_html;                  # End the page
#pod
#pod B<Creating a CGI Adapter class using Class::Adapter::Clear>
#pod
#pod   package My::CGI;
#pod   
#pod   use base 'Class::Adapter::Clear';
#pod   
#pod   # Optional - Create the thing we are decorating auto-magically
#pod   sub new {
#pod       my $class = shift;
#pod   
#pod       # Create the object we are decorating
#pod       my $query = CGI->new(@_);
#pod   
#pod       # Wrap it in the Adapter
#pod       $class->SUPER::new($query);
#pod   }
#pod   
#pod   # Decorate the h1 method to change what is created
#pod   sub h1 {
#pod   	my $self = shift;
#pod   	my $str  = shift;
#pod   
#pod     # Do something before the real method call
#pod     if ( defined $str and $str eq 'hello world' ) {
#pod     	$str = 'Hello World!';
#pod     }
#pod     
#pod     $self->_OBJECT_->($str, @_);
#pod   }
#pod   
#pod =head1 DESCRIPTION
#pod
#pod C<Class::Adapter::Clear> provides the base class for creating one common
#pod type of L<Class::Adapter> classes. For more power, move up to
#pod L<Class::Adapter::Builder>.
#pod
#pod On it's own C<Class::Adapter::Clear> passes all methods through to the same
#pod method in the parent object with the same parameters, responds to
#pod C<-E<gt>isa> like the parent object, and responds to C<-E<gt>can> like
#pod the parent object.
#pod
#pod It looks like a C<Duck>, and it quacks like a C<Duck>.
#pod
#pod On this base, you simple implement whatever method you want to do
#pod something special to.
#pod
#pod   # Different method, same parameters
#pod   sub method1 {
#pod       my $self = shift;
#pod       $self->_OBJECT_->method2(@_); # Call a different method
#pod   }
#pod   
#pod   # Same method, different parameters
#pod   sub method1 {
#pod       my $self = shift;
#pod       $self->_OBJECT_->method1( lc($_[0]) ); # Lowercase the param
#pod   }
#pod   
#pod   # Same method, same parameters, tweak the result
#pod   sub method1 {
#pod       my $self = shift;
#pod       my $rv = $self->_OBJECT_->method1(@_);
#pod       $rv =~ s/\n/<br>\n/g; # Add line-break HTML tags at each newline
#pod       return $rv;
#pod   }
#pod
#pod As you can see, the advantage of this full-scale I<Adapter> approach,
#pod compared to inheritance, or function wrapping (see L<Class::Hook>), is
#pod that you have complete and utter freedom to do anything you might need
#pod to do, without stressing the Perl inheritance model or doing anything
#pod unusual or tricky with C<CODE> references.
#pod
#pod You may never need this much power. But when you need it, you B<really>
#pod need it.
#pod
#pod As an aside, Class::Adapter::Clear is implemented with the following
#pod L<Class::Adapter::Builder> formula.
#pod
#pod   use Class::Adapter::Builder
#pod       ISA      => '_OBJECT_',
#pod       AUTOLOAD => 1;
#pod
#pod =head1 METHODS
#pod
#pod =head2 new $object
#pod
#pod As does the base L<Class::Adapter> class, the default C<new> constructor
#pod takes a single object as argument and creates a new object which holds the
#pod passed object.
#pod
#pod Returns a new C<Class::Adapter::Clear> object, or C<undef> if you do not pass
#pod in an object.
#pod
#pod =cut

use 5.005;
use strict;
use Class::Adapter::Builder
	ISA      => '_OBJECT_',
	AUTOLOAD => 1;

our $VERSION = '1.09';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Class::Adapter::Clear - A handy base Adapter class that makes no changes

=head1 VERSION

version 1.09

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

=head1 SEE ALSO

L<Class::Adapter>, L<Class::Adapter::Builder>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Class-Adapter>
(or L<bug-Class-Adapter@rt.cpan.org|mailto:bug-Class-Adapter@rt.cpan.org>).

=head1 AUTHOR

Adam Kennedy <adamk@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Adam Kennedy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
