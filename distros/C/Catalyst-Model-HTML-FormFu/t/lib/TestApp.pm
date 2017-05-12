package TestApp;
use strict;
BEGIN
{
    my @CATALYST_ARGS;
    my %CATALYST_CONFIG = (
        'Model::HTML::FormFu' => {
            config_dir => 't'
        }
    );
    my $has_cache_plugin = eval "require Catalyst::Plugin::Cache";
    my $has_cache_memory = eval "require Cache::Memory";

    if ($has_cache_plugin && $has_cache_memory) {
        push @CATALYST_ARGS, qw(Cache);
        $CATALYST_CONFIG{cache} = {
            backends => {
                memory => {
                    class => "Cache::Memory",
                }
            }
        };
        $CATALYST_CONFIG{'Model::HTML::FormFu'}->{cache_backend} = 'memory';
    }
    require Catalyst;
    Catalyst->import(@CATALYST_ARGS);
    __PACKAGE__->config(
        %CATALYST_CONFIG,
    );

}
use POSIX qw(strftime);

sub load : Local {
    my ($self, $c) = @_;
    my $form = $c->model('HTML::FormFu')->load_form('02_yaml/config.yml');

    my $today = $form->get_field({ name => 'today' })->value eq strftime('%Y-%m-%d-1', localtime) ? "OK" : "NOK";
    $c->res->output(<<EOM);
today: $today
EOM
}

__PACKAGE__->setup;

1;