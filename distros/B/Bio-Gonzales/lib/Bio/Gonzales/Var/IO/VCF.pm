package Bio::Gonzales::Var::IO::VCF;

use Mouse;

use warnings;
use strict;
use Carp;

use 5.010;
use List::Util qw/any/;

our $VERSION = 0.01_01;

with 'Bio::Gonzales::Util::Role::FileIO';

has meta       => ( is => 'rw', default => sub { {} } );
has sample_ids => ( is => 'rw', default => sub { [] } );
has _wrote_sth_before => ( is => 'rw' );

# stay consistent with GFF3 io
sub pragmas { shift->meta(@_) }

sub BUILD {
  my ($self) = @_;

  $self->_parse_header if ( $self->mode eq '<' );
}

sub format_header {
  my $self = shift;

  my $res = '';

  my $meta = $self->meta;
  $res .= "##fileformat=" . ( $meta->{fileformat}[0] // 'VCFv4.2' ) . "\n";
  for my $kw (qw/FILTER FORMAT INFO/) {
    next unless ( $meta->{$kw} && @{ $meta->{$kw} } > 0 );
    for my $v ( @{ $meta->{$kw} } ) {
      $res .= "##$kw=" . $v . "\n";
    }
  }

  for my $kw ( keys %$meta ) {
    next if ( any { $kw eq $_ } qw/fileformat FILTER FORMAT INFO/ );
    next unless ( @{ $meta->{$kw} } > 0 );
    for my $v ( @{ $meta->{$kw} } ) {
      $res .= "##$kw=" . $v . "\n";
    }
  }
  $res .= "#"
    . join( "\t", qw/CHROM POS ID  REF ALT QUAL  FILTER  INFO  FORMAT/, @{ $self->sample_ids } ) . "\n";
  return $res;
}

sub _write_header {
  my ($self) = @_;

  $self->_wrote_sth_before(1);

  my $fh = $self->fh;

  print $fh $self->format_header;
  return;
}

sub _parse_header {
  my $self = shift;
  my $fhi  = $self->_fhi;

  my @sample_ids;
  my %meta;
  my $l;
  while ( defined( $l = $fhi->() ) ) {
    next if ( !$l || $l =~ /^\s*$/ );
    #looks like the header is over!
    last unless $l =~ /^\#/;
    if ( $l =~ /^\s*#CHROM/ ) {

      ( undef, undef, undef, undef, undef, undef, undef, undef, undef, @sample_ids ) = split /\t/, $l;
    } elsif ( $l =~ s/^##// ) {
      my ( $k, $v ) = split /=/, $l, 2;
      $meta{$k} //= [];
      push @{ $meta{$k} }, $v;
    } else {
      next;
    }
  }
  push @{ $self->_cached_records }, $l;

  $self->meta( \%meta );
  $self->sample_ids( \@sample_ids );

  return;
}

sub next_var {
  my ($self) = @_;

  my $fhi = $self->_fhi;

  my $l;
  while ( defined( $l = $fhi->() ) ) {
    if ( $l =~ /^\#/ || $l =~ /^\s*$/ ) {
      next;
    } else {
      last;
    }
  }
  return unless $l;

  my ( $chr, $pos, $id, $ref, $alt, $qual, $filter, $info, $format, @variants ) = split /\t/, $l;
  return {
    seq_id    => $chr,
    pos       => $pos + 0,
    var_id    => $id,
    alleles   => [ $ref, split( /,/, $alt ) ],
    qual      => $qual,
    filter    => $filter,
    info      => $info,
    format    => $format,
    genotypes => \@variants,
  };
}

sub write_var {
  my ( $self, $var ) = @_;

  my $fh = $self->fh;

  $self->_write_header
    unless ( $self->_wrote_sth_before );

  my ( $ref, @alleles ) = @{ $var->{alleles} };
  $ref //= '.';
  my $alt = @alleles > 0 ? join( ",", @alleles ) : '.';
  say $fh join( "\t",
    @{$var}{qw(seq_id pos var_id)},
    $ref, $alt,
    @{$var}{qw(qual filter info format)},
    @{ $var->{genotypes} } );
}

1;

__END__

=head1 NAME

Bio::Gonzales::Var::IO::VCF - parse VCF files

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES
=head1 METHODS

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut


