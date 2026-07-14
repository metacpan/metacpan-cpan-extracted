package DBIO::Skills;
# ABSTRACT: Runtime access to the AI agent skills bundled with DBIO

use strict;
use warnings;

use File::ShareDir ();
use File::Spec;


# dist name => { skill-dir-name => path to SKILL.md }   (lazy, cached)
my %_skills_cache;
# dist names known to be loaded (the core dist is always present)
my %_loaded_dist = ( 'DBIO' => 1 );


sub register_dist {
  my ($class, $dist) = @_;
  $_loaded_dist{$dist} = 1 if defined $dist && length $dist;
  return;
}


sub register_class {
  my ($class, $pkg) = @_;
  return unless defined $pkg && $pkg =~ /^(DBIO)::([^:]+)::/;
  return $class->register_dist("$1-$2");
}

# Resolve a dist's sharedir skills: { name => SKILL.md path }. Cached; missing
# sharedir (e.g. running uninstalled) yields an empty map rather than dying.
sub _scan_dist {
  my ($dist) = @_;
  return $_skills_cache{$dist} if exists $_skills_cache{$dist};

  my %map;
  my $dir = eval { File::ShareDir::dist_dir($dist) };
  if (defined $dir) {
    my $sdir = File::Spec->catdir($dir, 'skills');
    if (opendir my $dh, $sdir) {
      for my $name (grep { !/^\./ } readdir $dh) {
        my $file = File::Spec->catfile($sdir, $name, 'SKILL.md');
        $map{$name} = $file if -f $file;
      }
      closedir $dh;
    }
  }

  $_skills_cache{$dist} = \%map;
  return \%map;
}

# Canonical skill name is always the dbio- form (matches the sharedir dir
# names). A bare name gets dbio- prepended; an already-prefixed name is left
# as-is. So both 'db2-database' and 'dbio-db2-database' resolve.
sub _canonical { my $n = shift; return $n =~ /^dbio-/ ? $n : "dbio-$n"; }


sub canonical_name { my ($class, $name) = @_; return _canonical($name); }

sub _slurp {
  my ($file) = @_;
  open my $fh, '<:encoding(UTF-8)', $file or return undef;
  local $/;
  return scalar <$fh>;
}


sub skill {
  my ($class, $name) = @_;
  return undef unless defined $name;
  my $want = _canonical($name);

  for my $dist (sort keys %_loaded_dist) {
    my $map = _scan_dist($dist);
    # Most sharedir dir names are canonical (dbio-...), but a few family
    # skills are not (e.g. 'karr'); try the canonical form first, then the
    # literal name as given.
    for my $key ($want, $name) {
      return _slurp($map->{$key}) if $map->{$key};
    }
  }
  return undef;
}


sub skills {
  my ($class) = @_;
  my %seen;
  for my $dist (keys %_loaded_dist) {
    $seen{$_} = 1 for keys %{ _scan_dist($dist) };
  }
  return sort keys %seen;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Skills - Runtime access to the AI agent skills bundled with DBIO

=head1 VERSION

version 0.900002

=head1 SYNOPSIS

  # whatever drivers are loaded expose their skills automatically
  use DBIO::PostgreSQL;

  my $md = DBIO->skill('postgresql-database');   # markdown text
  my @names = DBIO::Skills->skills;              # everything available now

  # from a connected schema (adds the schema's own driver + overrides)
  my $md = $schema->skill('mysql-database');

See F<t/skills.t> for a runnable example.

=head1 DESCRIPTION

DBIO is developed with the help of AI coding agents. To keep that work
consistent, each DBIO repository carries a set of B<agent skills> — short,
focused briefing documents an agent loads when working inside the repository.

The skill I<sources> live under C<.claude/skills/> in each source repository
(a dot-directory, deliberately excluded from the CPAN tarball). What B<is>
shipped is, for each distribution, the skills it B<owns>: they are packaged
into the distribution's sharedir under C<skills/> (see
L<Dist::Zilla::Plugin::DBIO::GatherSkills>). This module exposes those bundled
skills at runtime.

Discovery is fully dynamic: when a DBIO driver is loaded, its distribution is
registered (from the core driver-load path), and B<all> skills found in that
distribution's sharedir become available — no skill is ever named in code.

=head2 Skill categories

=over 4

=item * Shared family skills — owned by, and shipped from, the C<DBIO> core
distribution (C<dbio-coordination>, C<dbio-core>, C<dbio-driver-development>,
C<dbio-perl-syntax>, C<dbio-perl-class-patterns>, C<dbio-moo-moose>, C<karr>).

=item * The C<[@DBIO]> release skill (C<dbio-perl-release>) — owned by the
C<Dist-Zilla-PluginBundle-DBIO> distribution.

=item * Per-driver skills — owned by each C<DBIO-E<lt>driverE<gt>>
distribution: C<dbio-E<lt>driverE<gt>> (using the driver) and
C<dbio-E<lt>driverE<gt>-database> (the underlying database).

=back

=head2 For contributors

You do B<not> need any special tooling. Clone a repository and you get normal
files. Edit a skill's C<SKILL.md> where it lives in the repo you are working
in and commit it. Shared family skills are canonical in the C<dbio> core repo;
make the change there (or note it) so it propagates. Maintainers reconcile the
hardlinks at release time with the C<manage-skills> tool.

=head1 METHODS

=head2 register_dist

  DBIO::Skills->register_dist('DBIO-PostgreSQL');

Mark a distribution as loaded so its bundled skills become available. Called
automatically from the core driver-load path; rarely needed by hand.

=head2 register_class

  DBIO::Skills->register_class('DBIO::PostgreSQL::Storage');

Derive the distribution that owns a DBIO class (C<DBIO::DB2::Storage> →
C<DBIO-DB2>, C<DBIO::MySQL::Storage::MariaDB> → C<DBIO-MySQL>) and register it.
Called from the core driver-load path and from L<DBIO::Schema/skill>.

=head2 canonical_name

  my $key = DBIO::Skills->canonical_name('db2-database'); # 'dbio-db2-database'

Normalise a skill name to its canonical C<dbio-> form. Used by callers (e.g.
L<DBIO::Schema/skill>) that key their own overrides the same way.

=head2 skill

  my $markdown = DBIO::Skills->skill('postgresql-database');

Return the markdown text of the named skill, or C<undef> if no loaded
distribution provides it. The leading C<dbio-> is optional, so both
C<'db2-database'> and C<'dbio-db2-database'> resolve.

=head2 skills

  my @names = DBIO::Skills->skills;

Return the sorted list of skill names available from all currently loaded
distributions (full C<dbio-...> names).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
