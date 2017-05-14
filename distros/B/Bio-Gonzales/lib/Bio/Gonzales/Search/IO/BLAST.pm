package Bio::Gonzales::Search::IO::BLAST;

use warnings;
use strict;
use Carp;

use 5.010;

use base 'Exporter';
use Bio::Gonzales::Util::File qw/basename regex_glob is_archive/;
use List::Util qw/min max/;
use File::Temp qw/tempdir tempfile/;
use Bio::Gonzales::Seq::IO qw(faiterate faspew);

use Params::Validate qw/validate/;
our ( @EXPORT, @EXPORT_OK, %EXPORT_TAGS );
our $VERSION = '0.0546'; # VERSION

@EXPORT      = qw();
%EXPORT_TAGS = ();
@EXPORT_OK   = qw(makeblastdb);

sub makeblastdb {
  my %c = validate(
    @_,
    {
      seq_file     => 1,
      title        => 0,
      parse_seqids => { default => 0 },
      hash_index   => { default => 1 },
      alphabet     => 1,
      db_prefix    => 0,
      wd           => 0,
    }
  );

  my $unlink;
  my $seqf = $c{seq_file};
  if ( is_archive($seqf) ) {
    say STDERR "$seqf is an archive, extracting first ...";
    my $fait = faiterate($seqf);
    my ( $fh, $fn ) = tempfile();
    while ( my $s = $fait->() ) {
      faspew( $fh, $s );
    }
    $fh->close;
    $unlink = 1;
    $seqf   = $fn;
    say STDERR "extraction finished. making blast DB";
  }

  my $basename = basename( $c{seq_file} );
  my @cmd      = 'makeblastdb';
  push @cmd, '-in',    $seqf;
  push @cmd, '-title', $basename;
  push @cmd, '-parse_seqids' if ( $c{parse_seqids} );
  push @cmd, '-hash_index'   if ( $c{hash_index} );
  given ( $c{alphabet} ) {
    when (/^(?:a|p)/)   { push @cmd, '-dbtype', 'prot' }
    when (/^(?:n|d|r)/) { push @cmd, '-dbtype', 'nucl' }
  }
  $c{wd} //= './';
  $c{db_prefix} //= $basename;
  $c{db_prefix} .= '.bdb';
  my $db_name = File::Spec->catfile( $c{wd}, $c{db_prefix} );
  push @cmd, '-out', $db_name;

  my @existing_db_files = regex_glob( $c{wd}, qr/^\Q$c{db_prefix}.\En\w\w$/ );
  if ( @existing_db_files > 0 ) {
    my $oldest_db_file_age = min( map { ( stat $_ )[9] } @existing_db_files );
    my $seq_file_age = ( stat $c{seq_file} )[9];

    unless ( $seq_file_age > $oldest_db_file_age ) {
      #sequence file is older than db, so do noting
      say STDERR "sequence file $c{seq_file} is older than $db_name";
      say STDERR "Skipping blast db creation";
      return $db_name;
    }
  }

  say STDERR "Creating blast db:";
  say STDERR join " ", @cmd;
  local *STDERR;
  local *STDOUT;
  system @cmd;

  unlink $seqf if ($unlink);
  return $db_name;
}

1;
__END__

=head1 NAME

Bio::Gonzales::Search::IO::BLAST

=head1 SYNOPSIS

    Bio::Gonzales::Search::IO::BLAST qw(makeblastdb instantblast)

=head1 DESCRIPTION

=head1 OPTIONS

=head1 SUBROUTINES

=over 4

=item B<< $db_location = makeblastdb(\%config) >>

Creates a blast database with the config options supplied. Config options are:

    %config = (
        'seq_file!'  => undef,
        title        => 'basename of seq_file',
        parse_seqids => 1,
        hash_index   => 1,
        'alphabet!'  => 'n(ucleotide)? || p(rotein)? || d(na)? || a(a)?',
        db_prefix    => 'basename of seq_file.bdb',
        wd           => './',
    );

Options with C<!> are required.

=back

=head1 SEE ALSO

=head1 AUTHOR

jw bargsten, C<< <joachim.bargsten at wur.nl> >>

=cut
