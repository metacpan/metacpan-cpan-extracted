# -*- perl -*-
use Test::More;
use Test::Exception;

use ok 'Catalyst::View::ByCode::Renderer', ':markup';

#
# exported subs
#
can_ok 'Catalyst::View::ByCode::Renderer', qw(clear_markup init_markup get_markup);
can_ok 'Catalyst::View::ByCode::Renderer', qw(template block block_content
                                              load yield attr class id on
                                              stash c doctype boilerplate); ### FIXME: _ fails
can_ok 'main', qw(clear_markup init_markup get_markup);

#
# markup handling
#
lives_ok {init_markup()} 'initing markup lives';

lives_ok {get_markup()} 'getting markup lives';
is get_markup(), '', 'empty markup is empty' ;

lives_ok {clear_markup()} 'clearing markup lives';
is get_markup(), '', 'empty markup is empty' ;

#
# rendering content
#
@Catalyst::View::ByCode::Renderer::m = ( qw(foo bar baz) );
is get_markup(), 'foobarbaz', 'concatenating scalar content works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ undef, {}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'fooabcbar', 'concatenating a dummy tag works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', undef, 'baz' );
is get_markup(), 'foobaz', 'concatenating undef works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div>abc</div>bar', 'concatenating a tag works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {bla => 'blubb'}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div bla="blubb">abc</div>bar', 'concatenating a tag w/ attribute works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {'<%= "bla" %>' => undef}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div <%= "bla" %>>abc</div>bar', 'concatenating a tag w/ attribute works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {bla => 'blubb', z => 999}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div bla="blubb" z="999">abc</div>bar', 'concatenating a tag w/ attributes works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {bla => 'blu "b" b'}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div bla="blu &#34;b&#34; b">abc</div>bar', 'concatenating a tag w/ escaped attribute value works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {blaBlubb => 42}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div bla-blubb="42">abc</div>bar', 'concatenating a tag w/ camelCase attribute name works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {bla_foo => 'zz'}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div bla-foo="zz">abc</div>bar', 'concatenating a tag w/ _joined attribute name works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {blaFoo_bar => 'abz'}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div bla-foo-bar="abz">abc</div>bar', 'concatenating a tag w/ camelCase_joined attribute name works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {style => {float => 'right'}}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div style="float:right">abc</div>bar', 'concatenating a tag w/ hashref attribute value works' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {data => [1,2,3]}, 'a', 'b', 'c' ], 'bar' );
is get_markup(), 'foo<div data="1 2 3">abc</div>bar', 'concatenating a tag w/ arrayref attribute value works' ;


#
# print functionality
#
clear_markup();
lives_ok { Catalyst::View::ByCode::Renderer::PRINT(\0, "abc<>\x{0123}") } 'PRINT unescaped lives';
is get_markup(), "abc<>\x{0123}", 'unescaped markup looks good' ;

lives_ok { Catalyst::View::ByCode::Renderer::PRINT(\0, "just my 2 cent") } 'append PRINT unescaped lives';
is get_markup(), "abc<>\x{0123}just my 2 cent", 'unescaped markup looks good' ;

@Catalyst::View::ByCode::Renderer::m = ( 'foo', [ 'div', {data => [1,2,3]}, 'a', 'b', 'c' ], 'bar' );
@Catalyst::View::ByCode::Renderer::top = ( \@Catalyst::View::ByCode::Renderer::m,
                                           $Catalyst::View::ByCode::Renderer::m[1] );

lives_ok { Catalyst::View::ByCode::Renderer::PRINT(\0, "&\"\x{0444}") } 'append nested PRINT unescaped lives';
is get_markup(), qq{foo<div data="1 2 3">abc&"\x{0444}</div>bar}, 'append nested PRINT content looks good' ;

clear_markup();
lives_ok { Catalyst::View::ByCode::Renderer::PRINT(\1, "abc<>\x{0123}") } 'PRINT escaped lives';
is get_markup(), "abc&#60;&#62;&#291;", 'escaped markup looks good' ;


#
# render() logic in PRINT
#
my $o = RenderMe->new();
clear_markup();
lives_ok { Catalyst::View::ByCode::Renderer::PRINT(\1, $o) } 'PRINT object escaped lives';
is get_markup(), '<hello>"world"</hello>', 'escaped object markup looks good' ;

clear_markup();
lives_ok { Catalyst::View::ByCode::Renderer::PRINT(\o, $o) } 'PRINT object unescaped lives';
is get_markup(), '<hello>"world"</hello>', 'unescaped object markup looks good' ;


#
# done
#
done_testing();


# helper package for testing render() logic
{
    package RenderMe;
    
    sub new { bless {}, $_[0] }
    
    sub render { '<hello>"world"</hello>' };
}
