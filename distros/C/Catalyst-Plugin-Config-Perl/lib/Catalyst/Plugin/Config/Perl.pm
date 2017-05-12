package Catalyst::Plugin::Config::Perl;
use 5.012;
use Panda::Lib 'fclone';
use Panda::Config::Perl;

our $VERSION = '1.0.3';

use Class::Accessor::Inherited::XS inherited => [qw/cfg dev config_initial/];

sub setup {
    my $class = shift;
    my $initial_cfg = $class->config;
    $class->config_initial($initial_cfg);
    $class->cfg($initial_cfg);
    $class->config_reload;
    $class->next::method(@_);
}

sub config_reload {
    my $class = ref($_[0]) || $_[0];
    #my $start = Time::HiRes::time();
    my $initial_cfg = $class->config_initial;
    my $self_cfg = $initial_cfg->{'Plugin::Config::Perl'} || {};
    $initial_cfg->{home} = Path::Class::Dir->new($initial_cfg->{home}) unless ref $initial_cfg->{home};
    
    my $conf_file;
    if ($self_cfg->{file}) {
        $conf_file = $initial_cfg->{home}->file($self_cfg->{file});
    } else {
        my $local_file = $initial_cfg->{home}->file('local.conf');
        if (-f $local_file) { $conf_file = $local_file }
        else {
            my $main_file = $initial_cfg->{home}->file('conf/'.lc($class).'.conf');
            $conf_file = $main_file if -f $main_file;
        }
    }
    
    if ($conf_file) {
        my $cfg = Panda::Config::Perl->process($conf_file, $initial_cfg);
        my $old = $class->setup_finished;
        $class->setup_finished(0); # work around fucking and annoying Catalyst
        $class->config($cfg);
        $class->setup_finished($old);
        $class->cfg($cfg);
    }
    
    $class->dev($class->cfg->{dev});

    #print "ConfigSuite Init took ".((Time::HiRes::time() - $start)*1000)."\n";
    my $sub = $class->can('finalize_config');
    $sub->($class) if $sub;
    
    $class->dev($class->cfg->{dev});
}

1;