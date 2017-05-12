use 5.008;
use warnings;
use strict;

package Class::Scaffold::Base;
BEGIN {
  $Class::Scaffold::Base::VERSION = '1.102280';
}

# ABSTRACT: Base class for all classes of the class framework.
use Data::Miscellany 'set_push';
use Error::Hierarchy::Util 'load_class';
use parent qw/
  Data::Inherited
  Data::Comparable
  Error::Hierarchy::Mixin
  Class::Scaffold::Delegate::Mixin
  Class::Scaffold::Accessor
  Class::Scaffold::Factory::Type
  /;

# We subclass Class::Scaffold::Factory::Type so objects can introspect to see
# which object type they are.
__PACKAGE__->mk_constructor;

# so every_hash has something to fall back to:
sub FIRST_CONSTRUCTOR_ARGS { () }

# so everyone can call SUPER:: without worries, just pass through the args:
sub MUNGE_CONSTRUCTOR_ARGS {
    my $self = shift;
    @_;
}
sub init { 1 }

# Convenience method so subclasses don't need to say
#
#   use Class::Scaffold::Log;
#   my $log = Class::Scaffold::Log;
#   $log->info(...);
#
# or
#
#   Class::Scaffold::Log->debug(...);
#
# but can say
#
#   $self->log->info(...);
#
# Eliminating fixed package names is also a way of decoupling; later on we
# might choose to get the log from the delegate or anywhere else, in which
# case we can make the change in one location - here.
#
# Class::Scaffold::Log inherits from this class, so we don't use() it but
# require() it, to avoid 'redefined' warnings.
sub log {
    my $self = shift;
    require Class::Scaffold::Log;
    Class::Scaffold::Log->instance;
}

# Try to load currently not loaded packages of the Class-Scaffold and other
# registered distributions and call the wanted method.
#
# Throw an exception if the package in which we have to look for the wanted
# method is already loaded (= the method doesn't exist).
sub UNIVERSAL::DESTROY { }

sub UNIVERSAL::AUTOLOAD {
    my ($pkg, $method) = ($UNIVERSAL::AUTOLOAD =~ /(.*)::(.*)/);
    local $" = '|';
    our @autoload_packages;
    unless ($pkg =~ /^(@autoload_packages)/) {

        # we don't deal with crappy external libs and
        # their problems. get lost with your symbol.
        require Carp;
        local $Carp::CarpLevel = 1;
        Carp::confess sprintf "Undefined subroutine &%s called",
          $UNIVERSAL::AUTOLOAD;
    }
    (my $key = "$pkg.pm") =~ s!::!/!g;
    local $Error::Depth = $Error::Depth + 1;
    if (exists $INC{$key}) {

        # package has been loaded already, so the method wanted
        # doesn't seem to exist.
        require Carp;
        local $Carp::CarpLevel = 1;
        Carp::confess sprintf "Undefined subroutine &%s called",
          $UNIVERSAL::AUTOLOAD;
    } else {
        load_class $pkg, 1;
        no warnings;
        if (my $coderef = UNIVERSAL::can($pkg, $method)) {
            goto &$coderef;
        } else {
            require Carp;
            local $Carp::CarpLevel = 1;
            Carp::confess sprintf "Undefined subroutine &%s called",
              $UNIVERSAL::AUTOLOAD;
        }
    }
}

sub add_autoloaded_package {
    shift if $_[0] eq __PACKAGE__;
    my $prefix = shift;
    our @autoload_packages;
    set_push @autoload_packages, $prefix;
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Base - Base class for all classes of the class framework.

=head1 VERSION

version 1.102280

=head1 DESCRIPTION

This is the base class for all classes of the class framework. Everything
should subclass this.

=head1 METHODS

=head2 add_autoloaded_package

This class method takes a single prefix and adds it to the list - set, really
- of packages whose methods should be autoloaded. The L<Class::Scaffold>
framework will typically be used by an application whose classes are stored in
and underneath a package namespace. To avoid having to load all classes
explicitly, you can pass the namespace to this method. This class defines a
L<UNIVERSAL::AUTOLOAD> that respects the set of classes it should autoload
methods for.

=head2 FIRST_CONSTRUCTOR_ARGS

This method is used by the constructor to order key-value pairs that are
passed to the newly created object's accessors - see
L<Class::Accessor::Constructor>. This class just defines it as an empty list;
subclasses should override it as necessary. The method exists in this class so
even if subclasses don't override it, there's something for the constructor
mechanism to work with.

=head2 MUNGE_CONSTRUCTOR_ARGS

This method is used by the constructor to munge the constructor arguments -
see L<Class::Accessor::Constructor>. This class' method just returns the
arguments as is; subclasses should override it as necessary. The method exists
in this class so even if subclasses don't override it, there's something for
the constructor mechanism to work with.

=head2 init

This method is called at the end of the constructor - see
L<Class::Accessor::Constructor>. This class' method does nothing; subclasses
should override it and wrap it with C<SUPER::> as necessary. The method exists
in this class so even if subclasses don't override it, there's something for
the constructor mechanism to work with.

=head2 log

This method acts as a shortcut to L<Class::Scaffold::Log>. Instead of writing

    use Class::Scaffold::Log;
    Class::Scaffold::Log->instance->debug('foo');

you can simply write

    $self->log->debug('foo');

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

