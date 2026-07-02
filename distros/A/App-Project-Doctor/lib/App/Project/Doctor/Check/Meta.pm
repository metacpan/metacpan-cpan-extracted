package App::Project::Doctor::Check::Meta;

use strict;
use warnings;
use autodie qw(:all);

use parent -norequire, 'App::Project::Doctor::Check::Base';

use Carp qw(croak carp);
use Readonly;

our $VERSION = '0.02';

Readonly::Array my @REQUIRED_FIELDS => qw(name version author abstract license);
Readonly::Array my @META_FILES      => qw(META.json META.yml MYMETA.json MYMETA.yml);

sub name        { 'META' }
sub description { 'META.yml or META.json is present, parseable, and complete.' }
sub can_fix     { 0 }
sub order       { 30 }

sub check {
	my ($self, $ctx) = @_;
	croak 'check requires an App::Project::Doctor::Context' unless ref $ctx;

	my @findings;

	my ($meta_file) = grep { $ctx->has_file($_) } @META_FILES;

	unless ($meta_file) {
		push @findings, _f(
			severity => 'warning',
			message  => 'No META.{yml,json} -- run your builder to generate one.',
			detail   => 'CPAN indexers require META to discover name and version.',
		);
		# Fall back: at least confirm a builder file exists.
		unless ($ctx->builder_file) {
			push @findings, _f(
				severity => 'error',
				message  => 'No Makefile.PL, Build.PL, or dist.ini found.',
			);
		}
		return @findings;
	}

	require CPAN::Meta;
	my $meta = eval { CPAN::Meta->load_file($ctx->abs_path($meta_file)) };
	if ($@) {
		return _f(
			severity => 'error',
			message  => "Failed to parse $meta_file -- file may be malformed.",
			file     => $meta_file,
		);
	}

	my %data = %{ $meta->as_struct };
	for my $field (@REQUIRED_FIELDS) {
		next if defined $data{$field} && length $data{$field};
		push @findings, _f(
			severity => 'error',
			message  => "META field '$field' is missing or empty in $meta_file.",
			file     => $meta_file,
		);
	}

	unless (@findings) {
		push @findings, _f(
			severity => 'pass',
			message  => "$meta_file is valid and all required fields are present.",
		);
	}

	return @findings;
}

sub _f {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(check_name => 'META', @_);
}

1;

__END__

=head1 NAME

App::Project::Doctor::Check::Meta - Check META file presence and validity

=head1 DESCRIPTION

Uses L<CPAN::Meta> to parse the distribution META file and verifies that all
required fields (name, version, author, abstract, license) are present.

=head1 METHODS

=head2 check( $context )

Locates the first available META file, parses it, and validates required fields.

=head3 API SPECIFICATION

=head4 Input

  $context : App::Project::Doctor::Context

=head4 Output

  List of App::Project::Doctor::Finding --
    warning         when no META.* file is found (builder file present),
    warning + error when no META.* and no builder file found,
    error           when the META file cannot be parsed,
    one error per missing required field (name/version/author/abstract/license),
    pass            when all required fields are present.

=head3 MESSAGES

  Code | Trigger                     | Resolution
  -----|-----------------------------|-----------------------------------------
  M001 | No META.* file found        | Run builder to generate (make or dzil)
  M002 | META parse failure          | Correct malformed YAML/JSON by hand
  M003 | Required META field missing | Add field to Makefile.PL / dist.ini

=head3 FORMAL SPECIFICATION

  check : Context -> [Finding]
  check ctx ==
    let f = first meta_file existing in ctx
    in  if f = undef then [warning] ++ (if no builder then [error] else [])
        else let m = parse f
             in  if parse_fails then [error]
                 else [error per missing field] ++ (if all ok then [pass] else [])

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENSE

Copyright (C) 2026 Nigel Horne.
This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
