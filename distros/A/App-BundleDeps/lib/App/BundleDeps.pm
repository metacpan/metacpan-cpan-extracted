package App::BundleDeps;
use strict;
use warnings;
use local::lib ();
use Cwd ();
use ExtUtils::MakeMaker;
use File::Spec;

our $VERSION = '0.00006';

sub new {
    my ($class, @args) = @_;
    return bless { 
        extlib => File::Spec->catdir(File::Spec->curdir, 'extlib'),
        notest => 1,
        @args
    }, $class;
}

# XXX - accessors inlined for minimal setup
sub extlib {
    my $self = shift;
    $self->{extlib} = shift if @_;
    return $self->{extlib};
}

sub notest {
    my $self = shift;
    $self->{notest} = shift if @_;
    return $self->{notest};
}

sub deps {
    my $self = shift;
    $self->{deps} = shift if @_;
    return $self->{deps};
}

# given a META.yml file (if no arguments, looks for a META.yml in the current
# directory), does the proper dep bundling
sub bundle_from_meta {
    my ($self, $file) = @_;
    $file ||= 'META.yml';

    require YAML;
    require YAML::Dumper; # yeah, really, wtf
    my $meta = eval {
        YAML::LoadFile($file) 
    };
    if (! $meta || $@) {
        $@ ||= 'Unknown reason';
        die "Failed to load file $file: $@."
    }

    my $requires = $meta->{requires} || {};
    my $build_requires = $meta->{build_requires} || {};
    my %deps = (%{ $requires }, %{ $build_requires });
    $self->setup_deps(keys %deps);

    $self->bundle();
}

sub bundle_modules {
    my($self, @modules) = @_;

    $self->setup_deps(@modules);
    $self->bundle();
}

sub setup_deps {
    my ($self, @deps) = @_;

    @deps = grep { $_ ne 'perl' } sort @deps;
    $self->deps(\@deps);
}

sub bundle {
    my $self = shift;
    $self->bundle_deps();
}

sub bundle_deps {
    my $self = shift;

    $ENV{PERL5LIB} = ''; # detach existent local::lib
    local::lib->setup_local_lib_for( Cwd::abs_path( $self->extlib ) );

    # wtf: ExtUtils::MakeMaker shipped with Leopard is old
    if ($ExtUtils::MakeMaker::VERSION < 6.31) {
        $ENV{PERL_MM_OPT} =~ s/INSTALL_BASE=(.*)/$& INSTALLBASE=$1/;
    }

    # no man pages TODO: do the same with Module::Build
    $ENV{PERL_MM_OPT} .= " INSTALLMAN1DIR=none INSTALLMAN3DIR=none";
    $ENV{PERL_MM_USE_DEFAULT} = 1;

    # Remove /opt from PATH: end users won't have ports
    $ENV{PATH} = join ":", grep !/^\/opt/, split /:/, $ENV{PATH};

    my @cmd = ('cpanm', '--skip-installed');
    if ($self->notest) {
        push @cmd, '--notest';
    }
    push @cmd, @{ $self->deps };

    system(@cmd);
}

1;


__END__

=head1 NAME

App::BundleDeps - Bundle All Your Module Deps In A local::lib Dir

=head1 SYNOPSIS

    use App::BundleDeps;

    App::BundleDeps->new()->bundle_from_meta( 'META.yml' );

    # or

    my @modules = ( $module1, $module2, $module3, ... );
    App::BundleDeps->new()->bundle_modules( @modules );

=head1 DESCRIPTION

App::BundleDeps is a tool that allows you to "bundle" all your prerequisites in one local::lib installation. This is very useful when you want to deploy your application.

=head1 SCENARIO

Here, I'm going to show how to deploy a Catalyst application using App::BundleDeps and daemontools.

So, suppose you checked out / downloaded your production ready application here:

    /home/apps/MyApp-0.89

Move to that directory, and create your bundle:

    cd /home/apps/MyApp-0.89
    perl Makefile.PL NO_META=0
    perl -MApp::BundleDeps -e 'App::BundleDeps->new->bundle_from_meta("META.yml");'

You obviously have to have Makefile.PL setup so that it includes all the necessary prerequisites.

At this point you should have a directory named C<extlib>. Now prep your daemontools environemnt like so: First create the necessary directory structure (do it where svscan isn't watching)

    mkdir /var/lib/svscan/MyApp-0.89

Now move to that directory, and create a C<run> script file. We'll assume we're deploying a fastcgi server:

    #!/bin/sh
    MYAPP_DIR=/home/apps/MyApp-0.89
    PERL=/usr/local/bin/perl # I like to explicitly declare this, YMMV

    # XXX - You may have to specify MYAPP_HOME/MYAPP_CONFIG
    exec setuidgid app \
        $PERL \
        -Mlocal::lib=$MYAPP_DIR/extlib \
        $MAYPP_DIR/script/myapp_fastcgi.pl \
        -e \
        -l /path/to/socket \
        2>&1

You should probably set up run script for logging, but see the daemontools manual for that.

Now, create a symlink to where svscan is watching, typically /service or /etc/service:

    ln -s /var/lib/svscan/MyApp-0.89 /service/MyApp-0.89

And your service should start.

This is especially useful, because when you come up with MyApp-0.90, you can simply follow the same steps and deploy MyApp-0.90 with its own set of prerequisites (you don't have to care what MyApp-0.89 was using, or what the system installed module versions are!). When you checked that MyApp-0.90 is receiving the requests, just follow the following steps to unstage your previous app:

    rm /service/MyApp-0.89
    svc -dx /var/lib/svscan/MyApp-0.89
    svc -dx /var/lib/svscan/MyApp-0.89/log

Woohoo, done!

=head1 CAVEATS

=over 4

=item Prerequisites marked as "recommends" are not installed

=item Tests will not be run

=back

=head1 AUTHOR

Daisuke Maki - C<< <daisuke@endeworks.jp> >>

Miyagawa Tatsuhiko did the actual useful bits.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
