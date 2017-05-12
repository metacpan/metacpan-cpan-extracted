# make sure HTML::TreeBuilder is available
BEGIN {
    eval { require HTML::TreeBuilder; };
    if ($@) {
        eval "use Test::More skip_all => q{02html.t requires HTML::TreeBuilder.};";
        exit;
    }
}

use Test::More qw(no_plan);
use strict;
use warnings;
use Class::XPath;
use HTML::TreeBuilder;

# build a tree from some HTML
my $root = HTML::TreeBuilder->new;
isa_ok($root, 'HTML::TreeBuilder');
$root->parse_file("t/02html.html");
isa_ok($root, 'HTML::Element');

# add Class::XPath routines to HTML::Element
Class::XPath->add_methods(target         => 'HTML::Element',
                          call_match     => 'xpath_match',
                          call_xpath     => 'xpath_id',
                          get_parent     => 'parent',
                          get_name       => 'tag',
                          get_attr_names => 
                            sub { my %attr = shift->all_external_attr;
                                  return keys %attr; },
                          get_attr_value => 
                          sub { my %attr = shift->all_external_attr;
                                return $attr{$_[0]}; },
                          get_children   =>
                            sub { grep { ref $_ } shift->content_list },
                          get_content    =>
                            sub { grep { not ref $_ } shift->content_list },
                          get_root       => 
                            sub { local $_=shift; 
                                  while($_->parent) { $_ = $_->parent }
                                  return $_; });

# do some matching tests against the HTML
is($root->xpath_match('//table'), 3);
is($root->xpath_match('/head/title'), 1);
is($root->xpath_match('//head/title'), 1);
is(($root->xpath_match('/head/title'))[0]->xpath_id, '/head[0]/title[0]');
is(($root->xpath_match('/head/title'))[0]->parent->xpath_id, '/head[0]');
is(($root->xpath_match('/head/title'))[0]->parent->parent->xpath_id, '/');
is($root->xpath_match('//a'), 54);

my ($head) = $root->xpath_match('/head');
is($head->xpath_match('title'), 1);
is($head->xpath_match('/title'), 0);
