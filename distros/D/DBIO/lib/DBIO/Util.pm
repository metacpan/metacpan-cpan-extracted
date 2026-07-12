package DBIO::Util;
# ABSTRACT: Internal utility functions for DBIO

use warnings;
use strict;

use Config;

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
sub assert_no_internal_wantarray () { $ENV{DBIO_ASSERT_NO_INTERNAL_WANTARRAY} ? 1 : 0 }
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
use Carp 'croak';
use Storable 'nfreeze';
use Scalar::Util qw(weaken blessed reftype refaddr);
use Sub::Quote qw(qsub quote_sub);

use base 'Exporter';
our @EXPORT_OK = qw(
  sigwarn_silencer modver_gt_or_eq modver_gt_or_eq_and_lt
  fail_on_internal_wantarray fail_on_internal_call
  refdesc refcount hrefaddr
  scope_guard is_exception emit_loud_diag
  quote_sub qsub perlstring serialize dump_value
  UNRESOLVABLE_CONDITION
  dir_path file_path parent_dir slurp_file slurp_file_utf8 write_file mkpath rmtree
  split_name dumper_squashed eval_package_without_redefine_warnings class_path
  firstidx uniq apply array_eq
  foreignbuildargs is_access_broker
  is_windows is_dev_release old_mro help_url unstable_dollar_at
  has_ithreads dbiotest peepeeness shuffle_unordered_resultsets
  iv_size os_name spurious_version_check_warnings
  is_plain_value is_literal_value
  assert_no_internal_wantarray assert_no_internal_indirect_calls
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

  my $longmess = Carp::longmess();

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
  Carp::confess($args->{msg});
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
      Carp::cluck "Execution of scope guard $_[0] resulted in the non-trappable exception:\n\n$@";
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

{
  my $list_ctx_ok_stack_marker;

  sub fail_on_internal_wantarray () {
    return if $list_ctx_ok_stack_marker;

    if (! defined wantarray) {
      croak('fail_on_internal_wantarray() needs a tempvar to save the stack marker guard');
    }

    my $cf = 1;
    while ( ( (caller($cf+1))[3] || '' ) =~ / :: (?:

      # these are public API parts that alter behavior on wantarray
      search | search_related | slice | search_literal

        |

    ) $/x ) {
      $cf++;
    }

    my ($fr, $want, $argdesc);
    {
      package DB;
      $fr = [ caller($cf) ];
      $want = ( caller($cf-1) )[5];
      $argdesc = ref $DB::args[0]
        ? DBIO::Util::refdesc($DB::args[0])
        : 'non '
      ;
    };

    if (
      $want and $fr->[0] =~ /^(?:DBIO|DBICx::)/
    ) {
      DBIO::Exception->throw( sprintf (
        "Improper use of %s instance in list context at %s line %d\n\n    Stacktrace starts",
        $argdesc, @{$fr}[1,2]
      ), 'with_stacktrace');
    }

    my $mark = [];
    weaken ( $list_ctx_ok_stack_marker = $mark );
    $mark;
  }
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

# --- Loader utilities (merged from DBIO::Loader::Utils) ---

sub split_name {
  require String::CamelCase;
  my ($name, $v) = @_;
  my $BY_NON_ALPHANUM = qr/[\W_]+/;
  if ((not $v) || $v >= 8) {
    return map split($BY_NON_ALPHANUM, $_), String::CamelCase::wordsplit($name);
  }
  my $BY_CASE_TRANSITION_V7 = qr/(?<=[[:lower:]\d])[\W_]*(?=[[:upper:]])|[\W_]+/;
  my $is_camel_case = $name =~ /[[:upper:]]/ && $name =~ /[[:lower:]]/;
  return split $is_camel_case ? $BY_CASE_TRANSITION_V7 : $BY_NON_ALPHANUM, $name;
}

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

version 0.900001

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
