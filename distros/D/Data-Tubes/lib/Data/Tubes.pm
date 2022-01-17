package Data::Tubes;

# vim: ts=3 sts=3 sw=3 et ai :

use strict;
use warnings;
use English qw< -no_match_vars >;
our $VERSION     = '0.740';
our $API_VERSION = $VERSION;
use Exporter ();
our @ISA = qw< Exporter >;

use Log::Log4perl::Tiny qw< :easy :dead_if_first LOGLEVEL >;
use Data::Tubes::Util qw<
  args_array_with_options
  load_sub
  normalize_args
  pump
  resolve_module
  tube
>;

our @EXPORT_OK = (
   qw<
     drain
     pipeline
     summon
     tube
     >
);
our %EXPORT_TAGS = (all => \@EXPORT_OK,);

sub _drain_0_734 {
   my $tube    = shift;
   my @outcome = $tube->(@_);
   return unless scalar @outcome;
   return $outcome[0] if scalar(@outcome) == 1;
   return pump($outcome[1]) if $outcome[0] eq 'iterator';
   my $wa = wantarray();
   return if !defined($wa);
   return $outcome[1] unless $wa;
   return @{$outcome[1]};
} ## end sub _drain_0_734

sub drain {
   goto \&_drain_0_734 if $API_VERSION le '0.734';

   my $tube    = shift;
   my @outcome = $tube->(@_);

   my $retval;
   if (scalar(@outcome) < 2) {    # one single record inside
      $retval = \@outcome;
   }
   elsif ($outcome[0] eq 'iterator') {
      $retval = [pump($outcome[1])];
   }
   elsif ($outcome[0] eq 'records') {
      $retval = $outcome[1];
   }
   else {
      LOGDIE "invalid tube output";
   }

   my $wa = wantarray();
   return unless defined $wa;
   return $retval unless $wa;
   return @$retval;
} ## end sub drain

sub import {
   my $package = shift;
   my @filtered;
   while (@_) {
      my $item = shift;
      if (lc($item) eq '-api') {
         LOGDIE "no API version provided for parameter -api"
           unless @_;
         $API_VERSION = shift;
      }
      else {
         push @filtered, $item;
      }
   } ## end while (@_)
   $package->export_to_level(1, $package, @filtered);
} ## end sub import

sub pipeline {
   my ($tubes, $args) = args_array_with_options(@_, {name => 'sequence'});

   my $tap = delete $args->{tap};
   if (defined $tap) {
      $tap = sub {
         my $iterator = shift;
         while (my @items = $iterator->()) { }
         return;
        }
        if $tap eq 'sink';
      $tap = sub {
         my $iterator = shift;
         my @records;
         while (my @items = $iterator->()) { push @records, @items; }
         return unless @records;
         return $records[0] if @records == 1;
         return (records => \@records);
        }
        if $tap eq 'bucket';
      $tap = sub {
         my ($record) = $_[0]->();
         return $record;
        }
        if $tap eq 'first';
      $tap = sub {
         my $iterator = shift;
         my @records;
         while (my @items = $iterator->()) { push @records, @items; }
         return unless @records;
         return \@records;
        }
        if $tap eq 'array';
   } ## end if (defined $tap)

   if ((!defined($tap)) && (defined($args->{pump}))) {
      my $pump = delete $args->{pump};
      $tap = sub {
         my $iterator = shift;
         while (my ($record) = $iterator->()) {
            $pump->($record);
         }
         return;
        }
   } ## end if ((!defined($tap)) &&...)
   LOGDIE 'invalid tap or pump'
     if $tap && ref($tap) ne 'CODE';

   my $sequence = tube('^Data::Tubes::Plugin::Plumbing::sequence',
      %$args, tubes => $tubes);
   return $sequence unless $tap;

   return sub {
      my (undef, $iterator) = $sequence->(@_) or return;
      return $tap->($iterator);
   };
} ## end sub pipeline

sub summon {    # sort-of import
   my ($imports, $args) = args_array_with_options(
      @_,
      {
         prefix  => 'Data::Tubes::Plugin',
         package => (caller(0))[0],
      }
   );
   my $prefix = $args->{prefix};
   my $cpack  = $args->{package};

   for my $r (@_) {
      my @parts;
      if (ref($r) eq 'ARRAY') {
         @parts = $r;
      }
      else {
         my ($pack, $name) = $r =~ m{\A(.*)::(\w+)\z}mxs;
         @parts = [$pack, $name];
      }
      for my $part (@parts) {
         my ($pack, @names) = @$part;
         $pack = resolve_module($pack, $prefix);
         (my $fpack = "$pack.pm") =~ s{::}{/}gmxs;
         require $fpack;
         for my $name (@names) {
            my $sub = $pack->can($name)
              or LOGDIE "package '$pack' has no '$name' inside";
            no strict 'refs';
            *{$cpack . '::' . $name} = $sub;
         } ## end for my $name (@names)
      } ## end for my $part (@parts)
   } ## end for my $r (@_)
} ## end sub summon

1;
__END__
