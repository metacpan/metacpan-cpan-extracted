package CPAN::Changes::Parser;
use strict;
use warnings;

our $VERSION = '0.500004';
$VERSION =~ tr/_//d;

use Module::Runtime qw(use_module);
use Carp qw(croak);
use Encode qw(decode FB_CROAK LEAVE_SRC);

use Moo;

has _changelog_class => (
  is => 'ro',
  default => 'CPAN::Changes',
  coerce => sub { use_module($_[0]) },
);
has _release_class => (
  is => 'ro',
  default => 'CPAN::Changes::Release',
  coerce => sub { use_module($_[0]) },
);
has _entry_class => (
  is => 'ro',
  default => 'CPAN::Changes::Entry',
  coerce => sub { use_module($_[0]) },
);
has version_like => (
  is => 'ro',
);
has version_prefix => (
  is => 'ro',
);

sub parse_string {
  my ($self, $string) = @_;
  $self->_transform($self->_parse($string));
}

sub parse_file {
  my ($self, $file, $layers) = @_;
  my $mode = defined $layers ? "<$layers" : '<:raw';
  open my $fh, $mode, $file or croak "Can't open $file: $!";
  my $content = do { local $/; <$fh> };
  if (!defined $layers) {
    # if it's valid UTF-8, decode that.  otherwise, assume latin 1 and leave it.
    eval { $content = decode('UTF-8', $content, FB_CROAK | LEAVE_SRC) };
  }
  $self->parse_string($content);
}

sub _transform {
  my ($self, $data) = @_;

  my $release_class = $self->_release_class;
  my $entry_class = $self->_entry_class;

  $self->_changelog_class->new(
    (defined $data->{preamble} ? (preamble => $data->{preamble}) : ()),
    releases => [
      map {
        my $r = $_;
        $release_class->new(
          (map { defined $r->{$_} ? ($_ => $r->{$_}) : () }
            qw(version line date raw_date note)),
          ($_->{entries} ? (
            entries => [
              map { _trans_entry($entry_class, $_) } @{$_->{entries}},
            ],
          ) : () ),
        )
      } reverse @{$data->{releases}},
    ],
  );
}

sub _trans_entry {
  my ($entry_class, $entry) = @_;

  $entry_class->new(
    line => $entry->{line},
    text => $entry->{text},
    $entry->{entries} ? (
      entries => [
        map { _trans_entry($entry_class, $_) } @{$entry->{entries}},
      ],
    ) : (),
  );
}

our $VERSION_REGEX = qr{
  (?:
    v [0-9]+ (?: (?:\.[0-9]+ )+ (?:_[0-9]+)? )?
    |
    (?:[0-9]+)? (?:\.[0-9]+){2,} (?:_[0-9]+)?
    |
    [0-9]* \.[0-9]+ (?: _[0-9]+ )?
    |
    [0-9]+ (?: _[0-9]+ )?
  )
  (?: -TRIAL )?
}x;

sub _parse {
  my ($self, $string) = @_;

  my $version_prefix = qr/version|revision/i;
  if (defined(my $vp = $self->version_prefix)) {
    $version_prefix = qr/$version_prefix|$vp/
  }
  my $version_token = qr/$VERSION_REGEX(?:-TRIAL)?/;
  if (defined(my $vt = $self->version_like)) {
    $version_token = qr/$version_token|$vt/
  }

  my $raw_preamble = '';
  my @releases;
  my @indents;
  my $line_number = -1;
  while ($string =~ /((.*?)(?:\r\n?|\n|\z))/g) {
    my ($full_line, $line) = ($1, $2);
    last
      if !length $full_line;
    $line_number++;

    if ( $line =~ /^(?:$version_prefix\s+)?($version_token)(?:[:;.-]?\s+(.*))?$/i ) {
      my $version = $1;
      my $note    = $2;
      my $date;
      my $raw_date;
      if (defined $note) {
        ($date, $raw_date, $note) = _split_date($note);
      }

      my $release = {
        version => $version,
        (defined $date ? (date => $date) : ()),
        (defined $raw_date ? (raw_date => $raw_date) : ()),
        (defined $note ? (note => $note) : ()),
        raw     => $full_line,
        entries => [],
        line    => $line_number+1,
      };
      push @releases, $release;
      @indents = ($release);
      next;
    }
    elsif (!@indents) {
      $raw_preamble .= $full_line,
      next;
    }

    if ( $line =~ /^[-_*+~#=\s]*$/ ) {
      $indents[-1]{done}++
        if @indents > 1;

      if (@indents) {
        $indents[-1]{raw} .= $full_line;
      }
      else {
        $releases[-1]{raw} .= $full_line;
      }
      next;
    }

    $line =~ s/\s+$//;
    $line =~ s/^(\s*)//;
    my $indent = 1 + length _expand_tab($1);
    my $change;
    my $done;
    my $nest;
    my $style = '';
    if ( $line =~ /^\[\s*([^\[\]]*)\]$/ ) {
      $done   = 1;
      $nest   = 1;
      $change = $1;
      $style  = '[]';
      $change =~ s/\s+$//;
    }
    elsif ( $line =~ /^([-*+=#]+)\s+(.*)/ ) {
      $style = $1;
      $change = $2;
    }
    else {
      $change = $line;
      if (
        defined $indents[-1]{text}
        && !$indents[-1]{done}
        && (
          $indent > $#indents
          || (
            $indent == $#indents
            && (
              length $indents[-1]{style}
              || $indent == 1
            )
          )
        )
      ) {
        $indents[-1]{raw}  .= $full_line;
        $indents[-1]{text} .= " $change";
        next;
      }
    }

    my $group;
    my $nested;

    if ( !$nest && $indents[$indent]{nested} ) {
      $nested = $group = $indents[$indent]{nested};
    }
    elsif ( !$nest && $indents[$indent]{nest} ) {
      $nested = $group = $indents[$indent];
    }
    else {
      ($group) = grep {defined} reverse @indents[ 0 .. $indent - 1 ];
    }

    my $entry = {
      text   => $change,
      line   => $line_number+1,
      done   => $done,
      nest   => $nest,
      nested => $nested,
      style  => $style,
      raw    => $full_line,
    };
    push @{ $group->{entries} ||= [] }, $entry;

    if ( $indent <= $#indents ) {
      $#indents = $indent;
    }

    $indents[$indent] = $entry;
  }
  my $preamble;
  if (length $raw_preamble) {
    $preamble = $raw_preamble;
    $preamble =~ s/\A\s*\n//;
    $preamble =~ s/\s+\z//;
    $preamble =~ s/\r\n?/\n/g;
  }

  my @entries = @releases;
  while ( my $entry = shift @entries ) {
    push @entries, @{ $entry->{entries} } if $entry->{entries};
    delete @{$entry}{qw(done nest nested)};
  }
  return {
    ( defined $preamble ? (preamble => $preamble) : () ),
    raw_preamble => $raw_preamble,
    releases => \@releases,
  };
}

my @months = qw(
  Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec
);
my %months = map {; lc $months[$_] => $_ } 0 .. $#months;
our ($_SHORT_MONTH) = map qr{$_}i, join '|', map quotemeta, @months;
our ($_SHORT_DAY) = map qr{$_}i, join '|', map quotemeta, qw(
  Sun Mon Tue Wed Thu Fri Sat
);
our ($_UNKNOWN_DATE) = map qr{$_}i, join '|', map quotemeta, (
  'Unknown Release Date',
  'Unknown',
  'Not Released',
  'Development Release',
  'Development',
  'Developer Release',
);

our $_LOCALTIME_DATE = qr{
  (?:
    (?:$_SHORT_DAY\s+)?
    ($_SHORT_MONTH)\s+
    |
    ($_SHORT_MONTH)\s+
    (?:$_SHORT_DAY\s+)
  )
  (\d{1,2})\s+  # date
  (?: ([\d:]+)\s+ )?  # time
  (?: ([A-Z]+)\s+ )?  # timezone
  (\d{4})       # year
}x;

our $_RFC_2822_DATE = qr{
  $_SHORT_DAY,\s+
  (\d{1,2})\s+
  ($_SHORT_MONTH)\s+
  (\d{4})\s+
  (\d\d:\d\d:\d\d)\s+
  ([+-])(\d{2})(\d{2})
}x;

our $_DZIL_DATE = qr{
  (\d{4}-\d\d-\d\d)\s+
  (\d\d:\d\d(?::\d\d)?)(\s+[A-Za-z]+/[A-Za-z_-]+)
}x;

our $_ISO_8601_DATE = qr{
  \d\d\d\d # Year
  (?:
    [-/]\d\d # -Month
    (?:
      [-/]\d\d # -Day
      (?:
        [T\s]
        \d\d:\d\d # Hour:Minute
        (?:
          :\d\d         # :Second
          (?: \.\d+ )?  # .Fractional_Second
        )?
        (?:
          Z             # UTC
          |
          [+-]\d\d:\d\d # Hour:Minute TZ offset
          (?: :\d\d )?  # :Second TZ offset
        )?
      )?
    )?
  )?
}x;

sub _split_date {
  my $note = shift;
  my $date;
  my $parsed_date;
  # munge date formats, save the remainder as note
  if (defined $note && length $note) {
    $note =~ s/^[^\w\s]*\s+//;
    $note =~ s/\s+$//;

    # explicitly unknown dates
    if ( $note =~ s{^($_UNKNOWN_DATE)}{} ) {
      $parsed_date = $date = $1;
    }

    # handle localtime-like timestamps
    elsif ( $note =~ s{^($_LOCALTIME_DATE)}{} ) {
      $date = $1;
      $parsed_date = sprintf( '%d-%02d-%02d', $7, 1+$months{lc($2 || $3)}, $4 );
      if ($5) {
        # unfortunately ignores TZ data ($6)
        $parsed_date .= sprintf( 'T%sZ', $5 );
      }
    }

    # RFC 2822
    elsif ( $note =~ s{^($_RFC_2822_DATE)}{} ) {
      $date = $1;
      $parsed_date = sprintf( '%d-%02d-%02dT%s%s%02d:%02d',
        $4, 1+$months{lc $3}, $2, $5, $6, $7, $8 );
    }

    # handle dist-zilla style, again ingoring TZ data
    elsif ( $note =~ s{^($_DZIL_DATE)}{} ) {
      $date = $1;
      $parsed_date = sprintf( '%sT%sZ', $2, $3 );
      $note = $4 . $note;
    }

    # start with W3CDTF, ignore rest
    elsif ( $note =~ s{^($_ISO_8601_DATE)}{} ) {
      $parsed_date = $date = $1;
      $parsed_date =~ s{ }{T};
      $parsed_date =~ s{/}{-}g;

      # Add UTC TZ if date ends at H:M, H:M:S or H:M:S.FS
      $parsed_date .= 'Z'
        if length($parsed_date) == 16
        || length($parsed_date) == 19
        || $parsed_date =~ m{\.\d+$};
    }

    $note =~ s/^\s+//;
  }

  defined $_ && !length $_ && undef $_ for ($parsed_date, $date, $note);

  return ($parsed_date, $date, $note);
}

sub _expand_tab {
  my $string = "$_[0]";
  $string =~ s/([^\t]*)\t/$1 . (" " x (8 - (length $1) % 8))/eg;
  return $string;
}

1;
__END__

=head1 NAME

CPAN::Changes::Parser - Parse a CPAN Changelog file

=head1 SYNOPSIS

  my $parser = CPAN::Changes::Parser->new(
    version_like => qr/\{\{\$NEXT\}\}/,
    version_prefix => qr/=head\d\s+/,
  );

  my $changelog = $parser->parse_file('Changes', ':utf8');
  my $changelog = $parser->parse_string($content);

=head1 DESCRIPTION

Parses a file or string into a L<CPAN::Changes> object.  Many forms of change
log are accepted.

=head1 ATTRIBUTES

=head2 version_like

A regular expression for a token that will be accepted in place of a version
number.  For example, this could be set to C<qr/\{\{\$NEXT\}\}/> if the
L<Dist::Zilla> plugin L<[NextRelease]|Dist::Zilla::Plugin::NextRelease> is
managing the file.

=head2 version_prefix

A regular expression for a prefix that will be matched before a version number.
C<qr/=head\d\s+/> could be used if the change log is using Pod headings for the
release headings.

=head1 METHODS

=head2 parse_file

Parses a file into a L<CPAN::Changes> object.  Optionally accepts a string of
layers to be used when reading the file.

=head2 parse_string

Parses a string into a L<CPAN::Changes> object.

=head1 AUTHORS

See L<CPAN::Changes> for authors.

=head1 COPYRIGHT AND LICENSE

See L<CPAN::Changes> for the copyright and license.

=cut
