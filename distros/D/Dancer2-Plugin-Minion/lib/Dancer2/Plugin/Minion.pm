package Dancer2::Plugin::Minion;

# ABSTRACT: Use the Minion job queue in your Dancer2 apps.

use Dancer2::Plugin;
use Minion;

our $VERSION = '0.3.3';

plugin_keywords qw(
    minion
    add_task
    enqueue
    minion_app
);

has _backend => (
    is          => 'ro',
    from_config => 'backend',
    default     => sub{ 'SQLite' },
);

has _dsn => (
    is          => 'ro',
    from_config => 'dsn',
    default     => sub{ ':temp:' },
);

has 'minion' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        Minion->new( $_[0]->_backend => $_[0]->_dsn );
    },
);

sub add_task {
    return shift->minion->add_task( @_ );
}

sub enqueue {
    return shift->minion->enqueue( @_ );
}

sub minion_app {
    my $plugin = shift;
    my $return_to = shift || '/';

    require Mojolicious;
    my $app = Mojolicious->new;
    $app->log->level('warn');

    # emulate minion plugin, needed for admin panel
    $app->helper(minion => sub { $plugin->minion });
    # enable the minion command system
    push @{ $app->commands->namespaces }, 'Minion::Command';

    $app->plugin('Minion::Admin' => {
        route => $app->routes->any('/'),
        return_to => $return_to,
    });

    return $app;
}

1;
__END__

=pod

=head1 NAME

Dancer2::Plugin::Minion - Easy access to Minion job queue in your Dancer2 
applications

=head1 SYNOPSIS

    package MyApp;
    use Dancer2;
    use Dancer2::Plugin::Minion;
    use Plack::Builder;

    get '/' => sub {
        add_task( add => sub {
            my ($job, $first, $second) = @_;
            $job->finish($first + $second);
        });
    };

    get '/another-route' => sub {
        my $id = enqueue(add => [1, 1]);
        # Do something with $id
    };

    get '/yet-another-route' => sub {
        # Get a job ID, then...
        my $result = minion->job($id)->info->{result};
    };

    build {
      mount '/dashboard/' => minion_app->start;
      mount '/' => start;
    }

    # In config.yml
    plugins:
        Minion:
            dsn: sqlite:test.db
            backend: SQLite

=head1 DESCRIPTION

C<Dancer2::Plugin::Minion> makes it easy to add a job queue to any of your
L<Dancer2> applications. The queue is powered by L<Minion> and uses a 
backend of your choosing, such as PostgreSQL or SQLite.

The plugin lazily instantiates a Minion object, which is accessible via the
C<minion> keyword. Any method, attribute, or event you need in Minion is 
available via this keyword. Additionally, C<add_task> and C<enqueue> keywords
are available to make it convenient to add and start new queued jobs.

See the L<Minion> documentation for more complete documentation on the methods
and functionality available.

=head1 ATTRIBUTES

=head2 minion

The L<Minion>-based object. See the L<Minion> documentation for a list of
additional methods provided.

If no backend is specified, Minion will default to an in-memory temporary
database. This is not recommended for any serious use. See
L<the Mojo::SQLite|https://metacpan.org/pod/Mojo::SQLite#BASICS> docs
for details

=head1 METHODS

=head2 add_task()

Keyword/shortcut for C<< minion->add_task() >>. See 
L<Minion's add_task() documentation|Minion/add_task> for
more information.

=head2 enqueue()

Keyword/shortcut for C<< minion->enqueue() >>. 
See L<Minion's enqueue() documentation|Minion/enqueue1>
for more information.

=head2 minion_app()

Build a L<Mojolicious> application with the
L<Mojolicious::Plugin::Minion::Admin> application running. This application can
then be started and mounted inside your own but be sure to leave a trailing
slash in your mount path!

You can optionally pass in an absolute URL to act as the "return to" link. The url must
be absolute or else it will be made relative to the admin UI, which is probably
not what you want. For example: 
C<< mount '/dashboard/' => minion_app( 'http://localhost:5000/foo' )->start; >>

=head1 RUNNING JOBS

You will need to create a Minion worker if you want to be able to run your 
queued jobs. Thankfully, you can write a minimal worker with just a few
lines of code:

    #!/usr/bin/env perl

    use Dancer2;
    use Dancer2::Plugin::Minion;
    use MyJobLib;

    minion->add_task( my_job_1 => MyJobLib::job1());

    my $worker = minion->worker;
    $worker->run;

By using C<Dancer2::Plugin::Minion>, your worker will be configured with 
the settings provided in your F<config.yml> file. See L<Minion::Worker> 
for more information.

=head1 SEE ALSO

=over 4

=item * L<Dancer2>

=item * L<Minion>

=back

=head1 AUTHOR

Jason A. Crome C< cromedome AT cpan DOT org >

=head1 ACKNOWLEDGEMENTS

I'd like to extend a hearty thanks to my employer, Clearbuilt Technologies,
for giving me the necessary time and support for this module to come to
life.

The following contributors have sent patches, suggestions, or bug reports that
led to the improvement of this plugin:

=over 4

=item * Gabor Szabo
=item * Joel Berger
=item * Slaven Rezić

=back

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2020, Clearbuilt Technologies.

This is free software; you can redistribute it and/or modify it under 
the same terms as the Perl 5 programming language system itself.

=cut

