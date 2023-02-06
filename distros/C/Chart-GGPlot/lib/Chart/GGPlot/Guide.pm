package Chart::GGPlot::Guide;

# ABSTRACT: Role for guide

use Chart::GGPlot::Setup;
use Function::Parameters qw(classmethod);
use namespace::autoclean;

our $VERSION = '0.002003'; # VERSION

use parent qw(Chart::GGPlot::Params);

use Types::Standard qw(Str);

use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util qw(:all);


for my $attr (qw(title key reverse)) {
    no strict 'refs';
    *{$attr} = sub { $_[0]->at($attr); }
}

# undef means "any"
classmethod available_aes () { undef; }

method train ($scale, $aesthetics=undef) {
    return $self;
}

classmethod _reverse_df ($df) {
    return $df->select_rows( [ reverse( 0 .. $df->nrow - 1 ) ] );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Guide - Role for guide

=head1 VERSION

version 0.002003

=head1 ATTRIBUTES

=head2 title

A string indicating a title of the guide. If an empty string, the
title is not show. By default (C<undef>) the name of the scale
object or the name specified in C<labs()> is used for the title.

=head2 key

=head2 reverse

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019-2023 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
