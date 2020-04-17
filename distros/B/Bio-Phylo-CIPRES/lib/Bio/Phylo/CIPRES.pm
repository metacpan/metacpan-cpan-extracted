package Bio::Phylo::CIPRES;
use strict;
use warnings;
use URI;
use Carp;
use XML::Twig;
use Data::Dumper;
use LWP::UserAgent;
use YAML qw(LoadFile);
use Bio::Phylo::Util::Logger ':simple';
use Bio::Phylo::Util::Exceptions 'throw';

=head1 NAME

Bio::Phylo::CIPRES - Reusable components for CIPRES REST API access

=head1 SYNOPSIS

 my %result = Bio::Phylo::CIPRES->new( 
 	'infile'    => 'infile.fasta',                 # input data file
 	'tool'      => 'MAFFT_XSEDE',                  # tool to run
 	'param'     => { 'vparam.runtime_' => 7.5 },   # extra parameters, e.g. max runtime
 	'outfile'   => { 'output.mafft' => 'out.fa' }, # name of output data to fetch
 	'yml'       => 'config.yml',	               # client credentials
 )->run;
 
 while( my ( $name, $data ) = each %result ) {
 
    # write data to output file
 	my $outfile = "${name}.fasta";
 	open my $fh, '>', $outfile or die $!;
 	print $fh $data;
 } 

=head1 DESCRIPTION

The CyberInfrastructure for Phylogenetic RESearch (L<CIPRES|http://www.phylo.org>) is a 
portal that provides access to phylogenetic analyses tools that can be run on the XSEDE
HPC infrastructure. The portal has a web browser (point and click) interface, but also
a web service interface that can be interacted with using RESTful commands. The basic
workflow is as follows:

=over

=item * B<Launch a job>
This is done by issuing an HTTP POST request that includes: 1) HTTP authentication (i.e.
a user name and password that is registered to the realm), 2) uploading input data, 3)
configuration options for the job. The result value is an XML document that reports the
status. If all goes well, this will report that the job was launched successfully, and it
gives a URL to visit to check up on the status.

=item * B<Check job status>
The job URL is visited periodically (at most once every 60 seconds, as per CIPRES policy).
This is done using an authenticated GET request where the return value is an XML document
that reports whether the job has finished. Once it is finished, the document will include
a link to another document that lists the output data, which will be named (e.g. 
C<output.mafft>) and which will be identifiable by a URL from whence the data can be
retrieved.

=item * B<Get results>
Upon completion the results are fetched from their respective URLs. Under simple cases 
this will be just a single file (e.g. an alignment), but there could be multiple file 
types, as well as output from STDERR and STDOUT and various job status files that the
server generated internally.

=back

This module hides the complexity of this interaction, so that entire analyses can be 
run using only the commands shown in the synopsis section. The general idea is that 
you can reuse this functionality in other modules and scripts. It is also does the heavy
lifting for the L<cipresrun> executable that allows you to run analyses from terminal
interfaces.

=cut

# global constants
our $AUTOLOAD;
use version; our $VERSION = qv("v0.2.0");
my $REALM = "Cipres Authentication";
my $PORT  = 443;

=head1 METHODS

=head2 new()

The constructor takes the arguments as shown in the SYNOPSIS section. The arguments are
a direct translation of the named arguments (not option flags) that are passed on the 
command line to the L<cipresrun>  program. The value of the C<outfile> argument, and that
of the C<param> argument, is both a hash reference.

=cut

sub new {
	my $class  = shift;
	my @fields = qw[infile tool param outfile url user pass cipres_appkey];
	my $self   = bless { map { $_ => undef } @fields }, $class;
	my %args   = @_;
	while( my ( $property, $value ) = each %args ) {
		$self->$property($value);
	}
	return $self;
}

=head2 run()

Runs the entire analysis using the configuration as provided to the constructor. Returns
key value pairs where each key is an C<outfile> and each file is the data as text.

=cut

sub run {
	my $self = shift;
	my $url  = $self->launch_job;
	while(1) {
		sleep(60);
		my $status = $self->check_status($url);
		if ( $status->{'completed'} eq 'true' ) {
			$self->get_results( $status->{'outfiles'} );
			return $url;
		}
	}
}

=head2 launch_job()

Is called by C<run()>. Launches the analysis and returns the status URL at which progress
can be inspected.

=cut

sub launch_job {
	my $self = shift;
	my $ua   = $self->ua;
	my $url  = $self->url;
	my $load = $self->payload;
	my @head = $self->headers(1);
	my $res  = $ua->post( $url . '/job/' . $self->user, $load, @head );
	if ( $res->is_success ) {
	
		# run submission, parse result
		my $status_url;	
		my $result = $res->decoded_content;
		DEBUG $result;
		XML::Twig->new(
			'twig_handlers' => {
				'jobstatus/selfUri/url' => sub { $status_url = $_->text }
			}
		)->parse($result);
		INFO "Job launched at $status_url";
		return $status_url;	
	}
	else {
		throw 'NetworkError' => $res->status_line;	
	}
}

=head2 check_status()

Is called by C<run()>. Consults the status URL. Returns a hash reference whose values
specify whether the job is done, and if so, where the results can be fetched.

=cut

sub check_status {
	my ( $self, $url ) = @_;
	INFO "Going to check status for $url";
	my $ua   = $self->ua;
	my @head = $self->headers(0);
	my $res  = $ua->get( $url, @head );
	if ( $res->is_success ) {
	
		# post request, fetch result
		my ( $status, $outfiles );
		my $result = $res->decoded_content;
		DEBUG $result;
		XML::Twig->new(
			'twig_handlers' => {
				'jobstatus/resultsUri/url' => sub { $outfiles = $_->text },
				'jobstatus/terminalStage'  => sub { $status   = $_->text }			
			}
		)->parse($result);
		my $time = localtime();
		INFO "[$time] completed: $status";
		return { 'completed' => $status, 'outfiles' => $outfiles };	
	}
	else {
		throw 'NetworkError' => $res->status_line;	
	}	
}

=head2 get_results()

Is called by C<run()>. Returns the named result data as a hash.

=cut

sub get_results {
	my ( $self, $url ) = @_;	
	my %out  = %{ $self->outfile }; 
	my $ua   = $self->ua;
	my @head = $self->headers(0);
	my $res  = $ua->get( $url, @head );
	my %out_url;
	if ( $res->is_success ) {
		my $result = $res->decoded_content;
		DEBUG $result;
		XML::Twig->new(
			'twig_handlers' => {
				'results/jobfiles/jobfile' => sub {
					my $node = $_;
					my $name = $node->findvalue('filename');
					if ( $out{ $name } ) {
						$out_url{ $name } = $node->findvalue('downloadUri/url');
					}
					DEBUG $node->toString;
				}
			}
		)->parse($result);
		for my $name ( keys %out ) {
			my $location = $out_url{ $name };
			$res = $ua->get( $location, @head );
			if ( $res->is_success ) {
				open my $fh, '>', $out{ $name } or die $!;
				print $fh $res->decoded_content;
			}
			else {
				throw 'NetworkError' => $res->status_line;	
			}
		}		
	}
	else {
		throw 'NetworkError' => $res->status_line;	
	}
}

=head2 yml()

Given the location the config.yml file, populates properties of the object with the
right parameter values to authenticate the client with the CIPRES server.

=cut

sub yml {
	my ( $self, $yml ) = @_;
	INFO "Reading YAML file $yml";	
	my $info = LoadFile($yml);
	DEBUG "Parsed " . Dumper( $info );
	$self->user( $info->{'CRA_USER'} );
	$self->pass( $info->{'PASSWORD'} );
	$self->url( $info->{'URL'} );
	$self->cipres_appkey( $info->{'KEY'} );
}

=head2 ua()

Instantiates an authenticated L<LWP::UserAgent> object.

=cut

sub ua {
	my $self = shift;
	my $host = URI->new( $self->url )->host();
	my $user = $self->user;
	my $pass = $self->pass;
	my $ua   = LWP::UserAgent->new;
	DEBUG "Instantiating UserAgent $host:$PORT / $REALM / $user:****";
	$ua->ssl_opts( 'verify_hostname' => 0 );
	$ua->credentials(
		$host . ':' . $PORT,
		$REALM,
		$user => $pass
	);
	return $ua;
}

=head2 payload()

Constructs the HTTP POST payload for launching jobs. Returns an array reference of
key/value pairs.

=cut

sub payload {
	my $self = shift;
	DEBUG "Composing payload for ".$self->tool." with infile ".$self->infile;
	my $load = [
		'tool'                 => $self->tool,
		'input.infile_'        => [ $self->infile ],
		'metadata.statusEmail' => 'true',
		%{ $self->param }
	];
	DEBUG Dumper($load);
	return $load;
}

=head2 headers()

Constructs the HTTP headers to identify the client app and, optionally, to tell the
server that multipart/form-data is being attached as a payload.

=cut

sub headers {
	my ( $self, $form ) = @_;
	if ( $form ) {	
		DEBUG "Composing POST / form-data headers";	
		return (
			'Content_Type'  => 'form-data',
			'cipres-appkey' => $self->cipres_appkey,
		);
	}
	else {
		DEBUG "Composing GET headers";
		return ( 'cipres-appkey' => $self->cipres_appkey );
	}
}

=head2 clean_job()

Cleans up the job on the server that is identified by the provided input URL (i.e. the
status URL, which is the return value of the run() method).

=cut

sub clean_job {
	my ( $self, $url ) = @_;
	my $ua   = $self->ua;
	my @head = $self->headers(0);
	INFO "Going to clean job $url";
	$ua->delete( $url, @head );
}

sub AUTOLOAD {
	my ( $self, $arg ) = @_;
	my $property = $AUTOLOAD;
	$property =~ s/.*://;
	if ( exists $self->{$property} ) {
		if ( $arg ) {
			$self->{$property} = $arg;
			return $self;
		}
		else {
			return $self->{$property};
		}
	}
	else {
		my $template = 'Can\'t locate object method "%s" via package "%s"';		
		croak sprintf $template, $property, __PACKAGE__;
	}
}

sub DESTROY {
	# maybe kill and delete process on server?
}

=head1 SEE ALSO

Also consult the documentation for L<cipresrun>, which shows the usage of this module
from the command line.

=cut

1;
