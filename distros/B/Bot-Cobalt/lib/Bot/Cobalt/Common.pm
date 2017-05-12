package Bot::Cobalt::Common;
$Bot::Cobalt::Common::VERSION = '0.021003';
use v5.10;
use strictures 2;
use Carp;

use List::Objects::WithUtils;

use Import::Into;

use Bot::Cobalt::Utils ();
use IRC::Utils ();
use Object::Pluggable::Constants ();
use Try::Tiny ();

use Types::Standard ();
use List::Objects::Types ();

our $ImportMap = hash(
  string    => hash(
    'Bot::Cobalt::Utils' => array( qw/
      rplprintf
      color
      glob_to_re
      glob_to_re_str
      glob_grep
    / ),

    'IRC::Utils' => array( qw/
      lc_irc
      eq_irc
      uc_irc
      decode_irc
      strip_color
      strip_formatting
    / ),
  ),

  errors    => hash(
    'Carp' => array(qw/carp croak confess/),
  ),

  passwd    => hash(
   'Bot::Cobalt::Utils' => array( qw/ mkpasswd passwdcmp / ),
  ),

  time      => hash(
    'Bot::Cobalt::Utils' => array( qw/
      timestr_to_secs
      secs_to_timestr
      secs_to_str
      secs_to_str_y
    / ),
  ),

  validate  => hash(
    'IRC::Utils' => array( qw/
      is_valid_nick_name
      is_valid_chan_name
    / ),
  ),

  host      => hash(
    'IRC::Utils' => array( qw/
      parse_user
      normalize_mask
      matches_mask
    / ),
  ),

  constant  => hash(
    'Object::Pluggable::Constants' => array( ':ALL' ),
  ),

  types     => hash(
    'Types::Standard'      => array( -types ),
    'List::Objects::Types' => array( -types ),
  ),
);

my $FuncMap = 
  $ImportMap
    ->values
    ->map(sub {
        my @func_pkg_pairs;
        my $iter = $_->iter;
        while (my ($pkg, $opts) = $iter->()) {
          $opts->visit(sub {
            my $maybe_prefix = substr $_, 0, 1;
            push @func_pkg_pairs, ($_ => $pkg)
              unless $maybe_prefix eq ':'
              or     $maybe_prefix eq '-'
          })
        }
        @func_pkg_pairs
      })
    ->inflate;

sub import {
  my (undef, @items) = @_;
  my $target = caller;

  feature->import( ':5.10' );
  strictures->import::into($target);
  Try::Tiny->import::into($target);

  my $toimport = hash;

  # : or - prefixed tags are valid, everything else is a func/symbol:
  my (@tags, @funcs);
  for my $item (@items) {
    my $maybe_prefix = substr $item, 0, 1;
    if ($maybe_prefix eq ':' || $maybe_prefix eq '-') {
      push @tags, lc substr $item, 1;
    } else {
      push @funcs, $item;
    }
  }

  @tags = $ImportMap->keys->all 
    if grep {; $_ eq 'all' } @tags
    # empty import implies all:
    or !@tags and !@funcs;

  # groups/tags:
  for my $tag (@tags) {
    my $groups = $ImportMap->get($tag)
      || confess "Import failed; tag '$tag' not exported";
    for my $pkg ($groups->keys->all) {
      if ($toimport->exists($pkg)) {
        $toimport->get($pkg)->push( $groups->get($pkg)->all )
      } else {
        $toimport->set( $pkg => $groups->get($pkg) )
      }
    }
  }

  # individual symbols:
  for my $func (@funcs) {
    my $pkg = $FuncMap->get($func)
      || confess "Import failed; function '$func' not exported";
    if ($toimport->exists($pkg)) {
      $toimport->get($pkg)->push($func)
    } else {
      $toimport->set( $pkg => array($func) )
    }
  }

  my $iter = $toimport->iter;
  my @failed;
  while (my ($pkg, $optlist) = $iter->()) {
    my $importstr = $optlist->has_any ?
      "use $pkg qw/" . $optlist->uniq->join(' ') . "/;"
      : "use $pkg;";
    my $c = "package $target; $importstr; 1";
    local $@;
    eval $c and not $@ or carp $@ and push @failed, $pkg;
  }

  if (@failed) {
    croak 'Failed to import '. join ', ', @failed
  }

  1
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Common - Import commonly-used tools and constants

=head1 SYNOPSIS

  package Bot::Cobalt::Plugin::User::MyPlugin;
  
  ## Import useful stuff:
  use Bot::Cobalt::Common;

=head1 DESCRIPTION

This is a small exporter module providing easy inclusion of commonly
used tools and constants to make life easier on plugin authors.

L<strictures> are also enabled. This will turn on 'strict' and make (most)
warnings fatal.

L<Try::Tiny> is always imported.

=head2 Exported

=head3 Constants

=over

=item *

PLUGIN_EAT_NONE (L<Object::Pluggable::Constants>)

=item *

PLUGIN_EAT_ALL (L<Object::Pluggable::Constants>)

=back

=head3 Moo types

All of the L<Types::Standard> and L<List::Objects::Types> types are exported.

=head3 IRC::Utils

See L<IRC::Utils> for details.

=head4 String-related

  decode_irc
  lc_irc uc_irc eq_irc
  strip_color strip_formatting

=head4 Hostmasks

  parse_user
  normalize_mask
  matches_mask

=head4 Nicknames and channels

  is_valid_nick_name
  is_valid_chan_name

=head3 Bot::Cobalt::Utils

See L<Bot::Cobalt::Utils> for details.

=head4 String-related

  rplprintf
  color

=head4 Globs and matching

  glob_to_re
  glob_to_re_str
  glob_grep

=head4 Passwords

  mkpasswd
  passwdcmp

=head4 Time parsing

  timestr_to_secs
  secs_to_timestr
  secs_to_str
  secs_to_str_y

=head3 Carp

=head4 Warnings

  carp

=head4 Errors

  croak
  confess

=head2 Exported tags

You can load groups of commands by importing named tags:

  use Bot::Cobalt::Common qw/ :types :string /;

=head3 constant

Exports PLUGIN_EAT_NONE, PLUGIN_EAT_ALL constants from
L<Object::Pluggable>.

=head3 errors

Exports carp, croak, and confess from L<Carp>.

=head3 host

Exports parse_user, normalize_mask, and matches_mask from L<IRC::Utils>.

=head3 passwd

Exports mkpasswd and passwdcmp from L<App::bmkpasswd>.

=head3 string

Exports from L<Bot::Cobalt::Utils>: color, rplprintf, glob_to_re,
glob_to_re_str, glob_grep

Exports from L<IRC::Utils>: lc_irc, eq_irc, uc_irc, decode_irc,
strip_color, strip_formatting

=head3 time

Exports timestr_to_secs, secs_to_timestr, secs_to_str, and secs_to_str_y from
L<Bot::Cobalt::Utils>.

=head3 types

Exports all L<Type::Tiny> types from L<List::Objects::Types> and
L<Types::Standard>.

=head3 validate

Exports is_valid_nick_name and is_valid_chan_name from L<IRC::Utils>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
