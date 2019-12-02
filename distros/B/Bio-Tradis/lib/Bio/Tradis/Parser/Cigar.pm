package Bio::Tradis::Parser::Cigar;
$Bio::Tradis::Parser::Cigar::VERSION = '1.4.3';
# ABSTRACT: Take in a cigar string and output start and end relative to the reference sequence


use Moose;

has 'cigar'      => ( is => 'ro', isa => 'Str', required => 1 );
has 'coordinate' => ( is => 'ro', isa => 'Num', required => 1 );

has '_results' =>  (is      => 'ro', isa     => 'HashRef', lazy    => 1, builder => '_build__results');

sub _build__results
{
	my($self) = @_;
	my %results = ( start => 0, end => 0);
	my $current_coordinate = $self->coordinate;

	my @cigar_parts = $self->cigar =~ /(\d+[MIDNSHP=X])/g;
	for my $cigar_item (@cigar_parts)
	{
		if( $cigar_item =~ /(\d+)([MIDNSHP=X])/)
		{
			my $number = $1;
			my $action = $2;
			
			if($action eq 'M' || $action eq 'X' || $action eq '=' )
			{
				$results{start} = $current_coordinate if($results{start} == 0);
				$current_coordinate += $number;
				$results{end} = $current_coordinate -1 if($results{end} < $current_coordinate);
			}
			elsif($action eq 'S' || $action eq 'D' || $action eq 'N')
			{
				$current_coordinate += $number;
			}
			elsif($action eq 'I' )
			{
				# do nothing
			}
		}
	}
	
	return \%results;
}

sub start
{
	my($self) = @_;
	return $self->_results->{start};
}

sub end
{
	my($self) = @_;
	return $self->_results->{end};
}
__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bio::Tradis::Parser::Cigar - Take in a cigar string and output start and end relative to the reference sequence

=head1 VERSION

version 1.4.3

=head1 SYNOPSIS

Take in a cigar string and output start and end relative to the reference sequence

   use Bio::Tradis::Parser::Cigar;
   
   my $cigar = Bio::Tradis::Parser::Cigar->new(coordinate => 123, cigar => '10S90M');
   $cigar->start;
   $cigar->end;

=head1 AUTHOR

Carla Cummins <path-help@sanger.ac.uk>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by Wellcome Trust Sanger Institute.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
