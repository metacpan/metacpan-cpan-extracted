package Data::Collector::Info;
{
  $Data::Collector::Info::VERSION = '0.15';
}
# ABSTRACT: A base class for information classes

use Moose;
use namespace::autoclean;

use Carp;
use Set::Object;
use List::Util 'first';

has 'raw_data' => ( is => 'rw', isa => 'Str', lazy_build => 1 );
has 'engine'   => ( is => 'ro', isa => 'Object' );

my $REGISTRY     = Set::Object->new();
my $INFO_MODULES = Set::Object->new();

sub register {
    my $class = shift;
    my @keys  = @_;

    foreach my $key (@keys) {
        if ( first { $key eq $_ } $REGISTRY->members ) {
            croak "Sorry, key already reserved\n" .
                  'Is it possible you\'re collecting twice?';
        }

        $REGISTRY->insert($key);
    }
}

sub unregister {
    my @keys = @_;
    $REGISTRY->remove($_) for @keys;
}

sub clear_registry { $REGISTRY = Set::Object->new }

# overridable method
sub load      {1}
sub info_keys { die 'No default info_keys method' }
sub all       { die 'No default all method'       }

sub BUILD {
    my $self      = shift;
    my $class     = ref $self;
    my $contained = $INFO_MODULES->contains($class);

    if ( ! $contained ) {
        $INFO_MODULES->insert($class);

        my $keys = $self->info_keys;
        ref $keys eq 'ARRAY' and Data::Collector::Info->register( @{$keys} );

        $self->load();
    }
}

__PACKAGE__->meta->make_immutable;
1;



=pod

=head1 NAME

Data::Collector::Info - A base class for information classes

=head1 VERSION

version 0.15

=head1 SYNOPSIS

    package Data::Collector::Info::Bamba;
    use Moose;
    extends 'Data::Collector::Info';

    sub info_keys { ['bamba'] }

    sub _build_raw_data {
        my $self   = shift;
        my $engine = $self->engine;

        return $engine->run(/usr/bin/bamba-counter);
    }

    sub all {
        my $self = shift;
        return $self->raw_data;
    }

This synopsis shows how to create your own piece of info (in this case it counts
bambas (which is a peanut snack).

=head1 REGISTRY

Since all info modules return values which are all gathered in a single hash,
they might step on each other's toes. In order to avoid this, there is a
registry that keeps all the keys from each info module. If you create an info
module, you should register your keys in the registry. This is best done while
subclassing the C<load> method as shown in the synopsis.

=head1 ATTRIBUTES

=head2 raw_data

This contains the data received from the engine. You should implement a builder
for it under the name C<_build_raw_data>.

=head2 engine

This contains the object of the engine the info module would be using to fetch
information. This is set by L<Data::Collector> on initialize.

=head1 SUBROUTINES/METHODS

=head2 register

This method registers keys in the registry. You can provide as many as you want.

It should be called using the class, not any object, as such:

    Data::Collector::Info->register('bamba_count');

Now if anyone else will try to register another key (such as another bamba
module), L<Data::Collector::Info> will prevent it from happening.

=head2 unregister

This method can be used to remove keys from the registry. However, B<refrain>
from using this method in order to provide two collections. The reason is that
there is still a boolean in L<Data::Collector> that will stll prevent you from
running another collection.

=head2 clear_registry

This method ostensibly clears all keys from the registry. In actuality, it
simply replaces the existing registry with a new one.

=head2 info_keys

This method will run before an information module is loaded. You should subclass
this method to indicate what keys you're going to acquire.

Any type of data other than an arrayref will be ignored.

You B<must> subclass this method or your code will C<die>.

=head2 load

This method will run when an information module is loaded. You should subclass
this method if you're writing an info module that requires some extra bells
and whistles you could use this method.

However, you do not have to subclass it.

=head2 all

This method is run to get all the information attainable by the info module.

If you have several bits of information in your module, you can have methods
for each, but they should all be attainable using the C<all> method.

You B<must> subclass this method or your code will C<die>.

=head2 BUILD

This is a L<Moose> method which is done after module initialization. It's set
to run the C<load> method of the module. However, if you wish to do something
else, you could subclass it.

Unless you're pulling off something especially fancy, subclass the L<load>
and use that instead - for the sake of clarity if not anything else.

=head1 AUTHOR

Sawyer X <xsawyerx@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

