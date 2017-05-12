package Catalyst::Engine::JobQueue::POE;

use warnings;
use strict;
use base 'Catalyst::Engine::CGI';
use Carp;
use Data::Dumper;
use Email::MIME::Creator;
use Email::Send 2.15;
use File::Spec;
use IO::File;
use Scalar::Util qw/refaddr/;

use POE;
use POE::Component::Cron 0.014;
use DateTime::Event::Cron;
use DateTime::Event::Random;

use Catalyst::Exception;
use Catalyst::JobQueue::Job;

use version; our $VERSION = '0.0.4';

# Enable for helpful debugging information
sub DEBUG { $ENV{CATALYST_POE_DEBUG} || 0 } 

sub CGI_ENV_DEFAULTS {
    {
        REMOTE_ADDR     => '127.0.0.1',
        REMOTE_HOST     => 'localhost',
        REQUEST_METHOD  => 'GET',
        SERVER_NAME     => '127.0.0.1',
        SERVER_PORT     => 80,
        SERVER_PROTOCOL => 'HTTP/1.0',
    }
}

sub CONFIG_DEFAULTS {
    {
        render => { to => [qw/log/] },
        schedule_file => 'crontab',
    }
}

sub RENDER_DEFAULTS {
    {
        log => {
            level => 'info',
        },
        email => {
            from        => 'catalyst@localhost',
            to          => 'root@localhost',
            smtp        => 'localhost',
            dispostion  => 'attachment',
        },
    }
}

my $render_handler = {
    log  => \&_render_log,
    email => \&_render_email,
};

sub run { 
    my ( $self, $class, @args ) = @_;
    
    $self->spawn( $class, @args );
    
    POE::Kernel->run;
}

sub spawn {
    my ( $self, $class, $options ) = @_;

    my $pkg = __PACKAGE__;
    my $cfg = $class->config;

    if(not (defined $cfg and exists $cfg->{$pkg})) {
        $cfg->{$pkg} = CONFIG_DEFAULTS; 
    };

    $self->{config} = {
        appclass => $class,
        %{ $cfg->{$pkg} },
        %{ $options },
        home  => $cfg->{home},
    };
   
    POE::Session->create(
        object_states => [
            $self => [
                qw/_start
                   _stop
                   shutdown
                   dump_state
                   
                   process

                   handle_prepare
                   prepare_done

                   handle_finalize
                   finalize_done

                   run_job
                   job_done
               /
           ],
       ],
   );
   
   return $self;
} 

# start the server
sub _start {
    my ( $kernel, $self, $session ) = @_[ KERNEL, OBJECT, SESSION ];

    $kernel->alias_set( 'catalyst-jobqueue-poe' );
    
    # make a copy of %ENV
    $self->{global_env} = \%ENV;

    # dump our state if we get SIGUSR1
    $kernel->sig( 'USR1', 'dump_state' );

    # shutdown on INT
    $kernel->sig( 'INT', 'shutdown' );

    DEBUG && print "Job Queue started\n";
    DEBUG && print Dumper($self->{config});
    my $schedule_file = exists $self->{config}->{schedule_file} ?  $self->{config}{schedule_file} : CONFIG_DEFAULTS()->{schedule_file};
    my $file = substr($schedule_file, 0, 1) eq "/" ? $schedule_file : File::Spec->catfile($self->{config}->{home}, $schedule_file);
    DEBUG && print "Parsing cron file $file\n";
    if (-e $file) {
        my $job_list = _parse_crontab($file);
        $self->{jobs} = { map { $_->ID => $_ } @{$job_list} };
    }
    else {
        Catalyst::Exception->throw( message => qq/Cannot find schedule file "$file"/ );
    }

    DEBUG && print Dumper($self->{jobs});
    foreach my $jobid (keys %{$self->{jobs}}) {
        DEBUG && print "Starting job $jobid\n";
        my $job = $self->{jobs}->{$jobid};
        $job->scheduler( 
            POE::Component::Cron->add(
                $session,
                'run_job',
                DateTime::Event::Cron->from_cron($job->cronspec)->iterator( 
                    span =>
                    DateTime::Span->from_datetimes( 
                        start => DateTime->now,
                        end   => DateTime::Infinite::Future->new,
                    ),
                ),
                $job->ID,
            )
        );
        DEBUG && print "Job ID: ", $job->ID, "\n Data: " , Dumper($job);
    }
    
}

sub _stop { }

sub shutdown {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    $kernel->alias_remove( 'catalyst-jobqueue-poe' );

    DEBUG && warn "Shutting down...\n";
}

sub dump_state {
    my ( $kernel, $self ) = @_[ KERNEL, OBJECT ];

    my $job_count = scalar keys %{$self->{jobs}};
    warn "-- POE JobQueue state --";
    warn Dumper($self);
    warn "Active jobs: $job_count\n";
}

sub process {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];

    DEBUG && print "Processing request for job $ID\n";
    my $job = $self->{jobs}->{$ID};
    my $status = $self->{config}->{appclass}->handle_request( $ID );
    DEBUG && print "Got status $status from handler\n";
    $job->last_status( $status );

    # remove request specific data
    $job->cleanup();

    if ($status >= 400 or $status == 0) {
        $kernel->yield( 'job_done', $ID);
    }
    else {
        # success
    }
}

sub prepare {
    my ( $self, $c, $ID ) = @_;

    DEBUG && print "Preparing for job $ID\n";

    # store ID in context (must retrieve from there in finalize)
    $c->{_POE_JOB_ID} = $ID;
    
    my $job = $self->{jobs}->{$ID};
    $job->context( $c );

    $job->flags->{_prepare_done} = 0;

    $poe_kernel->yield( 'handle_prepare', 'prepare_request', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_connection', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_query_parameters', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_headers', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_cookies', $ID );
    $poe_kernel->yield( 'handle_prepare', 'prepare_path', $ID );

    # XXX Skip on-demand parsing stage 

    $poe_kernel->yield( 'prepare_done', $ID );

    # Wait until all prepare processing has completed, or we will return too
    # early
    while ( !$job->flags->{_prepare_done} ) {
        $poe_kernel->run_one_timeslice();
    } 
}

sub finalize {
    my ( $self, $c ) = @_;

    my $ID = $c->{_POE_JOB_ID};
    my $job = $self->{jobs}->{$ID};

    $job->flags->{_finalize_done} = 0;

    $poe_kernel->yield( 'handle_finalize', 'finalize_uploads', $ID );
    if ( $#{ $c->error } >= 0 ) {
        $poe_kernel->yield( 'handle_finalize', 'finalize_error', $ID );
    }
    $poe_kernel->yield( 'handle_finalize', 'finalize_headers', $ID );
    $poe_kernel->yield( 'handle_finalize', 'finalize_body', $ID );

    $poe_kernel->yield( 'finalize_done', $ID );

    # Wait until all prepare processing has completed, or we will return too
    # early
    while ( !$job->flags->{_finalize_done} ) {
        $poe_kernel->run_one_timeslice();
    }
   
    return $c->response->status;
}

# handle_prepare localizes our per-client %ENV and calls $c->$method
# Allows plugins to do things during each step 
sub handle_prepare {
    my ( $kernel, $self, $method, $ID ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];

    DEBUG && warn "[Job $ID] - $method\n";
    my $job = $self->{jobs}->{$ID};
    
    {
        local (*ENV) = $job->env;
        $job->context->$method();
    }     
}

# Engine method - deals only with context
sub prepare_headers {
    my ($self, $c) = @_;

    $c->request->header( 'X-Via-JobQueue-Job' => $c->{_POE_JOB_ID} );
}

sub write {
    my ($self, $c) = @_;
 
    return unless exists $c->engine->{config}{render}{to} and ref($c->engine->{config}{render}{to}) eq "ARRAY" and scalar($c->engine->{config}{render}{to}) > 0;

    my $ID = $c->{_POE_JOB_ID};
    DEBUG && warn "[Job $ID] Rendering output\n";
   
    foreach my $render_name ( @{$c->engine->{config}{render}{to}} ) {
        DEBUG && warn "Rendering to $render_name\n";
        if (exists $render_handler->{$render_name}) {
            my $cfg = RENDER_DEFAULTS()->{$render_name};
            @{$cfg}{keys %{$c->engine->{config}{render}{$render_name}}} = values %{$c->engine->{config}{render}{$render_name}};
            $render_handler->{$render_name}->($c, $cfg);
        }
        else {
            $c->log->warn("Missing renderer: $render_name [skipping]");
        }
    }

}


sub prepare_done {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];

    DEBUG && warn "[Job $ID] prepare_done\n";
    my $job = $self->{jobs}->{$ID};

    $job->flags->{_prepare_done} = 1;
}

# handle_finalize just calls $c->$method
# Allows plugins to do things during each step 
sub handle_finalize {
    my ( $kernel, $self, $method, $ID ) = @_[ KERNEL, OBJECT, ARG0, ARG1 ];

    DEBUG && warn "[Job $ID] - $method\n";
    my $job = $self->{jobs}->{$ID};
   
    # Skip nulling response body on HEAD requests (doesn't make sense)

    $job->context->$method();
}

sub finalize_done {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];

    DEBUG && warn "[Job $ID] - finalize_done\n";
    my $job = $self->{jobs}->{$ID};

    $job->flags->{_finalize_done} = 1;
}

sub job_done {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $job = $self->{jobs}->{$ID};
    DEBUG && warn "[Job $ID] STATUS: " . $job->last_status . "\n";

    # remove from scheduler cleanup job 
    $job->scheduler->delete;
    delete $self->{jobs}->{$ID};

    DEBUG && warn "[Job $ID] job_done\n";
}

sub run_job {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];

    my $job = $self->{jobs}->{$ID};
    
    DEBUG && print "Running request " . $job->request->[0] . " as " .  $job->user . "\n";
    DEBUG && print "Setting up CGI Env for request\n";
    $job->env( _make_cgi_env($job->request, $self->{global_env}) );
    $kernel->yield( 'process' , $ID );

}

sub get_job {
    my ( $kernel, $self, $ID ) = @_[ KERNEL, OBJECT, ARG0 ];

    return $self->{jobs}->{$ID};
}

sub _render_log
{
    my ($c, $cfg) = @_;
    
    my $level = $cfg->{level};

    $c->log->$level( $c->response->body );
}

sub _render_email
{
    my ($c, $cfg) = @_;

    my ($content_type, $charset) = split(/\s*;\s*/, $c->response->content_type);
    my $subject = "Response for Job $c->{_POE_JOB_ID}";
    my $attr = {
        dispostion   => $cfg->{disposition},
        content_type => $content_type,
    };
    $attr->{charset} = $charset if $charset;
    $attr->{encoding} = $c->response->content_encoding if $c->response->content_encoding;

    my $email = Email::MIME->create(
        header => [
            from    => $cfg->{from},
            to      => $cfg->{to},
            subject => $subject,
        ],
        attributes => $attr,
        body => $c->response->body,
    ) or die "Can't create email";

    DEBUG && warn "Sending email:\n$email->as_string";
    my $sender = Email::Send->new({ mailer => 'SMTP' });
    $sender->mailer_args([ Host => $cfg->{smtp} ]);
    $sender->send($email);
}

sub _make_cgi_env
{
    my ( $request, $global_env ) = @_;

    my @req_copy = @{$request};
    my $path = shift @req_copy;
    my $query_string = join('&', @req_copy);

    my %env = %{ CGI_ENV_DEFAULTS() };
    $env{PATH_INFO}     = $path || '';
    $env{QUERY_STRING}  = $query_string;

    # merge with global env
    @env{ keys %{ $global_env } } = values %{ $global_env };

    return \%env;

}

sub _parse_crontab
{
    my $filename = shift;

    my $file = IO::File->new($filename, O_RDONLY) or
        Catalyst::Exception->throw( message => qq/Cannot open crontab "$filename" 
            for reading, "$!"/  );

    my (@cron_entries, $job);
    while(my $line = <$file>) {
        chomp $line;
        $line =~ s/#.*$//;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;
        next unless length $line;
        my @cron_line = split(/\s+/, $line);
        $job = Catalyst::JobQueue::Job->new({
            cronspec => join(' ', splice (@cron_line, 0, 5)),
            user     => shift @cron_line,
            request  => \@cron_line,
        });
        push @cron_entries, $job;
    }
    return \@cron_entries;
}

1; # Magic true value required at end of module
__END__

=head1 NAME

Catalyst::Engine::JobQueue::POE - Cron-like job runner engine


=head1 VERSION

This document describes Catalyst::Engine::JobQueue::POE version 0.0.4


=head1 SYNOPSIS

A script using the Catalyst::Engine::JobQueue::POE module might look like:

  #!/usr/bin/perl
  
  use strict;
  use lib '/path/to/MyApp/lib';

  BEGIN {
    $ENV{CATALYST_ENGINE} = 'JobQueue::POE';
  }

  use MyApp;

  MyApp->run;

By specifying the appropiate environment variable, C<Catalyst> will start the
JobQueue runner with the POE engine.

  
=head1 DESCRIPTION

This is the Catalyst Engine specialized for running the JobQueue with POE.


=head1 INTERFACE

=head2 $self->get_job( $id )

Returns the job object with the given ID.


=head1 OVERLOADED METHODS

This class overloads some methods from C<Catalyst::Engine>.

=head2 $self->prepare_headers

=head2 $self->write


=head1 DIAGNOSTICS

=head2 Fatal errors

These will cause the JobQueue runner to stop.

=over

=item C<< Cannot find schedule file "%s" >>

The configured schedule file doesn't exist. Check that you have supplied the
correct filename, or that a file named F<crontab> exists if no
C<schedule_file> option was set.

=item C<< Cannot open crontab "%s" for reading, "%s" >>

The crontab file could not be read. The message at the end is the system
error. Check permissions.

=back

=head2 Warnings

These will warn you of some recoverable error. 

=over

=item C<< Missing renderer %s [skipping] >>

A renderer configured to deliver the job response could not be found. Check
the configuration and docs for supported renderers.

=back

=head1 CONFIGURATION AND ENVIRONMENT

Catalyst::Engine::JobQueue::POE can be configured with the standard Catalyst
configuration mechanism. It also uses environment variables for debugging and
its own format for job configuration.

=head2 Catalyst configuration

These should appear under the C<Catalyst::Engine::JobQueue::POE> key.

=over

=item schedule_file

The path to the file which describes the jobs to be run. See L</Job Configuration>
for more details. Relative to the application root.

=item render

Describes how the JobQueue shoudl handle responses

=over

=item to

A list of renderers to send the response to. Valid renderers are: C<log> and
C<email>.

=item log

The log renderer sends the response body to the Catalyst logger.

=over 

=item level

The log level at which the response is logged. See L<Catalyst::Log> for more
details. The default value is C<info>.

=back

=item email

The email renderer sends the response via email to a given address. The
content type, charset  and encoding are taken from the appropiate response
header (C<Content-Type> and C<Content-Encoding>). The subject is "Response for
Job <ID>".

=over

=item from

The address from which the email will be sent. The default value is 
C<< <catalyst@localhost> >>.

=item to

The address to which the email will be sent. The default value is 
C<< <root@localhost> >>.

=item smtp

The name of the SMTP server. The default value is C<localhost>.

=item disposition

How the response body should be added to the email. Valid values are C<inline>
and C<attachment>. The default value C<attachemnt>.

=back 

=back

=back

=head2 Environment variables

If you set C<CATALYST_POE_DEBUG> environment variable to a true value (like 1
or 'yes'), debug messages will be printed to STDOUT.

=head2 Job configuration

A job configuration file describes jobs and when to run them. It's syntax is
modeled after the L<crontab> file syntax. 

Each line describes a job. Comments start with '#' and run to the end of the
line.

Fields are separated by space. The first five fields describe how often the
job will be run, identical to the L<crontab> syntax (minute, hour, day of
month, month, day of week). The 6th field specifies a user which the job will
be run as (currently unused). The 7th field specifies the path used for the
job request and the rest can be used to provide additional parameters to the
request.

=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

Catalyst

POE::Component::Cron

Email::MIME::Creator

Email::Send


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-catalyst-engine-jobqueue-poe@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Gruen Christian-Rolf  C<< <kiki@abc.ro> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Gruen Christian-Rolf C<< <kiki@abc.ro> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.


=head1 SEE ALSO

L<Catalyst>, L<Catalyst::JobQueue::Job>


=cut
