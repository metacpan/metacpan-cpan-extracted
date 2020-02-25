package Chart::GGPlot::Types;

# ABSTRACT: Custom types and coercions

use Chart::GGPlot::Setup qw(:base :pdl); 

our $VERSION = '0.0009'; # VERSION

use Ref::Util qw(is_plain_arrayref);
use Type::Library -base, -declare => qw(
  GGParams AesMapping
  ColorBrewerTypeEnum PositionEnum
  Theme Margin Labeller
  Coord Facet Scale
);

use Type::Utils -all;
use Types::Standard -types;
use Types::PDL -types;
use Data::Frame::Types qw(:all);

declare GGParams, as ConsumerOf ["Chart::GGPlot::Params"];
coerce GGParams, from HashRef,
    via { 'Chart::GGPlot::Params'->new($_->flatten); };

declare AesMapping, as InstanceOf ["Chart::GGPlot::Aes"];
coerce AesMapping, from HashRef,
    via { 'Chart::GGPlot::Aes'->new($_->flatten); };

declare ColorBrewerTypeEnum, as Enum [qw(seq dev qual)];
declare PositionEnum,        as Enum [qw(left right top bottom)];

declare Theme, as InstanceOf["Chart::GGPlot::Theme"];

declare Margin, as InstanceOf["Chart::GGPlot::Margin"];

declare Labeller, as InstanceOf["Chart::GGPlot::Labeller"];
coerce Labeller, from Any,
    via { 'Chart::GGPlot::Labeller'->as_labeller($_); };

declare Coord, as ConsumerOf["Chart::GGPlot::Coord"];
declare Facet, as ConsumerOf["Chart::GGPlot::Facet"];
declare Scale, as ConsumerOf["Chart::GGPlot::Scale"];

declare_coercion "ArrayRefFromAny", to_type ArrayRef, from Any, via { [$_] };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Chart::GGPlot::Types - Custom types and coercions

=head1 VERSION

version 0.0009

=head1 DESCRIPTION

This modules defines custom L<Type::Tiny> types and coercions used
by the library.

=head1 SYNOPSYS

    use Chart::GGPlot::Types qw(:all);

=head1 SEE ALSO

L<Type::Tiny>

=head1 AUTHOR

Stephan Loyd <sloyd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Stephan Loyd.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
