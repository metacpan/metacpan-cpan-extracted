use warnings;
use strict;

use Test::More;
use Config;
use File::Spec;

my @known_authors;
my @sections; # array of arrayrefs, one per section

do {
  # according to #p5p this is how one safely reads random unicode
  # this set of boilerplate is insane... wasn't perl unicode-king...?
  no warnings 'once';
  require Encode;
  require PerlIO::encoding;
  local $PerlIO::encoding::fallback = Encode::FB_CROAK();

  open (my $fh, '<:encoding(UTF-8)', 'AUTHORS') or die "Unable to open AUTHORS - can't happen: $!\n";
  my @current_section;
  my $in_header = 1;
  while (<$fh>) {
    chomp;
    if ( ! $_ or /^\s*\#/ ) {
      # blank or comment line — if we had entries, a new comment block
      # after entries starts a new section
      if ( @current_section and /^\s*\#/ and !$in_header ) {
        push @sections, [ @current_section ];
        @current_section = ();
        $in_header = 1;
      }
      next;
    }
    $in_header = 0;
    push @current_section, $_;
    push @known_authors, $_;
  }
  push @sections, [ @current_section ] if @current_section;
};

die "Known AUTHORS file seems empty... can't happen..." unless @known_authors;

is_deeply (
  [ grep { /^\s/ or /\s\s/ } @known_authors ],
  [],
  "No entries with leading or doubled space",
);

is_deeply (
  [ grep { / \:[^\s\/] /x or /^ [^:]*? \s+ \: /x } @known_authors ],
  [],
  "No entries with malformed nicks",
);

for my $i ( 0 .. $#sections ) {
  is_deeply (
    $sections[$i],
    [ sort { lc $a cmp lc $b } @{ $sections[$i] } ],
    "Author list section @{[$i+1]} is case-insensitively sorted"
  );
}

my $email_re = qr/( \< [^\<\>]+ \> ) $/x;

my %known_authors;
for (@known_authors) {
  my ($name_email) = m/ ^ (?: [^\:]+ \: \s )? (.+) /x;
  my ($email) = $name_email =~ $email_re;

  fail "Duplicate found: $name_email" if (
    $known_authors{$name_email}++
      or
    ( $email and $known_authors{$email}++ )
  );
}

# augh taint mode
if (length $ENV{PATH}) {
  ( $ENV{PATH} ) = join ( $Config{path_sep},
    map { length($_) ? File::Spec->rel2abs($_) : () }
      split /\Q$Config{path_sep}/, $ENV{PATH}
  ) =~ /\A(.+)\z/;
}

if (-d '.git') {

  binmode (Test::More->builder->$_, ':utf8') for qw/output failure_output todo_output/;

  # this may fail - not every system has git
  for (
    map
      { my ($gitname) = m/^ \s* \d+ \s* (.+?) \s* $/mx; utf8::decode($gitname); $gitname }
      qx( git shortlog -e -s )
  ) {
    my ($eml) = $_ =~ $email_re;

    ok $known_authors{$eml},
      "Commit author '$_' (from .mailmap-aware `git shortlog -e -s`) reflected in ./AUTHORS";
  }
}

done_testing;
