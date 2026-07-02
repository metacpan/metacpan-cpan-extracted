package App::Project::Doctor::Check::Security;

use strict;
use warnings;
use autodie qw(:all);

use parent -norequire, 'App::Project::Doctor::Check::Base';

use Carp qw(croak carp);
use Readonly;

our $VERSION = '0.02';

Readonly::Array my @SECRET_PATTERNS => (
	qr/(?:password|passwd|secret|api_?key|token)\s*=\s*['"][^'"]{4,}['"]/i,
	qr/-----BEGIN (?:RSA |EC )?PRIVATE KEY-----/,
	qr/(?:AKIA|ASIA)[A-Z0-9]{16}/,
);

sub name        { 'Security' }
sub description { 'All modules declare strict/warnings; no hardcoded credentials.' }
sub can_fix     { 1 }
sub order       { 60 }

sub check {
	my ($self, $ctx) = @_;
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	my @findings;
	my $files = $ctx->perl_files('lib', 'script', 'bin');

	for my $rel (@{$files}) {
		my $content = eval { $ctx->slurp($rel) } // do { carp "Cannot slurp $rel"; next };

		# strict / warnings -- skip .t files (they inherit from test harness).
		unless ($rel =~ /\.t$/) {
			unless ($content =~ /^\s*use\s+strict\b/m) {
				push @findings, _f(
					severity => 'error',
					message  => "Missing 'use strict' in $rel.",
					file     => $rel,
					fix      => _fix_pragma($ctx, $rel, 'strict'),
				);
			}
			unless ($content =~ /^\s*use\s+warnings\b/m) {
				push @findings, _f(
					severity => 'error',
					message  => "Missing 'use warnings' in $rel.",
					file     => $rel,
					fix      => _fix_pragma($ctx, $rel, 'warnings'),
				);
			}
		}

		# Credential scan.
		my @lines = split /\n/, $content;
		for my $i (0 .. $#lines) {
			for my $pat (@SECRET_PATTERNS) {
				if ($lines[$i] =~ $pat) {
					push @findings, _f(
						severity => 'error',
						message  => "Possible hardcoded credential in $rel at line " . ($i + 1) . '.',
						file     => $rel,
						line     => $i + 1,
						detail   => 'Move secrets to environment variables or a config file.',
					);
					last;
				}
			}
		}
	}

	unless (@findings) {
		push @findings, _f(
			severity => 'pass',
			message  => 'All checked files use strict/warnings; no credential patterns found.',
		);
	}

	return @findings;
}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

sub _f {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(check_name => 'Security', @_);
}

sub _fix_pragma {
	my ($ctx, $rel, $pragma) = @_;
	return sub {
		my $abs = $ctx->abs_path($rel);
		open my $fh, '<', $abs;
		my @lines = <$fh>;
		close $fh;

		# A shebang must remain the very first line of a script so the OS
		# can recognise it; preserve it by starting the search one line in.
		my $insert_at = (@lines && $lines[0] =~ /^#!/) ? 1 : 0;
		for my $i ($insert_at .. $#lines) {
			if ($lines[$i] =~ /^\s*package\s+\S+/) {
				$insert_at = $i + 1;
				last;
			}
		}
		splice @lines, $insert_at, 0, "use $pragma;\n";

		open my $out, '>', $abs;
		print {$out} @lines;
		close $out;
	};
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::Security - Check for missing pragmas and hardcoded secrets

=head1 DESCRIPTION

Two security checks across all Perl source files:

=over 4

=item 1. C<use strict> and C<use warnings> present in every C<.pm> and script.

=item 2. Scan for hardcoded credential patterns (passwords, API keys, AWS
key prefixes, PEM private key headers).

=back

Pragma fixes are automated; credential findings require manual resolution.

=head3 MESSAGES

  Code | Trigger                      | Resolution
  -----|------------------------------|-------------------------------------------
  S001 | Missing 'use strict'         | Fix inserts pragma after package declaration
  S002 | Missing 'use warnings'       | Fix inserts pragma after package declaration
  S003 | Possible hardcoded secret    | Move to env var / external config

=head3 FORMAL SPECIFICATION

  check : Context -> [Finding]
  check ctx ==
    concat [ check_file f | f <- perl_files ctx ]
    where
      check_file f ==
        strict_check f ++ warnings_check f ++ credential_check f

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
