package Class::Std::Fast::Storable;

use version; $VERSION = qv('0.0.8');
use strict;
use warnings;
use Carp;
use Storable;

BEGIN {
    require Class::Std::Fast;
}

my $attributes_of_ref = {};
my @exported_subs = qw(
    Class::Std::Fast::ident
    Class::Std::Fast::DESTROY
    Class::Std::Fast::MODIFY_CODE_ATTRIBUTES
    Class::Std::Fast::AUTOLOAD
    Class::Std::Fast::_DUMP
    STORABLE_freeze
    STORABLE_thaw
    MODIFY_HASH_ATTRIBUTES
);

sub import {
    my $caller_package = caller;

    my %flags = (@_>=3)
            ? @_[1..$#_]
            : (@_==2) && $_[1] >=2
                ? ( constructor =>  'basic', cache => 0 )
                : ( constructor => 'normal', cache => 0);
    $flags{cache} = 0 if not defined $flags{cache};
    $flags{constructor} = 'normal' if not defined $flags{constructor};

    Class::Std::Fast::_init_import(
        $caller_package, %flags
    );

    no strict qw(refs);
    for my $name ( @exported_subs ) {
        my ($sub_name) = $name =~ m{(\w+)\z}xms;
        *{ $caller_package . '::' . $sub_name } = \&{$name};
    }
}

sub MODIFY_HASH_ATTRIBUTES {
    my $caller_package = $_[0];
    my @unhandled      = Class::Std::Fast::MODIFY_HASH_ATTRIBUTES(@_);
    my $i              = 0;
    $attributes_of_ref->{$caller_package} = {
        map {
            $_->{name} eq '????' ? '????_' . $i++ : $_->{name}
                => $_->{ref};
        } @{Class::Std::Fast::_get_internal_attributes($caller_package) || []}
    };
    return @unhandled;
}

# It's a constant - so there's no use creating it in each freeze again
my $FROZEN_ANON_SCALAR = Storable::freeze(\(my $anon_scalar));

sub STORABLE_freeze {
    # TODO do we really need to unpack @_? We're getting called for
    # Zillions of objects...
    my($self, $cloning) = @_;
    Class::Std::Fast::real_can($self, 'STORABLE_freeze_pre')
        && $self->STORABLE_freeze_pre($cloning);

    my %frozen_attr; #to be constructed
    my $id           = ${$self};
    my @package_list = ref $self;
    my %package_seen = ( $package_list[0]  => 1 ); # ignore diamond/looped base classes :-)

    no strict qw(refs);

    PACKAGE:
    while( my $package = shift @package_list) {
        #make sure we add any base classes to the list of
        #packages to examine for attributes.

        # Original line:
        # push @package_list, grep { ! $package_seen{$_}++; } @{"${package}::ISA"};
        # This one's faster...
        push @package_list, grep { ! exists $package_seen{$_} && do { $package_seen{$_} = undef; 1; } } @{"${package}::ISA"};

        #look for any attributes of this object for this package
        my $attr_ref = $attributes_of_ref->{$package} or next PACKAGE;

        # TODO replace inner my variable by $_ - faster...
        ATTR:              # examine attributes from known packages only
        for ( keys %{$attr_ref} ) {
            #nothing to do if attr not set for this object
            exists $attr_ref->{$_}{$id}
                and $frozen_attr{$package}{ $_ } = $attr_ref->{$_}{$id}; # save the attr by name into the package hash
        }
    }
    Class::Std::Fast::real_can($self, 'STORABLE_freeze_post')
        && $self->STORABLE_freeze_post($cloning, \%frozen_attr);

    return ($FROZEN_ANON_SCALAR, \%frozen_attr);
}

sub STORABLE_thaw {
    # croak "must be called from Storable" unless caller eq 'Storable';
    # unfortunately, Storable never appears on the call stack.

    # TODO do we really need to unpack @_? We're getting called for
    # zillions of objects...
    my $self = shift;
    my $cloning = shift;
    my $frozen_attr_ref = $_[1]; # $_[0] is the frozen anon scalar.

    Class::Std::Fast::real_can($self, 'STORABLE_thaw_pre')
        && $self->STORABLE_thaw_pre($cloning, $frozen_attr_ref);

    my $id = ${$self} ||= Class::Std::Fast::ID();

    PACKAGE:
    while( my ($package, $pkg_attr_ref) = each %{$frozen_attr_ref} ) {
        # TODO This test is quite expensive. Is there a better one?
        $self->isa($package)
            or croak "unknown base class '$package' seen while thawing "
                   . ref $self;
        ATTR:
        for ( keys  %{$attributes_of_ref->{$package}} ) {
            # for known attrs...
            # nothing to do if frozen attr doesn't exist
            exists $pkg_attr_ref->{$_} or next ATTR;

            # block attempts to meddle with existing objects
            exists $attributes_of_ref->{$package}->{$_}->{$id}
                and croak "trying to modify existing attributes for $package";

            # ok, set the attribute
            $attributes_of_ref->{$package}->{$_}->{$id}
                = delete $pkg_attr_ref->{$_};
        }
        # this is probably serious enough to throw an exception.
        # however, TODO: it would be nice if the class could somehow
        # indicate to ignore this problem.
        %$pkg_attr_ref
        and croak "unknown attribute(s) seen while thawing class $package:"
                     . join q{, }, keys %$pkg_attr_ref;
    }

    Class::Std::Fast::real_can($self, 'STORABLE_thaw_post')
        && $self->STORABLE_thaw_post($cloning);
}

1;

__END__

=pod

=head1 NAME

Class::Std::Fast::Storable - Fast Storable InsideOut objects

=head1 VERSION

This document describes Class::Std::Fast::Storable 0.0.8

=head1 SYNOPSIS

    package MyClass;

    use Class::Std::Fast::Storable;

    1;

    package main;

    use Storable qw(freeze thaw);

    my $thawn = freeze(thaw(MyClass->new()));

=head1 DESCRIPTION

Class::Std::Fast::Storable does the same as Class::Std::Storable
does for Class::Std. The API is the same as Class::Std::Storable's, with
few exceptions.

=head1 SUBROUTINES/METHODS

=head2 STORABLE_freeze

see method Class::Std::Storable::STORABLE_freeze

=head2 STORABLE_thaw

see method Class::Std::Storable::STORABLE_thaw

=head1 DIAGNOSTICS

see L<Class::Std>

and

see L<Class::Std::Storable>

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item *

L<version>

=item *

L<Class::Std>

=item *

L<Carp>

=back

=head1 INCOMPATIBILITIES

STORABLE_freeze_pre, STORABLE_freeze_post, STORABLE_thaw_pre and
STORABLE_thaw_post must not be implemented as AUTOMETHOD.

see L<Class::Std> and L<Class::Std::Storable>

=head1 BUGS AND LIMITATIONS

see L<Class::Std> and L<Class::Std::Storable>

=head1 RCS INFORMATIONS

=over

=item Last changed by

$Author: ac0v $

=item Id

$Id: Storable.pm 469 2008-05-26 11:26:35Z ac0v $

=item Revision

$Revision: 469 $

=item Date

$Date: 2008-05-26 13:26:35 +0200 (Mon, 26 May 2008) $

=item HeadURL

$HeadURL: file:///var/svn/repos/Hyper/Class-Std-Fast/branches/0.0.8/lib/Class/Std/Fast/Storable.pm $

=back

=head1 AUTHOR

Andreas 'ac0v' Specht  C<< <ACID@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007, Andreas Specht C<< <ACID@cpan.org> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
