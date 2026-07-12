use strict; use warnings;
use File::Find;
my %have;
my $root = '/storage/raid/home/getty/dev/perl/dbio-dev/dbio';
find(sub {
  my $f = $File::Find::name;
  if ($f =~ m{/DBIO/(.+?)\.(?:pm|pod)$}) {
    (my $k = "DBIO::$1") =~ s{/}{::}g;
    $have{$k}++;
  }
}, "$root/lib");

# External CPAN not shipped here
my %external = map { $_ => 1 } qw(
  Class::C3 Class::C3::XS Class::Accessor::Grouped Class::Method::Modifiers Class::XSAccessor
  CachedKids Catalyst Catalyst::Helper::Model::DBIC::Schema
  Catalyst::Model::DBIC::Schema
  DBD::Oracle DBD::Pg DBD::SQLite DBD::mysql
  DBI DBI::Shell Data::Dumper DateTime DSN DateTime::Format::Strptime
  HTML::FormHandler::Model::DBIC HashRefInflator
  Method::Signatures::Simple ManyToMany Module::Find Meta::NoIndex
  Moose Moose::Manual::MethodModifiers
  SQL::Abstract SQL::Abstract::Classic SQL::Translator
  Tie::Cache Tie::Cache::LRU overload
);
# External DBIO-fork legacy refs (not in core, intentional migration notes)
my %external_legacy = map { $_ => 1 } qw(
  DBIx::Class DBIx::Class::CDBICompat DBIx::Class::SQLMaker::ClassicExtensions
  DBIx::Class::Schema::Versioned Class::DBI
);

my %refs;
for my $pod (glob "$root/lib/DBIO/Manual/*.pod") {
  open my $fh, '<', $pod or die;
  while (<$fh>) {
    while (m{L<([A-Za-z_][\w:]*)(?:\|[^>]*)?(?:/([A-Za-z_]\w*))?>}g) {
      my ($mod, $sub) = ($1, $2);
      next if $mod =~ /^(https?|ftp|file|mailto)$/;
      $refs{$pod}{"$mod/$sub"}++ if $sub;
      $refs{$pod}{$mod}++      unless $sub;
    }
  }
}

my @broken;
for my $pod (sort keys %refs) {
  my $rel = $pod; $rel =~ s{^\Q$root\E/}{};
  for my $r (sort keys %{$refs{$pod}}) {
    my $mod = $r; $mod =~ s{/.*}{};
    next if $external{$mod};
    next if $external_legacy{$mod};
    next if $have{$mod};
    # bare refs like L<create>, L<search> — valid shorthand, skip
    next if $mod =~ /^[a-z]/;
    push @broken, "$rel: L<$r>";
  }
}
print "$_\n" for @broken;
