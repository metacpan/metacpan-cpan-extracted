package App::Benchmark::Accessors;
use strict;
use warnings;
our $VERSION = '2.00';

#<<<
package    # hide from PAUSE
  WithMoose;
use Moose;
has myattr => ( is => 'rw' );

package    # hide from PAUSE
  WithMooseImmutable;
use Moose;
has myattr => ( is => 'rw' );
__PACKAGE__->meta->make_immutable;

package    # hide from PAUSE
  WithMouse;
use Mouse;
has myattr => ( is => 'rw' );

package    # hide from PAUSE
  WithMouseImmutable;
use Mouse;
has myattr => ( is => 'rw' );
__PACKAGE__->meta->make_immutable;

package    # hide from PAUSE
  WithClassAccessor;
use parent qw(Class::Accessor);
__PACKAGE__->mk_accessors(qw/myattr/);

package    # hide from PAUSE
  WithClassAccessorFast;
use parent qw(Class::Accessor::Fast);
__PACKAGE__->mk_accessors(qw/myattr/);

package    # hide from PAUSE
  WithClassAccessorFastXS;
use parent qw(Class::Accessor::Fast::XS);
__PACKAGE__->mk_accessors(qw/myattr/);

package    # hide from PAUSE
  WithClassXSAccessorCompat;
use parent qw(Class::XSAccessor::Compat);
__PACKAGE__->mk_accessors(qw/myattr/);

package    # hide from PAUSE
  WithClassAccessorComplex;
use parent qw(Class::Accessor::Complex);
__PACKAGE__->mk_new->mk_scalar_accessors(qw/myattr/);

package    # hide from PAUSE
  WithClassAccessorConstructor;
use parent qw(Class::Accessor::Constructor Class::Accessor::Complex);
__PACKAGE__->mk_constructor->mk_scalar_accessors(qw/myattr/);

package    # hide from PAUSE
  WithClassAccessorClassy;
use Class::Accessor::Classy;
with 'new';
rw 'myattr';
no  Class::Accessor::Classy;

package    # hide from PAUSE
  WithClassAccessorLite;
use Class::Accessor::Lite new => 1, rw => [qw(myattr)];

package    # hide from PAUSE
  WithMojo;
use parent qw(Mojo::Base);
__PACKAGE__->attr('myattr');

package    # hide from PAUSE
  WithClassMethodMaker;
use Class::MethodMaker
    [ scalar => [ qw/myattr/ ],
      new    => [ qw/-hash new/ ],
    ];

package    # hide from PAUSE
  WithObjectTiny;
use Object::Tiny qw/myattr/;

package    # hide from PAUSE
  WithSpiffy;
use Spiffy -base;
field 'myattr';

package    # hide from PAUSE
  WithClassSpiffy;
use Class::Spiffy -base;
field 'myattr';

package    # hide from PAUSE
  WithAccessors;
use accessors qw(myattr);
sub new { bless {}, shift }

package    # hide from PAUSE
  WithClassXSAccessor;
use Class::XSAccessor accessors => { myattr => 'myattr' };
sub new {
    my $class = shift;
    bless { @_ } => $class;
}

package    # hide from PAUSE
  WithClassXSAccessorArray;
use Class::XSAccessor::Array accessors => { myattr => 0 };
sub new {
    my $class = shift;
    my %args = @_;
    bless [ $args{myattr} ] => $class;
}

package    # hide from PAUSE
  WithObjectTinyXS;
use Object::Tiny qw/myattr/;
use Class::XSAccessor accessors => { myattr => 'myattr' }, replace => 1;

package    # hide from PAUSE
  WithRose;
use parent qw(Rose::Object);
use Rose::Object::MakeMethods::Generic(scalar => 'myattr');

#package    # hide from PAUSE
#  WithBadgerClass;
#use Badger::Class
#    base     => 'Badger::Base',
#    mutators => 'myattr';

package    # hide from PAUSE
  WithRubyishAttribute;
use Rubyish::Attribute;
sub new { bless {}, shift }

attr_accessor "myattr";
#>>>
1;

__END__

=head1 NAME

App::Benchmark::Accessors - Benchmark accessor generators

=head1 DESCRIPTION

This distribution runs benchmarks on various accessor generators. The
following generators are being benchmarked:

=over 4

=item Moose

mutable and immutable

=item Mouse

mutable and immutable

=item Class::Accessor

=item Class::Accessor::Fast

=item Class::Accessor::Fast::XS

=item Class::XSAccessor::Compat

=item Class::Accessor::Complex

=item Class::Accessor::Constructor

=item Class::Accessor::Classy

=item Class::Accessor::Lite

=item Mojo::Base

=item Class::MethodMaker

=item Object::Tiny

=item Spiffy

=item Class::Spiffy

=item C<accessors>

=item Class::XSAccessor

=item Class::XSAccessor::Array

=item Object::Tiny

=item Rose

=item Rubyish::Attribute

=back

The benchmarks are being run as part of the test suite; see L<App::Benchmark>.
This way you can look at this distribution's CPAN testers page to see the
benchmark results on many different platforms and for many different perl
versions.

The C<t/construction.t> file benchmarks object creation, C<t/get.t> benchmarks
getter methods and C<t/set.t> benchmarks setter methods.

Not every benchmark is run on every module; for example, L<Object::Tiny>
doesn't create setter methods, and L<accessors> doesn't generate constructors.

Each benchmark test file takes an optional numeric parameter that is used as
the number of iterations.

It's probably a good idea not to read too much into these benchmarks; they
could be seen as micro-optimization. However, if you have a complex object
hierarchy and create lots of objects and run many many getters/setters on
them, they could help to save some time. But be sure to use L<Devel::NYTProf>
first to see where your real bottlenecks are.

=head1 AUTHORS

The following person is the author of all the files provided in
this distribution unless explicitly noted otherwise.

Marcel Gruenauer C<< <marcel@cpan.org> >>, L<http://marcelgruenauer.com>

=head1 COPYRIGHT AND LICENSE

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

