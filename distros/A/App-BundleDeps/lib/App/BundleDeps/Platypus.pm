package App::BundleDeps::Platypus;
use strict;
use warnings;
use base qw(App::BundleDeps);
use File::Path qw(rmtree);

foreach my $elem qw(app author icon identifier platypus resources default_resources script version background) {
    my $str = "sub $elem { my (\$self, \@args) = \@_; my \$ret = \$self->{$elem}; \$self->{$elem} = shift \@args if \@args; return \$ret }";
    eval $str;
    die if $@;
}

sub new {
    my ($class, @args) = @_;

    my $self = $class->SUPER::new(
        author => $ENV{USER},
        icon   => 'appIcon.icns',
        resources => [],
        background => 0,
        @args,
        default_resources => [ 'lib', 'extlib' ]
    );

    if (! $self->app) {
        my $script = $self->script;
        $script =~ s/\.plx?$//;
        $self->app( join " ", map ucfirst, split /[ _\-]/, $script);
    }

    if (! $self->identifier) {
        my $app = $self->app;
        $app =~ tr/ //d;
        $self->identifier( "com.example." . $self->author . ".app");
    }
    return $self;
}

sub bundle {
    my $self = shift;
    $self->SUPER::bundle();
    $self->build_platypus_app();
}

sub build_platypus_app {
    my $self = shift;

    my $app_path = $self->app . ".app";
    if (-e $app_path) {
        rmtree($app_path);
    }

    my $output =`platypus -v`;
    if ($output !~ /version (\d+\.\d+) by/) {
        print STDERR "Could not get version from platypus: Did you install the command line utility?\n";
        return;
    }
    my $version = $1;

    print "Building Mac application ", $self->app, ".app ...";
    system "platypus",
        "-a", $self->app, "-o", 'None', "-u", $self->author,
        "-p", $^X, "-s", '????',
        (-e $self->icon ? ("-i", $self->icon) : ()),
        "-I", $self->identifier,
        "-N", "APP_BUNDLER=Platypus-4.0",
        (map { ("-f", "$_") } @{$self->resources}, @{$self->default_resources}),
        "-c", $self->script,
        ($self->background ? "-B" : ()),
        "-V", $self->version,
        File::Spec->catfile( File::Spec->curdir, $app_path );
}


1;

__END__

=head1 NAME

App::BundleDeps::Platypus - Bundle Your App Via Platypus

=head1 SYNOPSIS

    App::BundleDeps::Platypus->new(
        script => 'myapp.pl',
        version => $version,
        # everything else is optional
        app => $appname,
        author => $author,
        icon => $icon,
        identifier => $identifier,
        resources => \@list,
        background => $bool,
    )->bundle_from_meta();

=cut