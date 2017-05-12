package Data::Tubes::Plugin::Plumbing;

# vim: ts=3 sts=3 sw=3 et ai :

use strict;
use warnings;
use English qw< -no_match_vars >;
use Data::Dumper;
use Scalar::Util qw< blessed >;
our $VERSION = '0.736';

use Log::Log4perl::Tiny
  qw< :easy :dead_if_first get_logger LOGLEVEL LEVELID_FOR >;
use Data::Tubes::Util qw<
  args_array_with_options
  load_module
  load_sub
  pump
  normalize_args
  traverse
>;
use Data::Tubes::Plugin::Util qw< identify log_helper tubify >;

sub alternatives {
   my ($tubes, $args) =
     args_array_with_options(@_, {name => 'alternatives'});
   identify($args);
   my $name = $args->{name};

   my @tubes = tubify($args, @$tubes);

   return sub {
      my $record = shift;
      for my $tube (@tubes) {
         if (my @retval = $tube->($record)) {
            return @retval;
         }
      }
      return;
   };
} ## end sub alternatives

sub _get_selector {
   my $args     = shift;
   my $selector = $args->{selector};
   if (!defined($selector) && defined($args->{key})) {
      my $key = $args->{key};
      my $ref = ref $key;
      $selector =
        ($ref eq 'CODE')
        ? $key
        : sub { return traverse($_[0], $ref ? @$key : $key); };
   } ## end if (!defined($selector...))
   LOGDIE "$args->{name}: required dispatch key or selector"
     if (! defined $selector) && (! $args->{missing_ok});
   return $selector;
} ## end sub _get_selector

sub cache {
   my %args = normalize_args(@_, [{name => 'cache'}, 'tube']);
   identify(\%args);
   my $name = $args{name};

   # the cached tube
   my ($tube) = tubify(\%args, $args{tube});
   LOGCROAK "$name: no tube to cache" unless defined $tube;

   # the cache! We will use something compatible with CHI
   my $cache = $args{cache} // {};
   $cache = ['^Data::Tubes::Util::Cache', repository => $cache]
     if ref($cache) eq 'HASH';
   if (!blessed($cache)) {
      my ($x, @args) = ref($cache) ? @$cache : $cache;
      $cache = ref($x) ? $x->(@args) : load_module($x)->new(@args);
   }
   my @get_options = $args{get_options} ? @{$args{get_options}} : ();
   my @set_options = $args{set_options} ? @{$args{set_options}} : ();

   # what allows me to look in the cache?
   my $selector = _get_selector({%args, missing_ok => 1});
   LOGCROAK "missing key or selector, but output is set"
     if (! defined $selector) && defined($args{output});

   # cleaning trigger, if any
   my $cleaner = $args{cleaner};
   $cleaner = $cache->can($cleaner) if defined($cleaner) && !ref($cleaner);

   # cloning facility, if needed
   my $merger = $args{merger};
   $merger = load_sub($merger) if defined($merger) && !ref($merger);

   my $output = $args{output};
   return sub {
      my $record = shift;
      my $key    = $selector ? $selector->($record) : $record;
      my $data   = $cache->get($key, @get_options);
      if (!$data) {    # MUST be an array reference at this point
         my @oc = $tube->($record);
         if (scalar(@oc) == 2) {
            my $rcs = ($oc[0] eq 'records') ? $oc[1] : pump($oc[1]);
            $rcs = [map { $_->{$output} } @$rcs] if defined($output);
            $data = [records => $rcs];
         }
         elsif (scalar @oc) {
            $data = defined($output) ? [$oc[0]{$output}] : \@oc;
         }
         else {
            $data = \@oc;
         }

         $cache->set($key, $data, @set_options);
         $cleaner->($cache) if $cleaner;
      } ## end if (!$data)

      return unless scalar @$data;

      if (scalar(@$data) == 1) {    # single record
         return $merger->($record, $output, $data->[0]) if $merger;
         return $data->[0] unless $output;
         $record->{$output} = $data->[0];
         return $record;
      } ## end if (scalar(@$data) == ...)

      # array of records here
      my $aref = $data->[1];
      my $records =
        $merger
        ? [map { $merger->($record, $output, $_) } @$aref]
        : $output ? [
         map {
            { %$record, $output => $_ }
         } @$aref
        ]
        : $aref;
      return (records => $records);
   };
} ## end sub cache

sub dispatch {
   my %args = normalize_args(@_,
      {default => undef, name => 'dispatch', loglevel => $INFO});
   identify(\%args);
   my $name = $args{name};

   my $selector = _get_selector(\%args);

   my $handler_for = {%{$args{handlers} || {}}};    # our cache
   my $factory = $args{factory};
   if (!defined($factory)) {
      $factory = sub {
         my ($key, $record) = @_;
         die {
            message => "$name: unhandled selection key '$key'",
            record  => $record,
         };
      };
   } ## end if (!defined($factory))
   LOGDIE "$name: required factory or handlers"
     unless defined $factory;

   my $default = $args{default};
   return sub {
      my $record = shift;

      # get a key into the cache
      my $key = $selector->($record) // $default;
      die {
         message => "$name: selector key is undefined",
         record  => $record,
        }
        unless defined $key;

      # register a new handler... or die!
      ($handler_for->{$key}) = tubify(\%args, $factory->($key, $record))
        unless exists $handler_for->{$key};

      return $handler_for->{$key}->($record);
   };
} ## end sub dispatch

sub fallback {

   # we lose syntax sugar but allow for Try::Tiny to remain optional
   eval { require Try::Tiny; }
     or LOGCONFESS 'Data::Tubes::Plugin::Plumbing::fallback '
     . 'needs Try::Tiny, please install';

   my ($tubes, $args) = args_array_with_options(@_, {name => 'fallback'});
   identify($args);
   my $name = $args->{name};

   my @tubes = tubify($args, @$tubes);
   my $catch = $args->{catch};
   return sub {
      my $record = shift;
      for my $tube (@tubes) {
         my (@retval, $do_fallback);
         Try::Tiny::try(
            sub {
               @retval = $tube->($record);
            },
            Try::Tiny::catch(
               sub {
                  $catch->($_, $record) if $catch;
                  $do_fallback = 1;
               }
            )
         );
         return @retval unless $do_fallback;
      } ## end for my $tube (@tubes)
      return;
   };
} ## end sub fallback

sub logger {
   my %args = normalize_args(@_, {name => 'log pipe', loglevel => $INFO});
   identify(\%args);
   my $loglevel = LEVELID_FOR($args{loglevel});
   my $mangler  = $args{target};
   if (!defined $mangler) {
      $mangler = sub { return shift; }
   }
   elsif (ref($mangler) ne 'CODE') {
      my @keys = ref($mangler) ? @$mangler : ($mangler);
      $mangler = sub {
         my $record = shift;
         return traverse($record, @keys);
      };
   } ## end elsif (ref($mangler) ne 'CODE')
   my $logger = get_logger();
   return sub {
      my $record = shift;
      $logger->log($loglevel, $mangler->($record));
      return $record;
   };
} ## end sub logger

sub pipeline {
   my ($tubes, $args) = args_array_with_options(@_, {name => 'pipeline'});
   return sequence(%$args, tubes => $tubes);
}

sub sequence {
   my %args =
     normalize_args(@_, [{name => 'sequence', tubes => []}, 'tubes']);
   identify(\%args);

   # cope with an empty list of tubes - equivalent to an "id" function but
   # always returning an iterator for consistency
   my $tubes = $args{tubes} || [];
   return sub {
      my @record = shift;
      return (
         iterator => sub {
            return unless @record;
            return shift @record;
         }
      );
     }
     unless @$tubes;

   # auto-generate tubes if you get definitions
   my @tubes = tubify(\%args, @$tubes);

   my $gate = $args{gate} // undef;

   my $logger = log_helper(\%args);
   my $name   = $args{name};
   return sub {
      my $record = shift;
      $logger->($record, \%args) if $logger;

      my @stack = ({record => $record});
      my $iterator = sub {
       STEP:
         while (@stack) {
            my $pos = $#stack;

            my $f = $stack[$pos];
            my @record =
                exists($f->{record})   ? delete $f->{record}
              : exists($f->{iterator}) ? $f->{iterator}->()
              : @{$f->{records} || []} ? shift @{$f->{records}}
              :                          ();
            if (!@record) {    # no more at this level...
               my $n = @stack;
               TRACE "$name: level $n backtracking, no more records";
               pop @stack;
               next STEP;
            } ## end if (!@record)

            my $record = $record[0];
            return $record if @stack > @tubes;    # output cache

            # cut the sequence early if the gate function says so
            return $record if $gate && ! $gate->($record);

            # something must be done...
            my @outcome = $tubes[$pos]->($record)
              or next STEP;

            unshift @outcome, 'record' if @outcome == 1;
            push @stack, {@outcome};              # and go to next level
         } ## end STEP: while (@stack)

         return;    # end of output, empty list
      };
      return (iterator => $iterator);
   };
} ## end sub sequence

1;
