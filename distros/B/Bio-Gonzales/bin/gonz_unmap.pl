#!/usr/bin/env perl
# created on 2013-12-19

use warnings;
use strict;
use 5.010;

use Bio::Gonzales::Matrix::IO;

use Bio::Gonzales::Util::File qw/openod/;
use Pod::Usage;
use Getopt::Long qw(:config);

my %opt = ();
GetOptions(
  \%opt,      'skip_na',     'comment=s',   'keep',     'header|h', 'col|m=i@',
  'filter=s', 'na_prefix:s', 'na_suffix:s', 'from|k=i', 'to|v=i',   'multi', 'help|?'
) or pod2usage(2);
pod2usage(1) if($opt{help});

my ( $map_fn, $data_fn, $out_fn ) = @ARGV;
pod2usage("$map_fn is no file")            unless ( -f $map_fn );
pod2usage("$data_fn is no file")           unless ( -f $data_fn || $data_fn eq '-' );
pod2usage("no output file (- for stdout)") unless ($out_fn);
pod2usage("no columns selected") unless ( exists( $opt{from} ) && exists( $opt{to} ) && exists( $opt{col} ) );

$out_fn  = \*STDOUT if ( $out_fn  eq '-' );
$data_fn = \*STDIN  if ( $data_fn eq '-' );

my $filter;
if ( $opt{filter} ) {
  $filter = sub {
    return $_[0] =~ /$opt{filter}/;
    }
}

my $map = dict_slurp( $map_fn,
  { key_idx => $opt{from}, val_idx => $opt{to}, uniq => 0, record_filter => $filter } );

my ( $fh,     undef ) = openod( $data_fn, '<' );
my ( $out_fh, undef ) = openod( $out_fn,  '>' );

if ( $opt{header} ) {
  print $out_fh scalar <$fh>;
}
my $keep = 0;

$keep = 1 if ( $opt{keep} );

ROW:
while (<$fh>) {
  print $out_fh $_ and next if ( $opt{comment} && /^$opt{comment}/ );
  chomp;
  my @f = split /\t/;
  for my $c ( @{ $opt{col} } ) {
    my $id = $f[$c];

    unless ( exists $map->{$id} ) {

      next ROW if ( $opt{skip_na} );

      die "could not map $id ($data_fn)"
        unless ( exists( $opt{na_suffix} ) || exists( $opt{na_prefix} ) );

      $id .= $opt{na_suffix} if ( exists( $opt{na_suffix} ) );
      $id = $opt{na_prefix} . $id if ( exists( $opt{na_prefix} ) );
      splice @f, $c + $keep, 1 - $keep, $id;
      say $out_fh join "\t", @f;
    } else {
      for my $v ( @{ $map->{$id} } ) {
        my @ff = @f;
        splice @ff, $c + $keep, 1 - $keep, $v;
        say $out_fh join "\t", @ff;
        last unless ( $opt{multi} );
      }
    }
  }
}
$fh->close;
$out_fh->close;

__END__

=head1 NAME

gonz_unmap.pl - unmap or remap identifiers/strings using a given id mapping

=head1 SYNOPSIS

  Usage: gonz_unmap.pl [OPTIONS] <map_file> <input_file> <output_file>

  gonz_unmap.pl will (un)map or remap identifiers of tables using a given id
  mapping. All input files are exptected to be tab-separated. Column numbers
  are zero-based.

  Examples:
    gonz_unmap.pl --from 0 --to 1 --col 0 map.tsv data.tsv data.unmapped.tsv
    # remaps column 0 (the 1st column) of data.tsv using the mapping of 
    # column 0 -> column 1 in map.tsv and saves it to data.unmapped.tsv.

 OPTIONS:

  -?, --help               show the full help with all options explained

  -k, --from
  -v, --to
  -m, --col=<NUMBER>
      --skip_na
      --comment=<REGEX>
      --keep
  -h, --header
      --filter=<REGEX>
      --na_prefix=<STRING>
      --na_suffix=<STRING>
      --multi
  
=head1 SEE ALSO

=head1 OPTIONS

=over 4

=item B<< --from >>

The column to match the ids against

=item B<< --to >>

If the C<from> column has a match, output the id in column C<to>.

=item B<< --col >>

The columns that should be mapped. Can be used multiple times to map multiple
columns with the same mapping at the same time.

=item B<< --skip_na >>

Do only output sucessfully mapped ids/strings.

(usually C<gonz_unmap.pl> dies if a mapping fails)

=item B<< --comment=<REGEX> >>

The data input has comments of the form C<< <REGEX> >>, just copy it directly
to the output.

=item B<< --keep >>

Do not replace the ids in the C<col>-column, but add a new column after it
with the mapped ids.

=item B<< --header >>

The data file has a header, just copy it directly to the output.

=item B<< --filter=<REGEX> >>

Prefilter the input data by C< <REGEX> >

=item B<< --na_prefix=<STRING> >>

Prefix the original ids with C<< <STRING> >> and take the prefixed version as
mapped id.

(usually C<gonz_unmap.pl> dies if a mapping fails)

=item B<< --na_suffix >>

Add the suffix C<< <STRING> >> the original ids and take the suffixed version
as mapped id.

(usually C<gonz_unmap.pl> dies if a mapping fails)

=item B<< --multi >>

If one id (from) maps to multiple ids (to), output all mappings. Default is to
take the last encountered (from,to)-pair as mapping entry.

=back

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
