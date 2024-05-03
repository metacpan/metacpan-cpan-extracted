package Test::CPAN::Changes;
use strict;
use warnings;

use CPAN::Changes::Parser;
use Test::Builder;
use version ();

our $VERSION = '0.500004';
$VERSION =~ tr/_//d;

use Exporter; BEGIN { *import = \&Exporter::import };

our @EXPORT = qw(changes_ok changes_file_ok);

our $Test   = Test::Builder->new;
our $Parser = CPAN::Changes::Parser->new(
  _release_class => 'Test::CPAN::Changes::Release',
);

sub changes_ok {
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  my ($arg) = @_;
  $Test->plan( tests => ( $arg && defined $arg->{version} ? 6 : 4 ) );
  return changes_file_ok( undef, @_ );
}

{
  package
    Test::CPAN::Changes::Release;
  use Moo;
  extends 'CPAN::Changes::Release';
  has raw_date => (is => 'ro');
}

sub changes_file_ok {
  my ( $file, $arg ) = @_;
  $file ||= 'Changes';
  $arg ||= {};

  local $Test::Builder::Level = $Test::Builder::Level + 1;

  my $tests = defined $arg->{version} ? 6 : 4;
  my $ok = 1;

  my $changes;

  $Test->ok(
    !!eval { $changes = $Parser->parse_file( $file ); 1 },
    "$file is loadable"
  ) or do {
    $Test->diag("Error: $@");
    $Test->skip("can't test unparsable change log") for 2 .. $tests;
    return !1;
  };

  my @releases =
    map $_->[0],
    sort { $a->[1] <=> $b->[1] }
    map [$_, $_->line],
    $changes->releases;

  $Test->ok( !!@releases, "$file contains at least one release" ) or $ok = 0;

  my $date_err;
  for my $release ( @releases ) {
    if ( !defined $release->date || $release->date eq ''  ) {
      $date_err = 'No date for version '.$release->version.' (line '.$release->line.')';
      last;
    }

    my $d = $release->raw_date;
    if (
      $d !~ m{^${CPAN::Changes::Parser::_ISO_8601_DATE}$}
      && $d !~ m{^(${CPAN::Changes::Parser::_UNKNOWN_DATE})$}
    ) {
      $Test->note( 'Date "' . $d . '" is not in the recommended W3CDTF format, should be "'.$release->date.'" (line '.$release->line.')' );
    }
  }
  $Test->ok( !defined $date_err, "$file contains all valid release dates" )
    or $Test->diag('  ERR: '.$date_err), $ok = 0;

  my $version_err;
  for my $release ( @releases ) {
    # strip off -TRIAL before testing
    (my $version = $release->version) =~ s/-TRIAL$//;
    if ( not version::is_lax($version) ) {
      $version_err = $release->version . ' (line '.$release->line.')';
      last;
    }
  }
  $Test->ok( !defined $version_err, "$file contains all valid release versions" )
    or $Test->diag('  ERR: '.$version_err), $ok = 0;

  if ( defined $arg->{version} ) {
    my $v = $arg->{version};

    my $release = $changes->release( $v );
    if ($Test->ok( !!$release, "$file has an entry for version $v" )) {
      my $entries = $release->entries;
      $Test->ok( !!@$entries, "$file version $v has content")
        or $ok = 0;
    }
    else {
      $Test->skip("can't check for entries in nonexistant version");
      $ok = 0;
    };
  }
  return !!$ok;
}

1;

__END__

=head1 NAME

Test::CPAN::Changes - Validation of the Changes file in a CPAN distribution

=head1 SYNOPSIS

  # in xt/author/cpan-changes.t
  use Test::More;
  use Test::CPAN::Changes;
  changes_ok;

  # checking for specific version
  use My::Module;
  use Test::More;
  use Test::CPAN::Changes;
  changes_ok({ version => My::Module->VERSION });

=head1 DESCRIPTION

This module allows CPAN authors to write automated tests to ensure their
changelogs match the specification.

=head1 SUBROUTINES

=head2 changes_ok( \%args )

Simple wrapper around C<changes_file_ok>. Declares a test plan, and uses the
default filename of C<Changes>.

=head2 changes_file_ok( $filename, \%arg )

Checks the contents of the changes file against the specification. No plan
is declared and if the filename is undefined, C<Changes> is used.

Four tests are performed.  The file must be parsable, must have releases in it,
and the versions and dates listed must be valid.

C<%arg> may include a I<version> entry, in which case two additional tests are
performed.  The entry for that version must exist and have content.  This is
useful to ensure that the version currently being released has documented
changes.

=head1 SEE ALSO

=over 4

=item * L<CPAN::Changes::Spec>

=item * L<CPAN::Changes>

=back

=head1 AUTHORS

See L<CPAN::Changes> for authors.

=head1 COPYRIGHT AND LICENSE

See L<CPAN::Changes> for the copyright and license.

=cut
