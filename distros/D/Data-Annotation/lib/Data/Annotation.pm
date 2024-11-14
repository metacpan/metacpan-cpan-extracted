package Data::Annotation;
use v5.24;
use Moo;
use experimental qw< signatures >;
{ our $VERSION = '0.002' }

use Ouch qw< :trytiny_var >;
use Try::Catch;
use Scalar::Util qw< blessed >;
use Data::Annotation::Chain;
use Data::Annotation::Overlay;

use namespace::clean;

has chains => (is => 'ro');
has default_chain  => (is => 'ro', init_arg => 'default-chain');
has default_retval => (is => 'ro', init_arg => 'default');
has description => (is => 'ro', default => '');
has parse_context => (is => 'ro', default => sub { return {} },
   init_arg => 'condition-parse-context');

# index chains by name and keep cached inflated chains in hashref
has _cache => (is => 'ro', default => sub { return {} });

sub _chain_for ($self, $name) {
   my $chains = $self->chains;
   my $cf = $self->_cache;
   ouch 404, "missing chain for '$name'" unless exists($chains->{$name});
   $cf->{$name} //= blessed($chains->{$name}) ? $chains->{$name}
      :  Data::Annotation::Chain->new(
            'condition-parse-context' => $self->parse_context,
            $chains->{$name}->%*,
         );
}

sub has_chain_for ($self, $name) {
   return defined($name) && exists($self->chains->{$name});
}

sub chains_list ($self) { sort { $a cmp $b } keys($self->chains->%*) }

sub inflate_chains ($self) {
   $self->_chain_for($_) for $self->chains_list;
   return $self;
}

sub overlay_cloak ($self, $data, %opts) {
   return Data::Annotation::Overlay->new(under => $data, %opts);
}

sub evaluate ($self, $chain, $data) {
   $chain = $self->default_chain unless $self->has_chain_for($chain);

   # cloak the input $data with an Overlay, unless it's already an
   # overlay in which case it's used directly
   $data = $self->overlay_cloak($data,
      value_if_missing => '',
      value_if_undef   => '',
   ) unless blessed($data) && $data->isa('Data::Annotation::Overlay');

   my @call_sequence;

   my $wrapped = sub ($name) {
      my @stack;
      push @stack, { name => $name, state => {} }
         if $self->has_chain_for($name);
      while (@stack) {
         my $frame = $stack[-1];

         my $call = { chain => $frame->{name} };
         push @call_sequence, $call;

         my $chain = $self->_chain_for($frame->{name});
         my ($outcome, $rname) = $chain->evaluate($frame->{state}, $data);
         $call->{outcome} = $outcome;
         $call->{rule} = defined($rname) ? "($rname)" : '';

         if (! defined($outcome)) {
            $call->{next} = 'pop';
            pop(@stack);
            next;
         }

         # see if there's a result, either implicit or explicit
         if (ref($outcome) ne 'HASH') {
            return $outcome;
         }
         if (exists($outcome->{result})) {
            return $outcome->{result};
         }

         # no result so far, we either have to goto or to call another rule
         my $name;
         if (defined($outcome->{goto})) {
            $name = $outcome->{goto};
            pop(@stack);
         }
         elsif (defined($outcome->{call})) {
            $name = $outcome->{call};
         }
         else {
            ouch 400, 'cannot process hash outcome, no result/goto/call';
         }
         push(@stack, { name => $name, state => {} });
      }

      # if we get here, no chain had a response so we use the default one
      my $retval = $self->default_retval;
      push @call_sequence,
         {
            initial_chain => $name,
            note  => 'return default',
            outcome => $retval,
         };
      return $retval;
   };

   my $retval = try { $wrapped->($chain) }
      catch {
         my $call = $call_sequence[-1];
         $call->{outcome} = undef;
         $call->{next}  = 'abort';
         $call->{error} = bleep();
         ouch 400, 'evaluation error', \@call_sequence;
      };

   return ($retval, $data, \@call_sequence) if wantarray;
   return $retval;
}

1;
