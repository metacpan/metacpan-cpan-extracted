package Bot::ChatBots::Role::Source;
use strict;
use warnings;
{ our $VERSION = '0.008'; }

use Ouch;
use Log::Any qw< $log >;
use Bot::ChatBots::Weak;
use Try::Tiny;
use 5.010;

use Moo::Role;

requires 'normalize_record';

has custom_pairs => (
   is      => 'rw',
   default => sub { return {} },
);

has processor => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_processor',
);

has typename => (
   is      => 'ro',
   lazy    => 1,
   builder => 'BUILD_typename',
);

sub BUILD_processor {
   ouch 500, 'no processor defined!';
}

sub BUILD_typename {
   my $self = shift;
   my @chunks = split /::/, lc ref $self;
   return (
      ((@chunks == 1) || ($chunks[-1] ne 'webhook'))
      ? $chunks[-1]
      : $chunks[-2]
   );
} ## end sub BUILD_typename

sub pack_source {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};

   my %class_custom_pairs =
       $self->can('class_custom_pairs')
     ? $self->class_custom_pairs
     : ();

   my $refs = Bot::ChatBots::Weak->new;
   $refs->set(self => $self);
   while (my ($k, $v) = each %{$args->{refs} // {}}) {
      $refs->set($k, $v);
   }

   my $source = {
      class => ref($self),
      refs  => $refs,
      type  => $self->typename,
      %class_custom_pairs,
      %{$self->custom_pairs},
      %{$args->{source_pairs} // {}},
   };

   return $source;
} ## end sub pack_source

sub process {
   my $self = shift;
   return $self->processor->(@_);
}

sub process_updates {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};

   my $updates = $args->{updates} // [];
   ouch 500, 'updates is not an array reference'
     unless ref($updates) eq 'ARRAY';
   my $n_updates = @$updates or return;

   my $source = $self->pack_source($args);

   my @retval;
   for my $i (0 .. ($n_updates - 1)) {
      my %call;
      push @retval, \%call if defined wantarray;    # no void context
      try {
         $call{update} = $updates->[$i];
         $call{record} = $self->normalize_record(
            {
               batch => {
                  count => ($i + 1),
                  total => $n_updates,
               },
               source => $source,
               update => $call{update},
               %{$args->{record_pairs} // {}},
            }
         );
         $call{outcome} = $self->process($call{record});
      } ## end try
      catch {
         $log->error(bleep $_);
         die $_ if $self->should_rethrow($args);
      };
   } ## end for my $i (0 .. ($n_updates...))

   $self->review_outcomes(@retval) if $self->can('review_outcomes');

   return unless defined wantarray;    # void is void!
   return @retval if wantarray;
   return \@retval;
} ## end sub process_updates

sub should_rethrow {
   my $self = shift;
   my $args = (@_ && ref($_[0])) ? $_[0] : {@_};
   return
       exists($args->{rethrow}) ? $args->{rethrow}
     : $self->can('rethrow')    ? $self->rethrow
     :                            0;
} ## end sub should_rethrow

1;
