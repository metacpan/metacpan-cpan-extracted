package Data::Phrasebook::Plain;
use strict;
use warnings FATAL => 'all';
use base qw( Data::Phrasebook::Generic Data::Phrasebook::Debug );
use Carp qw( croak );

use vars qw($VERSION);
$VERSION = '0.35';

=head1 NAME

Data::Phrasebook::Plain - The Simple Phrasebook Model.

=head1 SYNOPSIS

    use Data::Phrasebook;

    my $q = Data::Phrasebook->new(
        class  => 'Plain',
        loader => 'Text',
        file   => 'phrases.txt',
    );

    my $r = Data::Phrasebook->new( file => 'phrases.txt' );

    # simple keyword to phrase mapping
    my $phrase = $q->fetch($keyword);

    # keyword to phrase mapping with parameters
    $q->delimiters( qr{ \[% \s* (\w+) \s* %\] }x );
    my $phrase = $q->fetch($keyword,{this => 'that'});

=head1 DESCRIPTION

This module is the fallback or default phrasebook class. It doesn't do much
except act as a very simple templating facility.

=head1 METHODS

=head2 fetch

Retrieves the specified C<template> and substitutes any C<keywords> for
C<values>.

Thus, given:

    hello=Hello [% where %]!

And code:

    my $text = $q->fetch( 'hello', {
        where => 'world'
    } );

Return value is:

    Hello world!

The delimiters are deliberately taken from L<Template> Toolkit.

=cut

sub fetch {
    my $self = shift;
    my ($id, $args) = @_;

    $self->store(3,"->fetch IN - @_")	if($self->debug);

    my $map = $self->data($id);
    croak "No mapping for '$id'" unless($map);
    my $delim_RE = $self->delimiters;
    croak "Mapping for '$id' not a string." if ref $map;

    if($self->debug) {
        $self->store(4,"->fetch delimiters=[$delim_RE]");
        $self->store(4,"->fetch args=[".$self->dumper($args)."]");
    }

    $map =~ s{$delim_RE}[
        defined $args->{$1} ? $args->{$1}   :
        $self->{blank_args} ? ''            :  croak "No value given for '$1'";
    ]egx;

    return $map;
}

1;

__END__

=head1 SEE ALSO

L<Data::Phrasebook>,
L<Data::Phrasebook::Generic>.

=head1 SUPPORT

Please see the README file.

=head1 AUTHOR

  Original author: Iain Campbell Truskett (16.07.1979 - 29.12.2003)
  Maintainer: Barbie <barbie@cpan.org> since January 2004.
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2003 Iain Truskett.
  Copyright (C) 2004-2013 Barbie for Miss Barbell Productions.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
