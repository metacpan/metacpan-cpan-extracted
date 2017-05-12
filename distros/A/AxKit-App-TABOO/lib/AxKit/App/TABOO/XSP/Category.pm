package AxKit::App::TABOO::XSP::Category;
use 5.6.0;
use strict;
use warnings;
use Apache::AxKit::Language::XSP::SimpleTaglib;
use Apache::AxKit::Exception;
use AxKit;
use AxKit::App::TABOO;
use AxKit::App::TABOO::Data::Category;
use AxKit::App::TABOO::Data::Plurals::Categories;
use Session;
use Time::Piece ':override';
use XML::LibXML;


use vars qw/$NS/;


our $VERSION = '0.4';


=head1 NAME

AxKit::App::TABOO::XSP::Category - Category management tag library for TABOO

=head1 SYNOPSIS

Add the category: namespace to your XSP C<E<lt>xsp:pageE<gt>> tag, e.g.:

    <xsp:page
         language="Perl"
         xmlns:xsp="http://apache.org/xsp/core/v1"
         xmlns:category="http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category"
    >

Add this taglib to AxKit (via httpd.conf or .htaccess):

  AxAddXSPTaglib AxKit::App::TABOO::XSP::Category


=head1 DESCRIPTION

This XSP taglib provides two tags to retrieve a structured XML
fragment with all information of a single category or all categories
of a certain type.

L<Apache::AxKit::Language::XSP::SimpleTaglib> has been used to write
this taglib.

=cut



$NS = 'http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category';

sub _sanatize_catname {
    my $tmp = lc shift;
    $tmp =~ tr/a-z/_/cs;
    return $tmp;
}


package AxKit::App::TABOO::XSP::Category::Handlers;


=head1 Tag Reference

=head2 C<E<lt>get-category catname="foo"/E<gt>>

This tag will replace itself with some structured XML containing all
fields of categories of type C<foo>.  It relates to the TABOO Data
object L<AxKit::App::TABOO::Data::Category>, and calls on that to do
the hard work.

The root element of the returned object is C<cat:categories> and each
category is wrapped in an element C<cat:category> and contains C<catname>
and C<name>.

=cut

sub get_category : struct attribOrChild(catname) {
    return << 'EOC'
    my $cat = AxKit::App::TABOO::Data::Category->new();
    $cat->load(limit => {catname => $attr_catname});
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output', 'cat:categories');
    $doc->setDocumentElement($root);
    $doc = $cat->write_xml($doc, $root);
    $doc;
EOC
}


=head2 C<E<lt>get-categories type="foo" onlycontent="true"/E<gt>>

This tag will replace itself with some structured XML containing all
categories of type C<foo>.  It relates to the TABOO Data object
L<AxKit::App::TABOO::Data::Plurals::Categories>, and calls on that to
do the hard work. See the documentation of that class to see the
available types. If a boolean C<onlycontent> attribute (or child
element) is set, it will check if there are articles or stories in the
C<categ> category types, and return only those.

The root element of the returned object is C<categories> and each
category is wrapped in an element (surprise!) C<category>. The type
will also be available in an attribute called C<type>, and ordered
alphabetically by name.

=cut

sub get_categories : struct attribOrChild(type,onlycontent) {
    return << 'EOC'
    my $cats = AxKit::App::TABOO::Data::Plurals::Categories->new();
    $cats->load(limit => {type => $attr_type}, 
		onlycontent => $attr_onlycontent, 
		orderby => 'name');
    my $doc = XML::LibXML::Document->new();
    my $root = $doc->createElementNS('http://www.kjetil.kjernsmo.net/software/TABOO/NS/Category/Output', 'cat:categories');
    $root->setAttribute('type', $attr_type);
    $doc->setDocumentElement($root);
    $doc = $cats->write_xml($doc, $root);
    $doc;
EOC
}


=head2 C<E<lt>store/E<gt>>

It will take whatever data it finds in the L<Apache::Request> object
held by AxKit, and hand it to a new
L<AxKit::App::TABOO::Data::Article> object, which will use whatever
data it finds useful. It will not store anything unless the user is
logged in and authenticated with an authorization level. It will
perform different sanity checks and throw exceptions if the user tries
to add data it is not authorized to do.

Finally, the Data object is instructed to save itself. 


=cut


sub store {
    return << 'EOC'
    my %args = map { $_ => join('', $cgi->param($_)) } $cgi->param;
    my $authlevel = AxKit::App::TABOO::authlevel(AxKit::App::TABOO::session($r));
    AxKit::Debug(9, "Logged in as $args{'username'} at level $authlevel");
    unless ($authlevel >= 1) {
  	throw Apache::AxKit::Exception::Retval(
  					       return_code => AUTH_REQUIRED,
  					       -text => "Not authenticated and authorized with an authlevel");
    }    
    my $cat = AxKit::App::TABOO::Data::Category->new();

    if (($args{'type'} eq 'stsec') && ($authlevel < 6)) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => FORBIDDEN,
					       -text => "Authlevel 6 is needed to make new sections. Your level: " . $authlevel);
    }
    if ((($args{'type'} eq 'categ') || ($args{'type'} eq 'angle')) && ($authlevel < 4)) {
	throw Apache::AxKit::Exception::Retval(
					       return_code => FORBIDDEN,
					       -text => "Authlevel 4 is needed to make new categories. Your level: " . $authlevel);
    }

    $args{'catname'} = AxKit::App::TABOO::XSP::Category::_sanatize_catname($args{'catname'});
    $cat->populate(\%args);
    $cat->save();
EOC
}

=head2 C<E<lt>exists catname="foo"/E<gt>>

This tag will check if a category allready exists. It is a boolean
tag, which has child elements C<E<lt>trueE<gt>> and
C<E<lt>falseE<gt>>. It takes a catname, which may be given as an
attribute or a child element named C<catname>, and if the category is
found in the data store, the contents of C<E<lt>trueE<gt>> child
element is included, otherwise, the contents of C<E<lt>falseE<gt>> is
included.

=cut

sub exists : attribOrChild(catname) {
    return ''; # Gotta be something here
}

sub exists___true__open {
return << 'EOC';
    my $category = AxKit::App::TABOO::Data::Category->new();
    if (($attr_catname =~ m/submit/) || 
	($category->load(what => '1', limit => {catname => $attr_catname}))) {
EOC
}

sub exists___true {
  return '}'
}


sub exists___false__open {
return << 'EOC';
    my $category = AxKit::App::TABOO::Data::Category->new();
    unless (($attr_catname =~ m/submit/) || 
	    ($category->load(what => '1', limit => {catname => $attr_catname}))) {
EOC
}

sub exists___false {
  return '}'
}


    
1;


=head1 FORMALITIES

See L<AxKit::App::TABOO>.

=cut
