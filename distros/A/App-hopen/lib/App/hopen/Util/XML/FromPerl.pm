package App::hopen::Util::XML::FromPerl;

our $VERSION = '0.000015';

use strict;
use warnings;

# === Warnings ==============================================================

# Set up for warnings.  We can't do this in a separate package because
# warnings::enabled() and related rely on caller being the package that
# invoked this one, not this package itself.
use if $] ge '5.014', qw(warnings::register undefined);
use if $] lt '5.014', qw(warnings::register);

# @_warning_category is the category in which we will warn, or an empty list.
# @_warning_categories is the list of categories we need to check to see
#   if we should warn.
use vars qw(@_warning_category @_warning_categories);

if($] ge '5.014') {
   @_warning_category = (__PACKAGE__ . '::undefined');
   @_warning_categories = (__PACKAGE__, @_warning_category);
} else {
    @_warning_category = ();
    @_warning_categories = __PACKAGE__;
}

# Emit a warning and return a value.  Call via goto.  Usage:
#   @_ = ("warning message", $return_value);
#   goto &_emit_warning;

sub _emit_warning {
    my ($message, $retval) = @_;

    # Are all the categories of interest enabled?
    my $should_emit = 1;
    foreach(@_warning_categories) {
        if(!warnings::enabled($_)) {
            $should_emit = 0;
            last;
        }
    }

    warnings::warn(@_warning_category, $message) if $should_emit;

    return $retval;
} #_emit_warning

# === Code ==================================================================

use XML::LibXML;

use parent 'Exporter';
our @EXPORT_OK = qw(xml_from_perl xml_node_from_perl);

# Fill in the children of the given node from the passed value.
# No return value.
sub _fill_node_children {
    my ($doc, $parent, $data) = @_;
    unless(defined $data) {
        @_ = ("I can't create an XML node from undefined data", undef);
        goto &_emit_warning;
    }

    my ($one, $has_attrs);
    if(ref $data eq 'ARRAY') {
        $one = $data->[1];
        $has_attrs = ref $one eq 'HASH';
    }

    my $new_node;
    if (ref $data eq 'ARRAY' && $data->[0] eq '!--') {      # Comment
        my $separ = defined $, ? $, : ' ';

        # Grab the plain text nodes and paste them together.
        my $text = join $separ,
            map { $data->[$_] }
            grep { defined $data->[$_] and not ref $data->[$_] }
                (($has_attrs ? 2 : 1) .. $#$data);

        $new_node = $doc->createComment($text);

    } elsif (ref $data eq 'ARRAY') {                        # Regular node
        $new_node = $doc->createElement($data->[0]);

        if ($has_attrs) {
            my @keys = keys %$one;
            @keys = sort @keys unless tied %$one;
            for (@keys) {
                if (defined (my $v = $one->{$_})) {
                    $new_node->setAttribute($_, $v);
                }
            }
        }

        _fill_node_children($doc, $new_node, $data->[$_])
            for grep { defined $data->[$_] } (($has_attrs ? 2 : 1) .. $#$data);

    } else {                                                # Text node
        $new_node = $doc->createTextNode("$data");
    }

    $parent->appendChild($new_node);
    return undef;
} #_fill_node_children

# Create a phony element we can use as a temporary parent node
sub _create_phony {
    my $doc = shift;
    return $doc->createElementNS('https://metacpan.org/pod/XML::FromPerl',
                                    'phony_root');
} #_create_phony

sub xml_node_from_perl {
    my $doc = shift;
    my $data = shift;
    my $parent;

    $parent = _create_phony($doc);
    _fill_node_children $doc, $parent, $data;
    return $parent->firstChild;
} #xml_node_from_perl

sub xml_from_perl {
    my $data = shift;
    my $doc = XML::LibXML::Document->new(@_);

    unless(defined $data) {
        @_ = ("I can't create an XML document from undefined data", $doc);
        goto &_emit_warning;
    }

    my $parent = _create_phony($doc);
    $doc->setDocumentElement($parent);
    _fill_node_children $doc, $parent, $data;

    $doc->setDocumentElement($parent->firstChild);
    return $doc;
} #xml_from_perl

1;
__END__

=head1 NAME

XML::FromPerl - Generate XML from simple Perl data structures

=head1 SYNOPSIS

  use XML::FromPerl qw(xml_from_perl);

  my $doc = xml_from_perl
    [ Foo => { attr1 => val1, attr2 => val2},
      [ Bar => { attr3 => val3, ... },
        [ '!--', 'some comment, indicated by tag name "!--"' ],
        [ Bar => { ... },
        "Some Text here",
        [Doz => { ... },
          [ Bar => { ... }, [ ... ] ] ] ] ] ];

  $doc->toFile("foo.xml");
  # ->  <Foo attr1="val1" attr2="val2">
  #         <Bar attr3="val3">
  #             <!--some comment...-->
  #             ...
  #         </Bar>
  #     </Foo>

=head1 DESCRIPTION

This module is able to generate XML described using simple Perl data
structures.

XML nodes are declared as arrays where the first slot is the tag name,
the second is a HASH containing tag attributes and the rest are its
children. Perl scalars are used for text sections.

=head1 EXPORTABLE FUNCTIONS

=head2 xml_from_perl $data

Converts the given perl data structure into a L<XML::LibXML::Document>
object.

If C<$data> is undefined, the document will have no root element
or other contents.
A warning in category C<'XML::FromPerl::undefined'> will be issued.

=head2 xml_node_from_perl $doc, $data

Converts the given perl data structure into a L<XML::LibXML::Node>
object linked to the document passed.

If C<$data> is undefined, or is an arrayref including any undefined
entries, the undefined entries will be ignored.
A warning in category C<'XML::FromPerl::undefined'> will be issued for
each C<undef> item processed.

=head1 NOTES

=head2 Namespaces

I have not made my mind yet about how to handle XML namespaces other
than stating them explicitly in the names or setting the C<xmlns>
attribute.

=head2 Attribute order

If attribute order is important to you, declare then using
L<Tie::IxHash>:

For instance:

  use Tie::IxHash;
  sub attrs {
    my @attrs = @_;
    tie my(%attrs), 'Tie::Hash', @attrs;
    \%attrs
  }

  my $doc = xml_from_perl [ Foo => attrs(attr1 => val1, attrs2 => val2), ...];

Otherwise attributes are sorted in lexicographical order.

=head2 Memory usage

This module is not very memory efficient. At some point it is going to
keep in memory both the original perl data structure and the
XML::LibXML one.

Anyway, nowadays that shouldn't be a problem unless your data is
really huge.

=head2 Comments

Any attributes or children of a comment node will be ignored.
So, for example,

    [ '!--',
        { attr => 'val' },
        [ Foo => { attr => "hello" } ]
    ]

will produce

    <!---->

not

    <!--<Foo attr="hello"/>-->

This is due to a limitation of L<XML::LibXML>:
C<XML::LibXML::Comment::appendChild()> is a no-op.

Any text elements in a comment node will be joined together by the
value of C<$,>, or a single space if C<$,> is undefined.  For example,
if C<$, eq '#'>,

    [ '!--', qw(hello there world) ]

will produce

    <!--hello#there#world-->

=head1 SEE ALSO

L<XML::LibXML>, L<XML::LibXML::Document>, L<XML::LibXML::Node>.

Other modules for generating XML are L<XML::Writer> and
L<XML::Generator>. Check also L<XML::Compile>.

A related PerlMonks discussion:
L<http://www.perlmonks.org/?node_id=1195009>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017, 2019 by
Salvador FandiE<ntilde>o E<lt>sfandino@yahoo.comE<gt> and
Christopher White E<lt>cxw@cpan.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.24.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
