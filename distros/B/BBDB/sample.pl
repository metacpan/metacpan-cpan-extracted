#!/usr/bin/perl
use BBDB;


########################################################################
# Run through a bbdb file and collect all the unique names
# in the notes field and print them out seperated by spaces
########################################################################
my %notes;
my $bbdb;
my $all = BBDB::simple("sample_data.bbdb");
foreach $bbdb (@$all) {
  my $notes = $bbdb->part('notes');
  next unless @$notes;
  my @fields = map { $_->[0] } @$notes;
  @notes{@fields} = 1;
}
print join(' ',keys %notes),"\n\n";

########################################################################
# Run through the bbdb file and print out everybody that has
# a mailing address in a "standard" mailing label like format
########################################################################
sub printif {
  my $s = shift;
  print "$s\n" if $s;
}

foreach $bbdb (@$all) {
  my $i;
  for ($i=0; $i < @{$bbdb->part('address')}; $i++) {
    my $address = $bbdb->part('address')->[$i];
    if ($address->[0] eq 'mailing' ) {
      printf "%s %s\n",$bbdb->part('first'),$bbdb->part('last');
      map { printif $_ } @{$address->[1]};
      printf "%s, %s, %s\n%s\n",@$address[2..5];
    }
  }
}
########################################################################
