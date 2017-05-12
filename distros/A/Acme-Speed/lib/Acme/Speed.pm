package Acme::Speed;

use strict;
use warnings;

our $VERSION = "0.01";

my @members = qw(
    ArakakiHitoe
    UeharaTakako
    ImaiEriko
    ShimabukuroHiroko
);

sub new {
    my $class = shift;
    my $self = bless {members => []}, $class;

    $self->_initialize;

    return $self;
}

sub members {
    my $self = shift;
    my @members = @{$self->{members}};

    return @members;
}

sub _initialize {
    my $self = shift;

    for my $member (@members) {
        my $module_name = "Acme::Speed::Member::${member}";
        eval "require ${module_name};";

        push @{$self->{members}}, $module_name->new;
    }

    return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Speed - About "SPEED" is Japanese female vocal/dance group

=head1 SYNOPSIS

    use Acme::Speed;

    my $speed = Acme::Speed->new;

    my @members = $speed->members;

=head1 DESCRIPTION

"SPEED" is a Japanese female vocal/dance group.

This module provides an method to check each member of SPEED.

=head1 METHODS

=head2 new

=over 4

  my $speed = Acme::Speed->new;

Creates and returns a new Acme::Speed object.

=back

=head2 members

=over 4

  my @members = $speed->members;

Returns the members as a list of the L<Acme::Speed::Member::Base> 
based object represents each member. See also the documentation of 
L<Acme::Speed::Member::Base> for more details.

=back

=head1 LICENSE

Copyright (C) Keisuke KITA.

This library is free software; you can redistribute it and/or modify 
it under the same terms as Perl itself.

=head1 AUTHOR

Keisuke KITA E<lt>kei.kita2501@gmail.comE<gt>

=cut

