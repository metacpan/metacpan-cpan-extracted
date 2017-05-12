# TODO:
# - Support uri_base
# - Support uri_port
# - Support uri_path
# - Support daemon, logfile and pid
# - plugins can update config to map urls to code
# - Make all config options 'foo' respect $COG_FOO

package Cog::Config;
use Mo qw'build builder default required';

use File::ShareDir;
use Cwd qw(abs_path);
use IO::All;

### These options are set by user in config file:

# Common webapp options
has home_page_id => ();

# Server options
has server_host => (default => 'localhost');
has server_port => (default => '12345');
has proxymap => ();
has cache_urls => ();

### These fields are part of the Cog framework:

# Bootstrapping config values
my $app;
sub app { $app }
has app_class => required => 1;

# App Command Values
has cli_args => (default => sub{[]});

# App & WebApp definitions
has url_map => (default => sub{[]});
has post_map => (default => sub{[]});
has coffee_files => (default => sub{[]});
has js_files => (default => sub{[]});
has css_files => (default => sub{[]});
has image_files => (default => sub{[]});
has template_files => (default => sub{[]});
has site_navigation => (default => sub{[]});
has files_map => (builder => '_build_files_map', lazy => 1);
has all_js_file => ();
has all_css_file => ();

# App readiness
has is_init => (default => 0);
has is_config => (default => 0);
has is_ready => (default => 0);

# Private accessors
has _plugins => (default => sub{[]});
has _class_share_map => (default => sub{{}});


# Build the config object scanning through all the classes and merging
# their capabilites together appropriately.
#
# This is the hard part...
sub BUILD {
    my $self = shift;
    $app = delete $self->{app};

    my $root = $self->app->app_root;
    $self->{is_init} = 1
        if -d "$root/static";
    $self->{is_config} = 1
        if -e "$root/config.yaml";
    $self->{is_ready} = 1
        if -d "$root/static";

    $self->build_plugin_list();

    $self->build_class_share_map();

    $self->build_list('url_map', 'lol');
    $self->build_list('post_map', 'lol');
    $self->build_list('site_navigation', 'lol');

    $self->build_list('coffee_files');
    $self->build_list('js_files');
    $self->build_list('css_files');
    $self->build_list('image_files');
    $self->build_list('template_files');

    return $self;
}

sub build_plugin_list {
    my $self = shift;
    my $list = [];
    my $expanded = {};
    $self->expand_list($list, $self->app_class, $expanded);

    $self->{_plugins} = $list;
}

sub expand_list {
    my ($self, $list, $plugin, $expanded) = @_;
    return if $expanded->{$plugin};
    $expanded->{$plugin} = 1;
    eval "use $plugin";
    die "use $plugin; error: $@"
        if $@ and $@ !~ /Can't locate/;
    unshift @$list, $plugin;
    my $adds = [];
    my $parent;
    {
        no strict 'refs';
        $parent = ${"${plugin}::ISA"}[0];
    }
    if ($plugin->isa('Cog::App')) {
        if ($plugin->webapp_class) {
            push @$adds, $plugin->webapp_class;
        }
        push @$adds, $parent
            unless $parent =~ /^(Cog::Base|Cog::Plugin)$/;
    }
    elsif ($plugin->isa('Cog::WebApp')) {
        push @$adds, $parent
            unless $parent =~ /^(Cog::Base|Cog::Plugin)$/;
    }
    push @$adds, @{$plugin->plugins};

    for my $add (@$adds) {
        $self->expand_list($list, $add, $expanded);
    }
}

sub build_list {
    my $self = shift;
    my $name = shift;
    my $list_list = shift || 0;
    my $finals = $self->$name;
    my $list = [];
    my $plugins = $self->_plugins;
    my $method = $list_list ? 'add_to_list_list' : 'add_to_list';
    for my $plugin (@$plugins) {
        my $function = "${plugin}::$name";
        next unless defined(&$function);
        no strict 'refs';
        $self->$method($list, &$function());
    }
    $self->$method($list, $finals);
    $self->{$name} = $list;
}

sub add_to_list {
    my ($self, $list, $adds) = @_;
    my $point = @$list;
    for my $add (@$adds) {
        if ($add eq '()') {
            $point = @$list = ();
        }
        elsif ($add eq '^^') {
            $point = 0;
        }
        elsif ($add eq '$$') {
            $point = @$list;
        }
        elsif ($add eq '++') {
            $point++ if $point < @$list;
        }
        elsif ($add eq '--') {
            $point-- if $point > 0;
        }
        elsif ($add =~ s/^(\-\-|\+\+) *//) {
            my $indicator = $1;
            for ($point = 0; $point < @$list; $point++) {
                if ($add eq $list->[$point]) {
                    splice(@$list, $point, 1)
                        if $indicator eq '--';
                    $point++
                        if $indicator eq '++';
                    last;
                }
            }
        }
        else {
            splice(@$list, $point++, 0, $add);
        }
    }
}

sub add_to_list_list {
    my ($self, $list, $adds) = @_;
    my $point = @$list;
    for my $add (@$adds) {
        if (not ref $add and $add eq '()') {
            $point = @$list = ();
        }
        else {
            splice(@$list, $point++, 0, $add);
        }
    }
}

sub build_class_share_map {
    my $self = shift;
    my $plugins = $self->_plugins;
    my $class_share_map = $self->_class_share_map;
    for my $plugin (@$plugins) {
        my $dir = $self->find_share_dir($plugin)
            or die "Can't find share dir for $plugin";
        $class_share_map->{$plugin} = $dir
            if $dir;
    }
}

sub find_share_dir {
    my $self = shift;
    my $plugin = shift;

    my $dist = $plugin->DISTNAME;
    my $modpath = "$dist.pm";
    $modpath =~ s!-!/!g;

    while (1) {
        my $dir = $INC{$modpath} or last;
        $dir =~ s!(blib/)?lib/\Q$modpath\E$!! or last;
        $dir .= "share";
        return $dir if -e $dir;
        last;
    }

    my $dir = eval { File::ShareDir::dist_dir($dist) };
    return $dir if $dir;

    return;
}

sub _build_files_map {
    my $self = shift;

    my $hash = {};

    my $plugins = $self->_plugins;

    for my $plugin (@$plugins) {
        my $dir = $self->_class_share_map->{$plugin} or next;
        for (io->dir($dir)->All_Files) {
            next if "$_" =~ /\.(sw[p]|packlist)$/;
            my $full = $_->pathname;
            my $short = $full;
            $short =~ s!^\Q$dir\E/?!! or die;
            $hash->{$short} = [$plugin => $full];
        }
    }

    return $hash;
}

use constant namespace_map => {
    'app/app_class' => 'app_class',
    'app/webapp_class' => 'webapp_class',
    'server/port' => 'server_port',
    'server/host' => 'server_host',
};
sub flatten_namespace {
    my ($class, $hash, $path) = @_;
    $path ||= '';
    my $map = $class->namespace_map;
    my $ns = {};
    for my $key (keys %$hash) {
        my $value = $hash->{$key};
        my $name = $path ? "$path/$key" : $key;
        if (ref($value) eq 'HASH') {
            $ns = { %$ns, %{$class->flatten_namespace($value, $name)} };
        }
        elsif ($map->{$name}) {
            $ns->{$map->{$name}} = $value;
        }
        else {
            my $root = $ns;
            my @keys = split '/', $name;
            my $leaf = pop @keys;
            for my $k (@keys) {
                $root = $root->{$k} = {};
            }
            $root->{$leaf} = $value;
        }
    }
    return $ns;
}

1;
