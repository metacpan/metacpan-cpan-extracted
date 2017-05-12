use strict;
use warnings;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Archive::Tar;
use CPAN::Visitor;
use CPAN::Mini;
use Getopt::Long;

my $jobs = 0;
GetOptions( 'jobs:i' => \$jobs );

my %config = CPAN::Mini->read_config;
die "Must specific 'local: <path>' in .minicpanrc\n"
  unless $config{local};

my $visitor = CPAN::Visitor->new( cpan => $config{local} );

# or a subset of distributions
$visitor->select( exclude => qr{/Acme-} );

# Action is specified via a callback
$visitor->iterate(
  jobs => $jobs,
  enter => sub { 1 },
  leave => sub { 1 },
  extract => \&my_extract,
  visit => sub {
    my $job = shift;
    my $contents = $job->{result}{extract};
    print "$job->{distfile}\n" if grep { /Build\.PL/ } @$contents; 
  }
);


sub my_extract {
  my $job = shift;

  # cd to tmpdir for duration of this sub
  my $pushd = File::pushd::pushd( $job->{tempdir} );

  my @files;
  if ($job->{distpath} =~ /\.zip$/i) {
    my $zip = Archive::Zip->new;
    if ( $zip->read( $job->{distpath} ) == AZ_OK ) {
      @files = $zip->memberNames;
    }
  }
  else {
    my $tar = Archive::Tar->new($job->{distpath});
    @files = $tar->list_files;
  }

  return \@files;
}
