
# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself
package Data::Type::BaseException;

        Class::Maker::class
        {
	    isa => [qw( Class::Maker::Exception )],
	    
	    public =>
	    {
		bool => [qw( expected returned )],
		
		ref => [qw( type )],
	    },
	};

sub to_text : method
{
	my $this = shift;

	return sprintf "%s: Expected %s, Returned %s, Type %s\n", ref($this), $this->expected, $this->returned, $this->type; 
}

sub to_dump : method
{
	my $this = shift;

	eval "use Data::Dump"; 

	die $@ if $@;

	return Data::Dump::dump( $this );
}

package Data::Type::Exception;

        Class::Maker::class
        {
	    isa => [qw( Data::Type::BaseException )],
	    
	    public =>
	    {
		ref => [qw( value )],
		
		array => [qw( catched )],
	    },
	};
1;

__END__

=head1 NAME

Data::Type::Exception - base classes for exceptions

=head1 SYNOPSIS

  try
  {
    valid( 'muenalan<haaar..harr>cpan.org', STD::EMAIL );
  }
  catch Data::Type::Exception with
  {
    dump( $e ) foreach @_;
  };

=head1 DESCRIPTION

Exceptions are inherited from L<Class::Maker::Exception> which is a wrapper for the L<Error> module. C<Data::Type::Exception> is the base class inheriting from L<Class::Maker::Exception>.

=head1 Data::Type::Exception

=head2 ATTRIBUTES

=head3 $dte->file

The filename where the exception was thrown.

=head3 $dte->line

The line number.

=head3 $dte->type

The type 'object' used for verification.

=head3 $dte->value

Reference to the data subjected to verification.

=head3 $dte->catched

List of embedded sub-exceptions or other diagnostic details.

=head2 METHODS

=head3 $dte->to_text

A simple textual representation of the exception. Generally a very primitiv printf.

=head3 $dte->to_dump

Dumps the complete exception via C<dump()> from L<Data::Dump>.

=head1 Data::Type::Facet::Exception

Only interesting if you are creating custom types. This exception is thrown in the verification process if a facet (which is a subelement of the verification process) fails.

=head1 SEE ALSO

L<Class::Maker::Exception>.
 

=head1 CONTACT

Sourceforge L<http://sf.net/projects/datatype> is hosting a project dedicated to this module. And I enjoy receiving your comments/suggestion/reports also via L<http://rt.cpan.org> or L<http://testers.cpan.org>. 

=head1 AUTHOR

Murat Uenalan, <muenalan@cpan.org>

