use strict;
use warnings;
package App::Nopaste::Service::Codepeek;
# ABSTRACT: (DEPRECATED) Service for Codepeek - http://codepeek.com

our $VERSION = '1.013';

use parent 'App::Nopaste::Service';

warnings::warnif('deprecated', 'codepeek.com is offline, so this service no longer works');

sub uri { 'http://codepeek.com/paste' }

sub fill_form {
    my $self = shift;
    my $mech = shift;
    my %args = @_;

    $mech->form_number(1);

    $mech->submit_form(
        fields => {
            'paste'    => $args{text},
            'language' => ucfirst $args{lang},
            'privacy'  => $args{private},
        },
    );
}

sub return {
    my $self = shift;
    my $mech = shift;

    my $link = $mech->find_link( text_regex => qr#^http://codepeek.com/paste/[a-z0-9]+$#i );
    my $url = $link->url;
    return (0, "Could not construct paste link.") if !$url;
    return (1, $url);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Nopaste::Service::Codepeek - (DEPRECATED) Service for Codepeek - http://codepeek.com

=head1 VERSION

version 1.013

=head1 DEPRECATION NOTICE

L<http://codepeek.com> is now offline, so this service no longer works.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=App-Nopaste>
(or L<bug-App-Nopaste@rt.cpan.org|mailto:bug-App-Nopaste@rt.cpan.org>).

=head1 AUTHOR

Justin Hunter, <justin.d.hunter@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Shawn M Moore.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
