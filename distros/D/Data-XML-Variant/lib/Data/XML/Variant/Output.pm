package Data::XML::Variant::Output;

use strict;
use overload
  '""'     => sub { shift->output },
  fallback => 1;


=head1 NAME

Data::XML::Variant::Output - Output class for Data::XML::Variant

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Do not use this class directly.  This class is merely a convenient way of
"tagging" data as already having been processed (for example, escapes already
applied).

=head1 EXPORT

None.

=head1 METHODS

=head2 new

 my $output = Data::XML::Variant::Output->new($string);

Passed a string, the constructor will return an object with overloaded
stringification.  When printed, it will print the string it contains.

=cut

sub new {
    my ( $class, $string ) = @_;
    bless \$string, $class;
}

##############################################################################

=head2 output

  print $output->output;

Returns the C<$string> passed to C<new>.

=cut

sub output { ${$_[0]} }

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-data-xml-variant@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-XML-Variant>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2005 Curtis "Ovid" Poe, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
