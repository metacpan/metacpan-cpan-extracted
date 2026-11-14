package DBIO::Util;
# ABSTRACT: Internal utility functions for DBIO

use warnings;

our $VERSION = '0.900005';

use strict;

use Config;
use Digest::SHA ();
use POSIX ();

# All configuration as lowercase functions — safe in quote_sub/eval contexts
# when called fully qualified (DBIO::Util::func_name())
sub spurious_version_check_warnings () {
  ( $ENV{DBIO_TEST_VERSION_WARNS_INDISCRIMINATELY} || $] < 5.010 ) ? 1 : 0
}
sub is_windows ()      { $^O eq 'MSWin32' ? 1 : 0 }
sub is_dev_release ()  { ($DBIO::VERSION || '') =~ /_/ ? 1 : 0 }
sub old_mro ()         { $] < 5.009_005 ? 1 : 0 }
sub has_ithreads ()    { $Config{useithreads} ? 1 : 0 }
sub unstable_dollar_at () { "$]" < 5.013002 ? 1 : 0 }
sub dbiotest ()        { $INC{"DBIO/Test.pm"} ? 1 : 0 }
sub peepeeness ()      { $INC{"DBIO/Test.pm"} && eval { DBIO::Test->is_smoker } && ($] >= 5.013005 and $] <= 5.013006) }
sub shuffle_unordered_resultsets () { $ENV{DBIO_SHUFFLE_UNORDERED_RESULTSETS} ? 1 : 0 }
sub assert_no_internal_indirect_calls () { $ENV{DBIO_ASSERT_NO_INTERNAL_INDIRECT_CALLS} ? 1 : 0 }
sub stresstest_utf8_upgrade_generated_collapser_source () { $ENV{DBIO_STRESSTEST_UTF8_UPGRADE_GENERATED_COLLAPSER_SOURCE} ? 1 : 0 }
sub iv_size ()         { $Config{ivsize} }
sub os_name ()         { $^O }
sub help_url ()        { 'https://codeberg.org/dbio/dbio/issues' }

BEGIN {
  if ($] < 5.009_005) {
    require MRO::Compat;
  }
  else {
    require mro;
  }
}

# FIXME - this is not supposed to be here
# Carp::Skip to the rescue soon
use DBIO::Carp '^DBIO';

use B ();
use overload ();
use re ();
use Carp 'croak';
use Storable 'nfreeze';
use Scalar::Util qw(blessed reftype refaddr);
use Sub::Quote qw(qsub quote_sub);

use base 'Exporter';
our @EXPORT_OK = qw(
  sigwarn_silencer modver_gt_or_eq modver_gt_or_eq_and_lt
  fail_on_internal_call assert_no_list_context assert_function_name
  refdesc refcount hrefaddr
  scope_guard is_exception emit_loud_diag
  quote_sub qsub perlstring serialize dump_value deep_copy canonical_text
  UNRESOLVABLE_CONDITION
  dir_path file_path parent_dir slurp_file slurp_file_utf8 write_file mkpath rmtree
  dumper_squashed eval_package_without_redefine_warnings class_path
  assert_class_name assert_class_isa assert_identifier_text
  firstidx uniq apply array_eq
  foreignbuildargs is_access_broker mask_connect_secrets mask_statement_secrets
  mask_statement_fingerprint mask_bound_values password_from_source
  masked_longmess masked_confess masked_cluck
  is_windows is_dev_release old_mro help_url unstable_dollar_at
  has_ithreads dbiotest peepeeness shuffle_unordered_resultsets
  iv_size os_name spurious_version_check_warnings
  is_plain_value is_literal_value bare_binds assert_column_value
  assert_no_internal_indirect_calls
  stresstest_utf8_upgrade_generated_collapser_source
);

use constant UNRESOLVABLE_CONDITION => \ '1 = 0';

sub sigwarn_silencer ($) {
  my $pattern = shift;

  croak "Expecting a regexp" if ref $pattern ne 'Regexp';

  my $orig_sig_warn = $SIG{__WARN__} || sub { CORE::warn(@_) };

  return sub { &$orig_sig_warn unless $_[0] =~ $pattern };
}

sub perlstring ($) { q{"}. quotemeta( shift ). q{"} };

sub hrefaddr ($) { sprintf '0x%x', &refaddr||0 }

sub refdesc ($) {
  croak "Expecting a reference" if ! length ref $_[0];

  # be careful not to trigger stringification,
  # reuse @_ as a scratch-pad
  sprintf '%s%s(0x%x)',
    ( defined( $_[1] = blessed $_[0]) ? "$_[1]=" : '' ),
    reftype $_[0],
    refaddr($_[0]),
  ;
}

sub refcount ($) {
  croak "Expecting a reference" if ! length ref $_[0];

  # No tempvars - must operate on $_[0], otherwise the pad
  # will count as an extra ref
  B::svref_2object($_[0])->REFCNT;
}

sub serialize ($) {
  local $Storable::canonical = 1;
  nfreeze($_[0]);
}


sub deep_copy {
  my ($x, $seen) = @_;
  return $x unless ref $x;
  $seen ||= {};
  return $seen->{ refaddr $x } if exists $seen->{ refaddr $x };

  my $type  = reftype $x;
  my $class = blessed $x;
  my $copy;
  if ($type eq 'HASH') {
    $copy = {};
    $seen->{ refaddr $x } = $copy;
    $copy->{$_} = deep_copy($x->{$_}, $seen) for keys %$x;
  }
  elsif ($type eq 'ARRAY') {
    $copy = [];
    $seen->{ refaddr $x } = $copy;
    @$copy = map { deep_copy($_, $seen) } @$x;
  }
  elsif ($type eq 'SCALAR' or $type eq 'REF') {
    my $inner;
    $copy = \$inner;
    $seen->{ refaddr $x } = $copy;
    $inner = deep_copy($$x, $seen);
  }
  else {
    return $x;
  }
  bless $copy, $class if defined $class;
  return $copy;
}


sub canonical_text { _canonical_text($_[0]) }

sub _canonical_text {
  my ($x, $seen) = @_;
  return 'undef' unless defined $x;
  unless (ref $x) {
    (my $s = "$x") =~ s{(["\\])}{\\$1}g;
    return qq{"$s"};
  }

  $seen ||= {};
  my $addr = refaddr $x;
  return '*' . $seen->{$addr} if exists $seen->{$addr};
  $seen->{$addr} = scalar keys %$seen;

  my $class = blessed $x;
  my $type  = reftype $x;
  my $text;
  if    ($type eq 'HASH')  { $text = '{' . join(',', map { _canonical_text($_) . '=>' . _canonical_text($x->{$_}, $seen) } sort keys %$x) . '}' }
  elsif ($type eq 'ARRAY') { $text = '[' . join(',', map { _canonical_text($_, $seen) } @$x) . ']' }
  elsif ($type eq 'SCALAR' or $type eq 'REF') { $text = '\\' . _canonical_text($$x, $seen) }
  elsif ($type eq 'REGEXP') { my ($pattern, $mods) = re::regexp_pattern($x); $text = 'qr' . _canonical_text("$pattern/$mods") }
  else { $text = lc($type) . sprintf('(0x%x)', $addr) }
  return defined $class ? "$class=$text" : $text;
}

sub dump_value ($) {
  require Data::Dumper;
  local $Data::Dumper::Indent = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Useqq = 1;
  local $Data::Dumper::Quotekeys = 0;
  Data::Dumper::Dumper($_[0]);
}

my $seen_loud_screams;
sub emit_loud_diag {
  my $args = { ref $_[0] eq 'HASH' ? %{$_[0]} : @_ };

  unless ( defined $args->{msg} and length $args->{msg} ) {
    emit_loud_diag(
      msg => "No 'msg' value supplied to emit_loud_diag()"
    );
    exit 70;
  }

  my $msg = "\n" . join( ': ',
    ( $0 eq '-e' ? () : $0 ),
    $args->{msg}
  );

  # when we die - we usually want to keep doing it
  $args->{emit_dups} = !!$args->{confess}
    unless exists $args->{emit_dups};

  local $Carp::CarpLevel =
    ( $args->{skip_frames} || 0 )
      +
    $Carp::CarpLevel
      +
    # hide our own frame
    1
  ;

  # no password among the arguments, here and in the confess below
  my $longmess = masked_longmess();

  # different object references will thwart deduplication without this
  ( my $key = "${msg}\n${longmess}" ) =~ s/\b0x[0-9a-f]+\b/0x.../gi;

  return $seen_loud_screams->{$key} if
    $seen_loud_screams->{$key}++
      and
    ! $args->{emit_dups}
  ;

  $msg .= $longmess
    unless $msg =~ /\n\z/;

  print STDERR "$msg\n"
    or
  print STDOUT "\n!!!STDERR ISN'T WRITABLE!!!:$msg\n";

  return $seen_loud_screams->{$key}
    unless $args->{confess};

  # increment *again*, because... Carp.
  $Carp::CarpLevel++;
  # not $msg - Carp will reapply the longmess on its own
  masked_confess($args->{msg});
}


sub scope_guard (&) {
  croak 'Calling scope_guard() in void context makes no sense'
    if ! defined wantarray;

  # no direct blessing of coderefs - DESTROY is buggy on those
  bless [ $_[0] ], 'DBIO::Util::ScopeGuard';
}
{
  package #
    DBIO::Util::ScopeGuard;

  sub DESTROY {
    local $@ if DBIO::Util::unstable_dollar_at();

    eval {
      $_[0]->[0]->();
      1;
    } or do {
      DBIO::Util::masked_cluck("Execution of scope guard $_[0] resulted in the non-trappable exception:\n\n$@");
    };
  }
}

sub is_exception ($) {
  my $e = $_[0];

  # this is not strictly correct - an eval setting $@ to undef
  # is *not* the same as an eval setting $@ to ''
  # but for the sake of simplicity assume the following for
  # the time being
  return 0 unless defined $e;

  my ($not_blank, $suberror);
  {
    local $@;
    eval {
      $not_blank = ($e ne '') ? 1 : 0;
      1;
    } or $suberror = $@;
  }

  if (defined $suberror) {
    if (length (my $class = blessed($e) )) {
      carp_unique( sprintf(
        'External exception class %s implements partial (broken) overloading '
      . 'preventing its instances from being used in simple ($x eq $y) '
      . 'comparisons. Given Perl\'s "globally cooperative" exception '
      . 'handling this type of brokenness is extremely dangerous on '
      . 'exception objects, as it may (and often does) result in silent '
      . '"exception substitution". DBIO tries to work around this '
      . 'as much as possible, but other parts of your software stack may '
      . 'not be even aware of this. Please submit a bugreport against the '
      . 'distribution containing %s and in the meantime apply a fix similar '
      . 'to the one shown at %s, in order to ensure your exception handling '
      . 'is saner application-wide. What follows is the actual error text '
      . "as generated by Perl itself:\n\n%s\n ",
        $class,
        $class,
        'https://codeberg.org/dbio/dbio/src/branch/main/lib/DBIO/Util.pm',
        $suberror,
      ));

      # workaround, keeps spice flowing
      $not_blank = ("$e" ne '') ? 1 : 0;
    }
    else {
      # not blessed yet failed the 'ne'... this makes 0 sense...
      # just throw further
      die $suberror
    }
  }

  return $not_blank;
}


sub modver_gt_or_eq ($$) {
  my ($mod, $ver) = @_;

  croak "Nonsensical module name supplied"
    if ! defined $mod or ! length $mod;

  croak "Nonsensical minimum version supplied"
    if ! defined $ver or $ver =~ /[^0-9\.\_]/;

  local $SIG{__WARN__} = sigwarn_silencer( qr/\Qisn't numeric in subroutine entry/ )
    if spurious_version_check_warnings;

  croak "$mod does not seem to provide a version (perhaps it never loaded)"
    unless $mod->VERSION;

  local $@;
  eval { $mod->VERSION($ver) } ? 1 : 0;
}

sub modver_gt_or_eq_and_lt ($$$) {
  my ($mod, $v_ge, $v_lt) = @_;

  croak "Nonsensical maximum version supplied"
    if ! defined $v_lt or $v_lt =~ /[^0-9\.\_]/;

  return (
    modver_gt_or_eq($mod, $v_ge)
      and
    ! modver_gt_or_eq($mod, $v_lt)
  ) ? 1 : 0;
}

# DBIO has no wantarray-dependent return types (ADR 0042): a public method
# that returns a ResultSet returns it in every context. Entry points that
# used to be context-sensitive guard with "assert_no_list_context($what) if
# wantarray;". The call-site wantarray is the check: this sub is always
# invoked in void context (as a bare statement), so it cannot re-check
# wantarray itself -- it exists solely to throw the ADR 0042 exception once
# the caller has established list context. It replaces the
# fail_on_internal_wantarray stack-walker, which existed only to catch the
# same mistake when it originated inside DBIO itself.
sub assert_no_list_context {
  my $what = shift || 'this method';

  DBIO::Exception->throw( sprintf (
    "%s was called in list context, but DBIO methods do not change their "
    . "return type based on wantarray (ADR 0042). A method that returns a "
    . "ResultSet returns it in every context - fetch rows explicitly, e.g. "
    . "->all on the ResultSet.",
    $what
  ), 'with_stacktrace');
}

# A SQL function name in a select is an identifier, optionally schema-qualified;
# anything else is written as a literal (\'...' or \[ ... ]).
sub assert_function_name {
  my ($name, $what) = @_;

  return if defined $name and !ref $name
    and $name =~ /\A[A-Za-z_][A-Za-z0-9_]*(?:\.[A-Za-z_][A-Za-z0-9_]*)*\z/;

  DBIO::Exception->throw( sprintf (
    "%s: function name '%s' is not a plain identifier -- use a literal "
    . "(\\'...' or \\[ ... ]) for anything else",
    $what,
    defined $name ? (ref $name ? refdesc($name) : $name) : "undef",
  ));
}

# --- Path helpers (replace Path::Class with core modules) ---

require File::Spec;
require File::Basename;

sub dir_path  { File::Spec->catdir(@_) }
sub file_path { File::Spec->catfile(@_) }
sub parent_dir { File::Basename::dirname($_[0]) }

sub slurp_file {
  open my $fh, '<', $_[0] or croak "Cannot read $_[0]: $!";
  local $/;
  <$fh>;
}

sub mkpath {
  require File::Path;
  File::Path::mkpath([@_]);
}

sub rmtree {
  require File::Path;
  File::Path::rmtree([@_]);
}

# --- End path helpers ---

sub dumper_squashed {
  require Data::Dumper;
  my $dd = Data::Dumper->new([]);
  $dd->Terse(1)->Indent(0)->Useqq(1)->Deparse(1)->Quotekeys(0)->Sortkeys(1);
  return $dd->Values([ $_[0] ])->Dump;
}

sub eval_package_without_redefine_warnings {
  my ($pkg, $code) = @_;
  local $SIG{__WARN__} = sigwarn_silencer(qr/^Subroutine \S+ redefined/);
  my @delete_syms;
  my $try_again = 1;
  while ($try_again) {
    eval $code;
    if (my ($sym) = $@ =~ /^Subroutine (\S+) redefined/) {
      delete $INC{ +class_path($pkg) };
      push @delete_syms, $sym;
      foreach my $sym (@delete_syms) {
        no strict 'refs';
        undef *{"${pkg}::${sym}"};
      }
    }
    elsif ($@) {
      die $@ if $@;
    }
    else {
      $try_again = 0;
    }
  }
}

sub class_path {
  my $class = shift;
  my $class_path = $class;
  $class_path =~ s{::}{/}g;
  $class_path .= '.pm';
  return $class_path;
}


sub assert_class_name {
  my ($name) = @_;
  DBIO::Exception->throw(
    sprintf "'%s' is not a class name", defined $name ? $name : 'undef'
  ) unless defined $name and !ref $name
    and $name =~ /\A[A-Za-z_][A-Za-z0-9_]*(?:::[A-Za-z0-9_]+)*\z/;
  return $name;
}


sub assert_identifier_text {
  my ($what, $name) = @_;
  DBIO::Exception->throw(
    "$what must not contain ';', a line break or NUL: it is an identifier, "
  . 'and no driver takes those in one'
  ) if defined $name and !ref $name and $name =~ /[;\n\r\0]/;
  return $name;
}


sub assert_class_isa {
  my ($what, $class, $base) = @_;
  DBIO::Exception->throw("$what '$class' is not a $base")
    unless $class->isa($base);
  return $class;
}

sub slurp_file_utf8 {
  open my $fh, '<:encoding(UTF-8)', $_[0]
    or croak "Can't open '$_[0]' for reading: $!";
  my $data = do { local $/; <$fh> };
  close $fh;
  $data =~ s/\x0d\x0a|\x0a/\n/g;
  return $data;
}

sub write_file {
  open my $fh, '>:encoding(UTF-8)', $_[0]
    or croak "Can't open '$_[0]' for writing: $!";
  print $fh $_[1];
  close $fh;
}

sub firstidx (&@) {
  my $f = shift;
  foreach my $i (0..$#_) {
    local *_ = \$_[$i];
    return $i if $f->();
  }
  return -1;
}

sub uniq (@) {
  my %seen;
  grep { not $seen{$_}++ } @_;
}

sub apply (&@) {
  my $action = shift;
  $action->() foreach my @values = @_;
  wantarray ? @values : $values[-1];
}

sub array_eq {
  require List::Util;
  no warnings 'uninitialized';
  my ($l, $r) = @_;
  return @$l == @$r && List::Util::all { $l->[$_] eq $r->[$_] } 0..$#$l;
}

# --- End loader utilities ---

# --- From SQL::Abstract::Util (moved here to remove dependency) ---

sub is_literal_value ($) {
    ref $_[0] eq 'SCALAR'                                     ? [ ${$_[0]} ]
  : ( ref $_[0] eq 'REF' and ref ${$_[0]} eq 'ARRAY' )        ? [ @${ $_[0] } ]
  : undef;
}

# A column value is a value: a scalar, undef, an object, an arrayref (an array
# data type, always bound) or an explicit literal (\'...' / \[ $sql, @bind ]).
# Any other reference -- HASH, CODE, GLOB, a reference to a reference -- throws,
# naming the column and the type and never the value.
sub assert_column_value {
  my ($column, $value) = @_;
  my $ref = ref $value;
  return $value if ! $ref
    or blessed($value)
    or $ref eq 'ARRAY'
    or is_literal_value($value);

  DBIO::Exception->throw(
    "column '$column' got a $ref reference -- a column value is a value; "
    . 'use \\[ ... ] for literal SQL or an inflated column type'
  );
}

# The sync convention hands a bind over as a pair [ \%attrs => $value ]
# (DBIO::Storage::DBI::_resolve_bindattrs). An async runner's contract is bare
# values, and the async maker runs with bindtype normal, so a column bind is
# already bare -- only a literal bind (a subquery from as_query, \[ $sql, @bind ])
# arrives as a pair. The rule is the sync path's own: a two-element arrayref
# with a HASH or undef in front is a pair, and its value is the second element.
# That makes a plain value of exactly that form read as a pair; it is the
# convention's cost, named in the runner contract (Storage::Async::_query_async).
# The bindtype-columns forms the sync rule also takes (a column name or a
# SCALAR ref in front) are not produced by the async maker and not handled.
sub bare_binds {
  return map {
    ( ref $_ eq 'ARRAY' and @$_ == 2 and ( ! defined $_->[0] or ref $_->[0] eq 'HASH' ) )
      ? $_->[1]
      : $_
  } @_;
}

# FIXME XSify - this can be done so much more efficiently
sub is_plain_value ($) {
  my $val = shift;

  return \($val) unless length ref $val;

  # HASH with -value key
  if (ref $val eq 'HASH' and keys %$val == 1 and exists $val->{-value}) {
    return \($val->{-value});
  }

  # Check for blessed object
  my $blessed = Scalar::Util::blessed($val) or return undef;

  my $isa = mro::get_linear_isa($blessed);

  {
    no strict 'refs';

    # Check for stringification
    for my $pkg (@$isa) {
      my $glob = \*{ "${pkg}::(\"\"" };
      return \($val) if defined *$glob{CODE};
    }

    # Check for nummification/boolification with fallback
    my $has_numeric_overload = grep {
      defined *{ "${_}::(0+" }{CODE}
    } @$isa;

    my $has_bool_overload = grep {
      defined *{ "${_}::(bool" }{CODE}
    } @$isa;

    if ($has_numeric_overload or $has_bool_overload) {
      # Check fallback
      my $has_fallback = grep {
        defined *{ "${_}::()" }{CODE}
      } @$isa;

      my $fallback_val = ${ "${blessed}::()" };

      # If no fallback or fallback is true, it's a plain value
      if (!$has_fallback or !defined $fallback_val or $fallback_val) {
        return \($val);
      }
    }
  }

  return undef;
}

# Constructor bridge shared by DBIO::Moo and DBIO::Moose: filters the
# constructor arguments down to the keys DBIO::Row::new understands
# (declared columns, relationships, and -prefixed internals), leaving
# pure Moo/Moose attributes for the OO framework to handle itself.
# Installed as FOREIGNBUILDARGS, so it is called as a class method.
sub foreignbuildargs {
  my ( $class, @args ) = @_;

  # Normalize the constructor arguments to a single hashref
  my $attrs =
      ref $args[0] eq 'HASH' ? $args[0]
    : @args                   ? { @args }
    :                           {};

  # No result source yet (class under construction) — pass everything through
  my $rsrc = do { local $@; eval { $class->result_source_instance } };
  return ($attrs) unless $rsrc;

  # Keep only keys that DBIO::Row::new knows how to handle
  my %dbio_args;
  for my $key ( keys %$attrs ) {
    if (   $key =~ /^-/
        || $rsrc->has_column($key)
        || $rsrc->has_relationship($key) )
    {
      $dbio_args{$key} = $attrs->{$key};
    }
  }
  return ( \%dbio_args );
}

# Predicate for the CredentialSource contract: true when $x is a blessed
# DBIO::AccessBroker instance. Storage layers use this to tell a broker
# apart from a plain DSN/options hashref in connect_info, so a broker is
# never mistaken for an options hash and shredded into key/value pairs.
sub is_access_broker ($) {
  my $x = $_[0];
  return ( blessed($x) && $x->isa('DBIO::AccessBroker') ) ? 1 : 0;
}

# Masks the passwords in a text that is about to become a message -- an
# exception, a warning, a trace line, a diagnostic structure -- and returns
# the text (karr k297): a message never quotes credentials. This is the one
# place that knows how; every site that writes connect info into a message
# asks it. The value is replaced by '***'; the key, the user name and
# everything else stay, so the message remains usable.
#
#   mask_connect_secrets($text)
#   mask_connect_secrets($text, [ $dsn, $user, $password, \%dbi_attrs ])
#
# In any text it masks, whatever the case of the key:
#   - the value of a key ending in password, passwd, pwd, pass, passphrase,
#     key (sslkey, apikey, PRAGMA key / rekey), token (motherduck_token) or
#     secret (client_secret): libpq
#     keyword/value (password=x, password='a b'), a DSN part (;password=x),
#     ODBC (PWD=x, PWD={a;b}), the query of a URI (&password=x), a dumped
#     hash (password => 'x' -- shown as password =***, the '>' going with the
#     value, so that a value starting with one keeps nothing of itself); the
#     statement forms PRAGMA key = 'x' and PRAGMA key('x') as well;
#   - the password of a URI, scheme://user:SECRET@host.
#
# With the connect info of the connection the text is about (the DBI form, as
# DBIO::Storage::DBI gives it in _dbi_connect_info) it also masks:
#   - its password, and a Password among its DBI attributes, wherever the text
#     repeats them -- when defined and not empty. Each place as a whole,
#     whatever stands around it and whatever else finds a part of it: a value
#     found by its key does not end at the whitespace or the ';' inside one
#     but goes on through it, and two that overlap are one mask;
#   - its DSN, wherever the text quotes it whole or as DBI->connect quotes it,
#     without dbi:Driver: -- masked on its own, by the borders of the DSN,
#     unless a password of the connect info goes across one of them there.
#
# Both also where the text has them the way Carp writes an argument of a frame
# (karr k314): a trace Carp writes of its own accord -- under $Carp::Verbose,
# or a confess in a DBD -- shows what DBI->connect was called with, and the
# error DBI dies with brings it into the message. Carp puts a backslash before
# " \ $ and @, writes \x{..} for whatever is not printable ASCII, and shows
# of an argument longer than $Carp::MaxArgLen only the start, closed by "...
# So it masks as well:
#   - the password and the DSN with these backslashes and \x{..} in them;
#   - the start of a password that stands before the "... of an argument Carp
#     shortened -- however little of it, and wherever in the argument it
#     begins: the trace does not say what $Carp::MaxArgLen it was written with;
#   - the DSN where Carp shortened it inside its first masked value or behind
#     it. What says where a value ends may be what was cut off, so from that
#     value on nothing of the DSN is shown.
#
# A value without quotes ends where its syntax says: in a DSN known to start
# with dbi:, at the next ';'; in any other known DSN at the next whitespace.
# In a text around it nothing says what closes a value, so there it runs to
# the next whitespace or ';' -- a quote the text closes it with goes with it,
# rather than the rest of a password with a quote in it staying.
#
# Masking is idempotent: a value that already is the mask '***' -- followed by
# the end, whitespace, ';' or a closing quote or bracket -- is left standing
# with everything behind it, a quote that closes it included, so a text masked
# at its source loses nothing when it is masked again.
#
# What it masks too much, rather than leak: an argument Carp shortened that
# happens to end the way a password of the connect info starts loses that end,
# be it one character.
#
# What it cannot see: a secret under a key whose name does not end in one of
# those words; a password that is neither named by such a key nor given in
# the connect info; and of a password it was not given, in a text quoting a
# DSN it was not given either, the rest of a bare one that has whitespace or
# ';' in it. In a trace of Carp that is more than it sounds: a value in
# double quotes is a bare one there, Carp having put backslashes before them;
# a value Carp cut is one without its closing quote; and of the password of a
# URI Carp cut before the @ behind it nothing is masked. All of that is about
# a password the connect info does not name -- one it names is masked
# wherever it stands. Nor can it see a password Carp wrote from another scalar
# than the one in the connect info -- the characters there, their encoded
# bytes in the trace, or the other way round --, or one in a text that was
# escaped a second time, a trace having become an argument in another trace,
# or by something other than Carp. $text that is undef or a reference is
# returned as it came.
# (the whitespace around '=' and '(' is possessive: backtracking out of it would
# let a mask that already stands be found again as a value)
my $CONNECT_SECRET_MASK   = '***';
my $CONNECT_SECRET_KEY    = qr/(?<![A-Za-z0-9]) \w*? (?: password | passwd | pwd | pass | passphrase | key | token | secret ) ['"]? \s*+ = \s*+/xi;
my $CONNECT_SECRET_CALL   = qr/(?<![A-Za-z0-9]) \w*? (?: key | token | secret | password | passphrase ) \s*+ \( \s*+/xi;
my $CONNECT_SECRET_QUOTED = qr/ ' (?: [^'\\] | \\. )* ' | " (?: [^"\\] | \\. )* " | \{ (?: [^}] | \}\} )* \} /xs;
my $CONNECT_SECRET_URI    = qr/(?<![A-Za-z0-9+.\-]) [A-Za-z][A-Za-z0-9+.\-]* :\/\/ [^\s:\/\@'"]*/x;

# A string as Carp writes it where it is an argument of a frame, one element
# for each character and without the quotes around it. It has to equal what
# masked_longmess and its siblings write: mask_connect_secrets masks the traces
# Carp writes of its own accord as well. Should a Carp do otherwise,
# t/storage/connect_error_carp_trace_no_password.t fails -- it reads real
# traces.
my $CONNECT_SECRET_IN_TRACE = sub {
  map { /["\\\$\@]/ ? "\\$_" : /[ -~]/ ? $_ : sprintf '\\x{%x}', ord } split //, $_[0];
};

# Where $string has the start of a secret right before the "... of an argument
# Carp shortened, the longest start each time, as [ from, to ]. Carp cuts an
# argument by characters, before it escapes them: @in_trace is the secret as
# Carp writes it, by characters, and a start counts from $least of them on.
my $CONNECT_SECRET_CUT = sub {
  my ($string, $least, @in_trace) = @_;
  return if index($string, '"...') < 0;

  my $whole = join '', @in_trace;
  my @end   = (0);
  push @end, $end[-1] + length $_ for @in_trace;

  my (@cut, $from);
  while (( my $at = index $string, '"...', $from // 0 ) >= 0) {
    $from = $at + 1;
    for my $length (reverse @end[$least .. $#end]) {
      next if $length > $at or substr($string, $at - $length, $length) ne substr($whole, 0, $length);
      push @cut, [ $at - $length, $at ];
      last;
    }
  }

  return @cut;
};

sub mask_connect_secrets {
  my ($text, $connect_info) = @_;
  return $text if !defined $text or ref $text;

  my ($dsn, undef, $password, $attrs) = ref $connect_info eq 'ARRAY' ? @$connect_info : ();

  my @given = grep { defined $_ && !ref $_ && length $_ }
    $password, ( ref $attrs eq 'HASH' ? $attrs->{Password} : () );

  # ... and each as Carp writes it, by characters
  my @in_trace  = map { [ $CONNECT_SECRET_IN_TRACE->($_) ] } @given;
  my @passwords = ( @given, map { join '', @$_ } @in_trace );

  # Where a string has what the connect info names, as [ from, to ]: every
  # place a password is repeated at, and what an argument Carp shortened has
  # of one.
  my $known = sub {
    my ($string) = @_;
    my @known = map { $CONNECT_SECRET_CUT->($string, 1, @$_) } @in_trace;
    for my $password (@passwords) {
      my $at = -1;
      push @known, [ $at, $at + length $password ]
        while ( $at = index $string, $password, $at + 1 ) >= 0;
    }
    return @known;
  };

  # $bare is what a value without quotes consists of
  my $mask = sub {
    my ($string, $bare) = @_;

    # Everything is looked for in the string as it came and noted as
    # [ from, to ]: nothing found takes away what something else is found by.

    # What the connect info names is masked wherever it stands
    my @known = $known->($string);

    # What a key or the form of a URI names ends where it is guessed to end
    # (a URI's password is out of the way before the keys are looked for, as
    # a key in it is no key)
    my $guessed = sub {
      my ($in) = @_;
      my @found;
      push @found, [ $-[2], $+[2] ] while $in =~ /($CONNECT_SECRET_URI):([^\s'"]*)\@/g;
      substr($in, $_->[0], $_->[1] - $_->[0]) = '*' x ( $_->[1] - $_->[0] ) for @found;
      push @found, [ $-[2], $+[2] ]
        while $in =~ /($CONNECT_SECRET_KEY)(?!(?:>\s*)?\Q$CONNECT_SECRET_MASK\E(?:\z|[\s;'",)\]&}]))((?:>\s*)?(?:$CONNECT_SECRET_QUOTED|$bare))/g;
      push @found, [ $-[2], $+[2] ]
        while $in =~ /($CONNECT_SECRET_CALL)(?!\Q$CONNECT_SECRET_MASK\E['"]?\s*\))($CONNECT_SECRET_QUOTED)/g;
      return @found;
    };

    # ... and is guessed twice. In the string as it is: a known password in it
    # does not change what is found without knowing one. And in the string
    # with every known password made a word of its length: a value does not
    # end at the whitespace or the ';' inside one, the rest of it standing.
    my @found = ( @known, $guessed->($string) );
    if (@known) {
      my $worded = $string;
      substr($worded, $_->[0], $_->[1] - $_->[0]) = '*' x ( $_->[1] - $_->[0] ) for @known;
      push @found, $guessed->($worded);
    }

    # One mask for what overlaps, and for an empty value at the border of
    # something masked; two passwords side by side are two.
    my @masks;
    for my $next (sort { $a->[0] <=> $b->[0] or $b->[1] <=> $a->[1] } @found) {
      my $last = $masks[-1];
      if ($last and (
        $next->[0] < $last->[1]
          or
        $next->[0] == $last->[1] and ( $next->[0] == $next->[1] or $last->[0] == $last->[1] )
      )) {
        $last->[1] = $next->[1] if $next->[1] > $last->[1];
      }
      else {
        push @masks, [ @$next ];
      }
    }

    substr($string, $_->[0], $_->[1] - $_->[0]) = $CONNECT_SECRET_MASK for reverse @masks;
    return $string;
  };

  # the DSN of the connect info, as the text may quote it => as it is shown
  my %shown;
  if (defined $dsn && !ref $dsn && length $dsn) {
    my $bare = $dsn =~ /^dbi:/i ? qr/[^;]*/ : qr/\S*/;
    for my $quoted ($dsn, $dsn =~ /^dbi:[^:]*:(.+)\z/is) {
      my $masked = $mask->($quoted, $bare);
      next if $masked eq $quoted;
      $shown{$quoted} = $masked;

      # ... as Carp writes it,
      my @quoted = $CONNECT_SECRET_IN_TRACE->($quoted);
      $shown{ join '', @quoted } = join '', $CONNECT_SECRET_IN_TRACE->($masked);

      # ... and as Carp shortened it, inside its first masked value or behind
      # it. What says where a value ends may be what was cut off: from that
      # value on nothing of the DSN is shown.
      my $first = index $masked, $CONNECT_SECRET_MASK;
      my $head  = join '', @quoted[0 .. $first - 1], $CONNECT_SECRET_MASK;
      $shown{ substr $text, $_->[0], $_->[1] - $_->[0] } //= $head
        for $CONNECT_SECRET_CUT->($text, $first + 1, @quoted);
    }
  }

  my $in_text = qr/[^\s;]*/;
  return $mask->($text, $in_text) unless %shown;

  # A DSN is taken for quoted only where it ends: one going on in the text is
  # another, longer one, and what follows would be the rest of its value.
  my $quoted = join '|', map { quotemeta } sort { length $b <=> length $a } keys %shown;
  my @parts  = split /($quoted)(?=[\s;'",)\]]|\z)/, $text, -1;

  # ... and not where a password of the connect info goes across its border:
  # shown as the DSN, it would keep the part of that password it ends or
  # starts with. There it is text like the text around it.
  my @known = $known->($text);
  my ($to, @pieces) = (0);
  for my $part (0 .. $#parts) {
    my $from = $to;
    $to += length $parts[$part];
    if ($part % 2 and !grep { $_->[0] < $from && $from < $_->[1] or $_->[0] < $to && $to < $_->[1] } @known) {
      push @pieces, \$parts[$part];
    }
    elsif (@pieces and !ref $pieces[-1]) {
      $pieces[-1] .= $parts[$part];
    }
    else {
      push @pieces, $parts[$part];
    }
  }

  return join '', map { ref $_ ? $shown{$$_} : $mask->($_, $in_text) } @pieces;
}

# Masks what the statements in @statements carry as secrets, in a $text that
# quotes them or part of them -- the error of a refused statement (karr k343).
# A statement of a connect action (on_connect_do, on_connect_call, ATTACH,
# PRAGMA key) is quoted by the error of the database as a whole or as the
# token it choked on (SQLite: unrecognized token: "'SEKRET"). So:
#   - the text is masked by mask_connect_secrets, which finds the value of a
#     key (key, token, secret, password, ...) wherever the text writes it;
#   - every value a statement gives under such a key is taken out of the
#     statement and masked wherever the text repeats it, the quote that
#     opens it and the SQL escape of its own quotes included.
# Idempotent, like mask_connect_secrets. A placeholder or the mask itself is
# no value and is not taken.
sub _statement_secret_values {
  my (@statements) = @_;

  my %secret;
  for my $sql (grep { defined $_ && !ref $_ } @statements) {
    my @taken;
    push @taken, [ $-[1], $+[1] ]
      while $sql =~ /$CONNECT_SECRET_KEY((?:$CONNECT_SECRET_QUOTED|'.*\z|".*\z|[^\s;'"&,)]+))/g;
    push @taken, [ $-[1], $+[1] ]
      while $sql =~ /$CONNECT_SECRET_CALL($CONNECT_SECRET_QUOTED)/g;

    for my $at (@taken) {
      my $value = substr $sql, $at->[0], $at->[1] - $at->[0];
      if ($value =~ /\A(['"])(.*)\1\z/s) {
        my $quote = $1;
        $value = $2;
        $value =~ s/\Q$quote$quote\E/$quote/g;
        $value =~ s/\\(.)/$1/gs;
      }
      elsif ($value =~ /\A\{(.*)\}\z/s) {
        $value = $1;
      }
      else {
        # an unterminated quote: the rest of the statement is the value
        $value =~ s/\A['"]//;
      }
      # a placeholder is not a value the statement carries
      next if $value =~ /\A(?:\?|:[A-Za-z_]\w*|\$\d+)\z/;
      next unless length $value and $value ne $CONNECT_SECRET_MASK;
      $secret{$value} = 1;
    }
  }

  return keys %secret;
}

sub mask_statement_secrets {
  my ($text, @statements) = @_;
  return $text if !defined $text or ref $text;

  my @secret = _statement_secret_values(@statements);

  $text = mask_connect_secrets($text);
  # the longest first: a value that holds another is masked as a whole
  $text = mask_connect_secrets($text, [ undef, undef, $_ ])
    for sort { length $b <=> length $a or $a cmp $b } @secret;

  return $text;
}

# The text of a statement for the query trace (karr k343 (3), k392): the
# secrets the statement carries are masked as mask_statement_secrets masks
# them, and each mask carries a fingerprint of those secret values,
# ***[sha256:<8 hex>], so two traces of one statement can be told equal
# without showing a value.
sub mask_statement_fingerprint {
  my ($statement) = @_;
  return $statement if !defined $statement or ref $statement;

  my @secret = _statement_secret_values($statement);
  my $masked = mask_statement_secrets($statement, $statement);
  return $masked unless @secret;

  my $print = substr Digest::SHA::sha256_hex(join "\0", sort @secret), 0, 8;
  $masked =~ s/\Q$CONNECT_SECRET_MASK\E/$CONNECT_SECRET_MASK\[sha256:$print\]/g;
  return $masked;
}


sub mask_bound_values {
  my ($text, $values, $quote) = @_;
  return $text if !defined $text or ref $text;

  my %form;
  for my $given (@{ $values || [] }) {
    my $value = $given;
    next unless defined $value;
    if (length ref $value) {
      my $plain = is_plain_value($value) or next;
      $value = defined $$plain ? "$$plain" : next;
    }
    next unless length($value) >= 4;

    $form{$value} = 1;

    next unless $quote;
    my $quoted = eval { $quote->($value) };
    next unless defined $quoted and !ref $quoted;
    $form{$quoted} = 1;
    $form{$2} = 1 if $quoted =~ /\A(['"`])(.*)\1\z/s;
  }

  for my $form (sort { length($b) <=> length($a) or $a cmp $b } keys %form) {
    next if $form eq $CONNECT_SECRET_MASK or !length $form;
    $text =~ s/\Q$form\E/$CONNECT_SECRET_MASK/g;
  }

  return $text;
}

# The password of a command line tool, from a place other than its arguments
# (which ps and the shell history show): the environment variable named by
# env => NAME, or one line of STDIN with stdin => 1 (echo off when STDIN is a
# terminal). Returns undef when neither is asked for, throws when both are, or
# when the variable is not set; the text never names a value.
sub password_from_source {
  my (%from) = @_;

  die "Give the password by --password-env or --password-stdin, not both\n"
    if defined $from{env} and $from{stdin};

  if (defined $from{env}) {
    die "Environment variable $from{env} (--password-env) is not set\n"
      unless defined $ENV{ $from{env} };
    return $ENV{ $from{env} };
  }

  return undef unless $from{stdin};

  my $tty = -t STDIN;
  my ($termios, $saved_lflag);
  if ($tty) {
    $termios = POSIX::Termios->new;
    if ($termios->getattr(0)) {
      $saved_lflag = $termios->getlflag;
      $termios->setlflag($saved_lflag & ~POSIX::ECHO());
      $termios->setattr(0, POSIX::TCSANOW());
    }
    else {
      undef $termios;
    }
    print STDERR 'Password: ';
  }

  my $line = <STDIN>;

  if ($termios) {
    $termios->setlflag($saved_lflag);
    $termios->setattr(0, POSIX::TCSANOW());
    print STDERR "\n";
  }

  die "No password on STDIN (--password-stdin)\n" unless defined $line;
  $line =~ s/\r?\n\z//;
  return $line;
}

# DBIO's own stack traces (karr k304, k311): a trace never quotes credentials
# either. A stack trace shows the arguments of every live frame, and a schema
# is connected by handing it the password as one. These three functions build
# the trace themselves, from caller(), and are the one place that keeps a
# password out of it; every site in DBIO that writes a trace with arguments
# goes through them:
#
#   masked_longmess(@msg)     the text Carp::longmess(@msg) returns
#   masked_confess(@msg)      dies with it, as Carp::confess does
#   masked_cluck(@msg)        warns with it, as Carp::cluck does
#
# They write what Carp writes -- "MSG at FILE line N.\n" and a line
# "\tSUB(ARGS) called at FILE line N\n" for each frame, an argument shown as
# Carp shows it: numbers bare, strings in double quotes with \ before " \ $ @
# and \x{..} for what is not printable ASCII, cut at $Carp::MaxArgLen, no more
# than $Carp::MaxArgNums of them, "undef", "eval {...}", "require X" -- and
# read the variables Carp documents for it ($Carp::CarpLevel, %Carp::Internal,
# %Carp::CarpInternal, $Carp::MaxArgLen, $Carp::MaxArgNums, $Carp::MaxEvalLen,
# $Carp::RefArgFormatter, a CARP_TRACE method). That the form is Carp's is
# what lets mask_connect_secrets read a trace Carp wrote of its own accord
# as well; t/storage/connect_error_carp_trace_no_password.t reads real ones.
# Nothing of Carp is called that Carp does not document, and no symbol of Carp
# is replaced. $Carp::Verbose is not looked at: a longmess is always long.
#
# The connect info is taken from the arguments of the frames that are live when
# a trace is built -- all of them, not only those shown. No storage is needed,
# there may be none yet. It is found as:
#   - what connect() and connection() were called with on a DBIO::Schema, in
#     whichever class the sub is (a driver component overrides connection()):
#     the DBI form ( $dsn, $user, $password, \%attrs ), whatever the DSN looks
#     like, or the hash form;
#   - ( 'dbi:...', $user, $password, \%attrs ) in the arguments of any frame.
#
# Every argument that is no reference then goes through mask_connect_secrets,
# with each connect info found, before it is escaped and cut: the password and
# a Password attribute are masked wherever an argument repeats them -- in the
# frames of the caller too, alone or inside a longer argument -- and a password
# inside a DSN, under a password key or in a URI, in any argument at all. A
# reference is shown by its address; one the caller has spelled out
# (CARP_TRACE, $Carp::RefArgFormatter) is masked in the text that came of it.
#
# A caller that holds a connect info already -- DBIO::Exception->throw, with
# the one a schema's storage holds -- hands it over in $TRACE_CONNECT_INFO; it
# is masked like the ones found in the frames, and nothing is asked for it.
#
# What it cannot see: a password that reaches DBIO in no argument -- from an
# AccessBroker, a connection coderef, the environment -- and is an argument of
# its own in a frame of the caller; one the caller holds in another shape than
# the one it connects with; and one whose frames have all returned and that no
# connect info handed over names. As in a message, a password is masked wherever it is
# repeated, however short it is: rather too much than a leak. And what comes
# after a dbi: DSN and a user name in the arguments of a frame is taken for a
# password whatever it is.
#
# What it masks too much (karr k311): every argument that is no reference goes
# through mask_connect_secrets, whatever it holds. An SQL statement among the
# arguments reads "WHERE password = ***" where it said "WHERE password = ?".
#
# And it reaches the traces DBIO writes, no others. A trace Carp writes of its
# own accord -- every croak under $Carp::Verbose, a confess in code that is not
# DBIO's -- is not built here: its arguments are as Carp shows them, a password
# among them. Where DBIO hands such a text on with the connect info at hand --
# the error DBI->connect died with, as "DBI Connection failed" --
# mask_connect_secrets finds the password in it the way Carp wrote it (karr
# k314). Anywhere else that trace is Carp's own.
our $TRACE_REF_DEPTH = 0;

# A connect info the caller of the trace holds already (DBIO::Exception->throw
# passes the one a storage holds); masked like the ones found in the frames.
our $TRACE_CONNECT_INFO;

sub _trace_text {
  my ($kind, @msg) = @_;

  # a reference is no message: handed back as it came
  return wantarray ? @msg : $msg[0] if ref $msg[0];

  local ($!, $^E);

  # Every live frame, with the arguments it was called with. An argument may be
  # gone by now. The connect infos come out of them as well.
  my (@frames, @connect_info, %seen);
  my $depth = 0;
  while (1) {
    my (@frame, @args);
    {
      package DB;
      @frame = caller($depth);
      @args = map {
        my $arg;
        local $@ = $@;
        eval { $arg = $_; 1 } ? $arg : '** argument not available anymore **';
      } @DB::args if @frame and $frame[4];
    }
    last unless @frame;

    $frames[$depth] = [ \@frame, \@args ];

    # the two frames of this module's own are not the caller's
    next if $depth++ < 2;

    my @found = map { [ @args[$_ .. $_ + 3] ] }
      grep { defined $args[$_] and !ref $args[$_] and $args[$_] =~ /^dbi:/i } 0 .. $#args;

    if (@args > 1 and $frame[3] =~ /::connect(?:ion)?\z/ and UNIVERSAL::isa($args[0], 'DBIO::Schema')) {
      my $first = $args[1];
      push @found, ref $first eq 'HASH' ? [ @{$first}{qw(dsn user password)}, $first ]
                 : ref $first           ? ()
                 :                        [ @args[1 .. 4] ];
    }

    for my $found (@found) {
      my ($dsn, undef, $password, $attrs) = @$found;
      # read into a variable of its own: listed for the map below, the element
      # would come into being in the caller's hash
      my $attribute = ref $attrs eq 'HASH' ? $attrs->{Password} : undef;
      my @secret = map { defined $_ && !ref $_ ? "$_" : '' } $dsn, $password, $attribute;
      next if !grep { length } @secret or $seen{ join "\0", @secret }++;
      push @connect_info, [ $secret[0], undef, $secret[1], { Password => $secret[2] } ];
    }
  }

  # Where the trace starts: the first frame of a package that is not one of
  # Carp's own, past $Carp::CarpLevel, as the documented variables say. Frame 1
  # is the call of the public function; a longmess has one more level to skip
  # unless it is called from an internal package.
  my $level = $Carp::CarpLevel;
  $level++ if $kind eq 'longmess'
    and not ( $Carp::Internal{ $frames[1][0][0] } or $Carp::CarpInternal{ $frames[1][0][0] } );

  my $from = 0;
  {
    $from++;
    my $frame = $frames[$from];
    if (!$frame) {
      # nothing outside is left: the call itself is the place
      $from = 1;
      last;
    }
    my $package = $frame->[0][0];
    redo if $Carp::CarpInternal{$package};
    redo unless 0 > --$level;
    redo if $Carp::Internal{$package};
  }

  push @connect_info, $TRACE_CONNECT_INFO if ref $TRACE_CONNECT_INFO eq 'ARRAY';

  my $mask = sub {
    my $text = shift;
    return mask_connect_secrets($text) unless @connect_info;
    $text = mask_connect_secrets($text, $_) for @connect_info;
    return $text;
  };

  my $format_argument = sub {
    my $arg = $_[0];

    if (ref $arg) {
      my $shown;
      if (!$TRACE_REF_DEPTH) {
        local $TRACE_REF_DEPTH = 1;
        local $@;
        local $SIG{__DIE__} = sub {};
        if (blessed($arg) and eval { $arg->can('CARP_TRACE') }) {
          eval { $shown = $arg->CARP_TRACE; 1 } or undef $shown;
        }
        elsif (defined $Carp::RefArgFormatter) {
          my $copy = $arg;
          eval { $shown = $Carp::RefArgFormatter->($copy); 1 } or undef $shown;
        }
      }
      my $address = overload::StrVal($arg);
      return $address unless defined $shown and $shown ne $address;
      return $mask->($shown);
    }

    $arg = $mask->($arg);
    return 'undef' unless defined $arg;

    utf8::downgrade($arg, 1);
    return $arg if $arg =~ /\A-?[0-9]+(?:\.[0-9]*)?(?:[eE][-+]?[0-9]+)?\z/;

    my $suffix = '';
    my $max = $Carp::MaxArgLen;
    if (2 < $max and $max < length $arg) {
      substr($arg, $max - 3) = '';
      $suffix = '...';
    }

    $arg =~ s/(["\\\$\@])/\\$1/g;
    $arg =~ s/([^ -~])/sprintf '\\x{%x}', ord $1/eg;
    utf8::downgrade($arg, 1);

    return qq{"$arg"$suffix};
  };

  my $describe = sub {
    my ($frame, $args) = @_;
    my (undef, undef, undef, $sub, $has_args, undef, $evaltext, $is_require) = @$frame;

    my $name;
    if (defined $evaltext) {
      if ($is_require) {
        $name = "require $evaltext";
      }
      else {
        ( my $text = $evaltext ) =~ s/([\\\'])/\\$1/g;
        my $max = $Carp::MaxEvalLen || 0;
        substr($text, $max - 3) = '...' if 2 < $max and $max < length $text;
        $name = "eval '$text'";
      }
    }
    elsif (!defined $sub) {
      $name = '__ANON__::__ANON__';
    }
    else {
      $name = $sub eq '(eval)' ? 'eval {...}' : $sub;
    }

    if ($has_args) {
      my @shown = @$args;
      my $overflow;
      if ($Carp::MaxArgNums and @shown > $Carp::MaxArgNums) {
        $#shown = $Carp::MaxArgNums - 1;
        $overflow = 1;
      }
      @shown = map { $format_argument->($_) } @shown;
      push @shown, '...' if $overflow;
      $name .= '(' . join(', ', @shown) . ')';
    }

    return $name;
  };

  my $thread = '';
  if (defined &threads::tid) {
    my $tid = threads->tid;
    $thread = " thread $tid" if $tid;
  }

  my $first = $frames[$from][0];
  my $mess = join('', @msg) . " at $first->[1] line $first->[2]$thread";

  if ($.) {
    my $handle = ${^LAST_FH};
    # Carp up to 1.40 (perl 5.24 and older) names the handle only for a
    # line read; from 1.42 on it names a chunk read as well
    my $mode = $/ eq "\n" ? 'line' : 'chunk';
    $mess .= sprintf( ', <%s> %s %d', *{$handle}{NAME}, $mode, $. )
      if $handle and ( $mode eq 'line' or $Carp::VERSION >= 1.42 );
  }
  $mess .= ".\n";

  for my $i ($from + 1 .. $#frames) {
    my $at = $frames[$i][0];
    $mess .= "\t" . $describe->(@{ $frames[$i] }) . " called at $at->[1] line $at->[2]$thread\n";
  }

  return $mess;
}


sub masked_longmess { _trace_text('longmess', @_) }


sub masked_confess { die _trace_text('confess', @_) }


sub masked_cluck { warn _trace_text('confess', @_) }

sub fail_on_internal_call {
  my ($fr, $argdesc);
  {
    package DB;
    $fr = [ caller(1) ];
    $argdesc = ref $DB::args[0]
      ? DBIO::Util::refdesc($DB::args[0])
      : undef
    ;
  };

  if (
    $argdesc
      and
    $fr->[0] =~ /^(?:DBIO|DBICx::)/
  ) {
    DBIO::Exception->throw( sprintf (
      "Illegal internal call of indirect proxy-method %s() with argument %s: examine the last lines of the proxy method deparse below to determine what to call directly instead at %s on line %d\n\n%s\n\n    Stacktrace starts",
      $fr->[3], $argdesc, @{$fr}[1,2], ( $fr->[6] || do {
        require B::Deparse;
        no strict 'refs';
        B::Deparse->new->coderef2text(\&{$fr->[3]})
      }),
    ), 'with_stacktrace');
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Util - Internal utility functions for DBIO

=head1 VERSION

version 0.900005

=head1 METHODS

=head2 deep_copy

  my $copy = DBIO::Util::deep_copy($structure);

A deep copy of hashes, arrays and scalar references (blessed ones keep their
class; cycles stay cycles in the copy). Everything else a reference can point
at, a C<qr//> object, a code reference, a glob, is B<shared>, not cloned: none
of them is changed through a copy. L<Storable/dclone> does the same on a
current Perl, but a Storable before 3.08 (Perl before 5.28) dies on a regular
expression, so code that copies a structure which may hold one uses this.

=head2 canonical_text

  my $text = DBIO::Util::canonical_text($value);

The canonical text of a value, for deciding whether two values are the same:
equal text is an equal value. Hash keys are sorted, blessed hashes, arrays and
scalar references carry their class and are written by content, a plain scalar
reference by content, a C<qr//> object by pattern and flags, and a code
reference (or a glob, a handle, any other reference) by identity, so the same
sub is one value and two subs are two. C<undef> is told apart from the empty
string. A string and a number of the same text are the same value: the
internal flags Perl keeps beside a value (before 5.36 reading a string as a
number sets some) are not part of it. A reference met again inside its own
structure is written as C<*N>, N being the order of its first visit, so cycles
end. Unlike L<Storable>, it never dies on a code reference.

=head2 assert_class_name

  my $class = DBIO::Util::assert_class_name($name);

Returns C<$name> when it is a class name: Perl identifiers joined by C<::>,
the first one not starting with a digit. Anything else -- a file path, a name
with spaces, C<..>, an empty or undefined value -- throws
C<'...' is not a class name>. Class names are class names; every place that
turns a string into a loaded class (L<DBIO::Componentised/ensure_class_loaded>,
the C<require> of a configured class) asks this first.

=head2 assert_identifier_text

  DBIO::Util::assert_identifier_text("The connect key 'schema'", $name);

Returns C<$name> when it can be an identifier handed to a driver: no C<;>, no
line break (C<\n>, C<\r>) and no NUL in it. Otherwise throws a
L<DBIO::Exception> that starts with the description C<$what> and never
contains the value. Schema names, extension names and library names are
identifiers (ADR 0077); this is the one check core makes of them. Whether the
rest (a quote, a blank, a backslash) can be written is the driver's to answer,
by quoting the name as an identifier or by refusing it.

=head2 assert_class_isa

  DBIO::Util::assert_class_isa(pool_type => $class, 'DBIO::Replicated::Pool');

Throws unless the loaded class C<$class> is a C<$base> (or a subclass of it);
C<$what> names the setting in the message. Returns C<$class>. For a class a
setting names and the code instantiates: a pool is a pool, a storage class is
a storage.

=head2 mask_bound_values

  my $text = mask_bound_values($text, \@values, $quote);

The text of an error with the bound values of the statement taken out
(ADR 0075): every value that has at least four characters as a string is
replaced by C<***>. A value is looked for as it was written and as C<$quote>
writes it -- once with and once without the outer quotation marks, which finds
the doubled quote of C<''> and the C<\'> escape of an engine that quotes with
a backslash. The longest form goes first, so a value that holds another is
masked as a whole. A value of three characters or fewer stays in the text: it
is too short to tell from the words around it, and the rules for those belong
to the driver of the engine.

C<@values> are plain values; C<undef> and a reference that is no plain value
(C<is_plain_value>) are skipped, an object with a stringification counts as its
string. C<$quote> is optional, a coderef that quotes a value as the engine
does; one that dies is left out. Returns C<$text> unchanged when it is
C<undef> or a reference.

  mask_bound_values("Duplicate entry 'geheim-1' for key 'name'", ['geheim-1'])
  # Duplicate entry '***' for key 'name'

=head2 masked_longmess

  my $trace = DBIO::Util::masked_longmess("something went wrong");

Returns a message with a stack trace, in the form of L<Carp/longmess>:
C<MESSAGE at FILE line N.> and a line C<SUB(ARGS) called at FILE line N> for
each frame above the place the trace starts at, arguments shown as Carp shows
them (numbers bare, strings quoted and escaped, cut at C<$Carp::MaxArgLen>,
no more than C<$Carp::MaxArgNums> of them). A reference as the message is
returned as it came.

Every argument that is no reference is looked through for what the connect
info of the live frames names -- the arguments of C<connect> and
C<connection> on a L<DBIO::Schema>, a C<dbi:> DSN with a user name and a
password in any frame -- before it is formatted: a password is shown as C<***>
wherever an argument repeats it, and so is a password inside a DSN, under a
C<password>, C<passwd>, C<pwd> or C<pass> key, or in a URI. An SQL statement
among the arguments reads C<password = ***> where it said C<password = ?>.

DBIO builds its own traces with it, and a driver that writes one of its own
(a C<confess>, C<cluck> or C<longmess>) calls these functions instead of
L<Carp>'s. It reads C<$Carp::CarpLevel>, C<%Carp::Internal>,
C<%Carp::CarpInternal>, C<$Carp::MaxArgLen>, C<$Carp::MaxArgNums>,
C<$Carp::MaxEvalLen> and C<$Carp::RefArgFormatter> as L<Carp> documents them;
it does not look at C<$Carp::Verbose>, and it replaces nothing of Carp.

What it does not cover: a trace L<Carp> writes of its own accord -- a
C<croak> under C<$Carp::Verbose>, a C<confess> in code that is not DBIO's --
shows its arguments as Carp does, and so does a trace outside of DBIO; and a
password that reaches DBIO in no argument -- from a L<DBIO::AccessBroker>, a
connection coderef or the environment -- is not known to it.

=head2 masked_confess

  DBIO::Util::masked_confess("something went wrong");

Dies with the message and stack trace of L</masked_longmess>, as
L<Carp/confess> does. The place the trace starts at is the call of
C<masked_confess> itself.

=head2 masked_cluck

  DBIO::Util::masked_cluck("something looks wrong");

Warns with the message and stack trace of L</masked_longmess>, as
L<Carp/cluck> does. The place the trace starts at is the call of
C<masked_cluck> itself.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
