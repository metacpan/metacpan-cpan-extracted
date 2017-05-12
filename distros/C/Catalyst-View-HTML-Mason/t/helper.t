use strict;
use warnings;

use File::Temp;
use Test::More;

use Path::Class;
use Capture::Tiny 0.10 'capture';

use_ok('Catalyst::Helper::View::HTML::Mason');

my $tmpdir = File::Temp->newdir;
my $d = dir( "$tmpdir" );

$d->subdir('bin')->mkpath;

my $create_script = $d->subdir('bin')->file('foo_create.pl');
$create_script->openw->print(<<'');
use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('Foo', 'Create');

my ($stdout, $stderr) = capture {
    system $^X, $create_script, 'view', 'Noggin', 'HTML::Mason';
};

my $view_code = eval{ $d->subdir(qw( lib Foo View ))->file('Noggin.pm')->slurp };
diag $@ if $@;

like( $view_code, qr/package \s* Foo::View::Noggin/x );
like( $view_code, qr/extends \s* ['"]Catalyst::View::HTML::Mason['"]/x );
like( $stdout, qr/ created \s+ ["'] [^"']+ Noggin.pm ["'] \s* /xs );

done_testing;



