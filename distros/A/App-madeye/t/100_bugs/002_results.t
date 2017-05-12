use strict;
use warnings;
use Test::More tests => 1;
use App::MadEye;

my $count = 0;
{
    package Notify;
    use Params::Validate ':all';
    sub bar {
        my ($self, $c, $args) = validate_pos(@_ => OBJECT, OBJECT, OBJECT);
        $count++;
    }
    sub config { +{ } }
}

{
    package Agent;
    sub config { +{ } }
}

my $c = App::MadEye->new({config => { }});

for (1..4) {
    $c->register_hook('notify' => { plugin => bless({}, 'Notify'), method => 'bar'});
}
for (1..6) {
    $c->add_result(
        plugin  => 'Agent',
        target  => 'Fuga',
        message => 'Moge',
    );
}
$c->run();

is $count, 4;

