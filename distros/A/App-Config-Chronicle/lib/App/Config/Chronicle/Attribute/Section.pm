package App::Config::Chronicle::Attribute::Section;

use Moose;
use namespace::autoclean;
extends 'App::Config::Chronicle::Node';

our $VERSION = '0.06';    ## VERSION

=head1 NAME

App::Config::Chronicle::Attribute::Section

=cut

__PACKAGE__->meta->make_immutable;
1;

=head1 NOTE

This class isn't intended for consumption outside of App::Config::Chronicle.

=cut
