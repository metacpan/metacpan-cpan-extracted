package Catalyst::Plugin::Profile::DBI::Log;
# ABSTRACT: Capture queries executed during a Catalyst route with DBI::Log

our $VERSION = '0.02'; # VERSION (maintained by DZP::OurPkgVersion)

use Moose::Role;
use namespace::autoclean;
 
use CatalystX::InjectComponent;
use Data::UUID;
use DateTime;
use DDP;
use Path::Tiny;
use Time::HiRes;

# Load DBI::Log, but point it at /dev/null to start with; we'll give it a
# new filehandle at the beginning of each request.
use DBI::Log timing => 1, trace => 1, format => 'json', file => '/dev/null';


# Ick - find a better way to pass this around than a global var!
my $dbilog_output_dir;

after 'setup_finalize' => sub {
    my $self = shift;

    my $conf = $self->config->{'Plugin::Profile::DBI::Log'} || {};
    $dbilog_output_dir = $conf->{dbilog_out_dir} || 'dbilog_output';

    if (!-d $dbilog_output_dir) {
        $self->log->debug("Creating DBI::Log output dir $dbilog_output_dir");
        Path::Tiny::path($dbilog_output_dir)->mkpath;
    } else {
        $self->log->debug("OK, using DBI::Log output dir $dbilog_output_dir");
    }
};
 
after 'setup_components' => sub {
    my $class = shift;
    $class->log->debug("Inject controller into $class");
    CatalystX::InjectComponent->inject(
        into => $class,
        component => 'Catalyst::Plugin::Profile::DBI::Log::Controller::ControlProfiling',
        as => 'Controller::DBI::Log'
    );
};

# Start a profile run when a request begins...
# FIXME: is this the best hook?  Want the Catalyst equivalent of a Dancer
# `before` hook.  `prepare_body` looks like a reasonable "we've read the
# request from the network, we're about to handle it" point.
after 'prepare_body' => sub {
    my $c = shift;

    # We want to name all profile outputs safely and usefully, encoding
    # the request method, path, and timestamp, and a random number for some
    # uniqueness.
    my $path = $c->request->method . '_' . ($c->request->path || '/');
    $path =~ s{/}{_s_}g;
    $path =~ s{[^a-z0-9]}{_}gi;
    $path .= "_t_" . DateTime->now->strftime('%Y-%m-%d_%H:%M:%S');
    $path .= substr Data::UUID->new->create_str, 0, 8;
    $path = Path::Tiny::path($dbilog_output_dir, $path);
    open my $dbilog_fh, ">", $path
        or $c->log->debug("Can't open $path to write - $!");

    # Write our metadata to the log first
    print {$dbilog_fh} JSON::to_json(
        {
            logged_by  => __PACKAGE__ . "/$VERSION",
            method     => $c->request->method,
            path       => $c->request->path,
            path_query => $c->request->uri->path_query,
            ip         => $c->request->address,
            user_agent => $c->request->user_agent,
            start_timestamp => Time::HiRes::time(),
        }
    ) . "\n";
    $DBI::Log::opts{fh}   = $dbilog_fh;
    $DBI::Log::opts{file} = $path;
};


# And finalise it when the request is finished
after 'finalize_body' => sub {
    my $c = shift;
    $c->log->debug("finalize_body fired, stop profiling");
    # Make sure the file has been flushed before we do anything
    $DBI::Log::opts{fh}->flush();

    # Want to know how many queries were logged; if there were none, then
    # there's no point keeping the log, so we should delete it.
    seek $DBI::Log::opts{fh}, 0, 0;
    my $metadata_json = <$DBI::Log::opts{fh}>;
    my $first_query = <$DBI::Log::opts{fh}>;
    if (!$first_query) {
        $c->log->debug("No queries logged, delete file");
        unlink $DBI::Log::opts{file};
    }

};


1;

=head1 NAME

Catalyst::Plugin::Profile::DBI::Log - per-request DB query logging & profiling

=head1 SYNOPSIS

Load the plugin like any other Catalyst plugin e.g.

  use Catalyst qw(Profile::DBI::Log);

hit your app with some requests, then point your browser at C</dbi/log/index> 
and you'll see a list of HTTP requests handled, along with info on how many 
queries they ran and how long they spent waiting for the DB, with a clickable
link to view the actual queries and stack trace of where they came from.

=head1 DESCRIPTION

I needed a way to quickly and easily see, for each API route invocation (HTTP
request) my app handled,

=over

=item How many DB queries were performed

=item How long we spent waiting for DB queries

=item What the actual queries executed were and how long each took

=item Where in our codebase those queries were performed

=back

This plugin is designed to simplify just that.

When loaded, it arranges for L<DBI::Log> to log all queries to log files,
while adding some metadata of our own to identify the HTTP request being
processed.  It adds a route handler to provide routes to list requests
profiled along with summary info (how many queries, how long spent waiting on
queries etc), and clickable links to view all the queries performed, and to
view a stack trace of where the query was performed from (to see easily what
part of your codebase triggered it).


=head1 SEE ALSO

There are a couple of prior art examples which capture stats from DBIC
using L<DBIx::Class::Storage::Statistics> such as L<Catalyst::Plugin::DBIC::Profiler>
but parts of one of our apps, for hairy legacy reasons also go direct to the
DB with DBI, so we needed to catch those too - and wanted a useful way to
see the list of profiled requests right in the browser.


=head1 SECURITY

This is a development tool.  It captures, records and serves up raw SQL queries
which may well contain sensitive information - e.g. parameters used to search
the DB, etc.  I would not recommend loading it on a production site or exposing
an app with it loaded to the Internet.

=head1 AUTHOR

David Precious (BIGPRESH) C<< <davidp@preshweb.co.uk> >>

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2024 by David Precious

This library is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

=cut
