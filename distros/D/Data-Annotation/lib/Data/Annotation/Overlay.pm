package Data::Annotation::Overlay;
use v5.24;
use utf8;
use Moo;
use experimental qw< signatures >;
use Ouch qw< :trytiny_var >;
use Scalar::Util qw< blessed >;
use Data::Annotation::Traverse qw< :all >;
use namespace::clean;

has under => (is => 'ro', required => 1);
has over  => (is => 'ro', default => sub { return {} });
has traverse_methods => (is => 'ro', default => 1);
has strict_blessed   => (is => 'ro', default => 0);
has method_over_key  => (is => 'ro', default => 1);
has value_if_missing => (is => 'ro', predicate => 1);
has value_if_undef   => (is => 'ro', predicate => 1);
has cache_existing   => (is => 'ro', default => 1);

sub delete ($self, $path) { $self->set($path, MISSING) }

sub get ($self, $path) {
   ouch 400, 'cannot get an undefined path' unless defined($path);
   my $crumbs = crumble($path);
   my $kpath  = kpath($crumbs);

   # retrieve item, first look in the overlay, then go down
   my $retval;
   my $over = $self->over;
   my $under = $self->under;
   my $under_class = blessed($under);
   if (exists($over->{$kpath})) {
      $retval = $over->{$kpath};
   }
   elsif (blessed($under) && $under->isa(__PACKAGE__)) {
      $retval = $under->get($path); # get from previous layer in stack
   }
   else {
      $retval = traverse_plain($under, $crumbs, $self->traversal_options);
      $over->{$kpath} = $retval if $self->cache_existing;
   }

   return $self->return_value_for($retval);
}

# use traversal options and return value massaging
sub get_external ($self, $path, $data) {
   ouch 400, 'cannot get an undefined path' unless defined($path);
   my $crumbs = crumble($path);
   my $retval = traverse_plain($data, $crumbs, $self->traversal_options);
   return $self->return_value_for($retval);
}

sub merged ($self) {
   my %over;
   my $cursor = $self;
   my $any_layer_does_caching = 0;
   while ('necessary') {
      $any_layer_does_caching ||= $cursor->cache_existing;
      %over = ($cursor->over->%*, %over);
      my $under = $cursor->under;
      last unless blessed($under) && $under->isa(__PACKAGE__);
      $cursor = $under;
   }
   # now $cursor points to the bottom of the stack
   return $self->new(
      under            => $cursor->under,
      over             => \%over,
      traverse_methods => $cursor->traverse_methods,
      strict_blessed   => $cursor->strict_blessed,
      method_over_key  => $cursor->method_over_key,
      value_if_missing => $self->value_if_missing,
      value_if_undef   => $self->value_if_undef,
      cache_existing   => $any_layer_does_caching,
   );
}

sub return_value_for ($self, $retval) {
   if (means_missing($retval)) {
      return unless $self->has_value_if_missing;
      return $self->value_if_missing;
   }
   return $retval if defined($retval) || (! $self->has_value_if_undef);
   return $self->value_if_undef;
}

sub set ($self, $path, $value) {
   ouch 400, 'cannot set an undefined path' unless defined($path);
   $self->over->{kpath($path)} = $value;
   return $self;
}

sub traversal_options ($self) {
   return (
      traverse_methods => $self->traverse_methods,
      strict_blessed   => $self->strict_blessed,
      method_over_key  => $self->method_over_key,
   );
}

1;
