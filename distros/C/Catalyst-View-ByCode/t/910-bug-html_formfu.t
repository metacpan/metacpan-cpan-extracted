# -*- perl -*-
use Test::More;
use Test::Exception;

use ok 'Catalyst::View::ByCode::Renderer', ':default';

SKIP: {
    eval "use HTML::FormFu";
    skip 'HTML::FormFu required', 9 if $@;
    
    lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 1 lives';
    is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup is empty' ;
    
    
    # FormFu objects that can render() themselves
    my $f = HTML::FormFu->new();
    lives_ok { div(foo => 'bar') { $f } } 'adding an object markup lives';
    like Catalyst::View::ByCode::Renderer::get_markup(), qr{\s*<div\s+foo="bar">
                                                                  <form .*? </form>
                                                            \s*</div>}xms, 'markup 1 looks good';

    # a form inside a template {} did not work before patching
    lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing markup 2 lives';
    is Catalyst::View::ByCode::Renderer::get_markup(), '', 'markup is empty' ;

    lives_ok { template { $f } } 'constructing a template() lives';
    lives_ok { RUN() } 'calling the template lives';
    like Catalyst::View::ByCode::Renderer::get_markup(),
        qr{\s*<form .*? </form>\s*}xms, 
        'markup 2 looks good';
}

done_testing();
