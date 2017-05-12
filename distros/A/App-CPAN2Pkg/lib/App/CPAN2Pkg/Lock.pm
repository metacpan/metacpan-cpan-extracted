#
# This file is part of App-CPAN2Pkg
#
# This software is copyright (c) 2009 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.012;
use strict;
use warnings;

package App::CPAN2Pkg::Lock;
# ABSTRACT: Simple locking mechanism within cpan2pkg
$App::CPAN2Pkg::Lock::VERSION = '3.004';
use Moose;
use MooseX::Has::Sugar;

# -- attributes


has owner => (
    rw,
    isa       => 'Str',
    writer    => '_set_owner',
    clearer   => '_clear_owner',
    predicate => '_has_owner',
);


# -- methods


sub is_available {
    my $self = shift;
    return ! $self->_has_owner;
}



sub get {
    my ($self, $owner) = @_;
    die "need to specify owner parameter" unless defined $owner;
    if ( $self->_has_owner ) {
        my $current = $self->owner;
        die "lock already owned by $current";
    }
    $self->_set_owner( $owner );
}



sub release {
    my $self = shift;
    $self->_clear_owner;
}

1;

__END__

=pod

=head1 NAME

App::CPAN2Pkg::Lock - Simple locking mechanism within cpan2pkg

=head1 VERSION

version 3.004

=head1 SYNOPSIS

    use App::CPAN2Pkg::Lock;
    my $lock = App::CPAN2Pkg::Lock->new;
    $lock->get( 'foo' );
    # ...
    $lock->is_available; # false
    $lock->owner;        # foo
    $lock->get( 'bar' ); # dies
    # ...
    $lock->release;

=head1 DESCRIPTION

This class implements a simple locking mechanism.

=head1 ATTRIBUTES

=head2 owner

The lock owner (a string).

=head1 METHODS

=head2 is_available

    $lock->is_available;

Return true if one can get control on C<$lock>.

=head2 get

    $lock->get( $owner );

Try to give the C<$lock> control to C<$owner>. Dies if it's already
owned by something else, or if new C<$owner> is not specified.

=head2 release

    $lock->release;

Release C<$lock>. It's now available for locking again.

=head1 AUTHOR

Jerome Quelin <jquelin@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
