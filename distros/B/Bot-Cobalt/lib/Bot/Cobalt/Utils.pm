package Bot::Cobalt::Utils;
$Bot::Cobalt::Utils::VERSION = '0.021003';
use strictures 2;
use Carp;
use Scalar::Util 'reftype';

use App::bmkpasswd ();

use parent 'Exporter::Tiny';

our @EXPORT_OK = qw/
  secs_to_str
  secs_to_str_y
  secs_to_timestr
  timestr_to_secs

  mkpasswd
  passwdcmp

  color

  glob_grep
  glob_to_re
  glob_to_re_str
  rplprintf
/;

our %EXPORT_TAGS = (
  ALL => [ @EXPORT_OK ],
);


## codes mostly borrowed from IRC::Utils
our %COLORS = (
  NORMAL      => "\x0f",

  BOLD        => "\x02",
  UNDERLINE   => "\x1f",
  REVERSE     => "\x16",
  ITALIC      => "\x1d",

  WHITE       => "\x0300",
  BLACK       => "\x0301",
  BLUE        => "\x0302",
  GREEN       => "\x0303",
  RED         => "\x0304",
  BROWN       => "\x0305",
  PURPLE      => "\x0306",
  ORANGE      => "\x0307",
  YELLOW      => "\x0308",
  TEAL        => "\x0310",
  PINK        => "\x0313",
  GREY        => "\x0314",
  GRAY        => "\x0314",

  LIGHT_BLUE  => "\x0312",
  LIGHT_CYAN  => "\x0311",
  LIGHT_GREEN => "\x0309",
  LIGHT_GRAY  => "\x0315",
  LIGHT_GREY  => "\x0315",
);

my %default_fmt_vars;
for my $color (keys %COLORS) {
  my $fmtvar = 'C_'.$color;
  $default_fmt_vars{$fmtvar} = $COLORS{$color};
}

## String formatting, usually for langsets:
sub rplprintf {
  my $string = shift;
  return '' unless $string;

  ## rplprintf( $string, $vars )
  ## returns empty string if no string is specified.
  ##
  ## variables can be terminated with % or a space:
  ## rplprintf( "Error for %user%: %err")
  ##
  ## used for formatting lang RPLs
  ## $vars should be a hash keyed by variable, f.ex:
  ##   'user' => $username,
  ##   'err'  => $error,

  my %vars;

  if (@_ > 1) {
    my %args = @_;
    %vars = ( %default_fmt_vars, %args );
  } else {
    if (reftype $_[0] eq 'HASH') {
      %vars = ( %default_fmt_vars, %{$_[0]} );
    } else {
      confess "rplprintf() expects a hash"
    }
  }

  my $repl = sub {
    ## _repl($1, $2, $vars)
    my ($orig, $match) = @_;
    defined $vars{$match} ? $vars{$match} : $orig
  };

  my $regex = qr/(%([^\s%]+)%?)/;

  $string =~ s/$regex/$repl->($1, $2)/ge;

  $string
}


## Glob -> regex functions:

sub glob_grep ($;@) {
  my $glob = shift;
  confess "glob_grep called with no arguments!"
    unless defined $glob;

  my @array = ref $_[0] eq 'ARRAY' ? @{$_[0]} : @_ ;

  my $re = glob_to_re($glob);

  grep { m/$re/ } @array
}

sub glob_to_re ($) {
  my ($glob) = @_;
  confess "glob_to_re called with no arguments!"
    unless defined $glob;

  my $re = glob_to_re_str($glob);

  qr/$re/
}

sub glob_to_re_str ($) {
  ## Currently allows:
  ##   *  == .*
  ##   ?  == .
  ##   +  == literal space
  ##   leading ^ (beginning of str) is accepted
  ##   so is trailing $
  ##   char classes are accepted
  my ($glob) = @_;
  confess "glob_to_re_str called with no arguments!"
    unless defined $glob;

  my($re, $in_esc);
  my ($first, $pos) = (1, 0);
  my @chars = split '', $glob;
  for my $ch (@chars) {
    ++$pos;
    my $last = 1 if $pos == @chars;

    ## Leading ^ (start) is OK:
    if ($first) {
      if ($ch eq '^') {
        $re .= '^' ;
        next
      }
      $first = 0;
    ## So is trailing $ (end):
    } elsif ($last && $ch eq '$') {
      $re .= '$' ;
      last
    }

    ## Escape metas:
    if (grep { $_ eq $ch } qw/ . ( ) | ^ $ @ % { } /) {
      $re .= "\\$ch" ;
      $in_esc = 0;
      next
    }

    ## Handle * ? + wildcards:
    if ($ch eq '*') {
      $re .= $in_esc ? '\*' : '.*' ;
      $in_esc = 0;
      next
    }
    if ($ch eq '?') {
      $re .= $in_esc ? '\?' : '.' ;
      $in_esc = 0;
      next
    }
    if ($ch eq '+') {
      $re .= $in_esc ? '\+' : '\s' ;
      $in_esc = 0;
      next
    }
    if ( $ch eq '[' || $ch eq ']' ) {
      $re .= $in_esc ? "\\$ch" : $ch ;
      $in_esc = 0;
      next
    }

    ## Switch on/off escaping:
    if ($ch eq "\\") {
      if ($in_esc) {
        $re .= "\\\\";
        $in_esc = 0;
      } else { $in_esc = 1; }
      next
    }

    $re .= $ch;
    $in_esc = 0;
  }

  $re
}


## IRC color codes:
sub color ($;$) {
  ## color($format, $str)
  ## implements mirc formatting codes, against my better judgement
  ## if format is unspecified, returns NORMAL

  ## interpolate bold, reset to NORMAL after:
  ## $str = color('bold') . "Text" . color;
  ##  -or-
  ## format specified strings, resetting NORMAL after:
  ## $str = color('bold', "Some text"); # bold text ending in normal

  my ($format, $str) = @_;
  $format = uc($format||'normal');

  my $selected = $COLORS{$format};

  carp "Invalid COLOR $format passed to color()"
    unless $selected;

  return $selected . $str . $COLORS{NORMAL} if $str;
  $selected || $COLORS{NORMAL};
}


## Time/date ops:
sub timestr_to_secs ($) {
  ## turn something like 2h3m30s into seconds
  my ($timestr) = @_;

  unless ($timestr) {
    carp "timestr_to_secs() received a false value";
    return 0
  }

  ## maybe just seconds:
  return $timestr if $timestr =~ /^[0-9]+$/;

  my @chunks = $timestr =~ m/([0-9]+)([dhms])/gc;

  my $secs = 0;
  while ( my ($ti, $unit) = splice @chunks, 0, 2 ) {
    UNIT: {
      if ($unit eq 'd') {
        $secs += $ti * 86400;
        last UNIT
      }

      if ($unit eq 'h') {
        $secs += $ti * 3600;
        last UNIT
      }

      if ($unit eq 'm') {
        $secs += $ti * 60;
        last UNIT
      }

      $secs += $ti;
    }
  }

  $secs
}

sub _time_breakdown ($) {
  my ($diff) = @_;
  return unless defined $diff;

  my $days   = int $diff / 86400;
  my $sec    = $diff % 86400;
  my $hours  = int $sec / 3600;
  $sec %= 3600;
  my $mins   = int $sec / 60;
  $sec %= 60;

  ($days, $hours, $mins, $sec)
}

sub secs_to_timestr ($) {
  my ($diff) = @_;
  return unless defined $diff;
  my ($days, $hours, $mins, $sec) = _time_breakdown($diff);

  my $str;
  $str .= $days  .'d' if $days;
  $str .= $hours .'h' if $hours;
  $str .= $mins  .'m' if $mins;
  $str .= $sec   .'s' if $sec;

  $str
}

sub secs_to_str ($) {
  ## turn seconds into a string like '0 days, 00:00:00'
  my ($diff) = @_;
  return unless defined $diff;
  my ($days, $hours, $mins, $sec) = _time_breakdown($diff);
  my $plural = $days == 1 ? 'day' : 'days';
  sprintf "%d $plural, %2.2d:%2.2d:%2.2d", $days, $hours, $mins, $sec
}

sub secs_to_str_y {
  my ($diff) = @_;
  return unless defined $diff;
  my ($days, $hrs, $mins, $sec) = _time_breakdown($diff);
  my $yrs = int $days / 365;
  $days %= 365;
  my $plural_y = $yrs > 1 ? 'years' : 'year';
  my $plural_d = $days == 1 ? 'day' : 'days';
  $yrs ?
    sprintf "%d $plural_y, %d $plural_d, %2.2d:%2.2d:%2.2d",
      $yrs, $days, $hrs, $mins, $sec
    : sprintf "%d $plural_d, %2.2d:%2.2d:%2.2d",
        $days, $hrs, $mins, $sec
}


## App::bmkpasswd stubs as of 00_35
sub mkpasswd  ($;@) { App::bmkpasswd::mkpasswd(@_) }
sub passwdcmp ($$) { App::bmkpasswd::passwdcmp(@_) }

1;
__END__
=pod

=head1 NAME

Bot::Cobalt::Utils - Utilities for Cobalt plugins

=head1 DESCRIPTION

Bot::Cobalt::Utils provides a set of simple utility functions for the 
L<Bot::Cobalt> core and plugins.

Plugin authors may wish to make use of these; importing the B<:ALL> tag 
from Bot::Cobalt::Utils will give you access to the entirety of this 
utility module, including useful string formatting tools, safe 
password hashing functions, etc.

You may also want to look at L<Bot::Cobalt::Common>, which exports most 
of this module.

=head1 USAGE

Import nothing:

  use Bot::Cobalt::Utils;
  
  my $hash = Bot::Cobalt::Utils::mkpasswd('things');

Import some things:

  use Bot::Cobalt::Utils qw/ mkpasswd passwdcmp /;
  
  my $hash = mkpasswd('things');

Import all the things:

  use Bot::Cobalt::Utils qw/ :ALL /;
  
  my $hash = mkpasswd('things', 'sha512');
  my $secs = timestr_to_secs('3h30m');
  . . .


See below for a list of exportable functions.


=head1 FUNCTIONS

=head2 Exportable functions

=over 

=item L</timestr_to_secs> - Convert a string into seconds

=item L</secs_to_timestr> - Convert seconds back into timestr

=item L</secs_to_str> - Convert seconds into a 'readable' string

=item L</color> - Add format/color to IRC messages

=item L</glob_to_re_str> - Convert Cobalt-style globs to regex strings

=item L</glob_to_re> - Convert Cobalt-style globs to compiled regexes

=item L</glob_grep> - Search an array or arrayref by glob

=item L</rplprintf> - Format portable langset reply strings

=item L</mkpasswd> - Create crypted passwords

=item L</passwdcmp> - Compare crypted passwords

=back


=head2 Date and Time

=head3 timestr_to_secs

Convert a string such as "2h10m" into seconds.

  my $delay_s = timestr_to_secs '1h33m10s';

Useful for dealing with timers.


=head3 secs_to_timestr

Turns seconds back into a timestring suitable for feeding to 
L</timestr_to_secs>:

  my $timestr = secs_to_timestr 820; ## -> 13m40s


=head3 secs_to_str

Convert a timestamp delta into a string.

Useful for uptime reporting, for example:

  my $delta = time() - $your_start_TS;
  my $uptime_str = secs_to_str $delta;

Returns time formatted as: C<< <D> day(s), <H>:<M>:<S> >>

=head3 secs_to_str_y

Like L</secs_to_str>, but includes year calculation and returns time formatted
as: C<< <Y> year(s), <D> day(s), <H>:<M>:<S> >> B<if> there are more than 365
days; otherwise the same format as L</secs_to_str> is returned.

(Added in C<v0.18.1>)

=head2 String Formatting

=head3 color

Add mIRC formatting and color codes to a string.

Valid formatting codes:

  NORMAL BOLD UNDERLINE REVERSE ITALIC

Valid color codes:

  WHITE BLACK BLUE GREEN RED BROWN PURPLE ORANGE YELLOW TEAL PINK
  LIGHT_CYAN LIGHT_BLUE LIGHT_GRAY LIGHT_GREEN

Format/color type can be passed in upper or lower case.

If passed just a color or format name, returns the control code.

If passed nothing at all, returns the 'NORMAL' reset code:

  my $str = color('bold') . "bold text" . color() . "normal text";

If passed a color or format name and a string, returns the formatted
string, terminated by NORMAL:

  my $formatted = color('red', "red text") . "normal text";

If you need to retrieve (or alter via C<local>, for example) the actual
control characters themselves, they are accessible via the C<<
%Bot::Cobalt::Utils::COLORS >> hash:

  my $red = $Bot::Cobalt::Utils::COLORS{RED}

=head3 glob_to_re_str

glob_to_re_str() converts Cobalt-style globs to regex strings.

  my $re = glob_to_re_str "th?ngs*stuff";
  ## or perhaps compile it:
  my $compiled_re = qr/$re/;

Perl regular expressions are very convenient and powerful. Unfortunately, 
that also means it's easy to make them eat up all of your CPU and thereby 
possibly break your system (or at least be annoying!)

For string search functions, it's better to use Cobalt-style globs:

  * == match any number of any character
  ? == match any single character
  + == match any single space
  leading ^  == anchor at start of string
  trailing $ == anchor at end of string

Standard regex syntax will be escaped and a translated regex returned.

The only exception is character classes; this is valid, for example:

  ^[a-z0-9]*$

=head3 glob_to_re

glob_to_re() converts Cobalt-style globs to B<compiled> regexes (qr//)

Using a compiled regex for matching is faster. Note that compiled regexes 
can also be serialized to B<YAML> using Bot::Cobalt::Serializer.

See L</glob_to_re_str> for details on globs. This function shares the same 
syntax.


=head3 glob_grep

glob_grep() can be used to search an array or an array reference for strings 
matching the specified glob:

  my @matches = glob_grep($glob, @array) || 'No matches!';
  my @matches = glob_grep($glob, $array_ref);

Returns the output of grep, which will be a list in list context or 
the number of matches in scalar context.


=head3 rplprintf

rplprintf() provides string formatting with replacement of arbitrary 
variables.

  rplprintf( $string, %vars_hash );
  rplprintf( $string, $vars_ref  );

The first argument to C<rplprintf> should be the template string. 
It may contain variables in the form of B<%var> or B<%var%> to be 
replaced.

The second argument is the hash (or hash reference) mapping B<%var> 
variables to strings.

For example:

  $string = "Access denied for %user (%host%)";
  $response = rplprintf(  $string,
      user => "Joe",
      host => "joe!joe@example.org",
  );  
  ## $response = 'Access denied for Joe (joe!joe@example.org)'

Intended for formatting langset RPLs before sending, but can be used for 
any simple string template.

Variable names can be terminated with a space or % -- both are demonstrated 
in the example above. You'll need to terminate with a trailing % if there 
are non-space characters following, as in the above example: I<(%host%)>

The same color/format strings as L</color> can be applied via %C_* vars:

  $string = "Access %C_BOLD%denied%C_NORMAL";
  $response = rplprintf( $string );

=head2 Password handling

=head3 mkpasswd

Simple interface for creating hashed passwords.

Defaults to creating a password using L<Crypt::Eksblowfish::Bcrypt> 
with a random salt and bcrypt work cost '08' -- this is a pretty sane 
default.

See L<App::bmkpasswd> for details; the built-in hash generation sugar 
was moved to that package.

bcrypt is strongly recommended; SHA and MD5 methods are also supported. 
Salts are always random.

  ## create a bcrypted password (work cost 08)
  ## bcrypt is blowfish with a work cost factor.
  ## if hashes are stolen, they'll be slow to break
  ## see http://codahale.com/how-to-safely-store-a-password/
  my $hashed = mkpasswd $password;

  ## you can specify method options . . .
  ## here's bcrypt with a lower work cost factor.
  ## (must be a two-digit power of 2, possibly padded with 0)
  my $hashed = mkpasswd $password, 'bcrypt', '06';

  ## Available methods:
  ##  bcrypt (preferred)
  ##  SHA-256 or -512 (req. modern libc or Crypt::Passwd::XS)
  ##  MD5 (fast, portable, weak)
  my $sha_passwd = mkpasswd $password, 'sha512';
  ## same as:
  my $sha_passwd = mkpasswd $password, 'SHA-512';


=head3 passwdcmp

Compare hashed passwords via L<App::bmkpasswd>.

Compatible with whatever methods C<mkpasswd> supports on the current 
system.

  return passwdcmp $password, $hashed;

Returns the hash if the cleartext password is a match. Otherwise returns 
boolean false.


=head1 AUTHOR

Jon Portnoy (avenj)

=cut
