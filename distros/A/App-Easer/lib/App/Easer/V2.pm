package App::Easer::V2;
use v5.24;
use warnings;
use experimental qw< signatures >;
no warnings qw< experimental::signatures >;
{ our $VERSION = '2.002' }
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
   while (@args) {
      my $request = shift @args;
      if ($request eq '-command') {
         $registered{$target} = 1;
         no strict 'refs';
         push @{$target . '::ISA'}, 'App::Easer::V2::Command';
      }
      elsif ($request eq '-inherit') {
         no strict 'refs';
         push @{$target . '::ISA'}, 'App::Easer::V2::Command';
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
      else { push @args_for_exporter, $request }
   } ## end while (@args)
   $package->export_to_level(1, $package, @args_for_exporter);
} ## end sub import

package App::Easer::V2::Command;
use Scalar::Util 'blessed';
use List::Util 'any';
use English '-no_match_vars';

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
sub force_auto_children ($self, @r) { $self->_rw(@r) }
sub fallback_to ($self, @r) { $self->_rw(@r) }
sub hashy_class ($self, @r) { $self->_rw(@r) }
sub help ($self, @r) { $self->_rw(@r) }
sub help_channel ($slf, @r) { $slf->_rw(@r) }
sub name ($s, @r) { $s->_rw(@r) // ($s->aliases)[0] // '**no name**' }
sub params_validate ($self, @r) { $self->_rw(@r) }
sub parent ($self, @r) { $self->_rw(@r) }
sub residual_args ($self, @r) { $self->_rwa(@r) }
sub sources ($self, @r) { $self->_rwa(@r) }

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
         my $namerx   = qr{\A(?:$_)\z};
         my $ancestor = $self->parent;
         while ($ancestor) {
            push @options, my @pass =  # FIXME something's strange here
              grep {
               my $name = $self->name_for_option($_);
               (!$_->{transmit_exact})
                 && $name =~ m{$namerx}
                 && !$got{$name};
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
      default_child          => 'help',
      environment_prefix     => '',
      fallback_to            => undef,
      force_auto_children    => undef,
      hashy_class            => __PACKAGE__,
      help_channel           => '-STDOUT:encoding(UTF-8)',
      options                => [],
      params_validate        => undef,
      sources => [qw< +CmdLine +Environment +Parent=70 +Default=100 >],
      ($pkg_spec // {})->%*,
      (@args && ref $args[0] ? $args[0]->%* : @args),
   };
   my $self = bless {$pkg => $slot}, $pkg;
   return $self;
} ## end sub new

sub merge_hashes ($self, @hrefs) {
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

# collect options values from $args (= [...]) & other sources
# sets own configuration and residual_args
# acts based on what is provided by method options()
sub collect ($self, @args) {
   my @sequence;    # stuff collected from Sources, w/ context
   my @slices;      # ditto, no context
   my $config = {};      # merged configuration
   my @residual_args;    # what is left from the @args at the end

   my $last_priority = 0;
   for my $source ($self->sources) {
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
      $last_priority = my $priority = $meta->{priority} //= $last_priority + 10;
      push @sequence, [$priority, $src, \@opts, $locator, $slice];
      for (my $i = $#sequence; $i > 0; --$i) {
         last if $sequence[$i - 1][0] <= $sequence[$i][0];
         @sequence[$i - 1, $i] = @sequence[$i, $i - 1];
      }
      $config = $self->merge_hashes(map {$_->[-1]} @sequence);
      $self->_rwn(config => {merged => $config, sequence => \@sequence});
   } ## end for my $source ($self->...)

   # save and return
   $self->residual_args(\@residual_args);
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

sub source_CmdLine ($self, $ignore, $args) {
   my @args = $args->@*;

   require Getopt::Long;
   Getopt::Long::Configure('default', $self->getopt_config);

   my %option_for;
   my @specs = map {
      my $go = $_->{getopt};
      ref($go) eq 'ARRAY'
        ? ($go->[0] => sub { $go->[1]->(\%option_for, @_) })
        : $go;
     }
     grep { exists $_->{getopt} } $self->options;
   Getopt::Long::GetOptionsFromArray(\@args, \%option_for, @specs)
     or die "bailing out\n";

   # Check if we want to forbid the residual @args to start with a '-'
   my $strict = !$self->allow_residual_options;
   if ($strict && @args && $args[0] =~ m{\A -}mxs) {
      Getopt::Long::Configure('default', 'gnu_getopt');
      Getopt::Long::GetOptionsFromArray(\@args, {});
      die "bailing out\n";
   }

   return (\%option_for, \@args);
} ## end sub source_CmdLine

sub name_for_option ($self, $o) {
   return $o->{name} if defined $o->{name};
   return $1 if defined $o->{getopt} && $o->{getopt} =~ m{\A(\w+)}mxs;
   return lc $o->{environment}
     if defined $o->{environment} && $o->{environment} ne '1';
   return '~~~';
} ## end sub name_for_option

sub source_Default ($self, @ignore) {
   return {
      map { $self->name_for_option($_) => $_->{default} }
      grep { exists $_->{default} }
      grep { !$_->{inherited} } $self->options
   };
} ## end sub source_Default

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

sub source_Environment ($self, @ignore) {
   return {
      map {
         my $en = $self->environment_variable_name($_);
         defined($en)
           && exists($ENV{$en})
           ? ($self->name_for_option($_) => $ENV{$en})
           : ();
      } grep { !$_->{inherited} } $self->options
   };
} ## end sub source_Environment

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


# get the assembled config for the command. It supports the optional
# additional boolean parameter $blame to get back a more structured
# version where it's clear where each option comes from, to allow for
# further injection of parameters from elsewhere.
sub config_hash ($self, $blame = 0) {
   my $config = $self->_rwn('config') // {};
   return $config if $blame;
   return $config->{merged} // {};
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

# commit collected options values, called after collect ends
sub commit ($self, @n) {
   my $commit = $self->_rw(@n);
   return $commit if @n;
   return unless $commit;
   return $self->ref_to_sub($commit)->($self);
} ## end sub commit

# validate collected options values, called after commit ends.
sub validate ($self) {
   my $validator = $self->params_validate // return;
   require Params::Validate;
   if (my $config_validator = $validator->{config} // undef) {
      my @array = $self->config_hash;
      Params::Validate::validate(@array, $config_validator);
   }
   if (my $args_validator = $validator->{args} // undef) {
      my @array = $self->residual_args;
      Params::Validate::validate_pos(@array, $args_validator->@*);
   }
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
   require File::Spec;
   my @expanded_inc = map {
      my ($v, $dirs) = File::Spec->splitpath($_, 'no-file');
      [$v, File::Spec->splitdir($dirs)];
   } @INC;
   my %seen;
   push @children, map {
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
   push @children, map {
      my $prefix = $_;
      grep { !$seen{$_}++ }
        grep {
         my $this_prefix = substr $_, 0, length $prefix;
         $this_prefix eq $prefix;
        } keys %App::Easer::V2::registered;
   } $self->children_prefixes;
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

sub run_help ($self) { return $self->auto_help->run($self->name) }
sub full_help_text ($s) { return $s->auto_help->collect_help_for($s) }

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

# transform one or more children "hints" into instances.
sub inflate_children ($self, @hints) {
   my $hashy = $self->hashy_class;
   map {
      my $child = $_;
      if (!blessed($child)) {    # actually inflate it
         $child =
             ref($child) eq 'ARRAY' ? $self->instantiate($child->@*)
           : ref($child) eq 'HASH' ? $self->instantiate($hashy, $child)
           :                         $self->instantiate($child);
      } ## end if (!blessed($child))
      $child->parent($self);
      $child;
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

sub run ($self, $name, @args) {
   $self->call_name($name);
   $self->collect(@args);
   $self->commit;
   $self->validate;
   my ($child, @child_args) = $self->find_child;
   return $child->run(@child_args) if defined $child;
   $self->execution_reason($child_args[0]);
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

sub help_channel ($self) { $self->target->help_channel }

sub _build_printout_facility ($self) {
   my $channel = $self->help_channel;
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
sub aliases                { 'help' }
sub allow_residual_options { 0 }
sub description            { 'Print help for (sub)command' }
sub help                   { 'print a help command' }
sub name                   { 'help' }

sub __commandline_help ($getopt) {
   my @retval;

   my ($mode, $type, $desttype, $min, $max, $default);
   if (substr($getopt, -1, 1) eq '!') {
      $type = 'bool';
      substr $getopt, -1, 1, '';
      push @retval, 'boolean option';
   }
   elsif (substr($getopt, -1, 1) eq '+') {
      $mode = 'increment';
      substr $getopt, -1, 1, '';
      push @retval,
        'incremental option (adds 1 every time it is provided)';
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
      $mode     = $1 eq '=' ? 'mandatory' : 'optional';
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
      my $line = "$mode $type option";
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
      my $line = "optional integer, defaults to $default";
      $line .= ", list valued" if defined($desttype) && $desttype eq '@';
      push @retval, $line;
   } ## end elsif ($getopt =~ s<: (\d+) ([@%])? \z><>mxs)
   elsif ($getopt =~ s<:+ ([@%])? \z><>mxs) {
      $mode     = 'optional';
      $type     = 'i';
      $default  = 'increment';
      $desttype = $1;
      my $line = "optional integer, current value incremented if omitted";
      $line .= ", list valued" if defined($desttype) && $desttype eq '@';
      push @retval, $line;
   } ## end elsif ($getopt =~ s<:+ ([@%])? \z><>mxs)

   my @alternatives = split /\|/, $getopt;
   if ($type eq 'bool') {
      push @retval, map {
         if   (length($_) == 1) { "-$_" }
         else                   { "--$_ | --no-$_" }
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
   $self->printout($self->collect_help_for($self->target));
   return 0;
}

sub collect_help_for ($self, $target = undef) {
   $target //= $self->target;
   my @stuff;

   push @stuff, $target->help, "\n\n";

   if (defined(my $description = $target->description)) {
      $description =~ s{\A\s+|\s+\z}{}gmxs;    # trim
      $description =~ s{^}{    }gmxs;          # add some indentation
      push @stuff, "Description:\n$description\n\n";
   }

   # Print this only for sub-commands, not for the root
   push @stuff, sprintf "Can be called as: %s\n\n", join ', ',
     $target->aliases
     if $target->parent;

   if (my @options = $target->options) {
      push @stuff, "Options:\n";
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

         push @stuff, sprintf "%15s       default: %s\n", '',
           $opt->{default} // '*undef*'
           if exists $opt->{default};
      } ## end for my $opt (@options)

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
