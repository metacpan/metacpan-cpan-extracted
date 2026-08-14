use strict;
use warnings;
use Test::More;
use Path::Tiny;
use PPI;

# Ticket #108: no file under lib/ or bin/ says `use utf8`, and that is
# deliberate -- CLAUDE.md puts non-ASCII in *data* and gives App::karr::Encoding
# sole ownership of every character/octet crossing. A literal non-ASCII byte in
# a source file breaks that rule silently. Without `use utf8` Perl reads the
# three bytes of an em dash (e2 80 94) as three Latin-1 characters, and the
# :encoding(UTF-8) layer enable_std_utf8() installs then encodes each of them
# again, so the user gets c3 a2 c2 80 c2 94: a stray a-circumflex and two
# control characters. App::karr::Foundation::_append_log writes that to
# .karr.log through append_utf8, so it corrupts a file on disk, not just a
# terminal.
#
# Eleven literals had drifted in that way before anyone noticed, which is why
# this test polices the class rather than the eleven sites. The cure is to spell
# the character (`"\x{2014}"`), never to add `use utf8` to the offending file.
#
# POD and comments are exempt on purpose: they are not executable, PodWeaver
# takes a separate path, and they are full of em dashes that should stay. A test
# that cried wolf over every one of those would be switched off within a week,
# so the classification has to be exact -- hence PPI, rather than a regex over
# lines, which cannot tell a `#` opening a comment from one inside a string.

# Tokens whose content never reaches a filehandle as program output.
my %EXEMPT = map { $_ => 1 } qw(
  PPI::Token::Pod
  PPI::Token::Comment
  PPI::Token::End
  PPI::Token::Data
);

# Every non-ASCII byte in executable code in $file, as { line, kind, text }.
sub scan_file {
  my ($file) = @_;
  my $doc = PPI::Document->new("$file")
    or die "PPI could not parse $file: " . PPI::Document->errstr . "\n";
  my @found;
  $doc->find( sub {
    my (undef, $el) = @_;
    return 0 unless $el->isa('PPI::Token');
    return 0 if $EXEMPT{ ref $el };

    # A here-doc keeps its body out of ->content (that holds only the `<<"EOT"`
    # marker), so the body needs asking for by name. Checked, not assumed: a
    # scanner that only read ->content would report a clean tree while a
    # here-doc full of literal em dashes printed straight to the terminal.
    my @text = $el->content;
    push @text, $el->heredoc if $el->isa('PPI::Token::HereDoc');

    for my $t (@text) {
      next unless defined $t && $t =~ /[^\x00-\x7f]/;
      push @found, {
        line => $el->line_number,
        kind => ref $el,
        text => $t,
      };
      last;
    }
    return 0;
  } );
  return @found;
}

# Render a finding with the offending bytes spelled out, so a failure names the
# character to replace instead of printing mojibake back at the reader.
sub describe {
  my ($file, $f) = @_;
  ( my $shown = $f->{text} ) =~ s/([^\x20-\x7e\n])/sprintf '<%02x>', ord $1/ge;
  $shown =~ s/\n.*\z/ .../s;
  return sprintf '%s:%s [%s] %s', $file, $f->{line} // '?', $f->{kind}, $shown;
}

# --------------------------------------------------------------------------
# The scanner has to be able to fail, and has to leave POD and comments alone.
# Both are proven against fixtures before it is pointed at the distribution:
# a green result below is only worth having if these two subtests pass.
# --------------------------------------------------------------------------

my $tmp = Path::Tiny->tempdir;

subtest 'the scanner catches non-ASCII in executable code' => sub {
  # "\xe2\x80\x94" is the em dash written as the three separate Latin-1
  # characters Perl actually sees in a source file that lacks `use utf8` --
  # i.e. exactly the bug, byte for byte.
  my $bad = $tmp->child('Bad.pm');
  $bad->spew_raw( join '',
    "package Bad;\n",
    "my \$msg = \"skip \xe2\x80\x94 no board\";\n",
    "my \$doc = <<'EOT';\n",
    "here \xe2\x80\x94 doc\n",
    "EOT\n",
    "1;\n",
  );

  my @found = scan_file($bad);
  is( scalar @found, 2, 'both the string literal and the here-doc body are caught' )
    or diag( join "\n", map { describe( $bad, $_ ) } @found );
  is $found[0]{line}, 2, 'the string literal is reported on its own line';
  like $found[0]{kind}, qr/Quote/, '...and identified as a quoted string';
  is $found[1]{kind}, 'PPI::Token::HereDoc', 'the here-doc body is caught too';
};

subtest 'the scanner leaves POD, comments and __END__ alone' => sub {
  my $good = $tmp->child('Good.pm');
  $good->spew_raw( join '',
    "package Good;\n",
    "# a comment \xe2\x80\x94 with a dash\n",
    "\n",
    "=head1 NAME\n",
    "\n",
    "Good \xe2\x80\x94 pod prose with a dash\n",
    "\n",
    "=cut\n",
    "\n",
    "my \$msg = 'plain ascii';\n",
    "1;\n",
    "__END__\n",
    "trailing \xe2\x80\x94 matter\n",
  );

  # Guard against a vacuous pass: if the fixture lost its non-ASCII bytes the
  # subtest below would succeed while proving nothing.
  like $good->slurp_raw, qr/[^\x00-\x7f]/,
    'the fixture really does carry non-ASCII bytes';

  my @found = scan_file($good);
  is( scalar @found, 0, 'none of them are reported' )
    or diag( join "\n", map { describe( $good, $_ ) } @found );
};

# --------------------------------------------------------------------------
# The distribution itself.
# --------------------------------------------------------------------------

my @files;
path('lib')->visit(
  sub { my ($p) = @_; push @files, "$p" if $p->is_file && $p =~ /\.pm\z/ },
  { recurse => 1 },
);
push @files, map { "$_" } grep { $_->is_file } path('bin')->children;
@files = sort @files;

cmp_ok scalar @files, '>=', 2, 'found source files to scan'
  or BAIL_OUT('nothing to scan -- run this from the distribution root');
ok scalar( grep { m{lib/App/karr/Cmd/Context\.pm\z} } @files ),
  'the sweep reaches lib/App/karr/Cmd/Context.pm';
ok scalar( grep { m{bin/karr\z} } @files ), 'the sweep reaches bin/karr';

my @offenders;
for my $file (@files) {
  push @offenders, describe( $file, $_ ) for scan_file($file);
}

is scalar @offenders, 0,
  'no non-ASCII in executable code under lib/ and bin/ (ticket #108)'
  or diag(
    "Spell the character instead of pasting it -- \"\\x{2014}\" for an em dash.\n"
    . "Do NOT add `use utf8`: it would make the file an exception to the rule\n"
    . "that App::karr::Encoding owns every character/octet crossing.\n"
    . join( "\n", map { "  $_" } @offenders )
  );

done_testing;
