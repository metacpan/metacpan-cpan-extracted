package Acme::Taboo;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";
our @CENSORED = ('xxx', '***', '???', '(CENSORED)');

sub new {
    my ($class, @list) = @_;
    bless [@list], $class;
}

sub censor {
    my ($self, $str) = @_;
    my $taboo = my $replace = undef; 
    for $taboo (@$self) {
        $replace = $self->_get_replace;
        $str =~ s{$taboo}{$replace}g;
    }
    return $str;
}

sub _get_replace {
    my $self = shift;
    return rand(10) >= 7 ? $self->[int(rand($#{$self} + 1))] : $CENSORED[int(rand($#CENSORED + 1))] ;
}

1;
__END__

=encoding utf-8

=head1 NAME

Acme::Taboo - Automated Cencoring Micro Engine

=head1 SYNOPSIS

    use Acme::Taboo;
    my $taboo    = Acme::Taboo->new('bunny', 'coyote', 'roadrunner');
    my $str      = 'Do you love bugs bunny, or wily coyote?';
    my $censored = $taboo->censor($str);

=head1 DESCRIPTION

Acme::Taboo detects taboos from string and replaces it.

=head1 QUALITY GUARANTEE

This software is guaranteed quality by Acme corporation.

=head1 LICENSE

Copyright (C) ytnobody, not Acme corporation.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself if you think good about Acme corporation.

=head1 AUTHOR

ytnobody E<lt>ytnobody aaaaaaaaaaaaatttttttttttttt acme^D^D^D^Dgmail dddooottt comE<gt>

=cut

