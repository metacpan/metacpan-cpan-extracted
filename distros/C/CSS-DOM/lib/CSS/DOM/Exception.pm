package CSS::DOM::Exception;

use CSS::DOM::Constants;
use Exporter 5.57 'import';

our $VERSION = '0.16';

*EXPORT_OK = $CSS::DOM::Constants::EXPORT_TAGS{exception};
our %EXPORT_TAGS = (all => [@EXPORT_OK]);


use overload
	fallback => 1,
	'0+' => sub { $_[0][0] },
	'""' => sub { $_[0][1] =~ /^(.*?)\n?\z/s; "$1\n" },
;

sub new {
	bless [@_[1,2]], $_[0];
}

'true'
__END__

=head1 NAME

CSS::DOM::Exception - The Exception interface for CSS::DOM

=head1 SYNOPSIS

  use CSS::DOM::Exception 'SYNTAX_ERR';

  eval {
          die new CSS::DOM::Exception
                  SYNTAX_ERR,
                  '1 is not a valid property declaration'
  };

  $@ == SYNTAX_ERR; # true

  print $@;    # prints "1 is not a valid property declaration\n";

=head1 DESCRIPTION

This module implementations the W3C's DOMException 
interface.
CSS::DOM::Exception objects
stringify to the message passed to the constructer and numify to the 
error
number (see below, under L<'EXPORTS'>).

=head1 METHODS

=over 4

=item new CSS::DOM::Exception $type, $message

This class method creates a new exception object. C<$type> is expected to
be an integer (you can use the constants listed under L<'EXPORTS'>).
C<$message> is the error message.

=cut

sub new {
	bless [@_[1,2]], shift;
}


=back

=head1 EXPORTS

The following constants are optionally exported. The descriptions are 
copied from the DOM spec.

=over 4

=item INDEX_SIZE_ERR (1)

If index or size is negative, or greater than the allowed value

=item DOMSTRING_SIZE_ERR (2)

If the specified range of text does not fit into a DOMString

=item HIERARCHY_REQUEST_ERR (3)

If any node is inserted somewhere it doesn't belong

=item WRONG_DOCUMENT_ERR (4)

If a node is used in a different document than the one that created it (that doesn't support it)

=item INVALID_CHARACTER_ERR (5)

If an invalid character is specified, such as in a name.

=item NO_DATA_ALLOWED_ERR (6)

If data is specified for a node which does not support data

=item NO_MODIFICATION_ALLOWED_ERR (7)

If an attempt is made to modify an object where modifications are not allowed

=item NOT_FOUND_ERR (8)

If an attempt was made to reference a node in a context where it does not exist

=item NOT_SUPPORTED_ERR (9)

If the implementation does not support the type of object requested

=item INUSE_ATTRIBUTE_ERR (10)

If an attempt is made to add an attribute that is already inuse elsewhere

=item INVALID_STATE_ERR (11)

If an attempt is made to use an object that is not, or is no longer, 
usable

=item SYNTAX_ERR (12)

If an invalid or illegal string is specified

=item INVALID_MODIFICATION_ERR (13)

If an attempt is made to modify the type of the underlying object

=item NAMESPACE_ERR (14)

If an attempt is made to create or change an object in a way which is 
incorrect with 
regard to namespaces

=item INVALID_ACCESS_ERR (15)

If a parameter or an operation is not supported by the underlying object

=begin comment

=item UNSPECIFIED_EVENT_TYPE_ERR (0)

If the Event's type was not specified by initializing the event before the
method was called. Specification of the Event's type as null or an empty
string will also trigger this exception.

=end comment

=back

=head1 SEE ALSO

L<CSS::DOM>, L<HTML::DOM::Exception>
