
package IO::Capture;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(open_s close_s);

BEGIN {
	if ($] < 5.008) {
		*open_s = \&open_s6;
		*close_s = \&close_s6;
	} else {
		*open_s = \&open_s8;
		*close_s = \&close_s8;
	}
}

# this works for $] >= 5.008
# because it uses in-core files

my $memory;

sub open_s8 {
	my $glob = shift;
	$memory = '';
	open $glob, ">", \$memory or die $!;
}

sub close_s8 {
	my $glob = shift;
	close $glob or die $!;
	return $memory;
}

# this works anywhere
# but is uses a temp file

my $tmp_fn = 't/0.tmp';

sub slurp_tmp {
	local $/;
	open TMP, $tmp_fn or die $!;
	my $tmp = <TMP>;
	close TMP or die $!;
	return $tmp
}

sub open_s6 {
	my $glob = shift;
	open $glob, ">$tmp_fn" or die;
}

sub close_s6 {
	my $glob = shift;
	close $glob or die $!;
	my $memory = slurp_tmp;
	unlink $tmp_fn or die $!;
	return $memory
}


1;

__END__

=head1 NAME

IO::Capture - Capture the output sent to a glob

=head1 SYNOPSIS

  use IO::Capture qw(open_s close_s);
  local *STDOUT; # localize STDOUT
  open_s *STDOUT;

  # print to STDOUT: output is saved

  my $out = close_s *STDOUT; # and returned here

=head1 DESCRIPTION

This is a very fragile code. This is for testing
warnings to STDERR in "t/001_dot.t".
