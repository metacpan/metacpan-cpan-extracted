#!/usr/bin/perl
use lib 'lib';
use Applify;

option str  => iiiiiii    => 'asd';
option str  => x          => 'asd';
option file => input_file => 'File to read from', 'Makefile.PL', alias => 'i';
option str => output_dir => 'Directory to write files to', n_of => '0,2';
option flag => dry_run => 'Use --no-dry-run to actually do something', required => 1;

version 1.23;
documentation __FILE__;

sub app::generate_exit_value {
  return int rand 100;
}

app {
  my ($self, @extra) = @_;
  my $exit_value = 0;

  print "Extra arguments: @extra\n" if (@extra);
  print "Will read from: ", $self->input_file, "\n";
  print "Will write files to ", int @{$self->output_dir}, " output dirs\n";
  print "Will write files to: ", join(', ', @{$self->output_dir}), "\n";

  if ($self->dry_run) {
    die 'Will not run script';
  }

  return $self->generate_exit_value;
};

=head1 NAME

test1.pl - Example script

=head1 SYNOPSIS

Some description...

    test1.pl --help

=head1 DESCRIPTION

This script is just an example script...

=head1 AUTHOR

See L<Applify>.

=cut
