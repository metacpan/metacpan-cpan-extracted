use strict;
use warnings;

package Acme::Resume::MoopsParserTrait;

# ABSTRACT: Trait for the Moops parser
our $VERSION = '0.0105';

use Moo::Role;
use Module::Runtime qw($module_name_rx);

around _eat_package => sub {
    my $next = shift;
    my $self = shift;
    my ($rel) = @_;

    my $pkg = $self->_eat(qr{(?:::)?$module_name_rx});

    if($pkg !~ m{::}) {
        $pkg = 'Acme::Resume::For::' . $pkg;
    }

    return $self->qualify_module_name($pkg, $rel);

};

after parse => sub {
    my $self = shift;

    if($self->keyword eq 'resume') {
        push @{ $self->relations->{'with'} ||= [] } => (
            'Acme::Resume::Output::ToPlain',
        );
    }
};

around keywords => sub {
    my $next = shift;
    my $self = shift;

    my @all = ('resume', $self->$next(@_));
    return @all;
};

around class_for_keyword => sub {
    my $next = shift;
    my $self = shift;

    if($self->keyword eq 'resume') {
        require Moops::Keyword::Class;
        return 'Moops::Keyword::Class';
    }

    return $self->$next(@_);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Acme::Resume::MoopsParserTrait - Trait for the Moops parser

=head1 VERSION

Version 0.0105, released 2021-09-29.

=head1 SOURCE

L<https://github.com/Csson/p5-Acme-Resume>

=head1 HOMEPAGE

L<https://metacpan.org/release/Acme-Resume>

=head1 AUTHOR

Erik Carlsson <info@code301.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Erik Carlsson.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
