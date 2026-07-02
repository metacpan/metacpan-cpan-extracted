package App::Project::Doctor::Check::License;

use strict;
use warnings;
use autodie qw(:all);

use parent -norequire, 'App::Project::Doctor::Check::Base';

use Carp qw(croak carp);
use Readonly;

our $VERSION = '0.02';

Readonly::Hash my %LICENSE_KEYWORD => (
	perl_5   => qr/same terms as perl/i,
	gpl_2    => qr/GNU GENERAL PUBLIC LICENSE\s+Version 2/si,
	gpl_3    => qr/GNU GENERAL PUBLIC LICENSE\s+Version 3/si,
	lgpl_2   => qr/GNU LESSER GENERAL PUBLIC LICENSE\s+Version 2/si,
	mit      => qr/Permission is hereby granted, free of charge/i,
	bsd      => qr/Redistribution and use in source and binary forms/i,
	artistic => qr/The Artistic License/i,
);

sub name        { 'Licensing' }
sub description { 'A LICENSE file is present and agrees with the META declaration.' }
sub can_fix     { 0 }
sub order       { 45 }

sub check {
	my ($self, $ctx) = @_;
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	my @findings;

	# 1. LICENSE file must exist (accept both spellings).
	my $lic_file = $ctx->has_file('LICENSE')  ? 'LICENSE'
	             : $ctx->has_file('LICENCE')  ? 'LICENCE'
	             : undef;

	unless ($lic_file) {
		push @findings, _f(
			severity => 'error',
			message  => 'No LICENSE (or LICENCE) file found.',
			detail   => 'CPAN requires a license file for all distributions.',
		);
	}

	# 2. Cross-check META license field when both exist.
	my ($meta_file) = grep { $ctx->has_file($_) } qw(META.json META.yml MYMETA.json MYMETA.yml);
	if ($lic_file && $meta_file) {
		my $meta_id = _meta_license_id($ctx->abs_path($meta_file));
		if ($meta_id && $meta_id ne 'unknown') {
			my $pattern = $LICENSE_KEYWORD{$meta_id};
			if ($pattern) {
				my $content = $ctx->slurp($lic_file);
				unless ($content =~ $pattern) {
					push @findings, _f(
						severity => 'warning',
						message  => "LICENSE content does not match declared license '$meta_id' in $meta_file.",
					);
				}
			}
		}
	}

	unless (@findings) {
		push @findings, _f(
			severity => 'pass',
			message  => "LICENSE file present"
			          . ($meta_file ? ' and consistent with META.' : '.'),
		);
	}

	return @findings;
}

sub _f {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(check_name => 'Licensing', @_);
}

sub _meta_license_id {
	my $path = shift;
	require CPAN::Meta;
	my $meta = eval { CPAN::Meta->load_file($path) };
	return undef if $@ || !$meta;
	return $meta->license;
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::License - Check LICENSE file presence and META agreement

=head1 DESCRIPTION

Verifies a C<LICENSE>/C<LICENCE> file exists.  When a META file is available,
cross-checks the file content against the declared license identifier.

=head3 MESSAGES

  Code | Trigger                       | Resolution
  -----|-------------------------------|------------------------------------------
  L001 | LICENSE file absent           | Add a LICENSE file matching your META value
  L002 | LICENSE content != META value | Align file with declared license

=head3 FORMAL SPECIFICATION

  check : Context -> [Finding]
  check ctx ==
    let has_lic  = exists LICENSE in ctx
        mismatch = has_lic /\ (meta_lic /= undef) /\ not (content matches meta_lic)
    in  (if not has_lic then [error] else [])
        ++ (if mismatch  then [warning] else [])
        ++ (if has_lic /\ not mismatch then [pass] else [])

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
