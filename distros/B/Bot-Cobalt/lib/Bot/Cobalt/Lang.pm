package Bot::Cobalt::Lang;
$Bot::Cobalt::Lang::VERSION = '0.021003';
use v5.10;
use strictures 2;
use Carp;

use Bot::Cobalt::Common qw/:types/;
use Bot::Cobalt::Serializer;

use File::ShareDir 'dist_dir';

use Types::Path::Tiny -types;
use Path::Tiny;

use Try::Tiny;


use Moo;

## Configurable:
has lang_dir => (
  # BUILD dies without me or absolute_path (unless use_core_only => 1)
  lazy        => 1,
  is          => 'ro',
  isa         => Dir,
  coerce      => 1,
  predicate   => 'has_lang_dir',
  writer      => '_set_lang_dir',
);

has lang => (
  required  => 1,
  is        => 'rwp',
  isa       => Str,
);

has absolute_path => (
  # BUILD dies without me or lang_dir (unless use_core_only => 1)
  lazy      => 1,
  is        => 'ro',  
  isa       => AbsPath,
  coerce    => 1,
  predicate => 'has_absolute_path',
  writer    => '_set_absolute_path',
);

has _full_lang_path => (
  lazy      => 1,
  is        => 'ro',
  isa       => Path,
  coerce    => 1,
  builder   => sub {
    my ($self) = @_;
    return $self->absolute_path if $self->has_absolute_path;
    path( $self->lang_dir .'/'. $self->lang .'.yml' )
  },
);

has use_core => (
  is        => 'rwp',
  isa       => Bool,
  builder   => sub { 0 },
);

has use_core_only => (
  is        => 'rwp',
  isa       => Bool,
  builder   => sub { 0 },
  trigger   => sub {
    my ($self, $val) = @_;
    $self->_set_use_core(1) if $val
  },
);

has _core_set => (
  lazy      => 1,
  is        => 'ro',
  isa       => HashObj,
  coerce    => 1,
  builder   => sub {
    my ($self) = @_;
    my $cset_path = dist_dir('Bot-Cobalt') .'/etc/langs/english.yml';
    my $core_set_yaml = path($cset_path)->slurp_utf8;
    confess "Failed to read core set at $cset_path"
      unless $core_set_yaml;
    Bot::Cobalt::Serializer->new->thaw($core_set_yaml)
  },
);

has rpls => (
  lazy      => 1,  
  is        => 'rwp',
  isa       => HashObj,
  coerce    => 1,
  builder   => sub {
    ## FIXME ? at least cleanups, certainly
    my ($self) = @_;
    my $rpl_hash;

    ## Core (built-in) load; shallow copy:
    $rpl_hash = \%{ $self->_core_set->{RPL} }
      if $self->use_core;

    if ( $self->use_core_only ) {
      $self->_set_spec( $self->_core_set->{SPEC} );
      return $rpl_hash
    }

    my $croakable;
    my $loaded_set = try {
      Bot::Cobalt::Serializer->new->readfile( $self->_full_lang_path )
    } catch {
      ## croak() by default.
      ## If this is a core set load, return empty hash.
      if ( !$self->use_core ) {
        $croakable = "readfile() failure for " . $self->lang .
          "(" . $self->_full_lang_path . "): " .
          $_ ;
        undef
      } else {
        carp "Language load failure for ".$self->lang.": $_\n";
        +{ RPL => +{} }
      }
    } or croak $croakable;

    if ( $self->use_core ) {
      my $rev_for_loaded  = $loaded_set->{SPEC}      // 0;
      my $rev_for_builtin = $self->_core_set->{SPEC} // 0;

      if ($rev_for_builtin > $rev_for_loaded) {
        warn
          "Appear to be loading a core language set, but the internal",
          " set has a higher SPEC number than the loaded set",
          " ($rev_for_builtin > $rev_for_loaded).\n",
          " You may want to update language sets.\n" ;
      }

    }
    
    my $loaded_rpl_hash = $loaded_set->{RPL};

    confess "Language set loaded but no RPL hash found"
      unless ref $loaded_rpl_hash eq 'HASH';

    $self->_set_spec( $loaded_set->{SPEC} );
    
    @{$rpl_hash}{ keys(%$loaded_rpl_hash) }
      = @{$loaded_set->{RPL}}{ keys(%$loaded_rpl_hash) } ;

    $rpl_hash
  },
);

has spec => (
  is        => 'rwp',
  isa       => Int,
  builder   => sub { 0 },
);


sub BUILD {
  my ($self) = @_;
  unless ( $self->use_core_only ) {
    die "Need either a lang_dir or an absolute path"
      unless $self->has_absolute_path or $self->has_lang_dir;
  }
  ## Load/validate rpls() at construction time.
  $self->rpls;
}

1;

=pod

=head1 NAME

Bot::Cobalt::Lang - Bot::Cobalt language set loader

=head1 SYNOPSIS

  use Bot::Cobalt::Lang;

  ## Load 'english.yml' from language dir:
  my $english = Bot::Cobalt::Lang->new(
    lang     => 'english',    
    lang_dir => $path_to_lang_dir,
  );
  
  ## Access loaded RPL hash:
  my $str = $english->rpls->{$rpl};

  ## Fall back to core set:
  my $language = Bot::Cobalt::Lang->new(
    use_core => 1,
    lang     => $language,
    lang_dir => $lang_dir,
  );
  
  ## Use an absolute path:
  my $language = Bot::Cobalt::Lang->new(
    lang => "mylangset",
    absolute_path => $path_to_my_lang_yaml,
  );

  ## Load only the core (built-in) set:
  my $coreset = Bot::Cobalt::Lang->new(
    lang => 'coreset',
    use_core_only => 1,
  );

=head1 DESCRIPTION

Bot::Cobalt::Lang provides language set loading facilities to 
L<Bot::Cobalt> and extensions.

This is primarily used by L<Bot::Cobalt::Core> to feed the core 
B<lang()> hash.

B<new()> requires a 'lang' option and either a 'lang_dir' or 
'absolute_path' -- if an absolute path is not specified, the named 
'lang' is (attempted to be) loaded from the specified 'lang_dir' with an 
extension of ".yml".

The 'use_core' option will load the built-in language set. 
'use_core_only' will not attempt to load anything except the built-in 
set.

If the load fails, an exception is thrown.

=head2 rpls

The B<rpls> attribute accesses the loaded RPL
L<List::Objects::WithUtils::Hash>:

  my $this_str = $language->rpls->get($rpl) // "Missing RPL $rpl";

=head2 spec

The B<spec> attribute returns the SPEC: definition for the loaded 
language set.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

=cut
