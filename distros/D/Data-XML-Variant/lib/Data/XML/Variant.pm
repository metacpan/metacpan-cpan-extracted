package Data::XML::Variant;

use warnings;
use strict;

use aliased 'Data::XML::Variant::Build';

=head1 NAME

Data::XML::Variant - Output XML 'variants'

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

 use Data::XML::Variant;

 my $xml = Data::XML::Variant->new(
     {
         'doc'         => 'doc',
         'ns:customer' => 'customer',
         'sales'       => 'sales',
     }
 );
 print $xml->doc(
     [ 'xmlns:customer' => $url ],
     $xml->customer([id => 1], 'bob'),
     $xml->customer([id => 2], 'alice'),
     $xml->customer([id => 3], 'charlie'),
     $xml->sales("3000.12"),
 );
 __END__
 <doc xmlns:ns="$url">
   <ns:customer id="1">bob</ns:customer>
   <ns:customer id="2">alice</ns:customer>
   <ns:customer id="3">charlie</ns:customer>
   <sales>3000.12</sales>
 </doc>
 
B<Note>:  newlines and indentation were added in the above example for
illustrative purposes only.  See C<NEWLINES> in the
L<Data::XML::Variant::Build> documentation.

=head1 DESCRIPTION

Many shops have "legacy" XML variants which look very similar to XML but
aren't quite there.  Unfortunately, this means that most XML generating tools
will not build this "legacy" XML.  Sometimes they require attributes in a
specific order, don't quote attributes, fail to close tags, use illegal
characters, etc.  Rather than writing your own code to produce bad XML, this
module at least allows you to do this systematically.

L<Data::XML::Variant> makes it very, very easy to write XML.  It also makes it
very easy to shoot yourself in the foot.  You are responsible for B<all>
output.  If you get it wrong, you've been warned.  On the plus side, you don't
have to worry about namespaces, inserting arbitrary data (very handy if you
have an XML snippet from somewhere else), or remembering a lot of complicated
stuff.

This module should B<not> be used casually.  It assumes that you, the
programmer, really want to do what you're asking it to do.  As a result, do
not use this module unless you have a test suite which can verify that you're
really creating the XML you need.  It's easy to create bogus XML with this.

=head1 EXPORT

None.

=head1 METHODS

=head2 new

 my $xml = XML::Compose->new(
     {
         $tag1 => $method1,
         $tag2 => $method2,
     }
 );

C<new> accepts a hashref of tags and their appropriate methods.  Methods must
begin with a lower-case later.  Tags will be built with the exact text used.
Namespaces will B<not> be checked, validated, whatever.

See the C<Add> method in C<Data::XML::Variant::Build> for more information
about how methods are added.

=cut

sub new {
    my ($class, $tags) = @_;
    my $build = Build->New;
    while (my ($tag, $method) = each %$tags) {
        $build->Add($tag, $method);
    }
    return $build;
}

=head2 Instance methods.

See L<Data::XML::Variant::Build> for a list of built-in methods.  Public
methods I<all> begin with an upper case letter to distinguish them from the
methods you add as tags.

=head2 A more complicated example

Just to let you see a better example:

 my $xml = Data::XML::Variant->new({
     'ns:foo'  => 'foo',
     'bar'     => 'bar',
     'ns2:baz' => 'baz',
 });
 print $xml->Decl, # add declaration (optional)
       $xml->PI('xml-stylesheet', [type => 'text/xsl', href=>"$xslt_url"]),
       $xml->foo(
           [ id => 3, 'xmlns:ns2' => $url],
           $xml->bar('silly'),
           $xml->Comment('this is a > comment'),
           $xml->baz(['asdf:some_attr' => 'value'], 'whee!'),
       );

 __END__
 <?xml version="1.0">
 <?xml-stylesheet type="text/xsl" href="$xslt_url"?>
 <ns:foo id="3" xmlns:ns2="$url">
 <bar>silly</bar>
 <!-- this is a &gt; comment -->
 <ns2:baz asdf:some_attr="value">whee!</ns2:baz>
 </ns:foo>

=head1 SHOULD YOU USE THIS MODULE?

You probably don't want to use this module if you need to produce well-formed
XML.  However, this module I<will> allow you to do that.  Regardless of
whether or not you use this module, because XML variants are frequently
sloppy, you should not use this unless you are in the habit of writing
automated tests.  It's very easy to generate XML (or something similar) which
does not match your expectations.

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

1; # End of Data::XML::Variant
