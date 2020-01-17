package MyContainer;

use Modern::Perl;

use Carp qw(confess);

sub new {
    my $class = ref $_[0] || $_[0]; shift;
    my $self = bless {}, $class;
    $self;
}

sub import {
    my $class = ref $_[0] || $_[0]; shift;
    my $name  = $_[0] || 'container';
    my $pkg   = caller;

    no strict 'refs';
    no warnings 'redefine';
    *{"${pkg}::${name}"} = sub {
        #             container('name') or
        #         $c->container('name') or
        # MyApp::Web->container('name') or
        # MyApp::Web::container('name')
        shift if @_ and ( ref $_[0] || $_[0] ) eq $pkg;

        if (@_) {
            my $method = shift;
            unless ($class->instance->can($method)) {
                confess "such a method not exists. ${class}::$method";
            }
            $class->instance->$method(@_);
        }
        else {
            $class->instance;
        }
    };
}

sub instance {
    my $class = shift;
    no strict 'refs';
    ${"${class}::INSTANCE"} ||= $class->new;
}

########################################################################

use Cwd qw(abs_path);
use File::Spec::Functions qw(catdir catfile splitdir);
use Module::Runtime qw(use_module);

sub app_class {
    my $self = shift;
    $self->{app_class} //= ref($self) =~ s/::[^:]+$//r;
}

sub app_class_lc {
    my $self = shift;
    $self->{app_class_lc} //= lc $self->app_class;
}

sub app_home {
    my $self = shift;

    $self->{app_home} //= do {
        my $file = ref($self) =~ s/::/\//gr . '.pm';
        my $path = $INC{$file} or die;
        $path =~ s/$file$//;
        my @home = splitdir $path;
        pop @home while @home && ($home[-1] =~ /^(lib|blib|inc)$/ || $home[-1] eq '');
        abs_path(catdir(@home) || '.');
    };
}

sub config {
    my $self = shift;

    $self->{config} //= do {
        my $dir   = catdir($self->app_home, 'etc');
        my @files = (
            catfile($dir, "@{[$self->app_class_lc]}.pl"),
            catfile($dir, "@{[$self->app_class_lc]}_local.pl"),
        );
        use_module('Config::Merged')->load_files( { files => \@files, use_ext => 1 } );
    };
}

1;
