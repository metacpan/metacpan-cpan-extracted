package BGS;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(bgs_call bgs_back bgs_wait bgs_break);

our $VERSION = '0.11';

use IO::Select;
use Scalar::Util qw(refaddr);
use Storable qw(freeze thaw);
use POSIX ":sys_wait_h";


our $limit = 0; 

$SIG{CHLD} = "IGNORE";

my $sel = IO::Select->new();

my %fh2data   = (); 
my %vpid2data = (); 

my @to_call = (); 


sub _call {
	my ($data) = @_;

	my $sub = delete $$data{sub};

	pipe my $from_kid_fh, my $to_parent_fh or die "pipe: $!";

	my $kid_pid = fork;
	defined $kid_pid or die "Can't fork: $!";

	if ($kid_pid) {
		$sel->add($from_kid_fh);

		my $vpid = $$data{vpid};

		$$data{fh}  = $from_kid_fh;
		$$data{pid} = $kid_pid;

		$fh2data{$from_kid_fh} = $data;
		$vpid2data{$vpid}      = $data;

	} else {
		binmode $to_parent_fh;
		print $to_parent_fh freeze \ scalar $sub->();
		close $to_parent_fh;
		exit;
	}

}


sub _bgs_call {
	my ($sub, $callback) = @_;

	my $data = { sub => $sub };
	my $vpid = $$data{vpid} = refaddr $data;

	$$data{callback} = $callback if $callback;

	if ($limit > 0 and keys %fh2data >= $limit) {
		push @to_call, $data;
	} else {
		_call($data);
	}

	return $data;
}

sub bgs_call(&$) {
	my ($sub, $callback) = @_;

	my $data = _bgs_call($sub, $callback);

	return $$data{vpid};
}

sub bgs_back(&) { shift }


sub bgs_wait(;$) {
	my ($waited) = @_;

	local $SIG{PIPE} = "IGNORE";
	my $buf;            
	my $blksize = 1024; 
	while ($sel->count()) {
		foreach my $fh ($sel->can_read()) {
			my $data = $fh2data{$fh};
			my $len = sysread $fh, $buf, $blksize;
			if ($len) {
				push @{$$data{from_kid}}, $buf; 
			} elsif (defined $len) { 
				$sel->remove($fh); 
				close $fh or warn "Kid is existed: $?";

				delete $$data{fh};
				delete $$data{pid};
				my $callback = delete $$data{callback};
				
				if (exists $$data{from_kid}) {
					my $r = join "", @{$$data{from_kid}};
					delete $$data{from_kid};
					if ($callback) {
						$callback->(${thaw $r});
					} else {
						$$data{result} = ${thaw $r};
					}
				} else {
					if ($callback) {
						$callback->();
					} else {
						$$data{result} = undef;
					}
				}

				my $vpid = $$data{vpid};
				delete $fh2data{$fh};
				delete $vpid2data{$vpid};

				if (my $call = shift @to_call) {
					_call($call);
				}

				if ($waited and $waited == $vpid) {
					return;
				}

			} else {
				die "Can't read '$fh': $!";
			}
		}
	}
}


sub _clean {
	my ($data) = @_;
	my $vpid = $$data{vpid};
	delete $vpid2data{$vpid};
	my $fh = $$data{fh} or return;
	$sel->remove($fh);
	close $fh;
	delete $fh2data{$fh};
}


sub bgs_break(;$) {
	my ($vpid) = @_;
	if (defined $vpid) {
		my $data = $vpid2data{$vpid};
		defined $data or return;
		if (my $pid = $$data{pid}) {
			kill 15, $pid;
			1 while waitpid($pid, WNOHANG) > 0;
		}
		_clean($data);
		 @to_call = grep { $$_{vpid} ne $vpid } @to_call;
	} else {
		local $SIG{TERM} = "IGNORE";
		kill 15, -$$;
		1 while waitpid(-1, WNOHANG) > 0;
		_clean($_) foreach values %vpid2data;
		@to_call = ();
	}
}


1;


__END__


=head1 NAME

BGS - Background execution of subroutines in child processes.

=head1 SYNOPSIS

  use BGS;
  # $BGS::limit = 0;

  my @foo;

  foreach my $i (1 .. 2) {
    bgs_call {
      # child process
      return "Start $i";
    } bgs_back {
      # callback subroutine
      my $r = shift;
      push @foo, "End $i. Result: '$r'.\n";
    };
  }

  bgs_wait();

  print foreach @foo;

=head1 MOTIVATION

The module was created when need to receive information from dozens of
database servers in the shortest time appeared.

=head1 DESCRIPTION

=head2 bgs_call

Child process is created for each subroutine, that is prescribed with
B<bgs_call>, and it executes within this child process.

The subroutine must return either a B<scalar> or a B<reference>!

The answer of the subroutine passes to the callback subroutine as an argument.
If a child process ended without bgs_call value returning, than bgs_back subprogram is called without argument.

bgs_call return vpid (virtual pid) of child process.

=head2 bgs_back

The callback subroutine is described in B<bgs_back> block.

The answer of B<bgs_call> subroutine passes to B<bgs_back> subroutine
as an argument.

=head2 bgs_wait

Call of bgs_wait() reduces to child processes answers wait and
callback subroutines execution.

Call bgs_wait($vpid) to wait specific process.

=head2 bgs_break

kill all or specific child processes.

Call bgs_break($vpid) to kill specific process.

=head2 $BGS::limit

Set $BGS::limit to limit child processes count. Default is 0 (unlimited).

=head1 AUTHOR

Nick Kostyria

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 by Nick Kostyria

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
