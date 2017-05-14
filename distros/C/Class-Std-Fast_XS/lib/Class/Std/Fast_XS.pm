package Class::Std::Fast_XS;

use strict;
use warnings;

use base qw(DynaLoader);

our $VESION = 0.3;

my $do_cache_class_ref;

BEGIN {
    bootstrap Class::Std::Fast_XS 0.3;

    require Class::Std::Fast;

    my $attributes_of_ref = {};
    $do_cache_class_ref = Class::Std::Fast::_cache_class_ref();

    Class::Std::Fast_XS::init(
        $attributes_of_ref,
        Class::Std::Fast::_attribute_ref(),
        $do_cache_class_ref,
        Class::Std::Fast::OBJECT_CACHE_REF(),
    );

    no warnings qw(redefine);

    *Class::Std::Fast::__create_getter = sub {
        # my ($package, $referent, $name) = @_;
        $attributes_of_ref->{ "$_[0]::$_[2]" } ||= $_[1];
        newxs_getter("$_[0]::get_$_[2]", "$_[0]::$_[2]")
    };

    *Class::Std::Fast::__create_setter = sub {
        # my ($package, $referent, $name) = @_;
        $attributes_of_ref->{ "$_[0]::$_[2]" } ||= $_[1];
        newxs_setter("$_[0]::set_$_[2]", "$_[0]::$_[2]")
    };

    *Class::Std::Fast::DESTROY = \&Class::Std::Fast_XS::destroy;
}

# clean out do_cache_class hash to avoid creating references
# during global destruction
sub END {
    %{ $do_cache_class_ref } = ();
}

1;

__END__

=pod

=head1 NAME

Class::Std::Fast_XS - speed up Class::Std::Fast by adding some XS code

=head1 SYNOPSIS

 use Class::Std::Fast_XS

=head1 DESCRIPTION

Speeds up Class::Std::Fast by replacing it's accessors/mutators and DESTROY
method by XS variants.

The speed gain varies by platform:

Using perl 5.8.8 on Ubuntu 8.04 (32bit) Linux, the measured speed gain
is around 7.5% for accessors (getters) and around 35% for mutators
(setters). DESTROY was around 220% faster on this platform.

On a RHEL 5.0 box (64bit) with perl-5.8.8 the speed gain is around
40% for getters and around 60% for setters.

The speed gain on ActivePerl 5.8.8 (822) on Windows XP built with
MinGW/MSYS/gcc is around 45%

ActivePerl 5.10 (1001) on Windows XP yielded around 30% for accessors
and 50% for mutators.

=head1 USAGE

All you have to do is to require this module before you load/create
Class::Std::Fast- based classes. More precisely, all Class::Std::Fast-based
attributes (:ATTR) after loading Class::Std::Fast_XS will be affected.

If you're running a mod_perl environment, you should probably load
C<Class::Std::Fast_XS> from your apache config or your startup.pl.

=head1 BUGS AND LIMITATIONS

=over

=item * Loading

Only attributes detected after loading are affected.

Only classes created after loading are affected by DESTROY

=item * No object cache

Class::Std::Fast's DESTROY does not support Class::Std::Fast's object cache
yet. This does not mean that classing using the object_cache facility don't
work, it just means that the object_cache has no effect yet.

=back

=head1 ACKNOWLEDGEMENTS

Based on L<Class::XSAccessor|Class::XSAccessor> and L<AutoXS> by Steffen ME<uuml>ller.

=head1 LICENSE AND COPYRIGHT

Copyright 2008 Martin Kutter.

This library is free software. You may distribute/modify it under
the same terms as perl itself

=head1 AUTHOR

Martin Kutter E<lt>martin.kutter fen-net.deE<gt>

=head1 REPOSITORY INFORMATION

 $Rev: 468 $
 $LastChangedBy: kutterma $
 $Id: Fast_XS.pm 468 2008-05-21 19:29:31Z kutterma $
 $HeadURL: http://svn.hyper-framework.org/Hyper/Class-Std-Fast_XS/trunk/lib/Class/Std/Fast_XS.pm $

=cut
