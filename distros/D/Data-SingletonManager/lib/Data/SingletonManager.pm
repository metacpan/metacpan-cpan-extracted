=head1 NAME

Data::SingletonManager - return/set/clear instances of singletons identified by keys in different namespaces.

=head1 SYNOPSIS

  package My::Object;
  sub instance {
      my %args;
      ...
      my $key = "$args{userid}-$args{object_id}";
      return Data::SingletonManager->instance(
          namespace => __PACKAGE__,    # default; may omit.
          key => $key,
          creator => sub {
              return __PACKAGE__->new_instance($args{userid},
                                               $args{object_id});
          }
      );
  }

  package main;

  # return all singletons loaded in a namespace:
  @loaded_objs = Data::SingletonManager->instances("My::Object");

  # clear all singletons, in all packages (perhaps on new web request)
  Data::SingletonManager->clear_all;

  # clear all singletons in one namespace
  Data::SingletonManager->clear("My::Object");

=head1 DESCRIPTION

This is a small utility class to help manage multiple keyed singletons
in multiple namespaces.  It is not a base class so you can drop it into
any of your classes without namespace clashes with methods you might
already have, like "new", "instance", "new_instance", etc.

=head1 PACKAGE METHODS

All methods below are package methods.  There are no instance methods.

=over

=cut


############################################################################

package Data::SingletonManager;
use strict;
use Carp qw(croak);
use vars qw($VERSION);
$VERSION = "1.00";

my %data;  # namespace -> key -> value

=item instance(%args)

Package method to return (or create and save) a keyed instance where %args are:

=over

=item "namespace"

defaults to the calling package

=item "key"

scalar key for instance.  the (namespace, key) uniquely identifies an instance

=item "creator"

subref to return the instance if it doesn't already exist

=back

=cut

sub instance {
    my $class = shift;

    my %args = @_;

    my $ns  = delete $args{namespace} || _calling_package();

    my $key = delete $args{key} or
	croak "Argument 'key' required.";

    my $creator = delete $args{creator} or
	croak "Argument 'creator' required.";
    
    croak "Unknown argument(s): " . join(", ", keys %args) if %args;

    # return instance if we have it, else set it
    return $data{$ns}{$key} ||= $creator->();
}

############################################################################

=item instances([ $namespace ])

Return an array of all loaded instances in a namespace, which defaults
to the calling namespace if no namespace is given.

=cut

sub instances {
    my $class = shift;
    my $ns = shift || _calling_package();
    return () unless $data{$ns};
    return values %{ $data{$ns} };
}

############################################################################

=item clear([ $namespace ])

Clears all instances in a namespace, which defaults to the calling
namespace if no namespace is given.

=cut

sub clear {
    my $class = shift;
    my $ns = shift || _calling_package();
    delete $data{$ns};
}

############################################################################

=item clear_all

Clears all instances in all namespaces.

=cut

sub clear_all {
    %data = ();
}


############################################################################
#   Utility methods
############################################################################

sub _calling_package {
    my $i = 0;
    while (my ($pkg) = caller($i++)) {
	next if $pkg eq __PACKAGE__;
	return $pkg;
    }
    die;
}

############################################################################

=head1 AUTHORS

Brad Fitzpatrick <brad@danga.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Six Apart, Ltd.

License is granted to use and distribute this module under the same
terms as Perl itself.

=cut

1;
