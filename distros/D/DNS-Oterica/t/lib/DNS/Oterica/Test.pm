package DNS::Oterica::Test;
use strict;
use warnings;
use autodie;
use Carp;

use IPC::System::Simple qw(system capture);
use DNS::Oterica;

my $records = {};

my %collect_dispatch = (
  '+' => \&collect_plus,
  '@' => \&collect_at,
  'C' => \&collect_cname,
  '=' => \&collect_plus,
  'Z' => \&collect_z,
  '&' => \&collect_amp,
  ':' => \&collect_colon,
  '%' => \&collect_percent,
  '.' => \&collect_period,
  '^' => \&collect_ptr,
  "'" => \&collect_tick,
);

sub collect_dnso_nodes {
  my ($self, @lines) = @_;
  for my $line (@lines) {
    next if $line =~ /^#/;
    next if $line =~ /^$/;
    chomp $line;
    my ($type, $record) = ($line =~ /^(.)(.+)$/);
    my @parts = split /:/, $record;
    $collect_dispatch{$type}->(@parts);
  }
}

sub collect_dnso_node_families {
  my ($self, @lines) = @_;
  for my $item ( @lines ) {
    for my $line (split /\n/, $item) {
      next if $line =~ /^#/;
      next if $line =~ /^$/;
      my ($type, $record) = ($line =~ /^(.)(.+)$/);
      my @parts = split /:/, $record;
      $collect_dispatch{$type}->(@parts);
    }
  }
}

sub records {
  return $records;
}

sub collect_plus {
  my @parts = @_;
  push @{$records->{$parts[0]}{'+'}}, $parts[1];
}

sub collect_at {
  my @parts = @_;
  push @{$records->{$parts[0]}{'@'}}, $parts[2];
}

sub collect_cname {
  my @parts = @_;
  push @{$records->{$parts[0]}{'C'}}, $parts[1];
}

sub collect_z {
  my @parts = @_;
  push @{$records->{$parts[0]}{'Z'}}, $parts[1];
}

sub collect_amp {
  my @parts = @_;
  push @{$records->{$parts[0]}{'&'}}, $parts[2];
}

sub collect_colon {
  my @parts = @_;
  push @{$records->{$parts[0]}{':'}}, $parts[2];
}

sub collect_percent {
  my @parts = @_;
  push @{$records->{$parts[0]}{'%'}}, $parts[0];
}

sub collect_period {
  my @parts = @_;
  push @{$records->{$parts[0]}{'.'}}, $parts[2];
}

sub collect_ptr {
  my @parts = @_;
  my @bytes = split /\./, $parts[1];
  my $reverse = join '.', reverse(@bytes), 'in-addr', 'arpa';
  push @{$records->{$parts[0]}{'^'}}, $parts[1] ;
}

sub collect_tick {
  my @parts = @_;
  push @{$records->{$parts[0]}{"'"}}, $parts[1];
}

1;
