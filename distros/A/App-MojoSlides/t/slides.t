use Mojo::Base -strict;

use App::MojoSlides::Slides;
use Test::More;

# initialization tests
my $s;
$s = App::MojoSlides::Slides->new;
isa_ok $s, 'App::MojoSlides::Slides';

$s = App::MojoSlides::Slides->new(2);
is $s->last, 2, 'Initialize last with scalar';

$s = App::MojoSlides::Slides->new({last => 2});
is $s->last, 2, 'Initialize last with hashref';

$s = App::MojoSlides::Slides->new(last => 2);
is $s->last, 2, 'Initialize with pairs';

my $arrayref = [qw/hello world/];
$s = App::MojoSlides::Slides->new($arrayref);
is_deeply $s->list, $arrayref, 'Initialize list with arrayref';

$s = App::MojoSlides::Slides->new({list => $arrayref});
is_deeply $s->list, $arrayref, 'Initialize list with hashref';

$s = App::MojoSlides::Slides->new(list => $arrayref);
is_deeply $s->list, $arrayref, 'Initialize last with pairs';

done_testing;

