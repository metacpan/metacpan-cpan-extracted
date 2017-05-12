package Acme::Hello;
$Acme::Hello::VERSION = '0.05';

use strict;
use Acme::Hello::I18N;

use Exporter;
use base 'Exporter';
use vars '@EXPORT';

@EXPORT = 'hello';

=head1 NAME

Acme::Hello - Print a greeting message

=head1 VERSION

This document describes version 0.04 of B<Acme::Hello>.

=head1 SYNOPSIS

    use Acme::Hello;    # exports hello() by default
    hello();            # procedure call interface

    my $obj = Acme::Hello->new;
    $obj->hello;        # object-oriented interface

=cut

sub new {
    my ($class, %args) = @_;
    $class = ref($class) if (ref $class);

    $args{lh} ||= Acme::Hello::I18N->get_handle($args{language})
        or die "Cannot find handle for language: $args{language}.\n";

    return bless(\%args, $class);
}

sub hello {
    my $self = ref($_[0]) ? $_[0] : __PACKAGE__->new;

    print $self->loc("Hello, world!"), "\n";
}

sub lh {
    my $self = shift;
    $self->{lh} = shift if @_;
    return $self->{lh};
}

sub loc {
    my $self = shift;
    return $self->lh->maketext(@_);
}


1;

__END__

=head1 CC0 1.0 Universal

To the extent possible under law, 唐鳳 has waived all copyright and related
or neighboring rights to Acme-Hello.

This work is published from Taiwan.

L<http://creativecommons.org/publicdomain/zero/1.0>

=cut
