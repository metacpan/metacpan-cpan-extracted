=pod

=head1 NAME

App::WRT::MethodSpit - quickie method generation

=head1 SYNOPSIS

    # In Foo.pm:
    package Foo;
    use base 'App::WRT::MethodSpit';

    %default = (
      baz => 'bar,
      biz => 'buz'
    );

    # Set up accessor methods:
    __PACKAGE__->methodspit( keys %default );

    sub new {
      my $class = shift;
      my %params = @_;

      my %copy_of_default = %default;
      my $self = \%copy_of_default;
      bless $self, $class;

      $self->configure(%params);

      return $self;
    }

    # In calling code:
    $obj = Foo->new(
      baz => 'waffle'
    );
    say $obj->baz; # waffle
    say $obj->biz; # buz

=head1 DESCRIPTION

Cheap method generation, in place of using Class::Accessor or Object::Tiny.

Kind of stupid.

=cut

package App::WRT::MethodSpit;

use strict;
use warnings;
no  warnings 'uninitialized';

sub methodspit {
  my ($class, @names) = @_;

  # These are simple accessors.
  foreach my $name (@names) {
    makemethod($class, $name);
  }

  return;
}

# Handy-dandy basic closure:
sub makemethod {
  my ($class, $name) = @_;

  no strict 'refs';

  # Install a generated sub:
  *{ "${class}::${name}" } =
  sub {
    my ($self, $param) = @_;
    $self->{$name} = $param if defined $param;
    return $self->{$name};
  }
}

sub methodspit_depend {
  my ($class, $dependency, $names) = @_;

  my %names = %{ $names };

  foreach my $name (keys %names) {
    my $default = $names{$name};
    makemethod_depend($class, $dependency, $name, $default);
  }
}

# A more complicated closure.  Makes a return value dependent on another
# method, if not already explicitly defined.

sub makemethod_depend {
  my ($class, $dependency, $name, $default) = @_;

  no strict 'refs';

  *{ "${class}::${name}" } =
  sub {
    my ($self, $param) = @_;

    if (defined $param) {
      $self->{$name} = $param;
    }

    if (defined $self->{$name}) {
      return $self->{$name};
    } else {
      return $self->$dependency . $default;
    }
  }
}

# Set specified parameters:

sub configure {
  my $self = shift;
  my %params = @_;

  for my $p (keys %params) {
    $self->{$p} = $params{$p};
  }

  return;
}

1;
