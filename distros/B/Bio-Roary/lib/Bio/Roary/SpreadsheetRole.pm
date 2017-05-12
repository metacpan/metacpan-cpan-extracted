package Bio::Roary::SpreadsheetRole;
$Bio::Roary::SpreadsheetRole::VERSION = '3.8.0';
# ABSTRACT: Read and write a spreadsheet

use Moose::Role;

has 'spreadsheet'            => ( is => 'ro', isa  => 'Str',      required => 1 );
has '_fixed_headers'         => ( is => 'ro', isa  => 'ArrayRef', lazy    => 1, builder => '_build__fixed_headers' );
has '_input_spreadsheet_fh'  => ( is => 'ro', lazy => 1,          builder => '_build__input_spreadsheet_fh' );
has '_output_spreadsheet_fh' => ( is => 'ro', lazy => 1,          builder => '_build__output_spreadsheet_fh' );
has '_fixed_headers'         => ( is => 'ro', isa  => 'ArrayRef', lazy    => 1, builder => '_build__fixed_headers' );
has '_num_fixed_headers'     => ( is => 'ro', isa  => 'Int',      lazy    => 1, builder => '_build__num_fixed_headers' );
has '_csv_parser'            => ( is => 'ro', isa  => 'Text::CSV',lazy    => 1, builder => '_build__csv_parser' );
has '_csv_output'            => ( is => 'ro', isa  => 'Text::CSV',lazy    => 1, builder => '_build__csv_output' );

sub BUILD
{
	my ($self) = @_;
	$self->_input_spreadsheet_fh;
}

sub _build__fixed_headers
{
  my ($self) = @_;
  my @fixed_headers = @{Bio::Roary::GroupStatistics->fixed_headers()};
  return \@fixed_headers;
}

sub _build__csv_parser
{
  my ($self) = @_;
  return Text::CSV->new( { binary => 1, always_quote => 1} );
}

sub _build__csv_output
{
  my ($self) = @_;
  return Text::CSV->new( { binary => 1, always_quote => 1, eol => "\r\n"} );
}

sub _build__input_spreadsheet_fh {
    my ($self) = @_;
    open( my $fh, $self->spreadsheet ) or die "Couldnt open input spreadsheet: ".$self->spreadsheet ;
    return $fh;
}

sub _build__output_spreadsheet_fh {
    my ($self) = @_;
    open( my $fh, '>', $self->output_filename );
    return $fh;
}

sub _build__num_fixed_headers
{
  my ($self) = @_;
  return @{$self->_fixed_headers};
}



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Roary::SpreadsheetRole - Read and write a spreadsheet

=head1 VERSION

version 3.8.0

=head1 SYNOPSIS

with 'Bio::Roary::SpreadsheetRole';

=head1 AUTHOR

Andrew J. Page <ap13@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
