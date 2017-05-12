# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl CSS-Croco.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 18;
BEGIN { use_ok('CSS::Croco') };
my $parser = CSS::Croco->new;
my $stylesheet = $parser->parse( '
    @charset "windows-1251"; 
    * { color: red; background-color: black; fint-size: 12px !important}
    p { padding: 0 }
' );
isa_ok $stylesheet, 'CSS::Croco::StyleSheet';
my @rules = $stylesheet->rules;
my $decls = $rules[2]->declarations;
is ref $decls, 'CSS::Croco::DeclarationList';
is $decls->to_string(0), 'padding : 0;';
my $list = CSS::Croco::DeclarationList->parse( 'border: solid 1px; border: solid 2px;' );
is $list->property( 'border')->to_string, 'border : solid 1px';
is $list->property( 'border')->next->to_string, 'border : solid 2px';
is $list->property( 'border')->next->prev->to_string, 'border : solid 1px';
is $list->to_string(0), 'border : solid 1px;border : solid 2px;';
my $decl = $rules[2]->parse_declaration( 'background: url("http://google.com")' );
is $decl->to_string(0), 'background : url(http://google.com)';
is $decl->property, 'background';
$decl->property( 'bbb' );
is $decl->property, 'bbb';
ok !$decl->important;
$decl->important(1);
is $decl->to_string, 'bbb : url(http://google.com) !important';
ok ! $decl->next;
isa_ok $decl->value->get, 'URI';
is $decl->value->get->host, 'google.com';
my ($selector) = $rules[2]->selectors;
is $selector->name, 'p';
ok !$selector->is_case_sensitive;
