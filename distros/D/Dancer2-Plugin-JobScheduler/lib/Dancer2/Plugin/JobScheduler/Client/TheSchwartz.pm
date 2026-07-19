package Dancer2::Plugin::JobScheduler::Client::TheSchwartz;
## no critic (ControlStructures::ProhibitPostfixControls)

use strict;
use warnings;

# ABSTRACT: A front to the client of the job scheduler or other object via which the jobs are submitted

our $VERSION = '0.007';

=pod

=encoding utf8

=for Pod::Coverage config submit_job list_jobs

=head1 NAME

Dancer2::Plugin::JobScheduler::Client::TheSchwartz - Client connector to TheSchwartz

=head1 DESCRIPTION

Internal class.

Not to be used separately. Please see L<Dancer2::Plugin::JobScheduler>.

=cut

use Carp;
use English '-no_match_vars';
use Module::Load;
use Const::Fast;

use Log::Any qw( $log );

use Moo;
use TheSchwartz::JobScheduler;
use TheSchwartz::JobScheduler::Job;

const my $DEFAULT_HANDLE_UNIQKEY => 'no_check';

=head1 CONFIGURATION

The configuration of Dancer2::Plugin::JobScheduler::Client::TheSchwartz
requires only the knowledge of how to connect with
its database backends. TheSchwartz can use simultaneously
several databases as backends. When inserting a new task, TheSchwartz
loops over all available databases until it finds one
that it can connect to and inserts the task there.
TheSchwartz client does not maintain its own database handles.
Instead, it requires the calling program to give a
subroutine pointer or the name and method of a class
which can provide the handle.

In a long running process, such as a web service,
the database handle can become invalid. Database can
close the handle if it stays unused a long period of time.
The database handle has to be recreated if that happens.

If callback is a subroutine pointer,
then Dancer2::Plugin::JobScheduler will call the given
pointer and give one argument: the name of the database
it wants to reach.

This example creates two databases and uses a locally defined
subroutine to get the database handle:

    use Database::Temp;
    use DBI;
    my %test_dbs = (
        theschwartz_db1 => Database::Temp->new( driver => 'SQLite', );
        theschwartz_db2 => Database::Temp->new( driver => 'SQLite', );
    );
    my $get_dbh = sub {
        my ($id) = @_;
        return DBI->connect( $test_dbs{ $id }->connection_info );
    };
    my %plugin_config = (
        default => 'theschwartz',
        schedulers => {
            theschwartz => {
                package => 'TheSchwartz',
                parameters => {
                    dbh_callback => $get_dbh,
                    databases => [
                        {
                            id => 'theschwartz_db1',
                            prefix => q{},
                        },
                    ]
                }
            }
        }
    );

This example uses the Perl package L<Database::ManagedHandle>
to provide an open database handle.

    my %plugin_config = (
        default => 'theschwartz',
        schedulers => {
            theschwartz => {
                package => 'TheSchwartz',
                parameters => {
                    dbh_callback => 'Database::ManagedHandle->instance->dbh',
                    databases => [
                        {
                            id => 'theschwartz_db1',
                            prefix => q{},
                        },
                    ]
                }
            }
        }
    );
        my $get_dbh = sub {
            my ($id) = @_;
            return DBI->connect( $test_dbs{ $id }->connection_info );
        };

Please see L<Dancer2::Plugin::JobScheduler> on how to attach this
configuration to the plugin's configuration.

=cut

has config => (
    is          => 'ro',
    isa         => sub { croak if( ref $_[0] ne 'HASH' ) },
    required    => 1,
);

sub _verify_configuration {
    my ($self) = @_;
    if( ! $self->config->{'dbh_callback'} ) {
        my $e = 'Invalid config. Must define dbh_callback.';
        $log->errorf( $e );
        croak $e;
    }
    if( $self->config->{'databases'} ) {
        my $databases = $self->config->{'databases'};
        foreach my $key (keys %{ $databases }) {
            my $database = $databases->{ $key };
            if( $database->{'dbh_callback'} ) {
                my $e = q{Invalid config. }
                . q{databases->%s has item dbh_callback; database specific callbacks not supported};
                $log->errorf( $e, $key);
                croak sprintf $e, $key;
            }
        }
    } else {
        my $e = 'Invalid config. Must define databases.';
        $log->errorf( $e );
        croak $e;
    }
    return;
}

has _client => (
    is => 'lazy',
);
sub _build__client { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    $self->_verify_configuration();
    my $c = $self->config;
    $log->debugf( 'config: %s', $c );
    my $handle_uniqkey = $c->{'handle_uniqkey'} // $DEFAULT_HANDLE_UNIQKEY;
    my $client = TheSchwartz::JobScheduler->new(
        databases => $c->{'databases'},
        dbh_callback => 'Database::ManagedHandle->instance->dbh',
        opts => {
            handle_uniqkey => $handle_uniqkey,
        },
    );
    return $client;
}

sub submit_job {
    my ($self, $job, $opts) = @_;
    $log->debugf('submit_job: %s, %s', $job, $opts);

    croak 'No task name' if( ! $job->{'task'} );
    my $j = TheSchwartz::JobScheduler::Job->new;
    $j->funcname( $job->{'task'} );
    $j->arg( $job->{'args'} ) if $job->{'args'};
    $j->uniqkey( $job->{'opts'}->{'unique_key'} ) if $job->{'opts'}->{'unique_key'};
    $j->uniqkey( $job->{'opts'}->{'uniqkey'} ) if $job->{'opts'}->{'uniqkey'};
    $j->run_after( $job->{'opts'}->{'run_after'} ) if $job->{'opts'}->{'run_after'};

    my %args = ( job => $j, );
    if( $opts->{'dbh_callback'} ) {
      $args{'dbh_callback'} = $opts->{'dbh_callback'};
    }
    my $job_id = $self->_client->insert( %args );
    $log->debugf( 'job_id: %s', $job_id );

    if( $job_id ) {
        return (
            success => 1,
            status  => 'OK',
            error   => undef,
            id      => $job_id,
        );
    } else {
        return (
            success => 0,
            status  => 'FAIL',
            error   => undef,
        );
    }
}

sub list_jobs {
    my ($self, $search_params, $opts) = @_;
    $log->debugf('list_jobs(%s, %s)', $search_params, $opts);

    croak 'No task name', if( ! $search_params->{'task'} );
    $search_params->{'funcname'} = delete $search_params->{'task'};
    my %args = ( search_params => $search_params, );
    if( $opts->{'dbh_callback'} ) {
      $args{'dbh_callback'} = $opts->{'dbh_callback'};
    }
    my @jobs = $self->_client->list_jobs( %args, );
    $log->debugf('list_jobs(): jobs: %s', \@jobs);
    my @r_jobs;
    foreach my $job (@jobs) {
        my %opts;
        $opts{'unique_key'} = $job->uniqkey if $job->uniqkey;
        push @r_jobs, {
            task => $search_params->{'funcname'},
            args => $job->arg,
            opts => \%opts,
        };
    }
    my %r = (
        success => 1,
        status  => 'OK',
        error   => undef,
        jobs    => \@r_jobs,
    );

    return %r;
}

=pod

=head1 ADOPTION

If you're interested in adopting this module, and the author/maintainer
appears to be no longer active, please consult the PAUSE module
adoption process documented at L<https://github.com/Perl-Toolchain-Gang/pause/blob/master/doc/takeover-policy.md>.

The PAUSE admins (modules@perl.org) may grant co-maintainer or
primary-maintainer permissions to a suitable adopter if:

=over 4

=item *

There has been no release for a year or more, AND

=item *

There are outstanding issues, pull requests, or bug reports that would
benefit from attention, AND

=item *

Reasonable attempts to contact me have failed (CPAN email address,
GitHub issues on the project repository, and any other channels listed
in this distribution) over a period of at least one month, AND

=item *

The prospective adopter intends to make changes that benefit users of
the module.

=back

=for stopwords maintainership

In the event of my death or permanent incapacity, my heirs are not
obligated to maintain these modules, and I explicitly authorize the
PAUSE admins to transfer maintainership without further consultation
once the conditions above are met.

=head1 AUTHOR

Mikko Koivunalho <mikkoi@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1;
