package Bot::Cobalt::Core::Role::Singleton;
$Bot::Cobalt::Core::Role::Singleton::VERSION = '0.021003';
use Carp 'confess';
use strictures 2;

use Moo::Role;

no strict 'refs';

sub instance {
  my $class = $_[0];

  my $this_obj = \${$class.'::_singleton'};
  
  defined $$this_obj ? $$this_obj
    : ( $$this_obj = $class->new(@_[1 .. $#_]) )
}

sub has_instance {
  my $class = ref $_[0] || $_[0];
  !! ${$class.'::_singleton'};
}

sub clear_instance {
  my $class = ref $_[0] || $_[0];
  ${$class.'::_singleton'} = undef;
  1
}

sub is_instanced {
  confess "is_instanced is deprecated; use has_instance"
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Core::Role::Singleton

=head1 SYNOPSIS

  package MySingleton;
  use Moo;  
  with 'Bot::Cobalt::Core::Role::Singleton';

=head1 DESCRIPTION

A basic L<Moo::Role> implementing singletons for L<Bot::Cobalt>.

A singleton is a class that can only be instanced once.

Classes can consume this Role in order to gain the following methods:

=head2 instance

The instance method returns the existing singleton if there is one, or 
calls B<new> to create one if not. Consumers should be instanced by 
calling B<instance> rather than B<new>:

  ## Bot::Cobalt::Core is a singleton:
  my $core = Bot::Cobalt::Core->instance(
    cfg => Bot::Cobalt::Conf->new(etc => $etc),
    var => $var,
  );

Arguments are passed to B<new()> unmodified (if we are creating a new 
singleton).

=head2 has_instance

Returns boolean false if there is currently no instance.

=head2 clear_instance

Clear the singleton instance.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

(Essentially the same as other singleton implementations such as 
L<Class::Singleton>, L<MooseX::Singleton>, L<MooX::Singleton> etc)

=cut
