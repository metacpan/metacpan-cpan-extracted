package CSS::Parse::Packed;

use warnings;
use strict;

our $VERSION = '0.07';

use base qw/CSS::Parse/;
use Carp;
use CSS::Style;
use CSS::Selector;
use CSS::Property;

sub parse_string {
    my $self   = shift;
    my $string = shift;

    $string =~ s{\r\n|\r|\n}{ }g;
    $string =~ s{(?:\@[\S\s]*?;)}{}g;
    $self->_parse_string($string);
    $self->_create_styles;
}

sub _parse_string {
    my $self   = shift;
    my $string = shift;

    for my $str (grep { /\S/ } split /(?<=\})/, $string) {
        my ($selectors, $properties) = $str =~ m/^\s*([^{]+?)\s*\{(.*)\}\s*$/
            or carp "Invalid style data '$str'", next;

        my @selectors = split /\s*,\s*/, $selectors;
        for my $property (grep { /\S/ } split /\;/, $properties) {
            my ($name, $val) = $property =~ m/^\s*([\w._-]+)\s*:\s*(.*?)\s*$/
                or carp "Invalid property '$property'", next;
            for my $selector (@selectors) {
                $self->stash->{$selector}->{$name} = $val;
            }
        }
    }
}

sub _create_styles {
    my $self = shift;

    my @styles;
    for my $selector (keys %{$self->stash}) {
        my $s = CSS::Style->new({ adaptor => $self->{parent}->{adaptor} });
        $s->add_selector(CSS::Selector->new({ name => $selector }));
        while (my ($name, $val) = each %{ $self->stash->{$selector} }) {
            my $property = CSS::Property->new({
                property => $name,
                value    => $val,
                adaptor  => $s->{adaptor},
            });
            $s->add_property($property);
        }
        push @styles, $s;
    }

    $self->{parent}->{styles} = \@styles;
}

sub stash {
    $_[0]->{parent}->{__PACKAGE__."::stash"} ||= {};
}

1;
__END__

=head1 NAME

CSS::Parse::Packed - A CSS::Parse module packed duplicated selectors.

=head1 SYNOPSIS

    use CSS;
    my $css = CSS->new({ parser => 'CSS::Parse::Packed' });

=head1 DESCRIPTION

This module is a parser for CSS.pm. It parsing CSS by regular expression
based on CSS::Parse::Lite and packed duplicated selectors.

=head1 EXAMPLE

Original is:

    body { background-color:#FFFFFF; font-size: 1em; }
    body { padding:6px; font-size: 1.5em; }

After parsing:

    body { padding: 6px; background-color: #FFFFFF; font-size: 1.5em }

=head1 SEE ALSO

L<CSS>, L<CSS::Parse::Lite>

=head1 AUTHOR

Hiroshi Sakai  C<< <ziguzagu@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Hiroshi Sakai C<< <ziguzagu@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.
