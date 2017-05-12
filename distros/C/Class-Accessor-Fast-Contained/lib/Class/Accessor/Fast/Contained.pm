package Class::Accessor::Fast::Contained;

use strict;
use warnings FATAL => qw(all);

use base qw(Class::Accessor::Fast);

our $VERSION = '1.01';
$VERSION = eval $VERSION; # numify for warning-free dev releases

use Symbol;

# this module does two things differently to the venerable
# Class::Accessor::Fast,
#  1) fields are stored at arms-length in a single key of $self
#  2) new() allows mixin into an existing object

sub new {
    my ($class, $fields) = @_;

    $fields = {} unless defined $fields;

    my $self = (ref $class ? $class : bless {}, $class);

    my $copy = ("$self" =~ m/=GLOB/ ? *$self : $self);
    $copy->{ref $self} = {%$fields};

    return $self;
}

*{Symbol::qualify_to_ref('setup')} = \&new;

sub make_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;
        my $copy = ("$self" =~ m/=GLOB/ ? *$self : $self);
        return $copy->{ref $self}->{$field} if scalar @_ == 0;
        $copy->{ref $self}->{$field} = (@_ == 1 ? $_[0] : [@_]);
    };
}


sub make_ro_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;
        my $copy = ("$self" =~ m/=GLOB/ ? *$self : $self);
        return $copy->{ref $self}->{$field} if scalar @_ == 0;
        my $caller = caller;
        $self->_croak("'$caller' cannot alter the value of '$field' on objects of class '$class'");
    };
}

sub make_wo_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;
        my $copy = ("$self" =~ m/=GLOB/ ? *$self : $self);

        unless (@_) {
            my $caller = caller;
            $self->_croak("'$caller' cannot access the value of '$field' on objects of class '$class'");
        }
        else {
            return $copy->{ref $self}->{$field} = (@_ == 1 ? $_[0] : [@_]);
        }
    };
}

=head1 NAME

Class::Accessor::Fast::Contained - Fast accessors with data containment

=head1 VERSION

This document refers to version 1.01 of Class::Accessor::Fast::Contained

=head1 SYNOPSIS

 package Foo;
 use base qw(Class::Accessor::Fast::Contained);

 # The rest is the same as Class::Accessor::Fast

=head1 DESCRIPTION

This module does two things differently to the venerable Class::Accessor::Fast :

=over 4

=item *

Fields are stored at arms-length within a single hash value of $self, rather
than directly in the $self blessed referent.

=item *

C<new()> allows mixin into an existing object, rather than creating and
returning a new blessed hashref. To do this, just call something like:

 my $self = Some::Other::Class->new;
 $self = $self->Class::Accessor::Fast::Contained::new;

Note that the mixin code only supports objects which use a blessed hash
reference or a blessed typeglob reference.

An alias C<setup()> is available which does the same as C<new()> but might
make more sense if being used in this way.

=back

=head1 DEPENDENCIES

Other than the standard Perl distribution, you will need the following:

=over 4

=item *

Class::Accessor

=back

=head1 BUGS

If you spot a bug or are experiencing difficulties that are not explained
within the documentation, please send an email to oliver@cpan.org or submit a
bug to the RT system (http://rt.cpan.org/). It would help greatly if you are
able to pinpoint problems or even supply a patch.

=head1 SEE ALSO

L<Class::Accessor>

=head1 AUTHOR

Oliver Gorwits C<< <oliver.gorwits@oucs.ox.ac.uk> >>

=head1 ACKNOWLEDGEMENTS

Thanks to Marty Pauly and Michael G Schwern for L<Class::Accessor> and its
tests, which I've shamelessly borrowed for this distribution.

=head1 COPYRIGHT & LICENSE

Copyright (c) The University of Oxford 2008.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;

