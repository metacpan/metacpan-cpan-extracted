# -*- perl -*-

# Check module loading

use strict;

use Test::Simple tests => 6;

use Data::Mining::AssociationRules;

my %transaction_map;
my $transaction_file = 'basic.txt';
my $support_threshold = 1;

# Move into the test subdir to avoid pathname difficulties
chdir('t');

read_transaction_file(\%transaction_map, $transaction_file);

basic_test(1);
basic_test(1, 0.5);
basic_test(2);

sub basic_test {
  my $support_threshold = shift;
  my $confidence_threshold = shift;

  $confidence_threshold = 0 if !defined($confidence_threshold);

  #
  # Test simple generation of frequent sets
  #
  generate_frequent_sets(\%transaction_map, $transaction_file, $support_threshold);
  my $ok = compare_nset_files('basic', 'basic.txt', $support_threshold);
  ok ($ok, 'basic ARM test');

  #
  # Test simple generation of rules (given frequent set files)
  #
  generate_rules($transaction_file, $support_threshold);

  $ok &&= compare_files("basic-support-$support_threshold-conf-0-rules.txt",
                           "basic.txt-support-$support_threshold-conf-0-rules.txt");
  ok($ok, 'basic rules test');

  # Clean up files made by generate_frequent_sets() and generate_rules()
  opendir(DIR, '.') || die "can't opendir '.': $!";
  my @files = grep { /^basic.txt\-support\-$support_threshold\-/ } readdir(DIR);
  closedir DIR;
  if ($ok) {
    foreach my $file (@files) {
      unlink $file;
    }
  }
  else {
    print STDERR "Due to errors, leaving @files\n";
  }
}

#
# Return 1 if nsets are the same, 0 otherwise
#
sub compare_nset_files {
  my $original_prefix = shift;
  my $generated_prefix = shift;
  my $support_threshold = shift;

  my %orig_sets;
  read_frequent_sets(\%orig_sets, $original_prefix, $support_threshold);
  my %gen_sets;
  read_frequent_sets(\%gen_sets, $generated_prefix, $support_threshold);

  return compare_maps(\%orig_sets, \%gen_sets);
}

#
# Return
#
#  1 if rules files are the same (other than reordering or line
#     endings)
#  0 otherwise
#
# Assumes both files fit in memory
#
sub compare_files {
  my $file1 = shift;
  my $file2 = shift;

  # Read in files
  my %line;
  read_file(\%line, $file1);
  my %line2;
  read_file(\%line2, $file2);

  return compare_maps(\%line, \%line2);
}

sub read_file {
  my $line_map_ref = shift;
  my $file = shift;

  open(F, $file) or die "Couldn't open $file: $!\n";
  while ( <F> ) {
    s/[\r\n]//g;
    $$line_map_ref{$_}++;
  }
  close(F) or die "Couldn't close $file: $!\n";
}

#
# Compare maps
#
# Return
#  0 if different
#  1 if same
#
sub compare_maps {
  my $map1_ref = shift;
  my $map2_ref = shift;

  # Everything in map1 agrees with map2
  while (my ($key, $val) = each %{$map1_ref}) {
    my $val2 = $$map2_ref{$key};
    if (!defined($val2) || ($val != $val2)) {
      print STDERR "Map disagreement: key $key val $val val2 $val2\n";
      return 0;
    }
  }

  # Everything in map2 agrees with map1
  while (my ($key, $val) = each %{$map2_ref}) {
    my $val1 = $$map1_ref{$key};
    if (!defined($val1) || ($val != $val1)) {
      print STDERR "Map disagreement: key $key val $val val1 $val1\n";
      return 0;
    }
  }

  return 1;
}
