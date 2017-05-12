use strict;
use warnings;

package Dancer::Plugin::GearmanXS;
BEGIN {
  $Dancer::Plugin::GearmanXS::VERSION = '0.110570';
}

use Dancer ':syntax';
use Dancer::Plugin;

use Storable qw( nfreeze );

use Gearman::XS qw/:constants/;
use Gearman::XS::Client;

my $gearman_client = Gearman::XS::Client->new();
$gearman_client->add_servers(
    join( ',', @{ plugin_setting->{job_servers} || ['127.0.0.1:4730'] } ) );

my $gearman_serializer = sub { nfreeze(@_) };

=head1 NAME

Dancer::Plugin::GearmanXS - a Dancer Gearman::XS client

=head1 SYNOPSIS

This plugin allows Dancer to communicate with Gearman servers,
requesting they perform a task and return the result.

By default, task parameters are serialised using Storable's C<nfreeze> method.
Your Gearman workers will need to agree on the method used to serialize data.

You will need to configure a list of Gearman servers the plugin will be
contacting. In your configuration file:

    plugins:
        GearmanXS:
            job_servers:
                - 127.0.0.1
                - 192.168.1.100:12345

The job servers list defaults to C<127.0.0.1:4730> if not specified.

In your package/app:

    package MyApp;
    use Dancer;
    use Dancer::Plugin::GearmanXS;
    use YAML;

    # use YAML as serializer rather than Storable
    gearman_serializer => sub {
        Dump(@_);
    };

    get '/' => sub {

        ## using the underlying Gearman::XS interface
        my ($retval,$result) =
            gearman->do(
                'task_name',
                { arg1 => 'val1' },
            );
        );
        # check $retval and use gearman_client->error()

        ## using the simplified interface which serializes for you
        my $res = gearman_do( 'task_name', { arg1 => 'val1' } );

        template index => { result => $result }
    };

Error management can be done via either C<gearman-E<gt>error>
or C<gearman_error>.

If you need access to advanced features like C<add_task_high_background> or
C<set_fail_fn>, use the L<gearman> function: it's a L<Gearman::XS::Client>
object.

=head1 KEYWORDS

=head2 gearman

This method gives you direct access to the L<Gearman::XS::Client> instance.
See the module's POD for what you could do with it.
The other methods are shorthand for more common tasks, but do not provide
the same degree of control as accessing the client object directly.

=cut

register gearman => sub { $gearman_client };

=head2 gearman_error

Accesses the C<error> method for the L<Gearman::XS::Client>.

=cut

register gearman_error => sub { $gearman_client->error };

=head2 gearman_serializer

This method returns the current serializer subroutine reference.  You can pass
it a subroutine reference if you would like to use a serializer other than
L<Storable>'s C<nfreeze>.

=cut

register gearman_serializer => sub {
    return $gearman_serializer unless $_[0] and ref $_[0] eq 'CODE';
    $gearman_serializer = $_[0];
};

=head2 gearman_do

Creates, dispatches and waits on a task to complete,
returning the result (scalar reference on success,
or undef on failure). Uses the L<gearman_serializer>
to serialize the argument(s) given.
Use L<gearman_error> in case the of failure.

    my $result = gearman_do('add', [1,2]);
    return template error => { error => gearman_error } unless $result;

=cut

register gearman_do => sub {
    my ( $task_name, @args ) = @_;
    my $serialized_args = $gearman_serializer->(@args);
    my ( $ret, $result ) = $gearman_client->do( $task_name, $serialized_args );
    return if $ret ne GEARMAN_SUCCESS;
    return $result;
};

=head2 gearman_background

Creates and dispatches a job to be run in the background,
not waiting for any result. Returns undef on failure,
or the job handle.

    my $task = gearman_background('update_minicpan',
        ['/opt/minicpan','0755']
    );
    return template error => { error => gearman_error } unless $task;

=cut

register gearman_background => sub {
    my ( $task_name, @args ) = @_;
    my $serialized_args = $gearman_serializer->(@args);
    my ( $ret, $job_handle ) = $gearman_client->do_background( $task_name, $serialized_args );
    return if $ret ne GEARMAN_SUCCESS;
    return $job_handle;
};

=head2 gearman_add_task

Adds a task to be run in parallel, returning a task object. It does not
start executing the task: you will need to call L<gearman_run_tasks>
in order to do that. Returns undef on failure, or the task object.

    # fetches these sites are up, in parallel
    for my $site ( 'http://google.com', 'http://yahoo.com' ) {
        my $task = gearman_add_task('fetch_site', $site);
        return template error => { error => gearman_error } unless $task;
    }
    my $ret = gearman_run_tasks;
    return template error => { error => gearman_error } unless $ret;
    ## Tasks have completed

=cut

register gearman_add_task => sub {
    my ( $task_name, @args ) = @_;
    my $serialized_args = $gearman_serializer->(@args);
    my ( $ret, $job_handle ) = $gearman_client->add_task( $task_name, $serialized_args );
    return if $ret ne GEARMAN_SUCCESS;
    return $job_handle;
};

=head2 gearman_run_tasks

Once a number of tasks have been queued via L<gearman_add_tasks>, this method
allows them to run in parallel, and returns whether there has been a failure.
See L<gearman_add_task> for an example.

=cut

register gearman_run_tasks => sub {
    my ($ret) = $gearman_client->run_tasks();
    return ( $ret eq GEARMAN_SUCCESS );
};

register_plugin;

=head1 AUTHOR

Marco Fontani - C<< <MFONTANI at cpan.org> >>

=head1 BUGS

Please report any bugs via e-mail.

=head1 SEE ALSO

Dancer - L<Dancer>

Gearman::XS - L<Gearman::XS>

Gearman site - L<http://www.gearman.org>

Yosemite National Park: it's worth visiting.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Marco Fontani.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
