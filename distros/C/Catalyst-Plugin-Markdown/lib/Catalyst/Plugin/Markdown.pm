package Catalyst::Plugin::Markdown;

use strict;
use warnings;
use base 'Class::Data::Inheritable';
use Text::Markdown;

our $VERSION = '0.01';

__PACKAGE__->mk_classdata('markdown');
__PACKAGE__->markdown( Text::Markdown->new );

sub setup {
    my $c = shift;

    $c->config->{markdown}->{empty_element_suffix} ||= '';
    $c->config->{markdown}->{tab_width} ||= '';

    return $c->NEXT::setup(@_);
};

1;
__END__

=head1 NAME

Catalyst::Plugin::Markdown - Markdown for Catalyst

=head1 SYNOPSIS

    # include it in plugin list
    use Catalyst qw/Markdown/;

    my $html = $c->markdown->markdown($text);

=head1 DESCRIPTION

Persistent Markdown processor for Catalyst.

=head1 METHODS

=head2 $c->markdown;

Returns a ready to use L<Text::Markdown> object.

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Test>, L<Catalyst::Request>,
L<Catalyst::Response>, L<Catalyst::Helper>, L<Text::Markdown>

=head1 AUTHOR

Christopher H. Laco, <claco@chrislaco.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify 
it under the same terms as perl itself.
