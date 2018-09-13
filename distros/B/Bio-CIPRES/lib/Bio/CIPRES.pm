package Bio::CIPRES;

use 5.012;
use strict;
use warnings;

use Carp;
use Config::Tiny;
use List::Util qw/first/;
use LWP;
use URI;
use URI::Escape;
use XML::LibXML;

use Bio::CIPRES::Job;
use Bio::CIPRES::Error;

our $VERSION = '0.004002';
our $SERVER  = 'cipresrest.sdsc.edu';
our $API     = 'cipresrest/v1';
our $DOMAIN  = 'Cipres Authentication';

my %required = ( # must be defined after config parsing
    url     => "https://$SERVER/$API/",
    timeout => 60,
    app_id  => 'cipres_perl-E9B8D52FA2A54472BF13F25E4CD957D4',
    user    => undef,
    pass    => undef,
);

my %umb_only = ( # only for UMBRELLA auth
    eu             => undef, # if this is defined, then the rest are:
    eu_email       => undef, # REQUIRED
    app_name       => undef, # REQUIRED
    eu_institution => undef, # optional
    eu_country     => undef, # optional
);

my @eu_headers = qw/
    eu
    eu_email
    eu_institution
    eu_country
/;

sub new {

    my ($class, %args) = @_;
    my $self = bless {}, $class;

    # parse properties from file or constructor
    $self->_parse_args(%args);

    # setup user agent
    $self->{agent} = LWP::UserAgent->new(
        agent    => __PACKAGE__ . "/$VERSION",
        ssl_opts => {verify_hostname => 0},
        timeout  => $self->{cfg}->{timeout},
    );
   
    # create URI object for easier protocol/port parsing
    $self->{uri} = URI->new( $self->{cfg}->{url} );

    my $netloc = join ':', $self->{uri}->host, $self->{uri}->port;
    $self->{agent}->credentials(
        $netloc,
        $DOMAIN,
        $self->{cfg}->{user},
        $self->{cfg}->{pass}
    );

    my %headers = ( 'cipres-appkey' => $self->{cfg}->{app_id} );

    $self->{account} = uri_escape( $self->{cfg}->{user} );

    # UMBRELLA headers
    if (defined $self->{cfg}->{eu}) {
        croak "eu_email required for UMBRELLA authentication"
            if (! defined $self->{cfg}->{'eu_email'});
        croak "app_name required for UMBRELLA authentication"
            if (! defined $self->{cfg}->{'app_name'});
        for my $h (@eu_headers) {
            my $val = $self->{cfg}->{$h} // next;
            $h =~ s/_/\-/g;
            $headers{"cipres-$h"} = $val;
        }

        $self->{account}
            = uri_escape( "$self->{cfg}->{app_name}.$self->{cfg}->{eu}" );
    }

    $self->{uri}->path("/$API/job/$self->{account}");
    $self->{agent}->default_header(%headers);

    croak "Failed CIPRES API connection test\n"
        if (! $self->_check_connection);

    return $self;

}

sub _parse_args {

    my ($self, %args) = @_;
    my ($fn_cfg) = delete $args{conf};

    # set defaults
    $self->{cfg} = {%required}; # copy, don't reference!

    # read from config file if asked, overwriting defaults
    if (defined $fn_cfg) {
        croak "Invalid or missing configuration file specified"
            if (! -e $fn_cfg);
        my $cfg = Config::Tiny->read( $fn_cfg )
            or croak "Error reading configuration file: $@";
        $self->{cfg}->{$_} = $cfg->{_}->{$_}
            for (keys %{ $cfg->{_} });

    }

    # read parameters from constructor, overwriting if present
    $self->{cfg}->{$_} = $args{$_} for (keys %args);

    # check that all defined fields are valid
    my @extra = grep {! exists $required{$_} && ! exists $umb_only{$_}}
        keys %{ $self->{cfg} };
    croak "Unexpected config variables found (@extra) -- check syntax"
        if (scalar @extra);

    # check that all required fields are defined
    my @missing = grep {! defined $self->{cfg}->{$_}} keys %required;
    croak "Required config variables missing (@missing) -- check syntax"
        if (scalar @missing);

    # TODO: further parameter validation ???

    return 1;

}

sub list_jobs {

    my ($self) = @_;

    my $res = $self->_get( "$self->{uri}?expand=true" );
    my $dom = XML::LibXML->load_xml('string' => $res);

    return map {
        Bio::CIPRES::Job->new( agent => $self->{agent}, dom => $_ )
    } $dom->findnodes('/joblist/jobs/jobstatus');

}

sub get_job {

    my ($self, $handle) = @_;

    my $res = $self->_get( "$self->{uri}/$handle" );
    my $dom = XML::LibXML->load_xml('string' => $res);

    return Bio::CIPRES::Job->new(
        agent => $self->{agent},
        dom   => $dom,
    );

}

sub submit_job {

    my ($self, @args) = @_;

    my $res = $self->_post( $self->{uri}, @args );
    my $dom = XML::LibXML->load_xml('string' => $res);

    return Bio::CIPRES::Job->new(
        agent => $self->{agent},
        dom   => $dom,
    );

}

sub _get {

    my ($self, $url) = @_;

    my $res = $self->{agent}->get( $url )
        or croak "Error fetching file from $url: $@";

    die Bio::CIPRES::Error->new( $res->content )
        if (! $res->is_success);

    return $res->content;

}

sub _post {

    my ($self, $url, @args) = @_;

    my $res = $self->{agent}->post(
        $url,
        [ @args ],
        'content_type' => 'form-data',
    ) or croak "Error POSTing to $url: $@";

    die Bio::CIPRES::Error->new( $res->content )
        if (! $res->is_success);

    return $res->content;

}

sub _check_connection {

    # do a basic check of the API, fetching the link page

    my ($self) = @_;

    my $uri = $self->{uri}->clone();
    $uri->path($API);
    my $res = $self->_get( "$uri" );
    my $dom = XML::LibXML->load_xml('string' => $res);

    $dom = $dom->firstChild;
    return( $dom->nodeName eq 'links' );


}

1;


__END__

=head1 NAME

Bio::CIPRES - interface to the CIPRES REST API

=head1 SYNOPSIS

    use Bio::CIPRES;

    my $ua = Bio::CIPRES->new(
        user    => $username,
        pass    => $password,
        app_id  => $id,
        timeout => 60,
    );

    my $job = $ua->submit_job( %job_params );

    while (! $job->is_finished) {
        sleep $job->poll_interval;
        $job->refresh;
    }

    print STDOUT $job->stdout;
    print STDERR $job->stderr;

    if ($job->exit_code == 0) {

        for my $file ($job->outputs) {
            $file->download( out => $file->name );
        }

    }
    

=head1 DESCRIPTION

C<Bio::CIPRES> is an interface to the CIPRES REST API for running phylogenetic
analyses. Currently it provides general classes and methods for job submission
and handling - determination of the correct parameters to submit is up to the
user (check L<SEE ALSO> for links to tool documentation).

=head1 METHODS

=over 4

=item B<new>

    my $ua = Bio::CIPRES->new(
        user    => $username,
        pass    => $password,
        app_id  => $id,
        timeout => 60,
    );

    # or read configuration from file

    my $ua = Bio::CIPRES->new(
        conf => "$ENV{HOME}/.cipres"
    );

Create a new C<Bio::CIPRES> object. There are a number of required and
optional parameters which can be specified in the constructor or read from a
configuration file. The configuration file should contain key=value pairs, one
pair per line, as in:

    user=foo
    pass=bar
    app_id=foo_bar-12345

Required parameters (no defaults):

=over 1

=item * user - the username of your registered CIPRES REST account

=item * pass - the password of your registered CIPRES REST account

=back

The passphrase must be stored in plaintext, so the usual precautions apply
(e.g. the file should not be world-readable). If possible, find another way to
retrieve the passphrase within your code and pass it in directly as a method
argument.

Optional parameters (must be defined but defaults are provided):

=over 1

=item * app_id - override the application ID assigned to Bio::CIPRES 

=item * url - override the default base REST url (don't change this unless you
know what you're doing).

=item * timeout - set the network timeout for HTTP requests

=back

UMBRELLA parameters:

These parameters are only for use with UMBRELLA applications (you will need
you register your own UMBRELLA application to use this functionality). They
are not needed for non-UMBRELLA applications, but if C<eu> is defined then
UMBRELLA is assumed and C<eu_email> and C<app_name> must be defined as well.

=over 1

=item * eu - end user name

=item * eu_email - end user email address

=item * app_name - UMBRELLA application name as registered with CIPRES

=item * eu_institution - end user institution (currently optional)

=item * eu_country - end user two-letter country code (currently optional)

=back

=item B<submit_job>

    my $job = $ua->submit_job( %params );

Submit a new job to the CIPRES service. Params are set based on the tool
documentation (not covered here). Returns a L<Bio::CIPRES::Job> object.

Most params are passed as simple key => value pairs of strings based on the
CIPRES tool documentation. B<One important nuance>, however, is in the
handling of input files. If the contents of a input file are to be passed in
as a scalar, they should be provided directly as the scalar value to the
appropriate key:

    my $job = $ua->submit_job( 'input.infile_' => $in_contents );

However, if the input file is to be uploaded by filename, it should be passed
as an array reference:

    my $job = $ua->submit_job( 'input.infile_' => [$in_filename] );

Failure to understand the difference will result in errors either during job
submission or during the job run.

=item B<list_jobs>

    for my $job ( $ua->list_jobs ) {
        # do something
    }

Returns an array of L<Bio::CIPRES::Job> objects representing jobs in the
user's workspace.

=item B<get_job>

    my $job = $ua->get_job( $job_handle );

Takes a single argument (string containing the job handle/ID) and returns a
L<Bio::CIPRES::Job> object representing the appropriate job, or undef if not
found.

=back

=head1 TESTING

The distribution can be installed and tested in the usual ways. Note however,
that running the full test suite requires CIPRES REST credentials (not shipped
with package for obvious reasons). If a credentials file is found at
"$ENV{HOME}/.cipres", the full test suite will be run -- otherwise only
rudimentary tests will be run and most will be skipped.

=head1 CAVEATS AND BUGS

This is code is in alpha testing stage and the API is not guaranteed to be
stable.

Currently the use of UMBRELLA authentication is not implemented.

Please report bugs to the author.

=head1 SEE ALSO

L<https://www.phylo.org/restusers/documentation.action>

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2016-2018 Jeremy Volkening

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

