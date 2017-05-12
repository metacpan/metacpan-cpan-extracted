# -*- perl -*-
use Test::More;
use Test::Exception;

use ok 'Catalyst::View::ByCode::Renderer', ':default';

#
# exported subs
#
can_ok('main', qw(template block block_content
                  load yield attr class id on
                  stash c doctype _
                  div span h1));

ok !'main'->can('clear_markup'),  'clear_markup not exported';
ok !'main'->can('init_markup'),   'init_markup not exported';
ok !'main'->can('get_markup'),    'get_markup not exported';

#
# clear markup
#
lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup is empty';

#
# defining a template
#
ok !'main'->can('RUN'), 'sub RUN initially undefined';
lives_ok { template { print OUT 'bla' }; } 'defining a template works';
ok 'main'->can('RUN'), 'sub RUN defined by template directive';

is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup still empty';

lives_ok { RUN() } 'RUN can get called';
is Catalyst::View::ByCode::Renderer::get_markup(), 'bla', 'markup contains template result';


#
# defining a block
#
ok !'main'->can('some_block'), 'sub some_block initially undefined';
# must be eval()ed because Devel::Declare defines the block as soon as 'block' is scanned by compiler
lives_ok { eval q{ package main; block some_block { return 'was inside block' } }; die $@ if $@; } 'block definition works';
ok 'main'->can('some_block'), 'sub some_block now defined';

#
# adding things to a fresh document
#
lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 2 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 2 is empty';

lives_ok { div { attr abc => 42 }; } 'adding a div lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<div\s+abc="42">\s*</div>\s*}xms, 'markup2 looks OK';

#
# adding things to a fresh document and calling block
#
lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 3 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 3 is empty';

lives_ok { div { id 'xyz'; b { some_block(); }; }; } 'adding a div with block lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<div\s+id="xyz">\s*<b>\s*was\s+inside\s+block\s*</b>\s*</div>\s*}xms, 'markup3 looks OK';

#
# testing 'class' operator inside a tag
#
lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 4 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 4 is empty';

lives_ok { span { class 'xxx' }; } 'adding a span-tag with class lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<span\s+class="xxx">\s*</span>\s*}xms, 'markup4 looks OK';



lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 5 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 5 is empty';

lives_ok { span { class 'xxx'; class 'yyy' }; } 'adding a span-tag with 2 classes lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<span\s+class="yyy">\s*</span>\s*}xms, 'markup5 looks OK';



lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 6 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 6 is empty';

lives_ok { span { class 'xxx'; class '+yyy' }; } 'adding a span-tag with +2 classes lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<span\s+class="xxx\s+yyy">\s*</span>\s*}xms, 'markup6 looks OK';



lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 7 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 7 is empty';

lives_ok { span { class 'xxx yyy'; class '-yyy' }; } 'adding a span-tag with 2-1 classes lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<span\s+class="xxx">\s*</span>\s*}xms, 'markup7 looks OK';



lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 8 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 8 is empty';

lives_ok { span { class 'xxx yyy'; class '-yyy +zzz' }; } 'adding a span-tag with 2-1+1 classes lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<span\s+class="xxx\s+zzz">\s*</span>\s*}xms, 'markup8 looks OK';



lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 9 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 9 is empty';

lives_ok { span { class 'xxx yyy'; class '-yyy', '+zzz' }; } 'adding a span-tag with 2-1+1 classes lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<span\s+class="xxx\s+zzz">\s*</span>\s*}xms, 'markup9 looks OK';


#
# attrs with linebreaks
#
lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 10 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 10 is empty';

lives_ok { div(id => 'xyz',
               bla => 'blubb') { 'test' }; } 'adding a div with line-break lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<div\s+bla="blubb"\s+id="xyz">\s*test\s*</div>\s*}xms, 'markup10 looks OK';

#
# attrs with linebreaks (2)
#
{
    package X;
    sub new {
        my $class = shift;
        return bless {}, $class;
    }
    
    sub uri_for_action {
        return 'bla'; # just a dummy return value
    }
    
    package Y;
    sub new {
        my $class = shift;
        return bless {}, $class;
    }
    
    sub db_id {
        return 'blubb'; # just a dummy return value
    }
}

{
    no warnings 'redefine';
    sub c {
        return X->new;
    }
}

my $concept = Y->new;

lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 11 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 11 is empty';

# this version failed before (2010-02-23):
lives_ok { a(href => c->uri_for_action('concept/detail', $concept->db_id), 
             title => 'Details', 
             class => 'ajax', 
             'data-target' => '-new', 
             dataTitle => 'Detail'
             ) { 'xxx' } }
         'adding a a-tag with more line-breaks and strange attributes lives';

like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<a
                                                            \s+class="ajax"
                                                            \s+data-target="-new"
                                                            \s+data-title="Detail"
                                                            \s+href="bla"
                                                            \s+title="Details">
                                                            \s*xxx\s*</a>\s*}xms, 'markup11 looks OK';

# content objects that can render() themselves
my $o = RenderMe->new();
lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 12 lives';
is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup 12 is empty';
lives_ok { div(foo => 'bar') { $o } } 'adding an object markup lives';
like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<div\s+foo="bar">
                                                              <hello>"world"</hello>
                                                        \s*</div>}xms, 'markup 12 looks good';


#
# boilerplate
#
lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 13 lives';
boilerplate;
is Catalyst::View::ByCode::Renderer::get_markup(), 
   '<!--[if lt IE 7 ]> <html class="no-js ie6" lang="en"> <![endif]-->
<!--[if IE 7 ]>    <html class="no-js ie7" lang="en"> <![endif]-->
<!--[if IE 8 ]>    <html class="no-js ie8" lang="en"> <![endif]-->
<!--[if (gte IE 9)|!(IE)]><!--> <html class="no-js" lang="en"> <!--<![endif]-->
</html>', 'boilerplate w/o content looks good';

lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 14 lives';
boilerplate { div { 'bla' } };
is Catalyst::View::ByCode::Renderer::get_markup(), 
   '<!--[if lt IE 7 ]> <html class="no-js ie6" lang="en"> <![endif]-->
<!--[if IE 7 ]>    <html class="no-js ie7" lang="en"> <![endif]-->
<!--[if IE 8 ]>    <html class="no-js ie8" lang="en"> <![endif]-->
<!--[if (gte IE 9)|!(IE)]><!--> <html class="no-js" lang="en"> <!--<![endif]-->
<div>bla</div></html>', 'boilerplate w/ content looks good';


#
# scalar refs inside tags do not escape
#
lives_ok { Catalyst::View::ByCode::Renderer::init_markup() } 'initing markup 15 lives';
div { \'<foo & bar>' };
is Catalyst::View::ByCode::Renderer::get_markup(),
    '<div><foo & bar></div>',
    'scalar ref is not escaped';

#
# scalar refs do not escape
#
lives_ok { Catalyst::View::ByCode::Renderer::init_markup() } 'initing markup 16 lives';
div ( class => \'<abc & def>' ) { 'foo' };
is Catalyst::View::ByCode::Renderer::get_markup(),
    '<div class="<abc & def>">foo</div>',
    'scalar ref is expanded';

#
# code refs inside attributes do expand correctly
#
sub give_content { '"abc" def' }

lives_ok { Catalyst::View::ByCode::Renderer::init_markup() } 'initing markup 17 lives';
div ( class => \&give_content ) { 'bar' };
is Catalyst::View::ByCode::Renderer::get_markup(),
    '<div class="&#34;abc&#34; def">bar</div>',
    'code ref is expanded';

# usage of attr with one argument
lives_ok { Catalyst::View::ByCode::Renderer::init_markup() } 'initing markup 18 lives';
div ( class => 'foo' ) { attr '<%= baaah %>'; 'bar' };
is Catalyst::View::ByCode::Renderer::get_markup(),
    '<div <%= baaah %> class="foo">bar</div>',
    'attr sets additional content inside tag';



done_testing;

# helper class for render test
{
    package RenderMe;
    
    sub new { bless {}, $_[0] }
    
    sub render { '<hello>"world"</hello>' };
}
