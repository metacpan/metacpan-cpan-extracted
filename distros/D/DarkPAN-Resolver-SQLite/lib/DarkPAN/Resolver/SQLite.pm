package DarkPAN::Resolver::SQLite;

# A cpm resolver backed by DarkPAN::Indexer's SQLite database.
#
# Invoke it (custom class => use the '+' prefix so cpm takes the name
# verbatim instead of prepending App::cpm::Resolver::):
#
#   cpm install \
#     --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
#     Amazon::API~2.6.0
#
use strict;
use warnings;

use App::cpm::DistNotation;
use App::cpm::version;
use Carp;
use Data::Dumper;
use English qw(-no_match_vars);
use File::Temp qw(tempfile);
use DBI;
use HTTP::Tiny;
use IO::Uncompress::Gunzip qw(gunzip);

our $VERSION = '1.0.2';

########################################################################
sub new {
########################################################################
  my ( $class, $ctx, $mirror ) = @_;

  my $self = bless { mirror => $mirror }, $class;

  my $dbh = $self->_connect($mirror);

  my $sth = $dbh->prepare('SELECT version, distribution FROM modules WHERE module = ?');

  @{$self}{qw(dbh sth)} = ( $dbh, $sth );

  return $self;
}

########################################################################
sub DESTROY {
########################################################################
  my ($self) = @_;

  return if ${^GLOBAL_PHASE} eq 'DESTRUCT';

  if ( $self->{dbh} && ref( $self->{dbh} ) =~ /DBI::db/xsm && $self->{dbh}->ping ) {
    $self->{dbh}->disconnect;
  }

  if ( $self->{database} ) {
    unlink $self->{database};
  }

  return;
}

########################################################################
sub _connect {
########################################################################
  my ( $self, $mirror ) = @_;

  my $database = $self->_fetch_packages_version_index($mirror);

  croak "ERROR: could not load packages index\n"
    if !$database;

  $self->{database} = $database;  # so we can remove in DESTROY

  my $dbh = eval {
    return DBI->connect(
      sprintf( 'dbi:SQLite:dbname=%s', $database ),
      q{}, q{},
      { AutoCommit => 1,
        RaiseError => 1,
        PrintError => 0,
      },
    );
  };

  croak "ERROR: could not open database: $database\n$EVAL_ERROR"
    if $EVAL_ERROR;

  return $dbh;
}

########################################################################
sub resolve {
########################################################################
  my ( $self, $ctx, $task ) = @_;

  my $package = $task->{package};
  my $range   = $task->{version_range};  # full expression, may be undef

  $self->{sth}->execute($package);

  my $rows = $self->{sth}->fetchall_arrayref( {} );

  return { error => "not found in $self->{database}" }
    if !$rows || !@{$rows};

  # Keep only versions that satisfy the constraint, carrying the parsed
  # version object so we don't reparse in the sort. satisfy() is cpm's
  # own semantics, so our picks agree with the rest of the cascade.
  my @candidates;
  for my $row ( @{$rows} ) {
    my $vobj = eval { App::cpm::version->parse( $row->{version} // 0 ) };
    next if !$vobj;
    next if $range && !$vobj->satisfy($range);
    push @candidates, { %{$row}, vobj => $vobj };
  }

  if ( !@candidates ) {
    return { error => "found version(s) for $package, none satisfy " . ( $range // '(any)' ) . ", $self->{database}" };
  }

  # Highest satisfying version wins. NOTE: this sort MUST happen in Perl.
  # SQLite ORDER BY is lexical text sort -- it puts 1.10.0 below 1.9.0.
  my ($best) = sort { $b->{vobj} <=> $a->{vobj} } @candidates;

  # The DB stores the full S3 key (authors/id/A/AB/AUTHOR/Dist-x.tar.gz,
  # possibly under a bucket prefix). DistNotation wants the path relative
  # to authors/id/, so strip everything up to and including it. The
  # (?:.*/)? handles both a bare "authors/id/..." key and a prefixed
  # "orepan2/authors/id/..." one.
  ( my $rel = $best->{distribution} ) =~ s{^(?:.*/)?authors/id/}{};

  my $dist = App::cpm::DistNotation->new_from_dist($rel);
  return { error => "cannot parse dist path '$best->{distribution}'" }
    if !$dist;

  return {
    source   => 'cpan',
    distfile => $dist->distfile,
    uri      => $dist->cpan_uri( $self->{mirror} ),
    version  => $best->{version},
    package  => $package,
  };
}

########################################################################
sub _fetch_packages_version_index {
########################################################################
  my ( $self, $mirror ) = @_;

  my $url = sprintf '%s/modules/packages.db.gz', $mirror;

  my $rsp = HTTP::Tiny->new->get($url);

  return if !$rsp->{success};

  my $content          = $rsp->{content};
  my $unzipped_content = q{};

  gunzip( \$content, \$unzipped_content, Transparent => 0 )
    or croak "ERROR: could not decompress $url\n";

  my ( $fh, $database ) = tempfile(
    UNLINK => 0,
    SUFFIX => '.db',
  );

  binmode $fh;

  print {$fh} $unzipped_content;

  close $fh;

  return $database;
}

1;

## no critic

__END__

=pod

=encoding utf8

=head1 NAME

DarkPAN::Resolver::SQLite - a cpm resolver for multi-version DarkPAN indexes

=head1 SYNOPSIS

  # install the latest version from your DarkPAN
  cpm install \
    --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
    Amazon::API

  # install a specific historical version
  cpm install \
    --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
    Amazon::API@2.6.0

  # or a range
  cpm install \
    --resolver +DarkPAN::Resolver::SQLite,https://cpan.openbedrock.net/orepan2 \
    'Amazon::API~">= 2.0.0, < 3.0.0"'

=head1 DESCRIPTION

C<DarkPAN::Resolver::SQLite> is a resolver plugin for
L<cpm|App::cpm> that resolves distributions from a DarkPAN's
B<multi-version> SQLite index (as produced by L<DarkPAN::Indexer>).

A conventional DarkPAN publishes C<02packages.details.txt.gz>, which records
one indexed distribution for each package. A resolver using that index therefore
cannot select an older distribution merely because its tarball still exists in
the repository.

C<DarkPAN::Resolver::SQLite> instead reads the multi-version index produced by
L<DarkPAN::Indexer>, allowing it to select the highest available version that
satisfies the requested version constraint.

Because it participates in cpm's ordered resolver cascade, the SQLite
resolver composes with cpm's normal CPAN resolvers. Requests the DarkPAN can
satisfy are resolved from its multi-version index; requests it cannot satisfy
continue to cpm's default resolvers.

By default, adding C<--resolver> does not disable cpm's normal resolvers.
Users who specify C<--no-default-resolvers> are responsible for supplying the
complete resolver chain themselves.

=head1 WHY THIS EXISTS

A standard 02packages index is sufficient when only the current
indexed version matters. This resolver exists for DarkPANs that retain
multiple historical distributions and need normal Perl version
constraints to select among them.

=head1 USAGE

Invoke it as a custom cpm resolver. cpm prepends C<App::cpm::Resolver::> to a
bare resolver name, so a class outside that namespace must be given with a
leading C<+> (take-the-name-verbatim):

--resolver +DarkPAN::Resolver::SQLite,<mirror-url>

C<< <mirror-url> >> is the public base URL of your DarkPAN (the same URL a
browser or C<cpanm --mirror> would use), for example
C<https://cpan.openbedrock.net/orepan2>. The resolver fetches the index from
C<< <mirror-url>/modules/packages.db.gz >>.

Only a public HTTP(S) URL is required -- the resolver uses L<HTTP::Tiny> and does
B<not> need AWS credentials or S3 access, even for an S3-backed DarkPAN fronted
by CloudFront. (HTTPS requires L<IO::Socket::SSL>/L<Net::SSLeay> to be present,
as with any C<HTTP::Tiny> https use.)

=head1 HOW IT WORKS

On construction the resolver fetches C<modules/packages.db.gz> from
the mirror, decompresses it to a temporary file, opens the SQLite
database, and uses it only for package lookups.

=over 4

=item 1. selects all rows for the requested package from the index;

=item 2. keeps only versions that satisfy the request's version range, using
cpm's own version semantics (L<App::cpm::version>) so its choices agree with the
rest of the cascade;

=item 3. picks the highest satisfying version (compared in Perl -- SQLite's
lexical C<ORDER BY> would order C<1.10.0> below C<1.9.0>);

=item 4. reconstructs the fetch URI from the stored distribution path via
L<App::cpm::DistNotation> and returns it to cpm.

=back

The temporary database file is removed when the resolver object is destroyed.

=head1 METHODS

These implement the cpm resolver contract; you do not normally call them
directly.

=head2 new

  DarkPAN::Resolver::SQLite->new( $ctx, $mirror_url )

Fetches and opens the index. Called by cpm with the context and the argument
you supplied after the class name in C<--resolver>.

=head2 resolve

  $resolver->resolve( $ctx, $task )

Resolves one request. C<$task> carries C<package> and C<version_range>. Returns
a resolution hashref (C<source>, C<distfile>, C<uri>, C<version>, C<package>) on
success, or C<< { error => ... } >> if the package or a satisfying version is
not found -- allowing the cascade to fall through to the next resolver.

=head1 LIMITATIONS

Per-package resolution only: like every cpm resolver, it answers "which version
of I<this> package, from where"; it is not a global dependency solver. The
version index it reads must be published by L<DarkPAN::Indexer> at
C<modules/packages.db.gz> under the mirror. The whole index is fetched on
construction (no incremental/conditional fetch); this is negligible for typical
index sizes.

The resolver can select only distributions recorded in the published SQLite
index. A distribution tarball that exists in the repository but has not been
indexed is not visible to the resolver.

=head1 SEE ALSO

L<DarkPAN::Indexer>, L<App::cpm>, L<App::cpm::Resolver::02Packages>

=head1 AUTHOR

Rob Lauer

=cut
