package Catalyst::Plugin::ConfigLoader::MultiState;
use parent qw/Class::Accessor::Grouped/;
use strict;
use Carp();
use Storable();

our $VERSION = 0.08;

=head1 NAME

Catalyst::Plugin::ConfigLoader::MultiState - Convenient and flexible config
loader for Catalyst.

=head1 SYNOPSIS

    conf/myapp.conf:

    $db = {
        host     => 'db.myproj.com',
        driver   => 'Pg',
        user     => 'ilya',
        password => 'rumeev',
    };

    $var_dir = r('home')->subdir('var');
    $log_dir = $var_dir->subdir('log'); $log_dir->mkpath(0, 0755);

    rw(host, 'mysite.com');
    $uri = URI->new("http://$host");

    ...

    conf/chat.conf

    $history_cnt = 10;
    $tmp_dir = r(var_dir)->subdir('chat');
    $service_uri = URI->new( r(uri)->as_string .'/chat' );
    ...

    conf/myapp.dev

    $db = {host => 'dev.myproj.com'};
    rewrite(host, 'dev.mysite.com');
    ...other differences

    in MyApp:

    my $cfg = MyApp->config;
    print $cfg->{db}{user}; # ilya
    print $cfg->{db}{host}; # db.myproj.com
    print $cfg->{chat}{tmp_dir}; # Path::Class::Dir object (/path/to/myapp/var/chat)
    print $cfg->{host}; # mysite.com
    print $cfg->{uri}; # URI object http://mysite.com
    print $cfg->{chat}{service_uri}; # URI object (http://mysite.com/chat)

    Now if in local.conf:

    $dev = 1;

    Then

    print $cfg->{db}{user}; # ilya
    print $cfg->{db}{host}; # dev.myproj.com
    print $cfg->{host}; # dev.mysite.com
    print $cfg->{uri}; # URI object http://dev.mysite.com (magic :-)
    print $cfg->{chat}{service_uri}; # URI object http://dev.mysite.com/chat (more magic)


    Configure a plugin (Authentication for example)

    in conf/Plugin-Authentication.conf:

    module();

    $default_realm = 'default';
    $realms = {
        ...
    };


=head1 DESCRIPTION

This plugin provides you with powerful config system for your catalyst project.

It allows you to:

- write convenient variable definitions - your lovest perl language :-) What can be
  more powerful? You do not need to define a huge hash in config file -
  you just write separate variables.

- split your configs into separate files, each file with its own namespace
  (hash depth) or without - on your choice.

- access variables between configs. You can access any variable in any config
  by uri-like or hash path.

- overload your config hierarchy by *.<group_name> files on demand

- rewrite any previously defined variable. Any variables that depend on initial
  variable (or on variable that depends on inital, etc) will be recalculated in
  all configs.

- automatic overload for development servers

This is very useful for big projects where your config might grow over 100kb.
Especially when you have number of installations of application that must differ
from other without pain to redefine a hundreds of config variables in '_local' file
which, in addition to all, cannot be put in svn (cvs).

In most of cases this plugin has to be the first in plugin list.

=head1 Config syntax

Syntax is quite simple - it's perl. Just define variable with desired names.

$var_name = 'value';

Values can be any that scalars can be: scalar, hashref, arrayref, subroute, etc.
DO NOT write 'use strict' or you will be forced to define variables via 'our'
which is ugly for config.

If you define in myapp.conf (root config)

    $welcome_msg = 'hello world';

it will be accessible through

    MyApp->config->{welcome_msg}

Hashes acts as they are expected:

    $msgs = {
        welcome => 'hello world',
        bye     => 'bye world',
    };

    MyApp->config->{msgs}{bye};

It is a good idea to reuse variables in config to allow real flexibility:

    $var_dir = $home->subdir('var');
    $log_dir = $var_dir->subdir('log');
    $chat_log_dir = $log_dir->subdir('chat');
    ...

In contrast to:

    $var_dir = 'var';
    $log_dir = 'log';
    $chat_log_dir = 'chat';

or

    $var_dir = 'var';
    $log_dir = 'var/log';
    $chat_log_dir = 'var/log/chat';
    ...will grow :(

The second and third examples are much less flexible.
By means of second example we just hardcoded a part of config logic in our
application: it supposes that var_dir is UNDER home and log_dir is UNDER var_dir, etc,
which must not be an application's headache anyway. In third example we have a lot
of copy-paste and application still supposes that var_dir is under home.

=head1 Namespaces

All configs from files are written to separate namespaces by default (except for /myapp.*).
Plugin reads all *.conf files in folder 'conf' under app_home
(or whatever you set ->config->{'Plugin::ConfigLoader::MultiState'}{dir} to),
subdirs too - recursively, and special local config from file local.conf under app_home
(or whatever you set ->config->{'Plugin::ConfigLoader::MultiState'}{local} to).
Configs from /myapp.* and local.conf are written directly to root namespace (config hash).
Other configs are written accordingly to their paths.
For example config from chat.conf is written to $cfg->{chat} hash.
Config from test/more.conf is written to $cfg->{test}{more} hash.

Sometimes you don't want separate namespace, just split one big file to parts.
In this case you can use 'root' or 'inline' pragmas.
'root' pragma brings config file to the root namespace no matter where file is located.
'inline' brings file to one level upper.

Examples:

split root config:

/myapp.conf:

    ...part of definitions

/misc.conf:

    root;
    ...other part of definitions

split /chat.conf:

/chat/main.conf:

    inline;
    ...definitions

/chat/ban_rules.conf

    inline;
    ...definitions

=head2 Catalyst plugins configuration

To make configuration for catalyst plugin in separate file, name it after plugin
class name replacing '::' with '-' and use 'module' pragma;

For example Plugin-Authentication.conf:

    module;
    $default_realm = 'myrealm';
    $realms = {
        ....
    };

To embed plugin's config into any root ns file write __ instead of ::

    $Plugin__Authentication = {
        default_realm => 'myrealm',
        realms        => {...},
    };

=head1 Accessing variables from other config files

Files of each group (*.conf, *.dev, *.<group_name>) are processed in alphabetical
order (except for local.conf and myapp.conf - they are processed earlier).

Special file app_home/local.conf is processed twice - at start and in the end to have a
chance to pre-define something (config file groups for example) in the beggining
and rewrite/overload in the end.

You can access variable from any file that has already been processed (use test-like
namings: 01chat.conf, 02something.conf, ... - if it is matters, plugin removes ^\d+ from ns).

To access variable in root namespace use r() getter:

    $mydir = r('var_dir')->subdir('my');

Quotes is not required (for beauty):  r(var_dir)-> but be careful - variable name
must be allowed perl unqouted literal and must not be one of perl builtin functions
and not one of [root, inline, r, p, u, l, module, rw, rewrite], therefore this is not recommended.

To access variable in local (current) namespace use l() getter.

To access variable in upper namespace use u() getter.

To access any variable use p() getter with uri-like path:

    p('/chat/history_cnt') || r('chat')->{history_cnt}

To access variables initially defined by catalyst (home, root, pre-defined config variables)
use r('home'), r('root'), etc from anywhere. Note that MultiState tunes 'home'
variable - it makes it a Path::Class::Dir object instead of simple string.

=head1 Merging

If a config defines variable that already exists (in the same namespace)
it will be merged with existing variable (merged if both are hashes and replaced if not).
If you have variables in configs that depend on initial variable - SEE 'rewrites' section
or they won't be updated!

=head1 Overload

Configs can be overloaded by file or group of files that are not loaded by default.
The example is *.dev group which is activated when you predefine

    $dev=1;

in local.conf (or in MyApp->config before setup phase)

To activate other group(s) you must predefine it in local.conf (or in MyApp->config
before setup phase)

    $config_group = ['.beta']; #i'am one of beta-servers

Config will be overloaded from conf/*.beta, conf/*/*.beta,... after processing
standart configs (i.e. all config variables are accessible to *.beta files to
read and overload/rewrite). Group is dot plus files extension.

In myapp.beta for example:

    $db = {host => 'beta.myproj.com'};
    $debug = {enabled => 1};
    rewrite('base_price', 0);
    ...

In chat.beta for example:

    $welcome_msg = l('welcome_msg') . ' (beta server)';

All of the rules described above are applicable to all configs in any groups
(i.e. namespaces, visibility, etc).

You can define config groups in application's code as well as in local.conf.
To do that just define MyApp->config->{config_group} = [...] BEFORE setup()
(runtime overloading is not supported for now).

There is a way to define that in offline scripts and other places that use your
application (there are not only myapp_server.pl and Co :-) to customize your
application's behaviour:

Create this sub in MyApp.pm:

    sub import {
        my ($class, $rewrite_cfg) = @_;
        _merge_hash($class->config, $rewrite_cfg) if $rewrite_cfg;
    }

    sub _merge_hash {
        my ($h1, $h2) = (shift, shift);
        while (my ($k,$v2) = each %$h2) {
            my $v1 = $h1->{$k};
            if (ref($v1) eq 'HASH' && ref($v2) eq 'HASH') { merge_hash($v1, $v2) }
            else { $h1->{$k} = $v2 }
        }
    }

And just write in an offline script/daemon:

    use MyApp {
        log => {file => 'otherlog.log'},
        something => 'something',
        config_group => [qw/.script .maintenance/],
    };

But there is a big problem. By writing

    __PACKAGE__->setup();

in MyApp.pm we just left no chances for others to customize your application
BEFORE setup phase because 'use MyApp' will at the same time execute setup() before
import()

Fortunately there is a simple solution: not to write '__PACKAGE__->setup()' :-).
Instead write:

    sub import { #for places that do 'use MyApp'
        my ($class, $rewrite_cfg) = @_;
        _merge_hash($class->config, $rewrite_cfg) if $rewrite_cfg;
        $class->setup unless $class->setup_finished;
    }

    sub run { #myapp_server.pl does 'require MyApp', not 'use', so import() is not called
        my $class = shift;
        $class->setup unless $class->setup_finished;
        $class->next::method(@_);
    }

    sub _merge_hash {
        my ($h1, $h2) = (shift, shift);
        while (my ($k,$v2) = each %$h2) {
            my $v1 = $h1->{$k};
            if (ref($v1) eq 'HASH' && ref($v2) eq 'HASH') { merge_hash($v1, $v2) }
            else { $h1->{$k} = $v2 }
        }
    }

That's all. Now 'use MyApp {...}' will work. This is very useful to customize
config in service(script)-based way without creating configuration for them in
main config. For example to easily change log file or loglevel as in example above.

Also single-file overloading is also supported.

    $config_group = ['.beta', 'service', 'maintenance'];

Loads *.beta, 'service.rw' and 'maintenance.rw'. I.e. group is filename without
extension (loads filename plus '.rw')

=head1 Rewriting variables

'Rewrite' must be used when you want to overload some variable's value and you want
all variables that depend on it to be recalculated.

For example if you write in myapp.conf:

    $a = 1;
    $b = $a+1;

and in myapp.dev:

    $a = 10;

then (on dev server)

    $cfg->{a}; #10
    $cfg->{b}; #2

oops (!) :-)

'Rewrite' fixes that!

myapp.conf:

    rw(a, 1);
    $b = $a+1;

myapp.dev:

    rewrite(a, 10);

    $cfg->{a}; #10
    $cfg->{b}; #11

=head2 Syntax

    rw('variable_name', value_to_set);

Tells plugin that 'variable_name' is a rewritable variable. Also creates
$variable_name and sets it to value_to_set. The effect is similar to

    $variable_name = value_to_set;

but do not write that or rewrite will not work!

    rewrite(' /uri/path | relative/path ', value_to_set);

Rewrites variable. Uri path can be absolute or relative to current namespace
(namespace of the file where 'rewrite' is). It will croak if this variable is not
marked as rewritable.

You can even rewrite properties of objects. Actually you may pass any code that is
related to rewrite variable's value/properties to 'rewrite' function. Example:

myapp.conf:

    rw('uri', URI->new("http://mysite.com/preved"));
    $uri2 = URI->new($uri->as_string.'/medved');

myapp.dev:

    rewrite('uri', sub { r('uri')->path('poka') });

Result:

    $cfg->{uri};  # http://mysite.com/poka
    $cfg->{uri2}; # http://mysite.com/poka/medved

Looks ok :-)

=head1 METHODS

=over

=item dev

    Development server flag. $c->dev is true if current installation is development.
    Also available through $c->cfg->{dev}.

=item cfg

    Fast accessor for getting config hash.
    It is 70x faster than original ->config method.

=item setup

    Called by catalyst at setup phase. Reads files and initializes config.

=item finalize_config

This method is called after the config file is loaded. It can be used to implement
tuning of config values that can only be done at runtime.

This method has been added for compability.

=back

=head1 Defaults

    You can predefine defaults for config in ->config->{'Plugin::ConfigLoader::MultiState'}{defaults}.
    Variables from 'defaults' will be visible in config but won't override resulting values.

=head1 Startup perfomance

    It takes about 30ms to initialize config system with 25 files (25kb summary)
    on 2Ghz Xeon.

=head1 SEE ALSO

L<Catalyst::Runtime>, L<Catalyst::Plugin::ConfigLoader>.

=head1 AUTHOR

Pronin Oleg <syber@cpan.org>

=head1 LICENSE

You may distribute this code under the same terms as Perl itself.

=cut

__PACKAGE__->mk_group_accessors(inherited => qw/cfg dev/);

sub setup {
    my $class = shift;
    #my $start = Time::HiRes::time();

    my $stash = $class->config;
    $class->cfg($stash);
    my $self_cfg = $stash->{'Plugin::ConfigLoader::MultiState'} || {};
    my @groups = @{$stash->{config_group}||[]};
    my %groups_seen = map {$_ => 1} @groups;

    my $conf_dir = $class->path_to('')->subdir($self_cfg->{dir} || 'conf'); #Avoid retrieving Path::Class::File object
    my $files = Catalyst::Plugin::ConfigLoader::MultiState::Utils::get_file_list($conf_dir, '', lc($class));

    my %confs;
    foreach my $row (@$files) {
        if ($row->[2] eq 'rw') {
            $confs{rw}{join('/', @{$row->[1]})} = [$row->[0], $row->[1]];
            pop(@{$row->[1]});
        }
        else {
            push @{$confs{$row->[2]}}, [$row->[0], $row->[1]];
        }
    }

    $stash->{home} = Path::Class::Dir->new($stash->{home});
    my $defaults = delete $stash->{'Plugin::ConfigLoader::MultiState'}{defaults};
    my $initial_cfg = Storable::dclone($stash);
    Catalyst::Plugin::ConfigLoader::MultiState::Utils::merge_hash($stash, $defaults) if $defaults;
    my $local = $class->path_to($self_cfg->{'local'} || 'local.conf');
    $local->touch unless -e $local;

    my $state = {};
    $class->_config_execute($local, [], $stash, $state);
    my @list;
    push @list, @{$confs{conf}} if $confs{conf};

    unshift @groups, grep {!exists $groups_seen{$_}} @{delete($stash->{config_group})||[]};
    unshift @groups, '.dev' if $stash->{dev};
    $class->dev($stash->{dev});

    foreach my $group (@groups) {
        if (substr($group, 0, 1) eq '.') {
            substr($group, 0, 1, '');
            my $files = $confs{$group};
            push @list, @$files if $files;
        }
        else {
            my $file = $confs{rw}{$group};
            push @list, $file if $file;
        }
    }

    push @list, [$local, []];
    my $double_required;
    $class->_config_execute(@$_, $stash, $state) and $double_required=1 for @list;

    if ($double_required) {
        $state->{double} = 1;
        $class->_config_execute(@$_, $stash, $state) for @list;
    }

    Catalyst::Plugin::ConfigLoader::MultiState::Utils::merge_hash($stash, $initial_cfg);

    $class->finalize_config if $class->can('finalize_config');
    #print "ConfigSuite Init took ".((Time::HiRes::time() - $start)*1000)."\n";
    $class->next::method(@_);
}

sub _config_execute {
    my ($class, $file, $ns, $stash, $state) = (shift, shift, shift, shift, shift);

    my $pkg = $file; $pkg =~ tr!-/.~\!@#$%^&*()+\\:!_!;
    $pkg = 'Catalyst::Plugin::ConfigLoader::MultiState::Package::'.lc($class).'::'.$pkg;

    $ns = [@$ns];
    $ns = [] if @$ns == 1 and $ns->[0] eq lc($class);
    no strict 'refs';

    my ($local_stash, $upstash);
    my $select_stash = sub {
        $local_stash = $upstash = $stash;
        $local_stash = (($upstash = $local_stash)->{$_} ||= {}) for @$ns;
    };
    $select_stash->();

    my $double_required;

    unless (0 && $pkg->can('r')) { #redefine for closures to refresh closured variables
        no warnings 'redefine';
        *{"${pkg}::r"} = sub {$stash->{$_[0]}};
        *{"${pkg}::u"} = sub {$upstash->{$_[0]}};
        *{"${pkg}::l"} = sub {$local_stash->{$_[0]}};

        *{"${pkg}::root"} = sub {
            #return if $state->{double};
            $ns = [];
            $select_stash->();
        };

        *{"${pkg}::inline"} = sub {
            #return if $state->{double};
            pop(@$ns);
            $select_stash->();
        };

        *{"${pkg}::module"} = sub {
            #return if $state->{double};
            return unless @$ns;
            delete $upstash->{$ns->[$#$ns]};
            $ns->[$#$ns] =~ s/-/::/g;
            $select_stash->();
        };

        *{"${pkg}::rw"} = sub {
            my $var_name = $_[0];
            my $var_ns = '/'.join('/', @$ns, $var_name);
            $state->{rw}{$var_ns} ||= {};

            if (exists $local_stash->{$var_name}) {
                ${"${pkg}::$var_name"} = $local_stash->{$var_name};
                return;
            }

            ${"${pkg}::$var_name"} = $_[1];
        };

        *{"${pkg}::rewrite"} = sub {
            my $var_ns = shift;
            $var_ns = '/'.join('/', @$ns, $var_ns) unless $var_ns =~ /^\//;
            Carp::croak "Variable $var_ns is not marked for rewrite"
                unless exists $state->{rw}{$var_ns};
            return if exists $state->{rw}{$var_ns}{$pkg};
            my @var_ns = split('/', $var_ns);
            my $var_name = pop(@var_ns);
            my $cur_stash = $local_stash;
            foreach my $ns_part (@var_ns) {
                $cur_stash = $stash, next unless $ns_part;
                Carp::croak "Bat path $var_ns - variable not found"
                    unless ref($cur_stash = $cur_stash->{$ns_part}) eq 'HASH';
            }
            $double_required = 1;
            if (@_) {
                if (ref $_[0] eq 'CODE') { $_[0]->() }
                elsif (ref $_[0] eq 'HASH' and ref $cur_stash->{$var_name} eq 'HASH') {
                    Catalyst::Plugin::ConfigLoader::MultiState::Utils::merge_hash($cur_stash->{$var_name}, $_[0]);
                }
                else { $cur_stash->{$var_name} = $_[0] }
            }
            $state->{rw}{$var_ns}{$pkg} = 1;
        };

        *{"${pkg}::p"} = sub {
            my $var_ns = shift;
            $var_ns = '/'.join('/', @$ns, $var_ns) unless $var_ns =~ /^\//;
            my @var_ns = split('/', $var_ns);
            my $var_name = pop(@var_ns);
            my $cur_stash = $local_stash;
            foreach my $ns_part (@var_ns) {
                $cur_stash = $stash, next unless $ns_part;
                Carp::croak "Bat path $var_ns - variable not found"
                    unless ref($cur_stash = $cur_stash->{$ns_part}) eq 'HASH';
            }
            return $cur_stash->{$var_name};
        };
    }

    {
        unless ($state->{subs}{$pkg}) {
            open (my $fh, '<', $file.'') or die $!;
            my $content = join('', <$fh>);
            close $fh;

            $state->{subs}{$pkg} = eval "
                package $pkg;
                no strict;
                sub {
                    no warnings qw/uninitialized void once redefine/;
                    $content;
                };
            ";
            die "ConfigLoader: WARNING! Config DIED ($file): $@" if $@;
        }
        eval {$state->{subs}{$pkg}->(); 1}
            or die "ConfigLoader: WARNING! Config DIED ($file): $@";
    }

    foreach my $key (keys %{"${pkg}::"}) {
        next if $key eq 'BEGIN' or $key eq 'DESTROY' or $key eq 'AUTOLOAD' or
                $key =~ /^__ANON__\[/;
        my $val = ${"${pkg}::$key"};
        next if !defined $val and $key =~ /^(root|inline|module|r|u|l|p|rw|rewrite|can)$/;
        $key =~ s/__/::/g if index($key, '__') > 0;
        my $oldval = $local_stash->{$key};
        if (ref($val) eq 'HASH' and ref($oldval) eq 'HASH') {
            Catalyst::Plugin::ConfigLoader::MultiState::Utils::merge_hash($oldval, $val);
        }
        else {
            $local_stash->{$key} = $val;
        }
    }

    return $double_required;
}

package
    Catalyst::Plugin::ConfigLoader::MultiState::Utils;
use strict;
use File::Spec::Functions qw/catdir catfile splitdir/;

sub get_file_list {
    my $root = shift;
    my $subdir = shift;
    my $class = shift;
    my (@list, @folders);
    my $dir = catdir($root, $subdir);
    opendir (my $dh, $dir) or warn("Cannot open config directory $dir: $!"), return;
    foreach my $row (
        sort {
            ($b->[2] eq $class) <=> ($a->[2] eq $class) or
                    lc($a->[2]) cmp lc($b->[2]) or
                        $a->[1] <=> $b->[1]
        }
        map {
            my $entry = $_;
            my $path = catfile($dir, $entry);
            my $is_dir = -d $path ? 1 : 0;
            my $ext;
            $ext = $1 if !$is_dir and $entry =~ s/\.([^.]+)$//;
            [$path, $is_dir, $entry, $ext];
        }
        grep {index($_, '.')} readdir $dh
    ) {
        push(@list, @{ get_file_list($root, catdir($subdir, $row->[2]), $class) }), next
            if $row->[1];
        push @list, [$row->[0], [grep {s/^\d+(\D)/$1/; $_} splitdir($subdir), $row->[2]], $row->[3]];
    }
    closedir $dh;
    return \@list;
}

sub merge_hash {
    my ($hash1, $hash2) = (shift, shift);

    while (my ($k,$v2) = each %$hash2) {
        my $v1 = $hash1->{$k};
        if (ref($v1) eq 'HASH' && ref($v2) eq 'HASH') { merge_hash($v1, $v2) }
        else { $hash1->{$k} = $v2 }
    }
}

1;
