package Bio::BioVeL::AsynchronousService::TNRS;
use strict;
use warnings;
use Bio::BioVeL::AsynchronousService;
use base 'Bio::BioVeL::AsynchronousService';

=head1 NAME

Bio::BioVeL::AsynchronousService::TNRS - wrapper for the SUPERSMART TNRS service

=head1 DESCRIPTION

B<NOTE>: this service is untested, it is a work in progress. It is meant to show
how the scripts of the L<http://www.supersmart-project.org> could be executed as
asynchronous web services.

=head1 METHODS

=over

=item new

The constructor specifies one object property: the location of the input C<names>
list.

=cut

sub new {
	shift->SUPER::new( 'parameters' => [ 'names' ], @_ );
}

=item launch

Launches the TNRS script. This will require the SUPERSMART_HOME environment 
variable to be defined, which when running under mod_perl needs to be done by
adding something like the following to httpd.conf:

 PerlSetEnv SUPERSMART_HOME /Library/WebServer/Perl/supersmart

=cut

sub launch {
	my $self = shift;
	
	# this results dir may be made visible to the user
	my $outfile = $self->outdir . '/taxa.tsv';
	my $infile  = $self->outdir . '/names.txt';
	my $logfile = $self->outdir . '/TNRS.log';
	
	# SUPERSMART_HOME needs to be known and accessible to the httpd process
	my $script = $ENV{'SUPERSMART_HOME'} . '/script/supersmart/mpi_write_taxa_table.pl';
	
	# fetch the input file
	my $readfh  = $self->open_handle( $self->names );	
	open my $writefh, '>', $infile;
	print $writefh $_ while <$readfh>; 
	
	# run the job
	if ( system( $script, '-i' => $infile, ">$outfile", "2>$logfile" ) ) {
		$self->status( Bio::BioVeL::AsynchronousService::ERROR );
		$self->lasterr( $? );
	}
	else {
		$self->status( Bio::BioVeL::AsynchronousService::DONE );
	}
}

=item response_location

B<NOTE>: this is an untested feature. The idea is that child classes can re-direct
the client to an alternate location with, e.g. the most important output file or a
directory listing of files.

=cut

sub response_location { shift->outdir . '/taxa.tsv' }

=item response_body

Returns the analysis result as a string. In this service, this is the tab-separated
file of names-to-taxon-ID mappings.

=cut

sub response_body {
	my $self = shift;
	open my $fh, '<', $self->outdir . '/taxa.tsv';
	my @result = do { local $/; <$fh> };
	return join "\n", @result;
}

=back

=cut

1;