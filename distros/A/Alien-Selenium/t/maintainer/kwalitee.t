#!/usr/bin/perl -w

=head1 NAME

kwalitee.t - Applies (the spirit of) L<Test:Kwalitee> on the module.

=head1 DESCRIPTION

We mostly do the same thing as L<Test::Kwalitee>, ie one test
assertion per kwalitee metric, except that we actually make it work
(by default I<Test::Kwalitee> will eg try to POD-check the files in
C<_build>, I am neither amused nor making this up).  To this end, we
bypass I<Test::Kwalitee> almost entirely and directly hook into
L<Module::CPANTS::Analyse>, the actual Kwalitee checker.

=cut

use strict;
use Test::More;
use Cwd qw(cwd);

BEGIN { unless (eval <<"REQUIRED_TEST_KWALITEE_STUFF") {
use Module::CPANTS::Analyse;
use Test::Kwalitee ();
use Module::CPANTS::Kwalitee::Files;
1;
REQUIRED_TEST_KWALITEE_STUFF
    plan( skip_all => 'Need Test::Kwalitee and dependencies; skipping' );
    exit;
}}

=head2 Actual Kwalitee Tests

You could replace all of Test::Kwalitee's 100+ lines with the
following 20 or so.

=cut

my $analyzer = Module::CPANTS::Analyse->new({ distdir => cwd() });
{
  local $^W; # Warnings arise because we are testing without a real traball
  $analyzer->analyse();
  $analyzer->calc_kwalitee();
}

my @required_and_working_kwalitee = (qw(extractable),
  # extracts_nicely is irrelevant for a deployed package (and doesn't work to boot)
  qw(has_readme has_manifest has_meta_yml has_buildtool has_changelog
     no_symlinks has_tests),
  # has_version and has_proper_version work from the tarball only
  qw(metayml_is_parsable metayml_has_license
     metayml_conforms_to_known_spec proper_libs no_pod_errors
     has_working_buildtool use_strict has_test_pod has_test_pod_coverage
     has_humanreadable_license),
  # manifest_matches_dist might be led astray by files generated during tests
  qw( no_cpants_errors ));

my @optional_kwalitee_that_I_use = qw(metayml_conforms_spec_current
  prereq_matches_use build_prereq_matches_use use_warnings);

my @kwalitee_keys = grep {exists $analyzer->d->{kwalitee}->{$_}}
  (@required_and_working_kwalitee, @optional_kwalitee_that_I_use);

plan( tests => scalar @kwalitee_keys );
foreach my $kwalitee_key (@kwalitee_keys) {
  ok($analyzer->d->{kwalitee}->{$kwalitee_key}, "$kwalitee_key") or do {
    diag $analyzer->d->{error}->{$kwalitee_key};
  };
}

exit 0;

=head2 Medieval Antics on Module::CPANTS::Kwalitee::Files

=cut

package Module::CPANTS::Kwalitee::Files;
no warnings "redefine";

our (@files, @dirs, $size);

=head3 get_files ()

Copied and modified from the original code so as not to frob in
version-control directories, build directories and so on.

=cut

BEGIN { undef &get_files }

sub get_files {
    return if /^\.+$/;
    my $unixy=join('/',splitdir($File::Find::name));
    return if $unixy =~
      m{(^|/)(RCS|CVS|SCCS|\.git|\.svn|\.hg|_build|_Inline|blib)};
    if (-d $_) {
        push (@dirs,$unixy);
    } elsif (-f $_) {
        push (@files,$unixy);
        $size+=-s _ || 0;
    }
}
