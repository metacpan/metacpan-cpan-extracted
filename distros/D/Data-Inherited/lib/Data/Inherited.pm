use 5.008;
use strict;
use warnings;

package Data::Inherited;
our $VERSION = '1.100860';
# ABSTRACT: Hierarchy-wide accumulation of list and hash results
use NEXT 0.64;

sub every_list {
    my ($self, $list_name, $override_cache) = @_;
    our %every_cache;
    my $pkg = ref $self || $self;    # can also be called as a class method
    my $list;
    unless ($list = $override_cache ? undef : $every_cache{$list_name}{$pkg}) {

        $list = [];
        my $call       = "EVERY::LAST::$list_name";
        my @every_list = $self->$call;
        return unless scalar @every_list;
        while (my ($class, $class_list) = splice(@every_list, 0, 2)) {
            push @$list => @$class_list;
        }
        $every_cache{$list_name}{$pkg} = $list;
    }
    wantarray ? @$list : $list;
}

sub every_hash {
    my ($self, $hash_name, $override_cache) = @_;
    our %every_cache;
    my $pkg = ref $self || $self;    # can also be called as a class method
    my $hash;
    unless ($hash = $override_cache ? undef : $every_cache{$hash_name}{$pkg}) {

        $hash = {};
        my $call       = "EVERY::LAST::$hash_name";
        my @every_hash = $self->$call;
        while (my ($class, $class_hash) = splice(@every_hash, 0, 2)) {
            %$hash = (%$hash, @$class_hash);
        }
        $every_cache{$hash_name}{$pkg} = $hash;
    }
    wantarray ? %$hash : $hash;
}

sub flush_every_cache_by_key {
    my ($self, $key) = @_;
    our %every_cache;
    delete $every_cache{$key};
}
1;


__END__
=pod

=head1 NAME

Data::Inherited - Hierarchy-wide accumulation of list and hash results

=head1 VERSION

version 1.100860

=head1 SYNOPSIS

  package Foo;
  use base 'Data::Inherited';
  use constant PROPERTIES => (qw/name address/);

  package Bar;
  use base 'Foo';
  use constant PROPERTIES => (qw/age/);

  package main;
  my $bar = Bar->new;
  print "$_\n" for $bar->every_list('PROPERTIES');

  # prints:
  #
  # name
  # address
  # age

=head1 DESCRIPTION

This is a mixin class. By inheriting from it you get two methods that are able
to accumulate hierarchy-wide list and hash results.

=head1 METHODS

=head2 every_list(String $method_name, Bool ?$override_cache = 0)

Takes as arguments a method name (mandatory) and a boolean indicating whether
to override the cache (optional, off by default)

Causes every method in the object's hierarchy with the given name to be
invoked. The resulting list is the combined set of results from all the
methods, pushed together in top-to-bottom order (hierarchy-wise).

C<every_list()> returns a list in list context and an array reference in
scalar context.

The result is cached (per calling package) and the next time the method is
called from the same package with the same method argument, the cached result
is returned. This is to speed up method calls, because internally this module
uses L<NEXT>, which is quite slow. It is expected that C<every_list()> is used
for methods returning static lists (object defaults, static class definitions
and such).  If you want to override the caching mechanism, you can provide the
optional second argument. The result is cached in any case.

See the synopsis for an example.

=head2 every_hash(String $method_name, Bool ?$override_cache = 0)

Takes as arguments a method name (mandatory) and a boolean indicating whether
to override the cache (optional, off by default)

Causes every method in the object's hierarchy with the given name to be
invoked. The resulting hash is the combined set of results from all the
methods, overlaid in top-to-bottom order (hierarchy-wise).

C<every_hash()> returns a hash in list context and a hash reference in scalar
context.

The cache and the optional cache override argument work like with
C<every_list()>.

Example:

  package Person;
  use base 'Data::Inherited';

  sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my %args = @_;
    %args = ($self->every_hash('DEFAULTS'), %args);
    $self->$_($args{$_}) for keys %args;
    $self;
  };

  sub DEFAULTS {
    first_name => 'John',
    last_name  => 'Smith',
  };

  package Employee;
  use base 'Person';

  sub DEFAULTS {
    salary => 10_000,
  }

  package LocatedEmployee;
  use base 'Employee';

  # Note: no default for address, but different salary

  sub DEFAULTS {
    salary     => 20_000,
    first_name => 'Johan',
  }

  package main;
  my $p = LocatedEmployee->new;

  # salary: 20000
  # first_name: Johan
  # last_name: Smith

=head2 flush_every_cache_by_key(String $key)

Deletes the cache entry for the given key.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Inherited>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Inherited/>.

The development version lives at
L<http://github.com/hanekomu/Data-Inherited/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

