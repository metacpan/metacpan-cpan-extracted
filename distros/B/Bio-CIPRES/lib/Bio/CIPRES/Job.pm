package Bio::CIPRES::Job 0.001;

use 5.012;
use strict;
use warnings;

use overload
    '""' => sub {return $_[0]->{handle}};

use Carp;
use Time::Piece;
use XML::LibXML;
use Scalar::Util qw/blessed weaken/;
use List::Util qw/first/;

use Bio::CIPRES::Output;
use Bio::CIPRES::Error;


sub new {

    my ($class, %args) = @_;

    my $self = bless {}, $class;

    croak "Must define user agent" if (! defined $args{agent});
    croak "Agent must be an LWP::UserAgent object"
        if ( blessed($args{agent}) ne 'LWP::UserAgent' );
    $self->{agent} = $args{agent};
    weaken( $self->{agent} );

    croak "Must define initial status" if (! defined $args{dom});
    $self->_parse_status( $args{dom} );

    return $self;

}

sub delete {

    my ($self) = @_;

    my $res = $self->{agent}->delete( $self->{url_status} )
        or croak "LWP internal error: $@";

    die Bio::CIPRES::Error->new( $res->content )
        if (! $res->is_success);

    return 1;

}

sub is_finished   { return $_[0]->{is_finished} }
sub is_failed     { return $_[0]->{is_failed}   }
sub poll_interval { return $_[0]->{poll_secs}   }
sub submit_time   { return $_[0]->{submit_time} }

sub stage {

    my ($self) = @_;

    # Should be as easy as this:

    # return $self->{stage};

    # But the docs say:
    #
    # "Unfortunately, the current version of CIPRES sets
    # jobstatus.jobStage in a way that's somewhat inconsistent and difficult
    # to explain. You're better off using jobstatus.messages to monitor the
    # progress of a job."
    #
    # so we follow their advice.

    map {$_->{timestamp} =~ s/(\d\d)\:(\d\d)$/$1$2/}
        @{ $self->{messages} };

    my @sorted = sort {
        $a->{timestamp} <=> $b->{timestamp}
    } @{ $self->{messages} };

    return $sorted[-1]->{stage};

}

sub refresh {

    my ($self) = @_;

    my $xml = $self->_get( $self->{url_status} );
    my $dom = XML::LibXML->load_xml( string => $xml );
    $self->_parse_status($dom);

    return 1;

}

sub outputs {

    my ($self, %args) = @_;

    # download values if necessary
    if ($args{force_download} || ! defined $self->{outputs}) {
        my $xml = $self->_get( $self->{url_results} );
        my $dom = XML::LibXML->load_xml( string => $xml );

        $self->{outputs} = [ map {
            Bio::CIPRES::Output->new( agent => $self->{agent}, dom  => $_ )
        } $dom->findnodes('/results/jobfiles/jobfile') ];
    }

    return grep {
        (! defined $args{group} || $_->group eq $args{group} ) &&
        (! defined $args{name}  || $_->name  eq $args{name}  )
    } @{ $self->{outputs} };
   
}

sub exit_code {

    my ($self) = @_;

    my ($file) = $self->outputs(name => 'done.txt');

    return undef if (! defined $file);

    my $content = $file->download;
    if ($content =~ /^retval=(\d+)$/m) {
        return $1;
    }
  
    # uncoverable statement
    return undef;
       
}

sub stdout {

    my ($self) = @_;
    my ($file) = $self->outputs(name => 'STDOUT');
    return defined $file ? $file->download : undef;
    
}

sub stderr {

    my ($self) = @_;
    my ($file) = $self->outputs(name => 'STDERR');
    return defined $file ? $file->download : undef;
    
}

sub wait {

    my ($self, $timeout) = @_;

    $timeout //= -1;

    my $start = time;
    while (! $self->is_finished) {
        sleep $self->poll_interval;
        $self->refresh;
        next if ($timeout < 0);
        return 0 if (time - $start > $timeout);
    }
    return 1;

}

sub _get {

    my ($self, $url) = @_;

    my $res = $self->{agent}->get( $url )
        or croak "LWP internal error: $@";

    die Bio::CIPRES::Error->new( $res->content )
        if (! $res->is_success);

    return $res->content;

}

sub _parse_status {

    my ($self, $dom) = @_;

    my $s = {};

    # remove outer tag if necessary
    my $c = $dom->firstChild;
    $dom = $c if ($c->nodeName eq 'jobstatus');

    $s->{handle}      = $dom->findvalue('jobHandle');
    $s->{url_status}  = $dom->findvalue('selfUri/url');
    $s->{url_results} = $dom->findvalue('resultsUri/url');
    $s->{url_working} = $dom->findvalue('workingDirUri/url');
    $s->{poll_secs}   = $dom->findvalue('minPollIntervalSeconds');
    $s->{is_finished} = $dom->findvalue('terminalStage') =~ /^true$/i ? 1 : 0;
    $s->{is_failed}   = $dom->findvalue('failed') =~ /^true$/i ? 1 : 0;;
    $s->{stage}       = $dom->findvalue('jobStage');
    $s->{submit_time} = $dom->findvalue('dateSubmitted');

    # check for missing values
    map {length $s->{$_} || croak "Missing value for $_\n"} keys %$s;

    # parse submit time
    my $submit_time = $s->{submit_time};
    $submit_time =~ s/(\d\d):(\d\d)$/$1$2/;
    $submit_time = Time::Piece->strptime(
        $submit_time,
        "%Y-%m-%dT%H:%M:%S%z",
    ) or croak "Failed to parse submit time ($s->{submit_time})\n";
    $s->{submit_time} = $submit_time;

    # parse messages
    for my $msg ($dom->findnodes('messages/message')) {
        my $t = $msg->findvalue('timestamp');
        $t =~ s/(\d\d):(\d\d)$/$1$2/;
        my $ref = {
            timestamp => Time::Piece->strptime($t, "%Y-%m-%dT%H:%M:%S%z"),
            stage     => $msg->findvalue('stage'),
            text      => $msg->findvalue('text'),
        };

        # check for missing values
        map {length $ref->{$_} || croak "Missing value for $_\n"} keys %$ref;

        push @{ $s->{messages} }, $ref;

    }

    # parse metadata
    for my $meta ($dom->findnodes('metadata/entry')) {
        my $key = $meta->findvalue('key');
        my $val = $meta->findvalue('value');

        # check for missing values
        map {length $_ || croak "Unexpected metadata format\n"} ($key, $val);

        $s->{meta}->{$key} = $val;
    }

    $self->{$_} = $s->{$_} for (keys %$s);

    return 1;

}

1;

__END__

=head1 NAME

Bio::CIPRES::Job - a CIPRES job class

=head1 SYNOPSIS

    use Bio::CIPRES;

    my $ua  = Bio::CIPRES->new( %args );
    my $job = $ua->submit_job( %params );

    $job->wait(6000) or die "Timeout waiting for job completion";

    warn "Job returned non-zero status" if ($job->exit_code != 0);

    print STDOUT $job->stdout;
    print STDERR $job->stderr;

    $job->delete;

=head1 DESCRIPTION

C<Bio::CIPRES::Job> is a class representing a single CIPRES job. Its purpose
is to simplify handling of job status and job outputs.

Users should not create C<Bio::CIPRES::Job> objects directly - they are
returned by methods in the L<Bio::CIPRES> class.

=head1 METHODS

=over 4

=item B<stage>

    if ($job->stage eq 'QUEUE') {}

Returns a string describing the current stage of the job.

=item B<refresh>

    $job->refresh;

Makes a call to the API to retrieve the current status of the job, and updates
the object attributes accordingly. Generally this is called as part of a while
loop while waiting for a job to complete.

=item B<is_finished>

    if ($job->is_finished) {}

Returns true if the job has completed, false otherwise.

=item B<is_failed>

    die "CIPRES error" if ($job->is_failed);

Returns true if the submission has failed, false otherwise. Note that, according to
the API docs, this value can be false even if the job itself has failed for
some reason. Use L<Bio::CIPRES::Job::exit_code> for a more reliable way to
check for job success.

=item B<poll_interval>

    my $s = $job->poll_interval;

Returns the minimum number of seconds that the client should wait between
status updates. Generally this is called as part of a while loop.

=item B<wait>

    $job->wait($timeout) or die "Timeout waiting for job to finish";

Enters a blocking loop waiting for the job to finish. Takes a single optional
argument of the maximum number of seconds to wait before timing out (default:
no timeout). Returns true if the job finishes or false if the wait times out.

=item B<outputs>

    my @results = $job->outputs(
        name  => 'foo.txt',
        group => 'bar',
        force_download => 0,
    );

Returns an array of L<Bio::CIPRES::Output> objects representing files
generated by the job. Generally this should only be called after a job has
completed. By default returns all available outputs. Possible arguments
include:

=over 2

=item  * group

Limit returned outputs to those in the specified group

=item  * name

Limit returned output to that with the specified name

=item  * force_download

Force the client to re-download output list (as opposed to using cached
values). This is automatically called from within L<Bio::CIPRES::Job::refresh> and
generally doesn't need to be set by the user. (default: false)

=back

=item B<exit_code>

    warn "Job returned non-zero status" if ($job->exit_code != 0);

Returns the actual exit code of the job on the remote server. Exit codes < 0
indicate API or server errors, while exit codes > 0 indicate errors in the job
tool itself (possibly described in the tool's documentation).

=item B<stdout>

    print STDOUT $job->stdout;

Returns the STDOUT from the job as a string.

=item B<stderr>

    print STDERR $job->stderr;

Returns the STDERR from the job as a string.

=item B<submit_time>

Returns the original submission date/time as a Time::Piece object


=item B<delete>

    $job->delete;

Deletes a job from the user workspace, including all of the output files.
Generally this should be called once a job is completed and all desired output
files have been fetched. This will help to keep the user workspace clean.

=back

=head1 CAVEATS AND BUGS

Please reports bugs to the author.

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


