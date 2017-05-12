# -*- perl -*-
use Test::More;
use Test::Exception;
use Catalyst ();
use FindBin;
use lib "$FindBin::Bin/lib";
use Path::Class;
use MockCatalyst;

use ok 'Catalyst::View::ByCode';

# setup
my $c = MockCatalyst->new(
	root_dir => $FindBin::Bin,
);
my $view = Catalyst::View::ByCode->COMPONENT($c);

# check against the bug: _compile_template fails
my $subref = 1234;
lives_ok {$subref = $view->_compile_template($c, 'bug_block.pl')} 'compilation block lives';
is ref($subref), 'CODE', 'compile block result is a CODEref' ;

lives_ok {Catalyst::View::ByCode::Renderer::init_markup()} 'initing block markup lives';
lives_ok {$subref->()} 'calling block_template lives';
like Catalyst::View::ByCode::Renderer::get_markup(), 
     qr{\s*
        <b>\s*block1:\s*</b>
        \s*
        <div\s+id="block1">\s*-1-OK:\s+1\s*</div>\s*
        \s*
        <b>\s*block2:\s*</b>
        \s*
        <div\s+id="block2">\s*-2-OK:\s+1\s*</div>\s*
        \s*
        <b>\s*block3:\s*</b>
        \s*
        <div\s+id="block3">\s*-3-OK:\s+1\s*</div>\s*
        \s*
        <b>\s*after\s+blocks\s*</b>
        \s*}xms, 
     'block markup looks OK';


done_testing();
