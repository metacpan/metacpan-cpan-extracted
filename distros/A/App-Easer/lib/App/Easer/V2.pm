package App::Easer::V2;
use v5.24;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '2.007004' }
use Carp;

use parent 'Exporter';
our @EXPORT_OK = qw< appeaser_api d dd run >;

# repeated stuff to ease direct usage and fatpack-like inclusion
sub appeaser_api { __PACKAGE__ =~ s{.*::}{}rmxs }
sub d            { warn dd(@_) }

sub dd (@stuff) {
   no warnings;
   require Data::Dumper;
   local $Data::Dumper::Indent = 1;
   local $Data::Dumper::Sortkeys = 1;
   Data::Dumper::Dumper(
        @stuff == 0 ? []
      : (ref($stuff[0]) || @stuff % 2) ? \@stuff
      :                                  {@stuff}
   );
} ## end sub dd (@stuff)

sub run ($app, @args) {
   my $class = 'App::Easer::V2::Command';
   my $instance =
       ref($app) eq 'HASH'  ? $class->new($app)
     : ref($app) eq 'ARRAY' ? $class->instantiate($app->@*)
     :                        $class->instantiate($app);
   return $instance->run(@args);
} ## end sub run

sub import ($package, @args) {
   my $target = caller;
   my @args_for_exporter;
   our %registered;

   my $parent_class = 'App::Easer::V2::Command';
   while (@args) {
      my $request = shift @args;
      if ($request eq '-command') {
         $registered{$target} = 1;
         no strict 'refs';
         push @{$target . '::ISA'}, $parent_class;
      }
      elsif ($request eq '-inherit') {
         no strict 'refs';
         push @{$target . '::ISA'}, $parent_class;
      }
      elsif ($request eq '-register') {
         $registered{$target} = 1;
      }
      elsif ($request eq '-spec') {
         Carp::croak "no specification provided"
           unless @args;
         Carp::croak "invalid specification provided"
           unless ref($args[0]) eq 'HASH';
         no strict 'refs';
         no warnings 'once';
         ${$target . '::app_easer_spec'} = shift @args;
      } ## end elsif ($request eq '-spec')
      elsif ($request eq '-parent') { # 2024-08-28 EXPERIMENTAL
         Carp::croak "no parent class provided"
           unless @args;
         $parent_class = shift @args;

         # make sure it's required
         App::Easer::V2::Command->load_module($parent_class);
      }
      else { push @args_for_exporter, $request }
   } ## end while (@args)
   $package->export_to_level(1, $package, @args_for_exporter);
} ## end sub import

package App::Easer::V2::Command;
use Scalar::Util 'blessed';
use List::Util 'any';
use English '-no_match_vars';
use Scalar::Util qw< weaken >;

# some stuff can be managed via a hash reference kept in a "slot",
# allowing for overriding should be easy either with re-defining the
# "slot" method, or overriding the sub-method relying on it. The name of
# the slot is the same as the name of the actual package that $self is
# blessed into.
sub slot ($self) { return $self->{blessed($self)} //= {} }

# This is a poor man's way to easily define attributes in a single line
# Corinna will be a blessing eventually
sub _rwn ($self, $name, @newval) {
   my $vref = \$self->slot->{$name};
   $$vref = $newval[0] if @newval;
   return $$vref;
}

sub _rw ($s, @n) { $s->_rwn((caller(1))[3] =~ s{.*::}{}rmxs, @n) }

sub _rwa ($self, @n) {
   my $aref = $self->_rwn((caller(1))[3] =~ s{.*::}{}rmxs, @n);
   Carp::confess() unless defined $aref;
   return $aref->@*;
}

sub _rwad ($self, @n) {
   my $aref = $self->_rwn((caller(1))[3] =~ s{.*::}{}rmxs, @n) // [];
   return wantarray ? $aref->@* : [$aref->@*];
}

sub _rw_prd ($self, @n) {
   my $slot = $self->slot;
   my $name = (caller(1))[3] =~ s{.*::}{}rmxs;
   if (@n) {
      $slot->{$name} = $n[0];
   }
   elsif (ref(my $ref_to_default = $slot->{$name})) {
      my $parent = $self->parent;
      $slot->{$name} = $parent ? $parent->$name : $$ref_to_default;
   }
   return $slot->{$name};
}

# these "attributes" would point to stuff that is normally "scalar" and
# used as specification overall. It can be overridden but probably it's
# just easier to stick in a hash inside the slot. We don't want to put
# executables here, though - overriding should be the guiding principle
# in this case.
sub aliases ($self, @r) {
   if (my @aliases = $self->_rwad(@r)) { return @aliases }
   if (defined(my $name = $self->_rwn('name'))) { return $name }
   return;
}
sub allow_residual_options ($self, @r) { $self->_rw(@r) }
sub auto_environment ($self, @r) { $self->_rw(@r) }
sub call_name ($self, @r) { $self->_rw(@r) }
sub children ($self, @r) { $self->_rwa(@r) }
sub children_prefixes ($self, @r) { $self->_rwa(@r) }
sub default_child ($self, @r) { $self->_rw(@r) }
sub description ($self, @r) { $self->_rw(@r) }
sub environment_prefix ($self, @r) { $self->_rw(@r) }
sub execution_reason ($self, @r) { $self->_rw(@r) }
sub fallback_to ($self, @r) { $self->_rw(@r) }
sub final_commit_stack ($self, @r) { $self->_rwa(@r) }
sub force_auto_children ($self, @r) { $self->_rw(@r) }
sub hashy_class ($self, @r) { $self->_rw(@r) }
sub help ($self, @r) { $self->_rw(@r) }
sub help_channel ($slf, @r) { $slf->_rw(@r) }
sub name ($s, @r) { $s->_rw(@r) // ($s->aliases)[0] // '**no name**' }
sub options_help ($s, @r) { $s->_rw(@r) }
sub params_validate ($self, @r) { $self->_rw(@r) }
sub parent ($self, @r) { $self->_rw(@r) }
sub pre_execute ($self, @r) { $self->_rwa(@r) }
sub residual_args ($self, @r) { $self->_rwa(@r) }
sub _last_cmdline ($self, @r) { $self->_rw(@r) }
sub _sources ($self, @r) { $self->_rwn(sources => @r) }
sub usage ($self, @r) { $self->_rw(@r) }

sub config_hash_key ($self, @r) { $self->_rw_prd(@r) }

sub is_root ($self) { ! defined($self->parent) }
sub root ($self) {
   my $slot = $self->slot;
   return $slot->{root} //= do {
      my $retval = $self;
      while (defined(my $parent = $retval->parent)) {
         $retval = $parent;
      }
      $retval;
   };
}

sub child ($self, @newval) {
   my $slot = $self->slot;
   if (@newval) {
      $slot->{child} = $newval[0];
      weaken($slot->{child});
   }
   return $slot->{child};
}
sub is_leaf ($self) { ! defined($self->child) }
sub leaf ($self) {
   my $slot = $self->slot;
   if (! exists($slot->{leaf})) {
      my $retval = $self;
      while (defined(my $parent = $retval->child)) {
         $retval = $parent;
      }
      $slot->{leaf} = $retval;
      weaken($slot->{leaf});
   }
   return $slot->{leaf};
}


# 2024-08-27 expand to allow hashref in addition to arrayref
# backwards-compatibility contract is that overriding this function allows
# returning the list of sources to use, which might be composed of a single
# hashref...
sub sources ($self, @new) {
   my $r;
   my $slot = $self->slot;
   if (@new) { # setter + getter
      $r = $slot->{sources} = $new[0];
   }
   else {   # getter only, set default if *nothing* has been set yet
      state $default_array =
         [ qw< +CmdLine +Environment +Parent=70 +Default=100 > ];
      state $default_hash  = {
         current => [ qw< +CmdLine +Environment +Default +ParentSlices > ],
         final   => [ ],
      };
      state $default_hash_v2_008 = {
         current => [ qw< +CmdLine +Environment +Default +ParentSlices > ],
         final   => [ ],
      };
      $r = $slot->{sources};
      $r = $slot->{sources} =
         ! defined($r)            ? Carp::confess()
         : $r eq 'default-array'  ? $default_array
         : $r eq 'default-hash'   ? $default_hash
         : $r eq 'v2.008'         ? $default_hash_v2_008
         :                         Carp::confess()
         unless ref($r); # string-based, get either default
   }
   Carp::confess() unless defined($r);

   return $r->@* if ref($r) eq 'ARRAY'; # backwards-compatible behaviour
   return \$r if ref($r) eq 'HASH';     # new behaviour
   Carp::confess(); # unsupported condition
}

# getter only
sub _sources_for_phase ($self, $phase) {
   my @sources = $self->sources; # might call an overridden thing

   return ${$sources[0]}->{$phase}
      if @sources == 1
         && ref($sources[0]) eq 'REF'
         && ref(${$sources[0]}) eq 'HASH';

   # backwards compatibility means that we only support the "current"
   # phase and do nothing for other ones.
   return $phase eq 'current' ? \@sources : ();
}

sub supports ($self, $what) {
   any { $_ eq $what } $self->aliases;
}

sub options ($self, @r) {
   return map { $self->resolve_options($_) } $self->_rwa(@r);
}

sub resolve_options ($self, $spec) {
   return $spec if ref($spec) eq 'HASH';
   $spec = [inherit_options => $spec] unless ref $spec;
   Carp::confess("invalid spec $spec") unless ref($spec) eq 'ARRAY';
   my ($method_name, @names) = $spec->@*;
   my $method = $self->can($method_name)
     or Carp::confess("cannot find method $method_name in $self");
   return $self->$method(@names);
} ## end sub resolve_options

sub inherit_options ($self, @names) {
   my %got;
   map {
      my @options;
      if ($_ eq '+parent') {
         @options = grep { $_->{transmit} // 0 } $self->parent->options;
      }
      else {
         my $name_exact = ref($_) ? undef : $_;
         my $name_rx    = qr{\A(?:$_)\z};
         my $ancestor = $self->parent;
         while ($ancestor) {
            push @options, my @pass =  # FIXME something's strange here
              grep {
               my $name = $self->name_for_option($_);
               ($_->{transmit} // 0)
               && (! $got{$name}++)     # inherit once only
               && (
                  (defined($name_exact) && $name eq $name_exact)
                  || (! $_->{transmit_exact} && $name =~ m{$name_rx})
               );
              } $ancestor->options;
            $ancestor = $ancestor->parent;
         } ## end while ($ancestor)
      } ## end else [ if ($_ eq '+parent') ]
      map { +{transmit => 1, $_->%*, inherited => 1} } @options;
   } @names;
} ## end sub inherit_options

sub new ($pkg, @args) {
   my $pkg_spec = do { no strict 'refs'; ${$pkg . '::app_easer_spec'} };
   my $slot = {
      aliases                => [],
      allow_residual_options => 0,
      auto_environment       => 0,
      children               => [],
      children_prefixes      => [$pkg . '::Cmd'],
      config_hash_key        => \'merged',
      default_child          => 'help',
      environment_prefix     => '',
      fallback_to            => undef,
      final_commit_stack     => [],
      force_auto_children    => undef,
      hashy_class            => __PACKAGE__,
      help_channel           => '-STDOUT:encoding(UTF-8)',
      options                => [],
      params_validate        => undef,
      pre_execute            => [],
      residual_args          => [],
      sources                => 'default-array',   # 2024-08-24 defer
      ($pkg_spec // {})->%*,
      (@args && ref $args[0] ? $args[0]->%* : @args),
   };
   my $self = bless {$pkg => $slot}, $pkg;
   return $self;
} ## end sub new

sub merge_hashes ($self, @hrefs) { # FIXME this seems way more complicated than needed
   my (%retval, %is_overridable);
   for my $href (@hrefs) {
      for my $src_key (keys $href->%*) {
         my $dst_key          = $src_key;
         my $this_overridable = 0;
         $retval{$dst_key} = $href->{$src_key}
           if $is_overridable{$dst_key} || !exists($retval{$dst_key});
         $is_overridable{$dst_key} = 0 unless $this_overridable;
      } ## end for my $src_key (keys $href...)
   } ## end for my $href (@hrefs)
   return \%retval;
} ## end sub merge_hashes

sub _collect ($self, $sources, @args) {
   my @residual_args;    # what is left from the @args at the end

   my $slot = $self->slot;
   my $last_priority = 0;
   for my $source ($sources->@*) {
      my ($src, @opts) = ref($source) eq 'ARRAY' ? $source->@* : $source;
      my $meta = (@opts && ref $opts[0]) ? shift @opts : {};
      my $locator = $src;
      if (! ref($src)) {
         ($src, my $priority) = split m{=}mxs, $src;
         $meta->{priority} = $priority if defined $priority;
         $locator = $src =~ s{\A \+}{source_}rmxs;
      }
      my $sub = $self->ref_to_sub($locator)
        or die "unhandled source for $locator\n";

      my ($slice, $residuals) = $sub->($self, \@opts, \@args);
      push @residual_args, $residuals->@* if defined $residuals;

      # whatever happened in the source, it might have changed the
      # internals and we need to re-load them from the current config
      my $latest = $self->_rwn('config') // {};
      my @sequence = ($latest->{sequence} //= [])->@*;    # legacy
      my %all_eslices_at = ($latest->{all_eslices_at} // {})->%*; # v2.8
      my %command_eslices_at = ($latest->{command_eslices_at} // {})->%*;

      # only operate if the source returned something to track
      if ($slice) {
         $last_priority = my $priority
            = $meta->{priority} //= $last_priority + 10;

         my $eslice = [$priority, $src, \@opts, $locator, $slice];

         # new way of collecting the aggregated configuration
         # the merge takes into account priorities across all command
         # layers, this function encapsulates getting all of them
         push(($all_eslices_at{$priority} //= [])->@*, $eslice);
         push(($command_eslices_at{$priority} //= [])->@*, $eslice);

         # older way of collecting the aggregated configuration
         push @sequence, $eslice;
         for (my $i = $#sequence; $i > 0; --$i) {
            last if $sequence[$i - 1][0] <= $sequence[$i][0];
            @sequence[$i - 1, $i] = @sequence[$i, $i - 1];
         }
      }

      # whatever happened, re-compute the aggregated configuration in the
      # new "matrix" way and in the legacy way
      my $matrix_config = $self->merge_hashes(
         map { $_->[-1] }                 # take slice out of eslice
         map { $all_eslices_at{$_}->@* }  # unroll all eslices
         sort { $a <=> $b }               # sort by priority
         keys(%all_eslices_at)            # keys is the priority
      );
      my $legacy_config = $self->merge_hashes(map {$_->[-1]} @sequence);

      # save configuration at each step, so that each following source
      # can take advantage of configurations collected so far. This is
      # important for e.g. sources that load options from files whose
      # path is provided as an option itself.
      $self->_rwn(
         config => {
            merged             => $legacy_config,
            merged_legacy      => $legacy_config,
            'v2.008'           => $matrix_config,
            sequence           => \@sequence,
            all_eslices_at     => \%all_eslices_at,
            command_eslices_at => \%command_eslices_at,
         }
      );
   } ## end for my $source ($self->...)
   #App::Easer::V2::d(config => $self->_rwn('config'));

   # return what's left
   return \@residual_args;
}

sub collect ($self, @args) {
   if (my $sources = $self->_sources_for_phase('current')) {
      $self->residual_args($self->_collect($sources, @args));
   }
   return $self;
} ## end sub collect

# last round of configuration options collection
sub final_collect ($self) {
   if (my $sources = $self->_sources_for_phase('final')) {
      $self->_collect($sources);
   }
   return $self;
} ## end sub collect

sub getopt_config ($self, @n) {
   my $value = $self->_rw(@n);
   if (!defined $value) {
      my @r = qw< gnu_getopt >;
      push @r, qw< require_order pass_through > if $self->list_children;
      push @r, qw< pass_through > if $self->allow_residual_options;
      $value = $self->_rw(\@r);
   } ## end if (!defined $value)
   return $value->@*;
} ## end sub getopt_config

# This source is not supposed to accept "options", although it might in
# the future, e.g. to set a specific getopt_config instead of setting it
# as a general parameter. On the other hand, it does focus on processing
# $args
sub source_CmdLine ($self, $ignore, $args) {
   my @args = $args->@*;

   require Getopt::Long;
   Getopt::Long::Configure('default', $self->getopt_config);

   my (%option_for, @specs, %name_for);
   for my $option ($self->options) {
      next unless exists($option->{getopt});
      my $go = $option->{getopt};
      if (ref($go) eq 'ARRAY') {
         my ($string, $callback) = $go->@*;
         push @specs, $string, sub { $callback->(\%option_for, @_) };
         $go = $string;
      }
      else {
         push @specs, $go;
      }

      my ($go_name) = $go =~ m{\A(\w[-\w]*)}mxs;
      my $official_name = $self->name_for_option($option);
      $name_for{$go_name} = $official_name if $go_name ne $official_name;
   }

   Getopt::Long::GetOptionsFromArray(\@args, \%option_for, @specs)
     or die "bailing out\n";

   # Check if we want to forbid the residual @args to start with a '-'
   my $strict = !$self->allow_residual_options;
   die "bailing out (allow_residual_options is false and got <@args>)"
      if $strict && @args && $args[0] =~ m{\A - . }mxs;

   # remap names where the official one is different from the getopt one
   $self->_rename_options_inplace(\%option_for, \%name_for);

   $self->_last_cmdline( { option_for => \%option_for, args => \@args });

   return (\%option_for, \@args);
} ## end sub source_CmdLine

sub _rename_options_inplace ($self, $collected, $name_for) {
   my %renamed;
   for my $go_name (sort { $a cmp $b } keys $name_for->%*) {
      next unless exists $collected->{$go_name};
      my $official_name = $name_for->{$go_name};
      $renamed{$official_name} = delete($collected->{$go_name});
   }
   $collected->{$_} = $renamed{$_} for keys %renamed;
   return $self;
}

sub source_LastCmdLine ($self, @ignore) {
   my $last = $self->_last_cmdline or return {};
   return $last->{option_for};
}

sub name_for_option ($self, $o) {
   return $o->{name} if defined $o->{name};
   return $1
     if defined $o->{getopt} && $o->{getopt} =~ m{\A(\w[-\w]*)}mxs;
   return lc $o->{environment}
     if defined $o->{environment} && $o->{environment} ne '1';
   return '~~~';
} ## end sub name_for_option

sub source_Default ($self, $opts, @ignore) {
   my %opts = $opts->@*;
   my $include_inherited = $opts{include_inherited};
   return {
      map { $self->name_for_option($_) => $_->{default} }
      grep { exists $_->{default} }
      grep { $include_inherited || !$_->{inherited} } $self->options
   };
}
sub source_FinalDefault ($self, @i) {
   return $self->source_Default([ include_inherited => 1]);
}

sub source_FromTrail ($self, $trail, @ignore) {
   my $conf = $self->config_hash;
   for my $key ($trail->@*) {
      return {} unless defined $conf->{$key};
      $conf = $conf->{$key};
      die "invalid trail $trail->@* for configuration gathering"
        unless ref($conf) eq 'HASH';
   } ## end for my $key ($keys->@*)
   return $conf;
}

sub environment_variable_name ($self, $ospec) {
   my $env =
       exists $ospec->{environment} ? $ospec->{environment}
     : $self->auto_environment      ? 1
     :                                undef;
   return $env unless ($env // '') eq '1';

   # get prefixes all the way up to the first command
   my @prefixes;
   for (my $instance = $self; $instance; $instance = $instance->parent) {
      unshift @prefixes, $instance->environment_prefix // '';
   }

   return uc(join '', @prefixes, $self->name_for_option($ospec));
} ## end sub environment_variable_name


sub source_Environment ($self, $opts, @ignore) {
   my %opts = $opts->@*;
   my $include_inherited = $opts{include_inherited};
   return {
      map {
         my $en = $self->environment_variable_name($_);
         defined($en)
           && exists($ENV{$en})
           ? ($self->name_for_option($_) => $ENV{$en})
           : ();
      } grep { $include_inherited || !$_->{inherited} } $self->options
   };
} ## end sub source_Environment
sub source_FinalEnvironment ($self, @i) {
   return $self->source_Environment([ include_inherited => 1 ]);
}

sub source_JsonFileFromConfig ($self, $key, @ignore) {
   $key = $key->[0] // 'config';
   defined(my $filename = $self->config($key)) or return {};
   require JSON::PP;
   return JSON::PP::decode_json($self->slurp($filename));
} ## end sub source_JsonFileFromConfig

sub slurp ($self, $file, $mode = '<:encoding(UTF-8)') {
   open my $fh, $mode, $file or die "open('$file'): $!\n";
   local $/;
   return <$fh>;
}

sub source_JsonFiles ($self, $candidates, @ignore) {
   require JSON::PP;
   return $self->merge_hashes(
      map  { JSON::PP::decode_json($self->slurp($_)) }
      grep { -e $_ } $candidates->@*
   );
} ## end sub source_JsonFiles

sub source_Parent ($self, @ignore) {
   my $parent = $self->parent or return {};
   return $parent->config_hash(0);
}

sub source_ParentSlices ($self, @ignore) {
   my $parent = $self->parent or return; # no Parent, no Party

   my $latest = $self->_rwn('config');
   $self->_rwn(config => ($latest = {})) unless defined $latest;
   my $all_eslices_at = $latest->{all_eslices_at} //= {};

   # get all stuff from parent, keeping priorities.
   my $pslices_at = $parent->config_hash(1)->{all_eslices_at} // {};
   for my $priority (keys($pslices_at->%*)) {
      my $eslices = $all_eslices_at->{$priority} //= [];
      push $eslices->@*, $pslices_at->{$priority}->@*;
   }

   return;
}

# get the assembled config for the command. It supports the optional
# additional boolean parameter $blame to get back a more structured
# version where it's clear where each option comes from, to allow for
# further injection of parameters from elsewhere.
sub config_hash ($self, $blame = 0) {
   my $config = $self->_rwn('config') // {};
   return $config if $blame;
   return $config->{$self->config_hash_key} // {};
}

# get one or more specific configurtion values
sub config ($self, @keys) {
   my $hash = $self->config_hash(0);
   return $hash->{$keys[0]} if @keys == 1;
   return $hash->@{@keys};
}

sub set_config ($self, $key, @value) {
   my $hash = $self->config_hash(0);
   delete $hash->{$key};
   $hash->{$key} = $value[0] if @value;
   return $self;
} ## end sub set_config

# totally replace whatever has been collected at this level
sub set_config_hash ($self, $new, $full = 0) {
   if (! $full) {
      my $previous = $self->_rwn('config') // {};
      my $key = $self->config_hash_key;
      $new = { $previous->%*, merged => $new, override => $new };
   }
   $self->_rwn(config => $new);
   return $self;
}

sub inject_configs ($self, $data, $priority = 1000) {

   # we define an on-the-fly source and get it considered through the
   # regular source-handling mechanism by _collect
   $self->_collect(
      [
         sub ($self, $opts, $args) {
            my $latest = $self->_rwn('config');
            $self->_rwn(config => ($latest = {})) unless $latest;
            my $queue = $latest->{all_eslices_at}{$priority} //= [];
            push $queue->@*, [ $priority, injection => [], '', $data ];
            return;
         },
      ]
   );
}

# (intermediate) commit collected options values, called after collect ends
sub commit ($self, @n) {
   my $commit = $self->_rw(@n);
   return $commit if @n;  # setter, don't call the commit callback
   return unless $commit;
   return $self->ref_to_sub($commit)->($self);
} ## end sub commit

# final commit of collected options values, called after final_collect ends
# this method tries to "propagate" the call up to the parent (and the root
# eventually) unless told not to do so. This should allow concentrating
# some housekeeping operations in the root command while still waiting for
# all options to have been collected
sub final_commit ($self, @n) {
   return $self->_rw(@n) if @n;  # setter, don't call the callback

   # we operate down at the slot level because we want to separate the case
   # where key 'final_commit' is absent (defaulting to propagation up to
   # the parent) and where it's set but otherwise false (in which case
   # there is no propagation).
   my $slot = $self->slot;

   # put "myself" onto the call stack for final_commit
   my $stack = $slot->{final_commit_stack} //= [];
   push $stack->@*, $self;

   if (exists($slot->{final_commit})) {
      my $commit = $slot->{final_commit};

      # if $commit is false (but present, because it exists) then we
      # stop and do not propagate to the parent
      return unless $commit;

      # otherwise, we call it and its return value will tell us whether to
      # propagate to the parent too or stop here
      my $propagate_to_parent = $self->ref_to_sub($commit)->($self);
      return unless $propagate_to_parent;
   }

   # here we try to propagate to the parent... if it exists
   my $parent = $self->parent;
   return unless $parent;  # we're root, no parent, no propagation up

   $parent->final_commit_stack([$stack->@*]);
   return $parent->final_commit;
} ## end sub commit

# validate collected options values, called after commit ends.
sub validate ($self, @n) {

   # Support the "accessor" interface for using a validation sub
   my $validator = $self->_rw(@n);
   return $validator if @n;

   # If set, it MUST be a validation sub reference. Otherwise, try the
   # params_validate/Params::Validate path.
   if ($validator) {
      die "validator can only be a CODE reference\n"
         unless ref $validator eq 'CODE';
      $validator->($self);
   }
   elsif (my $params_validate = $self->params_validate) {
      require Params::Validate;
      if (my $config_validator = $params_validate->{config} // undef) {
         my @array = $self->config_hash;
         &Params::Validate::validate(\@array, $config_validator);
      }
      if (my $args_validator = $params_validate->{args} // undef) {
         my @array = $self->residual_args;
         &Params::Validate::validate_pos(\@array, $args_validator->@*);
      }
   }
   else {} # no validation needed

   return $self;
} ## end sub validate ($self)

sub find_matching_child ($self, $command) {
   return unless defined $command;
   for my $candidate ($self->list_children) {
      my ($child) = $self->inflate_children($candidate);
      return $child if $child->supports($command);
   }
   return;
} ## end sub find_matching_child

sub _inflate_default_child ($self) {
   defined(my $default = $self->default_child)
     or die "undefined default child\n";
   return undef if $default eq '-self';
   my $child = $self->find_matching_child($default)
     or die "no child matching the default $default\n";
   return $child;
} ## end sub inflate_default_child ($self)

# look for a child to hand execution over. Returns an child instance or
# undef (which means that the $self is in charge of executing
# something). This implements the most sensible default, deviations will
# have to be coded explicitly.
# Return values:
# - (undef, '-leaf') if no child exists
# - ($instance, @args) if a child is found with $args[0]
# - ($instance, '-default') if the default child is returned
# - (undef, '-fallback') in case $self is the fallback
# - ($instance, '-fallback', @args) in case the fallback is returned
sub find_child ($self) {
   my @candidates = $self->list_children or return (undef, '-leaf');
   my @residuals = $self->residual_args;
   if (@residuals) {
      if (my $child = $self->find_matching_child($residuals[0])) {
         return ($child, @residuals);
      }    # otherwise... see what the fallback is about
   }
   elsif (defined(my $default = $self->default_child)) {
      return ($self->_inflate_default_child, '-default');
   }

   # try the fallback...
   my $fallback = $self->fallback;
   if (defined $fallback) {
      return (undef, '-fallback') if $fallback eq '-self';
      return ($self->_inflate_default_child, '-default')
        if $fallback eq '-default';
      if (my $child = $self->find_matching_child($fallback)) {
         return ($child, -fallback => @residuals);
      }
   } ## end if (defined $fallback)

   # no fallback at this point... it's an error, build a message and die!
   # FIXME this can be improved
   die "cannot find sub-command '$residuals[0]'\n";
} ## end sub find_child ($self)

# get the list of children. This only gives back a list of "hints" that
# can be turned into instances via inflate_children. In this case, it's
# module names
sub list_children ($self) {
   my @children = $self->children;

   # handle auto-loading of children from modules in @INC via prefixes
   require File::Spec;
   my @expanded_inc = map {
      my ($v, $dirs) = File::Spec->splitpath($_, 'no-file');
      [$v, File::Spec->splitdir($dirs)];
   } @INC;
   my %seen;
   my @autoloaded_children = map {
      my @parts = split m{::}mxs, $_ . 'x';
      substr(my $bprefix = pop @parts, -1, 1, '');
      map {
         my ($v, @dirs) = $_->@*;
         my $dirs = File::Spec->catdir(@dirs, @parts);
         if (opendir my $dh, File::Spec->catpath($v, $dirs, '')) {
            grep { !$seen{$_}++ }
              map {
               substr(my $lastpart = $_, -3, 3, '');
               join '::', @parts, $lastpart;
              } grep {
               my $path = File::Spec->catpath($v, $dirs, $_);
               (-e $path && !-d $path)
                 && substr($_, 0,  length($bprefix)) eq $bprefix
                 && substr($_, -3, 3) eq '.pm'
              } sort { $a cmp $b } readdir $dh;
         } ## end if (opendir my $dh, File::Spec...)
         else { () }
      } @expanded_inc;
   } $self->children_prefixes;
   push @autoloaded_children, map {
      my $prefix = $_;
      my $prefix_length = length($prefix);
      grep { !$seen{$_}++ }
        grep {
         (substr($_, 0, length $prefix) eq $prefix)
            && (index($_, ':', $prefix_length) < 0);
        } keys %App::Easer::V2::registered;
   } $self->children_prefixes;

   # auto-loaded children are appended with consistent sorting
   push @children, sort { $a cmp $b } @autoloaded_children;

   push @children, $self->auto_children
     if $self->force_auto_children // @children;
   return @children;
} ## end sub list_children ($self)

sub _auto_child ($self, $name, $inflate = 0) {
   my $child = __PACKAGE__ . '::' . ucfirst(lc($name));
   ($child) = $self->inflate_children($child) if $inflate;
   return $child;
}

# returns either class names or inflated objects
sub auto_children ($self, $inflate = 0) {
   map { $self->_auto_child($_, $inflate) } qw< help commands tree >;
}

sub auto_commands ($self) { return $self->_auto_child('commands', 1) }

sub auto_help ($self) { return $self->_auto_child('help', 1) }

sub auto_tree ($self) { return $self->_auto_child('tree', 1) }

sub run_help ($self, $mode = 'help') { $self->auto_help->run($mode) }

sub full_help_text ($s, @as) { $s->auto_help->collect_help_for($s, @as) }

sub load_module ($sop, $module) {
   my $file = "$module.pm" =~ s{::}{/}grmxs;
   eval { require $file } or Carp::confess("module<$module>: $EVAL_ERROR");
   return $module;
}

# Gets a specification like "Foo::Bar::baz" and returns a reference to
# sub "baz" in "Foo::Bar". If no package name is set, returns a
# reference to a sub in the package of $self. FIXME document properly
sub ref_to_sub ($self, $spec) {
   Carp::confess("undefined specification in ref_to_sub")
     unless defined $spec;
   return $spec if ref($spec) eq 'CODE';
   my ($class, $function) =
     ref($spec) eq 'ARRAY'
     ? $spec->@*
     : $spec =~ m{\A (?: (.*) :: )? (.*) \z}mxs;
   return $self->can($function) unless length($class // '');
   $self->load_module($class)   unless $class->can($function);
   return $class->can($function);
} ## end sub ref_to_sub

sub instantiate ($sop, $class, @args) {
   $sop->load_module($class) unless $class->can('new');
   return $class->new(@args);
}

sub _reparent ($self, $child) {
   $child->parent($self);
   $self->child($child); # saves a weak reference to $child

   # 2024-08-27 propagate sources configurations
   if (! ref($child->_sources)) { # still default, my need to set it
      my ($first, @rest) = $self->sources;
      if (ref($first) eq 'REF') {  # new approach, propagate
         my $ssources = $$first;
         $child->_sources(my $csources = { $ssources->%* });
         if (my $next = $ssources->{next}) {
            my @csources =
                 ref($next) eq 'ARRAY' ? $next->@*
               : ref($next) eq 'CODE'  ? $next->($child)
               :                         Carp::confess(); # no clue
            $csources->{current} = \@csources;
         }
      }
   }

   # propagate pre-execute callbacks down the line
   $child->pre_execute_schedule($self->pre_execute);

   return $child;
}

# transform one or more children "hints" into instances.
sub inflate_children ($self, @hints) {
   my $hashy = $self->hashy_class;
   map {
      my $child = $_;
      if (!blessed($child)) {    # actually inflate it
         $child =
             ref($child) eq 'ARRAY' ? $self->instantiate($child->@*)
           : ref($child) eq 'HASH'  ? $self->instantiate($hashy, $child)
           :                          $self->instantiate($child);
      } ## end if (!blessed($child))
      $self->_reparent($child);  # returns $child
   } grep { defined $_ } @hints;
} ## end sub inflate_children

# fallback mechanism when finding a child, relies on fallback_to.
sub fallback ($self) {
   my $fto = $self->fallback_to;
   return $fto if !defined($fto) || $fto !~ m{\A(?: 0 | [1-9]\d* )\z};
   my @children = $self->list_children;
   return $children[$fto] if $fto <= $#children;
   return undef;
} ## end sub fallback ($self)

# execute what's set as the execute sub in the slot
sub execute ($self) {
   my $spec = $self->_rw or die "nothing to search for execution\n";
   my $sub = $self->ref_to_sub($spec) or die "nothing to execute\n";
   return $sub->($self);
}

sub pre_execute_schedule ($self, @specs) {
   if (my $spec = $self->_rw) {
      my $sub = $self->ref_to_sub($spec) or die "nothing for pre_execute_schedule\n";
      return $sub->($self, @specs);
   }

   # default approach is to append to the current ones
   $self->pre_execute([$self->pre_execute, @specs]);
   return $self;
}

sub pre_execute_run ($self) {
   if (my $spec = $self->_rw) {
      my $sub = $self->ref_to_sub($spec) or die "nothing to pre-execute\n";
      return $sub->($self);
   }

   # default is to run 'em all
   for my $spec ($self->pre_execute) {
      my $sub = $self->ref_to_sub($spec) or die "nothing to pre-execute\n";
      $sub->($self);
   }
   return $self;
}

sub run ($self, $name, @args) {
   $self->call_name($name);
   $self->collect(@args);
   $self->commit;
   $self->validate;
   my ($child, @child_args) = $self->find_child;
   return $child->run(@child_args) if defined $child;

   # we're the executors
   $self->execution_reason($child_args[0]);
   $self->final_collect;  # no @args passed in this collection
   $self->final_commit;
   $self->pre_execute_run;
   return $self->execute;
} ## end sub run

package App::Easer::V2::Command::Commands;
push our @ISA, 'App::Easer::V2::Command';
sub aliases                { 'commands' }
sub allow_residual_options { 0 }
sub description            { 'Print list of supported sub-commands' }
sub help                   { 'list sub-commands' }
sub name                   { 'commands' }

sub target ($self) {
   my ($subc, @rest) = $self->residual_args;
   die "this command does not support many arguments\n" if @rest;
   my $target = $self->parent;
   $target = $target->find_matching_child($subc) if defined $subc;
   die "cannot find sub-command '$subc'\n" unless defined $target;
   return $target;
} ## end sub target ($self)

sub list_commands_for ($self, $target = undef) {
   $target //= $self->target;
   my @lines;
   for my $command ($target->inflate_children($target->list_children)) {
      my $help    = $command->help // '(**missing help**)';
      my @aliases = $command->aliases;
      next unless @aliases;
      push @lines, sprintf '%15s: %s', shift(@aliases), $help;
      push @lines, sprintf '%15s  (also as: %s)', '', join ', ', @aliases
        if @aliases;
   } ## end for my $command ($target...)
   return unless @lines;
   return join "\n", @lines;
} ## end sub list_commands_for

sub _build_printout_facility ($self) {
   my $channel = $self->target->help_channel;
   my $refch = ref $channel;

   return $channel if $refch eq 'CODE';

   my $fh;
   if ($refch eq 'GLOB') {
      $fh = $channel;
   }
   elsif ($refch eq 'SCALAR') {
      open $fh, '>', $channel or die "open(): $!\n";
   }
   elsif ($refch) {
      die 'invalid channel';
   }
   else {
      ($channel, my $binmode) = split m{:}mxs, $channel, 2;
      if ($channel eq '-' || lc($channel) eq '-stdout') {
         $fh = \*STDOUT;
      }
      elsif (lc($channel) eq '-stderr') {
         $fh = \*STDERR;
      }
      else {
         open $fh, '>', $channel or die "open('$channel'): $!\n";
      }
      binmode $fh, $binmode if length($binmode // '');
   }

   return sub ($cmd, @stuff) {
      print {$fh} @stuff;
      return $cmd;
   }
}

sub printout ($self, @stuff) {
   my $pof = $self->_rw;
   $self->_rw($pof = $self->_build_printout_facility) unless $pof;
   $pof->($self, @stuff);
}

sub execute ($self) {
   my $target = $self->target;
   my $name   = $target->call_name // $target->name;
   if (defined(my $commands = $self->list_commands_for($target))) {
      $self->printout("sub-commands for $name\n", $commands, "\n");
   }
   else {
      $self->printout("no sub-commands for $name\n");
   }
} ## end sub execute ($self)

package App::Easer::V2::Command::Help;
push our @ISA, 'App::Easer::V2::Command::Commands';
our @aliases = qw< help usage >;
sub aliases                { @aliases }
sub allow_residual_options { 0 }
sub description            { 'Print help for (sub)command' }
sub help                   { 'print a help command' }
sub name                   { 'help' }

sub __commandline_help ($getopt) {
   my @retval;

   my ($mode, $type, $desttype, $min, $max, $default);
   if (substr($getopt, -1, 1) eq '!') {
      $type = 'bool-negatable';
      substr $getopt, -1, 1, '';
      push @retval, 'boolean (can be negated)';
   }
   elsif ($getopt =~ s<:\+ ([@%])? \z><>mxs) {
      $mode     = 'optional';
      $type     = 'i';
      $default  = 'increment';
      $desttype = $1;
      my $line = "integer, value is optional, defaults to incrementing current value";
      $line .= ", list valued" if defined($desttype) && $desttype eq '@';
      push @retval, $line;
   } ## end elsif ($getopt =~ s<:+ ([@%])? \z><>mxs)
   elsif (substr($getopt, -1, 1) eq '+') {
      $mode = 'increment';
      substr $getopt, -1, 1, '';
      push @retval,
        'incremental integer (adds 1 every time it is provided)';
   } ## end elsif (substr($getopt, -1...))
   elsif (
      $getopt =~ s<(
         [:=])    # 1 mode
         ([siof]) # 2 type
         ([@%])?  # 3 desttype
         (?:
            \{
               (\d*)? # 4 min
               ,?
               (\d*)? # 5 max
            \}
         )? \z><>mxs
     )
   {
      $mode     = $1 eq '=' ? 'required' : 'optional';
      $type     = $2;
      $desttype = $3;
      $min      = $4;
      $max      = $5;
      if (defined $min) {
         $mode = $min ? 'optional' : 'required';
      }
      $type = {
         s => 'string',
         i => 'integer',
         o => 'perl-extended-integer',
         f => 'float',
      }->{$type};
      my $line = "$type, value is $mode";
      $line .= ", at least $min times" if defined($min) && $min > 1;
      $line .= ", no more than $max times"
        if defined($max) && length($max);
      $line .= ", list valued" if defined($desttype) && $desttype eq '@';
      push @retval, $line;
   } ## end elsif ($getopt =~ s<( ) )
   elsif ($getopt =~ s<: (\d+) ([@%])? \z><>mxs) {
      $mode     = 'optional';
      $type     = 'i';
      $default  = $1;
      $desttype = $2;
      my $line = "integer, value is optional, defaults to $default";
      $line .= ", list valued" if defined($desttype) && $desttype eq '@';
      push @retval, $line;
   } ## end elsif ($getopt =~ s<: (\d+) ([@%])? \z><>mxs)
   else {  # boolean, non-negatable
      $type = 'bool';
      push @retval, 'boolean';
   }

   my @alternatives = split /\|/, $getopt;
   if ($type eq 'bool-negatable') {
      push @retval, map {
         if   (length($_) == 1) { "-$_" }
         else                   { "--$_ | --no-$_" }
      } @alternatives;
   } ## end if ($type eq 'bool')
   elsif ($type eq 'bool' || $mode eq 'increment') {
      push @retval, map {
         if   (length($_) == 1) { "-$_"  }
         else                   { "--$_" }
      } @alternatives;
   } ## end if ($type eq 'bool')
   elsif ($mode eq 'optional') {
      push @retval, map {
         if   (length($_) == 1) { "-$_ [<value>]" }
         else                   { "--$_ [<value>]" }
      } @alternatives;
   } ## end elsif ($mode eq 'optional')
   else {
      push @retval, map {
         if   (length($_) == 1) { "-$_ <value>" }
         else                   { "--$_ <value>" }
      } @alternatives;
   } ## end else [ if ($type eq 'bool') ]

   return @retval;
} ## end sub __commandline_help ($getopt)

sub execute ($self) {
   $self->printout($self->collect_help_for($self->target, $self->call_name));
   return 0;
}

sub collect_help_for ($self, $target, $mode = 'help') {
   my @stuff;

   my $trim_and_prefix = sub ($text, $prefix = '    ') {
      $text =~ s{\A\s+|\s+\z}{}gmxs;    # trim
      $text =~ s{^}{$prefix}gmxs;       # add some indentation
      return $text;
   };

   push @stuff, ($target->help // 'no concise help yet'), "\n\n";

   if ($mode eq 'help' && defined(my $description = $target->description)) {
      push @stuff, "Description:\n", $trim_and_prefix->($description), "\n\n";
   }

   if (defined(my $usage = $target->usage)) {
      push @stuff, "Usage:\n", $trim_and_prefix->($usage), "\n\n";
   }

   # Print this only for sub-commands, not for the root
   push @stuff, sprintf "Can be called as: %s\n\n", join ', ',
     $target->aliases
     if $target->parent;

   my @options = $target->options;
   my $options_help = $target->options_help;
   if (@options || defined($options_help)) {
      push @stuff, "Options:\n";

      $options_help //= {};
      if (! ref($options_help)) {
         push @stuff, $trim_and_prefix->($options_help), "\n\n";
      }
      else {
         my $preamble = $options_help->{preamble} // undef;
         push @stuff, $trim_and_prefix->($preamble), "\n\n"
            if defined($preamble);

         my $n = 0;                               # count the option
         for my $opt (@options) {
            push @stuff, "\n" if $n++;            # from second line on

            push @stuff, sprintf "%15s: %s\n", $target->name_for_option($opt),
            $opt->{help} // '';

            if (exists $opt->{getopt}) {
               my @lines = __commandline_help($opt->{getopt});
               push @stuff, sprintf "%15s  command-line: %s\n", '',
               shift(@lines);
               push @stuff,
               map { sprintf "%15s                %s\n", '', $_ } @lines;
            } ## end if (exists $opt->{getopt...})

            if (defined(my $env = $self->environment_variable_name($opt))) {
               push @stuff, sprintf "%15s   environment: %s\n", '', $env;
            }

            if (exists($opt->{default})) {
               my $default = $opt->{default};
               my $print = ! defined($default) ? '*undef*'
                  : ! ref($default) ? $default
                  : do { require JSON::PP; JSON::PP::encode_json($default) };
               push @stuff, sprintf "%15s       default: %s\n", '', $print;
            }
         } ## end for my $opt (@options)

         my $postamble = $options_help->{postamble} // undef;
         push @stuff, "\n", $trim_and_prefix->($postamble), "\n"
            if defined($postamble);
      }

      push @stuff, "\n";
   } ## end if (my @options = $target...)
   else {
      push @stuff, "This command has no option\n";
   }

   if (defined(my $commands = $self->list_commands_for($target))) {
      push @stuff, "Sub-commands:\n", $commands, "\n";
   }
   else {
      push @stuff, "No sub-commands\n";
   }

   return join '', @stuff;
} ## end sub execute ($self)

package App::Easer::V2::Command::Tree;
push our @ISA, 'App::Easer::V2::Command::Commands';
sub aliases     { 'tree' }
sub description { 'Print tree of supported sub-commands' }
sub help        { 'print sub-commands in a tree' }
sub name        { 'tree' }

sub options {
   return (
      {
         getopt      => 'include_auto|include-auto|I!',
         default     => 0,
         environment => 1,
      },
   );
} ## end sub options

sub list_commands_for ($self, $target) {
   my $exclude_auto = $self->config('include_auto') ? 0 : 1;
   my @lines;
   for my $command ($target->inflate_children($target->list_children)) {
      my ($name) = $command->aliases or next;
      next
        if $name =~ m{\A(?: help | commands | tree)\z}mxs && $exclude_auto;
      my $help = $command->help // '(**missing help**)';
      push @lines, sprintf '- %s (%s)', $name, $help;
      if (defined(my $subtree = $self->list_commands_for($command))) {
         push @lines, $subtree =~ s{^}{  }rgmxs;
      }
   } ## end for my $command ($target...)
   return unless @lines;
   return join "\n", @lines;
} ## end sub list_commands_for

1;
