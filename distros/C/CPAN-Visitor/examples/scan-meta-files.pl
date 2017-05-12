# Contributed by Ricardo Signes
use CPAN::Visitor;
use Text::CSV_XS;;
use YAML::Tiny;

my $visitor = CPAN::Visitor->new(cpan => "/Users/rjbs/mirrors/minicpan");
my $count   = $visitor->select;

printf "preparing to scan %s files...\n", $count;

my $csv   = Text::CSV_XS->new;
my $total = 0;
my @data;

$csv->eol("\n");

open my $csv_fh, ">:encoding(utf8)", "dist.csv" or die "dist.csv: $!";

my @cols = qw(
  distfile
  author
  has_meta_yml has_meta_json meta_spec
  meta_generator meta_gen_package meta_gen_version
  meta_error
  has_dist_ini
);

$csv->print($csv_fh, \@cols);

my %template = map {; $_ => '' } @cols;

$visitor->iterate(
  visit => sub {
    my ($job) = @_;
    $total++;

    my %dist = %template;
    $dist{has_meta_yml}  = -e 'META.yml'  ? 1 : 0;
    $dist{has_meta_json} = -e 'META.json' ? 1 : 0;
    $dist{has_dist_ini}  = -e 'dist.ini'  ? 1 : 0;

    $dist{distfile} = $job->{distfile};
    ($dist{author}) = split m{/}, $job->{distfile};

    my ($data) = eval { YAML::Tiny->read('META.yml')->[0] };
    if ($data) {
      $dist{meta_spec} = eval { $data->{'meta-speak'}{version} };
      $dist{meta_generator} = $data->{generated_by};

      if ($data->{generated_by} =~ /(\S+) version (\S+)/) {
        $dist{meta_gen_package} = $1;
        $dist{meta_gen_version} = $2;
      }
    } else {
      my $error = $@;
      ($error) = split m{$}m, $error;
      $dist{meta_error} = $error;
    }

    $csv->print($csv_fh, [ @dist{ @cols } ]);
    say "completed $total / $count";
  }
);

close $csv_fh or die "new.csv: $!";

