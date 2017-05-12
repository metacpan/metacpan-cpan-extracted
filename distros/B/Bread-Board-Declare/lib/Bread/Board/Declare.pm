package Bread::Board::Declare;
BEGIN {
  $Bread::Board::Declare::AUTHORITY = 'cpan:DOY';
}
{
  $Bread::Board::Declare::VERSION = '0.16';
}
use Moose::Exporter;
# ABSTRACT: create Bread::Board containers as normal Moose objects

use Bread::Board ();


my (undef, undef, $init_meta) = Moose::Exporter->build_import_methods(
    as_is => ['dep'],
    install => ['import', 'unimport'],
    class_metaroles => {
        attribute => ['Bread::Board::Declare::Meta::Role::Attribute'],
        class     => ['Bread::Board::Declare::Meta::Role::Class'],
        instance  => ['Bread::Board::Declare::Meta::Role::Instance'],
    },
    role_metaroles => {
        applied_attribute => ['Bread::Board::Declare::Meta::Role::Attribute'],
    },
    base_class_roles => ['Bread::Board::Declare::Role::Object'],
);

sub init_meta {
    my $package = shift;
    my %options = @_;
    if (my $meta = Class::MOP::class_of($options{for_class})) {
        if ($meta->isa('Class::MOP::Class')) {
            my @supers = $meta->superclasses;
            $meta->superclasses('Bread::Board::Container')
                if @supers == 1 && $supers[0] eq 'Moose::Object';
        }
    }
    $package->$init_meta(%options);
}


sub dep {
    if (@_ > 1) {
        my %opts = (
            name => '__ANON__',
            @_,
        );

        if (exists $opts{dependencies}) {
            confess("Dependencies are not supported for inline services");
        }

        if (exists $opts{value}) {
            return Bread::Board::Literal->new(%opts);
        }
        elsif (exists $opts{block}) {
            return Bread::Board::BlockInjection->new(%opts);
        }
        elsif (exists $opts{class}) {
            return Bread::Board::ConstructorInjection->new(%opts);
        }
        else {
        }
    }
    else {
        return Bread::Board::Dependency->new(service_path => $_[0]);
    }
}


1;

__END__

=pod

=head1 NAME

Bread::Board::Declare - create Bread::Board containers as normal Moose objects

=head1 VERSION

version 0.16

=head1 SYNOPSIS

  package MyApp;
  use Moose;
  use Bread::Board::Declare;

  has dsn => (
      is    => 'ro',
      isa   => 'Str',
      value => 'dbi:mysql:my_db',
  );

  has dbic => (
      is           => 'ro',
      isa          => 'MyApp::Model::DBIC',
      dependencies => ['dsn'],
      lifecycle    => 'Singleton',
  );

  has tt => (
      is  => 'ro',
      isa => 'MyApp::View::TT',
      dependencies => {
          template_root => dep(value => './root/templates'),
      },
  );

  has controller => (
      is           => 'ro',
      isa          => 'MyApp::Controller',
      dependencies => {
          model => 'dbic',
          view  => 'tt',
      },
  );

  MyApp->new->controller; # new controller object with new model and view
  MyApp->new(
      model => MyApp::Model::KiokuDB->new,
  )->controller; # new controller object with new view and kioku model

=head1 DESCRIPTION

This module is a L<Moose> extension which allows for declaring L<Bread::Board>
container classes in a more straightforward and natural way. It sets up
L<Bread::Board::Container> as the superclass, and creates services associated
with each attribute that you create, according to these rules:

=over 4

=item

If the C<< service => 0 >> option is passed to C<has>, no service is created.

=item

If the C<value> option is passed to C<has>, a L<Bread::Board::Literal>
service is created, with the given value.

=item

If the C<block> option is passed to C<has>, a L<Bread::Board::BlockInjection>
service is created, with the given coderef as the block. In addition to
receiving the service object (as happens in Bread::Board), this coderef will
also be passed the container object.

=item

If the attribute has a type constraint corresponding to a class, a
L<Bread::Board::ConstructorInjection> service is created, with the class
corresponding to the type constraint.

=item

Otherwise, a BlockInjection service is created which throws an exception. This allows services to be created for the sole purpose of being set through the attribute, without requiring a default to be specified. Note that
C<< required => 1 >> is still valid on these attributes.

=back

Constructor parameters for services (C<dependencies>, C<lifecycle>, etc) can
also be passed into the attribute definition; these will be forwarded to the
service constructor. See
L<Bread::Board::Declare::Meta::Role::Attribute::Service> for a full list of
additional parameters to C<has>.

If C<< infer => 1 >> is passed in the attribute definition, the class in the
type constraint will be introspected to find its required dependencies, and
those dependencies will be automatically fulfilled as much as possible by
corresponding services in the container. See
L<Bread::Board::Manual::Concepts::Typemap> for more information.

In addition to creating the services, this module also modifies the attribute
reader generation, so that if the attribute has no value, a value will be
resolved from the associated service. It also modifies the C<get> method on
services so that if the associated attribute has a value, that value will be
returned immediately. This allows for overriding service values by passing
replacement values into the constructor, or by calling setter methods.

Note that C<default>/C<builder> doesn't make a lot of sense in this setting, so
they are explicitly disabled. In addition, multiple inheritance would just
cause a lot of problems, so it is also disabled (although single inheritance
and role application works properly).

=head1 EXPORTS

=head2 dep

  dependencies => {
      foo => dep('foo'),
      bar => dep(value => 'bar'),
  }

This is a helper function for specifying dependency lists. Passing a single
argument will explicitly mark it as a dependency to be resolved by looking it
up in the container. This isn't strictly necessary (the dependency
specifications for L<Bread::Board> have a coercion which does this
automatically), but being explicit can be easier to understand at times.

This function can also take a hash of arguments. In that case, an anonymous
service is created to satisfy the dependency. The hash is passed directly to
the constructor for the appropriate service: if the C<value> parameter is
passed, a L<Bread::Board::Literal> service will be created, if the C<block>
parameter is passed, a L<Bread::Board::BlockInjection> service will be created,
and if the C<class> parameter is passed, a
L<Bread::Board::ConstructorInjection> service will be created. Note that these
anonymous services cannot have dependencies themselves, nor can they be
depended on by other services.

=head1 BUGS

No known bugs.

Please report any bugs to GitHub Issues at
L<https://github.com/doy/bread-board-declare/issues>.

=head1 SEE ALSO

L<Bread::Board>

=head1 SUPPORT

You can find this documentation for this module with the perldoc command.

    perldoc Bread::Board::Declare

You can also look for information at:

=over 4

=item * MetaCPAN

L<https://metacpan.org/release/Bread-Board-Declare>

=item * Github

L<https://github.com/doy/bread-board-declare>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Bread-Board-Declare>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Bread-Board-Declare>

=back

=for Pod::Coverage init_meta

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut
