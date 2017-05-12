
# This is out of the test tree, because it's too much work to make it not
# depend on Exporter::Renaming


use strict;
use warnings;

use Test::More;

eval { require Exporter::Renaming; };

if ($@) {
    plan 'skip_all' => "Exporter::Renaming not installed"
}
else {
    plan 'no_plan';
}


# String eval because it's hard to only enable the Exporter::Renaming
# magic when Exporter::Renaming is installed

eval <<'EOF';

my $Package = 'CGI::Application::Plugin::Config::Context';

{
    package WebApp;
    use Test::More;

    use Exporter::Renaming;

    use base 'CGI::Application';
    use CGI::Application::Plugin::Config::Context Renaming => ['conf' => 'bozo'];

    sub cgiapp_init {
        my $self = shift;

        my $conf1 = $self->bozo;
        my $conf2 = $self->bozo('named');
        my $conf3 = $self->bozo;
        my $conf4 = $self->bozo('named');

        is(ref $conf1, $Package, 'conf1 object created');
        is(ref $conf2, $Package, 'conf2 object created');
        is(ref $conf3, $Package, 'conf3 object created');
        is(ref $conf4, $Package, 'conf4 object created');

        is("$conf1", "$conf3", "Unnamed configs are same object");
        is("$conf2", "$conf4", "Named configs are same object");
        isnt("$conf1", "$conf2", "Named and and Unnamed configs are different objects");

    }

}

my $webapp = WebApp->new;

EOF
