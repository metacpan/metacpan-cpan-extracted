package Cog::App;
use Mo qw'build default';
extends 'Cog::Base';

use Getopt::Long qw(:config pass_through);
use IO::All;
use YAML::XS;
use Cwd 'abs_path';
use File::Basename;
use File::Spec;

has Name => sub {
        my $Name = ref($_[0]);
        $Name =~ s/::App\b//;
        return $Name if $Name =~ /^\w+$/;
        die "Can't determine 'Name' attribute for '${\ref($_[0])}'";
    };

has app_script => basename $0;

has app_root => sub {
        my $root = abs_path(dirname($_[0]->config_file));
        return $root if -d $root;
        die "Can't determine 'app_root' for '${\ref($_[0])}'";
    };

has build_root => sub {
        $_[0]->app_root;
    };

has webapp_root => sub {
        my $root = $_[0]->app_root;
        File::Spec->catdir($root, 'webapp');
    };

has config_file => sub {
        abs_path($_[0]->app_script . '.yaml');
    };

use constant config_class => 'Cog::Config';
use constant maker_class => 'Cog::Maker';
use constant webapp_class => '';
use constant runner_class => 'Cog::Runner';

sub plugins { [] };

has action => ();
has time => time();

# If we use the generic 'bin/cog' script, we need to determine which Cog
# application class we are representing.
sub get_app_class {
    my ($class, @argv) = @_;
    my $app_class;
    @ARGV = @argv;
    Getopt::Long::GetOptions(
        'app=s' => \$app_class,
    );
    $app_class ||= $ENV{COG_APP} || $class;
    unless ($app_class->can('new')) {
        eval "use $app_class; 1"
            or die $@;
    }
    die "$app_class is not a Cog::App application"
        unless $app_class->isa('Cog::App') and
            $app_class ne 'Cog::App';

    return $app_class;
}

sub BUILD {
    my ($self) = @_;

    my $config_class = $self->config_class;
    eval "require $config_class"
        unless UNIVERSAL::can($config_class, 'new');

    my $config_file = $self->config_file;

    my $hash = $config_class->flatten_namespace(
        -e $config_file ? YAML::XS::LoadFile($config_file) : {}
    );
    my $app_class = $hash->{app_class} ||= ref($self);
    if ($app_class ne ref($self)) {
        eval "require $app_class; 1" or die $@;
        $self = $_[0] = $app_class->new();
    }

    $Cog::Base::initialize->(
        $self,
        $config_class->new(
            %$hash,
            app => $self,
            cli_args => [@ARGV],
        ),
    );
}

sub run {
    my $self = shift;

    $self->parse_command_args;

    my $action = $self->action;
    my $method = "handle_$action";

    my $function = $self->can($method)
        or die "'$action' is an invalid action\n";

    if ($action ne 'init') {
        die "Can't determine 'config_file' for '${\ref($_[0])}'"
          unless $self->config_file;
        $self->_chdir_root();
    }

    $function->($self);

    return 0;
}

sub parse_command_args {
    my $self = shift;
    my $argv = $self->config->cli_args;
    my $script = $self->app_script;
    $script =~ s!.*/!!;
    my $action = '';
    if ($script =~ /^(pre-commit|post-commit)$/) {
        $script =~ s/-/_/;
        $self->action($script);
    }
    elsif (@$argv and $argv->[0] =~ /^[\w\-]+$/) {
        $action = shift @$argv;
        $action =~ s/-/_/g;
    }
    elsif (not @$argv) {
        $action = 'help';
    }
    else {
        die "Invalid cog command. Can't parse these arguments: '@_'";
    }
    $self->action($action);
}

#-----------------------------------------------------------------------------
sub handle_help {
    my $self = shift;
    print $self->usage;
}

sub usage {
    my $self = shift;
    my $Name = $self->Name;
    my $name = $self->app_script;
    $name =~ s!.*/!!;
    return <<"...";
Usage: $name <command>

Commands:
    init   - Make current directory into a $Name app
    update - Update the app with the latest assets
    make   - Prepare the app content for the web
    start  - Start the local app server
    stop   - Stop the server

...
}

sub handle_init {
    my $self = shift;
    my $root = $self->app_root;
    die "Can't init. Cog environment already exists.\n"
        if $self->config->is_init;
    my $share = $self->config->find_share_dir($self);

    my $config_file = $self->config_file;
    if (not -e $config_file) {
        require Template::Toolkit::Simple;
        my $data = +{%$self};
        $data->{app_class} = ref($self);
        my $config = Template::Toolkit::Simple::tt()
            ->path(["$share/template/"])
            ->data($data)
            ->post_chomp
            ->render('config.yaml');
        io($config_file)->print($config);
    }

    $self->_chdir_root;

    my $Name = $self->Name;
    my $name = $self->app_script;
    $name =~ s!.*/!!;

    print <<"...";

$Name was successfully initialized in:

    $root

The next step is to edit:

    $config_file

Then run:

    $name update

...
}

sub handle_update {
    my $self = shift;
    my $root = $self->app_root;

    $self->maker->make_assets();

    my $Name = $self->Name;
    my $name = $self->app_script;
    $name =~ s!.*/!!;

    print <<"...";
$Name was successfully updated in the $root/ subdirectory.

Now run:

    $name make

...
}

sub handle_make {
    my $self = shift;
    $self->maker->make;
    my $Name = $self->Name;
    my $name = $self->app_script;
    $name =~ s!.*/!!;
    print <<"...";

$Name is up to date and ready to use.
To start the web server, run this command:

    $name start

...

}

sub handle_start {
    my $self = shift;
    my $Name = $self->Name;
    print <<"...";
$Name web server is starting up...

...
    my @args = @{$self->config->cli_args};
    unshift @args, ('-p' => $self->config->server_port)
        if $self->config->server_port;
    $self->runner->run(@args);
}

sub handle_stop {
    die 'TODO';
}

sub handle_edit {
    die 'TODO';
}

sub handle_clean {
    my $self = shift;
    $self->maker->make_clean;
    my $Name = $self->Name;
    my $name = $self->app_script;
    $name =~ s!.*/!!;
    print <<"...";

$Name is clean. To rebuild, run this command:

    $name update

...

}

# Put the App in the context of its defined root directory.
sub _chdir_root {
    my $self = shift;
    my $app_root = $self->app_root;
    chdir $app_root
      or die "Can't chdir into $app_root";
}

1;
