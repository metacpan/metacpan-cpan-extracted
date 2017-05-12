package AxKit::App::TABOO::XSP::Language;
use 5.6.0;
use strict;
use warnings;
use Apache::AxKit::Language::XSP::SimpleTaglib;
use Apache::AxKit::Exception;
use AxKit;
use AxKit::App::TABOO::Data::Language;
use AxKit::App::TABOO::Data::Plurals::Languages;
use Time::Piece ':override';
use XML::LibXML;


use vars qw/$NS/;


our $VERSION = '0.4';


=head1 NAME

AxKit::App::TABOO::XSP::Language - Language management tag library for TABOO

=head1 SYNOPSIS

Add the language: namespace to your XSP C<E<lt>xsp:pageE<gt>> tag, e.g.:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:language="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Language"
    >

Add this taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::App::TABOO::XSP::Language


=head1 DESCRIPTION

This XSP taglib provides two tags to retrieve a structured XML
fragment with all information of a single language or all languages
of a certain type.

L<Apache::AxKit::Language::XSP::SimpleTaglib> has been used to write
this taglib.

=cut



$NS = 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Language';

package AxKit::App::TABOO::XSP::Language::Handlers;


=head1 Tag Reference

=head2 C<E<lt>get-language lang="foo"/E<gt>>

This tag will replace itself with some structured XML containing all
fields of languages of type C<foo>.  It relates to the TABOO Data
object L<AxKit::App::TABOO::Data::Language>, and calls on that to do
the hard work.

The root element of the returned object is C<cat:languages> and each
language is wrapped in an element C<cat:language> and contains C<lang>
and C<name>.

=cut

sub get_language : struct attribOrChild(lang) {
    return << 'EOC'
    my $lang = AxKit::App::TABOO::Data::Language->new();
    $lang->load(limit => {code => $attr_lang});
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Language/Output', 'lang:languages');
    $doc->setDocumentElement($root);
    $doc = $lang->write_xml($doc, $root);
    $doc;
EOC
}


=head2 C<E<lt>get-languages/E<gt>>

This tag will replace itself with some structured XML containing all
languages.  It relates to the TABOO Data object
L<AxKit::App::TABOO::Data::Plurals::Languages>, and calls on that to
do the hard work.

The root element of the returned object is C<languages> and each
language is wrapped in an element C<language>, and ordered
alphabetically by local name.

=cut

# TODO: The code will also be available in an attribute C<xml:lang>,



sub get_languages : struct attribOrChild(code,onlycontent) {
    return << 'EOC'
    my $langs = AxKit::App::TABOO::Data::Plurals::Languages->new();
    $langs->load(orderby => 'localname');
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Language/Output', 'lang:languages');
    $doc->setDocumentElement($root);
    $doc = $langs->write_xml($doc, $root);
    $doc;
EOC
}


=head2 C<E<lt>exists lang="foo"/E<gt>>

This tag will check if a language allready exists. It is a boolean
tag, which has child elements C<E<lt>trueE<gt>> and
C<E<lt>falseE<gt>>. It takes a lang parameter, which may be given as
an attribute or a child element named C<lang>, and if the language is
found in the data store, the contents of C<E<lt>trueE<gt>> child
element is included, otherwise, the contents of C<E<lt>falseE<gt>> is
included.

=cut

sub exists : attribOrChild(lang) {
    return ''; # Gotta be something here
}

sub exists___true__open {
return << 'EOC';
    my $lang = AxKit::App::TABOO::Data::Language->new();
    if ($lang->load(what => '1', limit => {lang => $attr_lang})) {
EOC
}

sub exists___true {
  return '}'
}


sub exists___false__open {
return << 'EOC';
    my $lang = AxKit::App::TABOO::Data::Language->new();
    unless ($lang->load(what => '1', limit => {lang => $attr_lang})) {
EOC
}

sub exists___false {
  return '}'
}


    
1;


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut
