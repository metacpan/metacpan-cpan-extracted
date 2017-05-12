package BGS::Limit;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(bgs_call bgs_back bgs_wait bgs_break);

our $VERSION = '0.07';

use BGS ();


my @jobs = (); 

sub bgs_call(&$) { push @jobs, \@_ }
sub bgs_back(&)  { shift }


sub do_job {
 	my $job = shift @jobs or return;
	my ($sub, $callback) = @$job;
	&BGS::bgs_call($sub, sub {
 		my $r = shift;
		$callback->($r);
		do_job();
 	});
}


sub bgs_wait($) {
	my ($max) = @_;
	if ($max) {
		do_job() foreach 1 .. $max;
		BGS::bgs_wait();
	} else {
		foreach (@jobs) {
			my ($sub, $callback) = @$_;
			my $r = $sub->();
			$callback->($r);
		}
	}
}


sub bgs_break() {
	@jobs = ();
	BGS::bgs_break();
}


1;


__END__


=head1 NAME

BGS::Limit - Background execution of subroutines in child processes with limit of child processes.

=head1 SYNOPSIS

  use BGS::Limit;

  my @foo;

  foreach my $i (1 .. 7) {
    bgs_call {
      # child process
      return "Start $i";
    } bgs_back {
      # callback subroutine
      my $r = shift;
      push @foo, "End $i. Result: '$r'.\n";
    };
  }

  my $limit = 3;
  bgs_wait($limit);

  print foreach @foo;

If $limit == 0, child processes are not used.

=head1 ATTENTION

Do not use $_ in bgs_call.

bgs_call do not return kid_pid, but count of kid processes.

=head1 SEE

 BGS - Background execution of subroutines in child processes.

=head1 AUTHOR

Nick Kostirya

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Nick Kostirya

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
