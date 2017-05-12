package Bio::RetrieveAssemblies::RemoteSpreadsheetRole;
$Bio::RetrieveAssemblies::RemoteSpreadsheetRole::VERSION = '1.1.5';
use Moose::Role;
use Text::CSV;
use Data::Validate::URI qw(is_uri);
use File::Slurp::Tiny qw(read_file write_file);
use Bio::RetrieveAssemblies::Exceptions;
use Log::Log4perl qw(:easy);
with('Bio::RetrieveAssemblies::LoggingRole');

# ABSTRACT: Role for downloading a spreadsheet


has 'url'                     => ( is => 'ro', isa => 'Str',       required => 1 );
has 'accession_column_index'  => ( is => 'ro', isa => 'Int',       default  => 0 );
has 'accession_column_header' => ( is => 'ro', isa => 'Str',       required => 1 );
has '_tsv_parser'             => ( is => 'ro', isa => 'Text::CSV', lazy     => 1, builder => '_build__tsv_parser' );
has '_tsv_content'            => ( is => 'ro', isa => 'ArrayRef',  lazy     => 1, builder => '_build__tsv_content' );
has '_output_file'            => ( is => 'ro', isa => 'Str',       default => '.spreadsheet_query');

sub _build__tsv_parser {
    my ($self) = @_;
    my $tsv_parser = Text::CSV->new( { binary => 1, sep_char => "\t" } )
      or Bio::RetrieveAssemblies::Exceptions::CSVParser->throw( error => "Cannot use CSV: " . Text::CSV->error_diag() );

    return $tsv_parser;
}

sub _build__tsv_content {
    my ($self) = @_;

    my $tsv_content = "";

    # If its not a url, then try opening it as a file
    if ( is_uri( $self->url ) ) {
		
		$self->logger->info("Downloading url: ".$self->url);
		my $quiet_str = "-q";
		if($self->verbose)
		{
			$quiet_str = "";
		}
		my $cmd = "wget $quiet_str -O ".$self->_output_file." '".$self->url."'";
		$self->logger->info("Downloading cmd: ".$cmd);
		system($cmd);
        $tsv_content = read_file( $self->_output_file );
		unlink($self->_output_file);
          
    }
    else {
        $tsv_content = read_file( $self->url );
    }

    $tsv_content =~ s/[\r\n]+/\n/;
    my @lines = split( /\n/, $tsv_content );
    return \@lines;
}

sub _build_accessions {
    my ($self) = @_;

    my %accessions;
	$self->logger->info("Parsing downloaded file");
    for my $line ( @{ $self->_tsv_content } ) {
        $self->_tsv_parser->parse($line);
        my @columns = $self->_tsv_parser->fields();
        next if ( $columns[ $self->accession_column_index ] eq $self->accession_column_header );
        next if ( $columns[0] eq '' || $columns[0] =~ /^#/ );
        if ( $self->_filter_out_line( \@columns ) )
		{
			next ;
		}

        $accessions{ $columns[ $self->accession_column_index ] } = 1;
    }
    return \%accessions;
}

sub _filter_out_line {
    my ( $self, $columns ) = @_;
    return 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::RetrieveAssemblies::RemoteSpreadsheetRole - Role for downloading a spreadsheet

=head1 VERSION

version 1.1.5

=head1 SYNOPSIS

Role for downloading a spreadsheet

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
