package Dancer2::Debugger;

use 5.006;
use strict;
use warnings;

=head1 NAME

Dancer2::Debugger - Dancer2 panels for Plack::Debugger

=head1 VERSION

0.008

=cut

our $VERSION = '0.008';

use Dancer2::Core::Types;
use File::Spec;
use JSON::MaybeXS;
use Module::Find qw/findallmod/;
use Module::Runtime qw/use_module/;
use Plack::App::Debugger;
use Plack::Builder ();
use Plack::Debugger;
use Plack::Debugger::Storage;
use Plack::Middleware::Debugger::Injector;

use Moo;
use namespace::clean;

=head1 SYNOPSIS

In your .psgi file:

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use FindBin;
    use lib "$FindBin::Bin/../lib";

    use Plack::Builder;

    use Dancer2::Debugger;
    my $debugger = Dancer2::Debugger->new;

    use MyApp;
    my $app = MyApp->to_app;

    builder {
        $debugger->mount;
        mount '/' => builder {
            $debugger->enable;
            $app;
        }
    };

In environments/development.yml file:

    plugins:
        Debugger:
            enabled: 1

In MyApp.pm:

    use Dancer2::Plugin::Debugger

=head1 DESCRIPTION

L<Dancer2::Debugger> makes using the excellent L<Plack::Debugger> much more
convenient and in addition provides a number of Dancer2 panels.

Current panels included with this distribution:

=over

=item L<Plack::Debugger::Panel::Dancer2::Logger>

=item L<Plack::Debugger::Panel::Dancer2::Routes>

=item L<Plack::Debugger::Panel::Dancer2::Session>

=item L<Plack::Debugger::Panel::Dancer2::Settings>

=item L<Plack::Debugger::Panel::Dancer2::TemplateTimer>

=item L<Plack::Debugger::Panel::Dancer2::TemplateVariables>

=back

Some of the debugger panels make use of collectors which are imported into
your L<Dancer2> app using L<Dancer2::Plugin::Debugger> which is also 
included in this distribution.

=head1 ATTRIBUTES

=head2 app

Instantiated L<Plack::App::Debugger> object.

=cut

has app => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Plack::App::Debugger->new( debugger => $self->debugger );
    },
);

=head2 data_dir

See L<Plack::Debugger::Storage/data_dir>.

Defaults to C<debugger_panel> in the system temp directory (usually C</tmp>
on Linux/UNIX systems).

Attempts to create the directory if it does not exist.

=cut

has data_dir => (
    is      => 'ro',
    default => sub {
        my $dir = File::Spec->catfile( File::Spec->tmpdir, 'debugger_panel' );
        return $dir if ( -d $dir || mkdir $dir );
        die "Unable to create data_dir $dir: $!";
    },
);

=head2 debugger

Instantiated L<Plack::Debugger> object.

=cut

has debugger => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Plack::Debugger->new(
            storage => $self->storage,
            panels  => $self->panel_objects,
        );
    }
);

=head2 deserializer

See L<Plack::Debugger::Storage/deserializer>.

Defaults to the value of L</serializer>.

=cut

has deserializer => (
    is      => 'ro',
    isa     => Object,
    lazy    => 1,
    default => sub { shift->serializer },
);

=head2 filename_fmt

See L<Plack::Debugger::Storage/filename_fmt>.

Defaults to C<%s.json>.

=cut

has filename_fmt => (
    is      => 'ro',
    default => '%s.json',
);

=head2 injector_ignore_status

If set to a true value then we override
L<Plack::Middleware::Debugger::Injector/should_ignore_status> to always
return false so that the injector tries to add the javascript snippet to the
page irrespective of the http status code.

Defaults to false.

=cut

has injector_ignore_status => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
);

=head2 panels

Array reference of panel class names to load. Defaults to all classes
found in C<@INC> under L<Plack::Debugger::Panel>.

=cut

has panels => (
    is      => 'ro',
    isa     => ArrayRef,
    default => sub {
        my @found = findallmod Plack::Debugger::Panel;
        return [ sort @found ];
    },
);

=head2 panel_objects

Imported and instantiated panel objects.

=cut

has panel_objects => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    default => sub {
        my $self = shift;
        my @panels;
        foreach my $panel ( @{ $self->panels } ) {
            push @panels, use_module($panel)->new;
        }
        return [@panels];
    },
);

=head2 serializer

See L<Plack::Debugger::Storage/serializer>.

Defaults to C<< JSON::MaybeXS->new( convert_blessed => 1, utf8 => 1 ) >>

=cut

has serializer => (
    is      => 'ro',
    isa     => Object,
    default => sub {
        JSON::MaybeXS->new(
            convert_blessed => 1,
            allow_blessed   => 1,
            allow_unknown   => 1,
            utf8            => 1,
        );
    },
);

=head2 storage

Instantiated L<Plack::Debugger::Storage> object.

=cut

has storage => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        Plack::Debugger::Storage->new(
            data_dir     => $self->data_dir,
            serializer   => sub { $self->serializer->encode(shift) },
            deserializer => sub { $self->deserializer->decode(shift) },
            filename_fmt => $self->filename_fmt,
        );
    },
);

=head1 METHODS

=head2 BUILD

Handle L</injector_ignore_status> if it is true.

=cut

sub BUILD {
    my $self = shift;
    if ( $self->injector_ignore_status ) {
        no warnings 'redefine';
        *Plack::Middleware::Debugger::Injector::should_ignore_status = sub {
            return 0;
        };
    }
}

=head2 enable

Convenience method for use in psgi file which runs the following methods:

L<Plack::App::Debugger/make_injector_middleware> and
L<Plack::Debugger/create_middleware>.

=cut

sub enable {
    my $self = shift;
    Plack::Builder::enable $self->app->make_injector_middleware;
    Plack::Builder::enable $self->debugger->make_collector_middleware;
}

=head2 mount

Convenience method for use in psgi file to mount L<Plack::App::Debugger>.

=cut

sub mount {
    my $self = shift;
    Plack::Builder::mount $self->app->base_url => $self->app->to_app;
}

1;
__END__

=head1 SEE ALSO

L<Plack::Debugger>, L<Plack::Debugger::Panel::Dancer2::Version>

=head1 AUTHORS

Peter Mottram (SysPete), C<peter@sysnix.com>

=head1 CONTRIBUTORS

 James Morrison - GH #2

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Peter Mottram (SysPete).

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
