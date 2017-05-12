package DBIx::RewriteDSN;

use strict;
use warnings;
our $VERSION = '0.05';

use DBI;
use File::Slurp;

my $orig_connect = \&DBI::connect;
my $filename;
my $RULES = "";

sub import {
	my ($class, %opts) = @_;
	if ($opts{-file}) {
		$filename = $opts{-file};
		$RULES .= File::Slurp::slurp($filename) . "\n";
	}
	if ($opts{-rules}) {
		$RULES .= $opts{-rules} . "\n";
	}

	if ($RULES && $ENV{DBI_REWRITE_DSN}) {
		$class->enable;
	}
}

sub enable {
	my ($class) = @_;
	no warnings 'redefine';
	*DBI::connect = \&_connect;
}

sub disable {
	my ($class) = @_;
	no warnings 'redefine';
	*DBI::connect = $orig_connect;
}

sub prepend_rules {
	my ($class, $rules) = @_;
	$RULES = $rules . "\n" . $RULES;
}


sub rewrite {
	my ($dsn) = @_;

	my $new_dsn;
	for (split /\n/, $RULES) {
		chomp;
		$_ =~ s/^\s+|\s+$//g;
		$_ or next;
		$_ =~ /^#/ and next;

		my ($match, $rewrite) = split(/\s+/, $_);
		if ($dsn =~ $match) {
			$rewrite =~ s{\\}{\\\\}g;
			$new_dsn = eval(sprintf('qq{%s}', $rewrite || "")); ## no critic
			last;
		}
	}

	if ($new_dsn && $new_dsn ne $dsn) {
		print STDERR sprintf("Rewrote '%s' to '%s'\n", $dsn, $new_dsn) if ($ENV{DBI_REWRITE_DSN} || "") eq 'verbose';
		$dsn = $new_dsn;
	} else {
		print STDERR sprintf("Didn't rewrite %s\n", $dsn) if ($ENV{DBI_REWRITE_DSN} || "") eq 'verbose';
	}

	$dsn;
}

sub _connect {
	my ($class, $dsn, @rest) = @_;
	$dsn = DBIx::RewriteDSN::rewrite($dsn);
	$orig_connect->($class, $dsn, @rest);
}


1;
__END__

=head1 NAME

DBIx::RewriteDSN - dsn rewriter for debug

=head1 SYNOPSIS

  use DBI;
  use DBIx::RewriteDSN -rules => q{
    dbi:SQLite:dbname=foobar dbi:SQLite:dbname=test_foobar
  };

  ## DBIx::RewriteDSN redefine DBI::connect and 
  ## rewrite dsn passed to DBI::connect
  my $dbh = DBI->connect("dbi:SQLite:dbname=foobar", "", "");

  $dbh->{Name} #=> dbname=test_foobar

External File:

  use DBI;
  use DBIx::RewriteDSN -file => "dbi_rewrite.rules";

  my $dbh = DBI->connect("dbi:SQLite:dbname=foobar", "", "");

=head1 DESCRIPTION

DBIx::RewriteDSN is dsn rewriter.
This enables rewrite all DBI->connect based on rule text.

=head1 CLASS METHODS

=head2 use DBIx::RewriteDSN -file => "filename";

Enable rewrites based on rules in C<filename>.

=head2 use DBIx::RewriteDSN -rules => "rules";

Enable rewrites based on rules.

If C<DBI_REWRITE_DSN> is false, import does not anything by default.

=head2 DBIx::RewriteDSN->disable

Disable rewrites.

=head2 DBIx::RewriteDSN->enable

Re-enable rewrites.

=head3 DBIx::RewriteDSN->prepend_rules($rules);

Prepend $rules to current rules.

=head1 RULES

Rules is like:

  dbi:SQLite:dbname=foobar dbi:SQLite:dbname=foobar_test

  dbi:mysql:database=([^;]+).* dbi:SQLite:dbname=$1

  # fallback
  (.*) dbi:fallback:$1

=over

=item All empty lines are ignored

=item Matches are left, replaces are right

=item All matches are regexp

=back

=head1 AUTHOR

cho45 E<lt>cho45@lowreal.netE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
