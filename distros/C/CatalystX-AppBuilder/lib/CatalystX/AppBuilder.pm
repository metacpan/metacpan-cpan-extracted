package CatalystX::AppBuilder;
use Moose;
use namespace::clean -except => qw(meta);

our $VERSION = '0.00011';

has appname => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has appmeta => (
    init_arg => undef,
    is => 'ro',
    isa => 'Moose::Meta::Class',
    lazy_build => 1
);

has debug => (
    is => 'ro',
    isa => 'Bool',
    default => 0,
);

has version => (
    is => 'ro',
    isa => 'Str',
    required => 1,
    lazy_build => 1,
);

has superclasses => (
    is => 'ro',
    isa => 'Maybe[ArrayRef]',
    required => 1,
    lazy_build => 1,
);

has config => (
    is => 'ro',
    isa => 'HashRef',
    lazy_build => 1,
);

has plugins => (
    is => 'ro',
    isa => 'ArrayRef',
    lazy_build => 1,
);

sub _build_version      { '0.00001' }
sub _build_superclasses { [ 'Catalyst' ] }
sub _build_config {
    my $self = shift;
    my %config = (
        name => $self->appname,
    );
    return \%config;
}

sub _build_plugins {
    my $self = shift;
    my @plugins = qw(ConfigLoader);
    if ($self->debug) {
        unshift @plugins, '-Debug';
    }
    return \@plugins;
}

sub BUILD {
    my $self = shift;

    my $appname = $self->appname;
    my $meta = Moose::Util::find_meta( $appname );
    if (! $meta || ! $appname->isa('Catalyst') ) {
        if ($self->debug) {
            print STDERR "Defining $appname via " . (blessed $self) . "\n";
        }
        $meta = Moose::Meta::Class->create(
            $appname => (
                version => $self->version,
                superclasses => $self->superclasses
            )
        );

        if ($appname->isa('Catalyst')) {
            # Don't let the base class fool us!
            delete $appname->config->{home};
            delete $appname->config->{root};
        }
        # Fugly, I know, but we need to load Catalyst in the app's namespace
        # for many things to take effect.
        eval <<"        EOCODE";
            package $appname;
            use Catalyst;
        EOCODE
        die if $@;
    }
    return $meta;
}

sub bootstrap {
    my $self = shift;
    my $runsetup = shift;
    my $appclass = $self->appname;

    if (! $runsetup) {
        # newer catalyst now uses Catalyst::ScriptRunner.
        # run setup if we were explicitly asked for, or we were called from
        # within Catalyst::ScriptRunner
        my $i = 1;
        $runsetup = 1;
        while (my @caller = caller($i++)) {
            my $package = $caller[0];
            my $sub     = $caller[3];

            # DO NOT run setup if we're being recursively called from
            # an inherited AppBuilder
            if ($package->isa('Class::MOP::Class')) {
                if ($sub =~ /superclasses$/) {
                    $runsetup = 0;
                    last;
                }
            } elsif ($package->isa('Catalyst::ScriptRunner')) {
                last;
            } elsif ($package->isa('Catalyst::Restarter')) {
                last;
            }
        }
    }

    if ($runsetup) {
        my @plugins;
        my %plugins;
        foreach my $plugin (@{ $self->plugins }) {
            if ($plugins{$plugin}++) {
                warn "$plugin appears multiple times in the plugin list! Ignoring...";
            } else {
                push @plugins, $plugin;
            }
        }

        $appclass->config( $self->config );
        $appclass->setup( @plugins );
    }
}

sub inherited_path_to {
    my $self = shift;

    # XXX You have to have built the class
    my $meta = Moose::Util::find_meta($self->appname);

    my @inheritance;
    foreach my $class ($meta->linearized_isa) {
        next if ! $class->isa( 'Catalyst' );
        next if $class eq 'Catalyst';

        push @inheritance, $class;
    }

    my @paths = @_;
    return map {
        my $m = $_;
        $m =~ s/::/\//g;
        $m .= '.pm';
        my $f = Path::Class::File->new($INC{$m})->parent;
        DESCENT: while ($f) {
            for my $stopper (qw(Makefile.PL Build.PL dist.ini minil.toml)) {
                if (-f $f->file($stopper)) {
                    $f = $f->subdir(@paths)->stringify;
                    last DESCENT;
                }
            }
            last if $f->stringify eq $f->parent->stringify;
            $f = $f->parent;
        }
        $f;
    } @inheritance;
}

sub app_path_to {
    my $self = shift;

    return $self->appname->path_to(@_)->stringify;
}
    

__PACKAGE__->meta->make_immutable();

1;


__END__

=head1 NAME

CatalystX::AppBuilder - Build Your Application Instance Programatically

=head1 SYNOPSIS

    # In MyApp.pm
    my $builder = CatalystX::AppBuilder->new(
        appname => 'MyApp',
        plugins => [ ... ],
    )
    $builder->bootstrap();

=head1 DESCRIPTION

WARNING: YMMV regarding this module.

This module gives you a programatic interface to I<configuring> Catalyst
applications.

The main motivation to write this module is: to write reusable Catalyst
appllications. For instance, if you build your MyApp::Base and you wanted to
create a new application afterwards that is I<mostly> like MyApp::Base, 
but slightly tweaked. Perhaps you want to add or remove a plugin or two.
Perhaps you want to tweak just a single parameter.

Traditionally, your option then was to use catalyst.pl and create another
scaffold, and copy/paste the necessary bits, and tweak what you need.

After testing several approaches, it proved that the current Catalyst 
architecture (which is Moose based, but does not allow us to use Moose-ish 
initialization, since the Catalyst app instance does not materialize until 
dispatch time) did not allow the type of inheritance behavior we wanted, so
we decided to create a builder module around Catalyst to overcome this.
Therefore, if/when these obstacles (to us) are gone, this module may
simply dissappear from CPAN. You've been warned.

=head1 HOW TO USE

=head2 DEFINING A CATALYST APP

This module is NOT a "just-execute-this-command-and-you-get-catalyst-running"
module. For the simple applications, please just follow what the Catalyst
manual gives you.

However, if you I<really> wanted to, you can define a simple Catalyst
app like so:

    # in MyApp.pm
    use strict;
    use CatalystX::AppBuilder;
    
    my $builder = CatalystX::AppBuilder->new(
        debug  => 1, # if you want
        appname => "MyApp",
        plugins => [ qw(
            Authentication
            Session
            # and others...
        ) ],
        config  => { ... }
    );

    $builder->bootstrap();

=head2 DEFINING YOUR CatalystX::AppBuilder SUBCLASS

The originally intended approach to using this module is to create a
subclass of CatalystX::AppBuilder and configure it to your own needs,
and then keep reusing it.

To build your own MyApp::Builder, you just need to subclass it:

    package MyApp::Builder;
    use Moose;

    extends 'CatalystX::AppBuilder';

Then you will be able to give it defaults to the various configuration
parameters:

    override _build_config => sub {
        my $config = super(); # Get what CatalystX::AppBuilder gives you
        $config->{ SomeComponent } = { ... };
        return $config;
    };

    override _build_plugins => sub {
        my $plugins = super(); # Get what CatalystX::AppBuilder gives you

        push @$plugins, qw(
            Unicode
            Authentication
            Session
            Session::Store::File
            Session::State::Cookie
        );

        return $plugins;
    };

Then you can simply do this instead of giving parameters to 
CatalystX::AppBuilder every time:

    # in MyApp.pm
    use MyApp::Builder;
    MyApp::Builder->new()->bootstrap();

=head2 EXTENDING A CATALYST APP USING CatalystX::AppBuilder

Once you created your own MyApp::Builder, you can keep inheriting it to 
create custom Builders which in turn create more custom Catalyst applications:

    package MyAnotherApp::Builder;
    use Moose;

    extends 'MyApp::Builder';

    override _build_superclasses => sub {
        return [ 'MyApp' ]
    }

    ... do your tweaking ...

    # in MyAnotherApp.pm
    use MyAnotherApp::Builder;

    MyAnotherApp::Builder->new()->bootstrap();

Voila, you just reused every inch of Catalyst app that you created via
inheritance!

=head2 INCLUDING EVERY PATH FROM YOUR INHERITANCE HIERARCHY

Components like Catalyst::View::TT, which in turn uses Template Toolkit
inside, allows you to include multiple directories to look for the 
template files.

This can be used to recycle the templates that you used in a base application.

CatalystX::AppBuilder gives you a couple of tools to easily include
paths that are associated with all of the Catalyst applications that are
inherited. For example, if you have MyApp::Base and MyApp::Extended,
and MyApp::Extended is built using MyApp::Extended::Builder, you can do 
something like this:

    package MyApp::Extended::Builder;
    use Moose;

    extends 'CatalystX::AppBuilder'; 

    override _build_superclasses => sub {
        return [ 'MyApp::Base' ]
    };

    override _build_config => sub {
        my $self = shift;
        my $config = super();

        $config->{'View::TT'}->{INCLUDE_PATH} = 
            [ $self->inherited_path_to('root') ];
        # Above is equivalent to 
        #    [ MyApp::Extended->path_to('root'), MyApp::Base->path_to('root') ]
    };

So now you can refer to some template, and it will first look under the
first app, then the base app, thus allowing you to reuse the templates.

=head1 ATTRIBUTES

=head2 appname 

The module name of the Catalyst application. Required.

=head2 appmeta 

The metaclass object of the Catalyst application. Users cannot set this.

=head2 debug

Boolean flag to enable debug output in the application

=head2 version

The version string to use (probably meaningless...)

=head2 superclasses

The list of superclasses of the Catalyst application.

=head2 config

The config hash to give to the Catalyst application.

=head2 plugins

The list of plugins to give to the Catalyst application.

=head1 METHODS

=head2 bootstrap($runsetup)

Bootstraps the Catalyst app.

=head2 inherited_path_to(@pathspec)

Calls path_to() on all Catalyst applications in the inheritance tree.

=head2 app_path_to(@pathspec);

Calls path_to() on the curent Catalyst application.

=head1 TODO

Documentation. Samples. Tests.

=head1 AUTHOR

Daisuke Maki C<< <daisuke@endeworks.jp> >>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html
=cut
