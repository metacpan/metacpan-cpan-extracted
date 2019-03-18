package Chart::GGPlot::Guide;

# ABSTRACT: Role for guide

use Chart::GGPlot::Setup;
use namespace::autoclean;

our $VERSION = '0.0001'; # VERSION

use parent qw(Chart::GGPlot::Params);

use Types::Standard qw(Str);

use Chart::GGPlot::Types qw(:all);
use Chart::GGPlot::Util qw(:all);


method title() {
    return $self->at('title');
}

method available_aes() { undef; }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Guide - Role for guide

=head1 VERSION

version 0.0001

=head1 ATTRIBUTES

=head2 title

A string indicating a title of the guide. If an empty string, the
title is not show. By default (C<undef>) the name of the scale
object or the name specified in C<labs()> is used for the title.

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
