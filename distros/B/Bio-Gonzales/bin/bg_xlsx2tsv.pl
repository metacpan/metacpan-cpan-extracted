#!/usr/bin/env perl
# created on 2015-01-22

use warnings;
use strict;
use 5.010;

use Bio::Gonzales::Matrix::IO qw(:DEFAULT xlsx_slurp);

use Pod::Usage;
use Getopt::Long;
use File::Spec;

my %opt = ( suffix => '.tsv', na_value => 'NA' );
GetOptions( \%opt, 'help', 'stdout|c', 'na_value=s', 'overwrite|f', 'index|i=i', 'suffix=s' ) or pod2usage(2);

pod2usage( -exitval => 0, -verbose => 2 ) if ( $opt{help} );
pod2usage(2)
  unless ( @ARGV && @ARGV > 0 );

my $in_f   = shift;
my $prefix = shift;

unless ($prefix) {
  $prefix = $in_f;
  $prefix =~ s/\..*?$//;
}

my $d = xlsx_slurp($in_f);

if ( $opt{index} && $opt{'index'} > 0 && @$d >= $opt{'index'} ) {
  say STDERR "out pattern: $prefix$opt{suffix}";
  my $idx      = $opt{index} - 1;
  my $res_file = $prefix . $opt{suffix};
  if ( $opt{stdout} ) {
    $res_file = \*STDOUT;
  } else {

    die("$res_file exists") if ( -e $res_file && !$opt{overwrite} );
  }
  clean($d->[$idx]);
  mspew( $res_file, $d->[$idx], { na_value => $opt{na_value} } );
} else {
  say STDERR "out pattern: $prefix<NUM>$opt{suffix}";
  my $i = 1;
  for my $s (@$d) {
    clean($s);
    if ( @$s > 0 ) {
      my $res_file = $prefix . $i . $opt{suffix};
      die("$res_file exists") if ( -e $res_file && !$opt{overwrite} );
      mspew( $res_file, $s, { na_value => $opt{na_value} } );
    }
    $i++;
  }
}

sub clean {
  my $d = shift;
  for my $x (@$d) {
    for my $y (@$x) {
      $y =~ y/\r\n//d if($y);
    }
  }
}

__END__

=head1 NAME


bg_xlsx2tsv - convert xlsx files to tsv format

=head1 SYNOPSIS

sample [OPTIONS] FILE PREFIX

Options:

  --help            brief help message
  --index|i=INT     only extract this sheet (1-based)
  --suffix=STRING   output file suffix
  --stdout|c        output to stdout (requires index option)

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <jwb at cpan dot org> >>

=cut
