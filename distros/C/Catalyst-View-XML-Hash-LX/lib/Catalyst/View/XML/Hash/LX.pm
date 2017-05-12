package Catalyst::View::XML::Hash::LX;
use Moose;
BEGIN { extends 'Catalyst::View' }

use XML::Hash::LX;
use Moose;
use namespace::autoclean;


=head1 NAME

Catalyst::View::XML::Hash::LX - Serialize the stash as XML using XML::Hash::LX

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    __PACKAGE__->config(
        'XML::Hash::LX' => {
            rootname => 'document',
            attrmap => {
                action => [qw( class name )],
                view   => [qw( type )]
            }
        }
    );

=head1 DESCRIPTION

This Catalyst view renders the context stash as XML using L<XML::Hash::LX>.  This enables you
to quickly render customized XML output using a set of rules to dictate which hash parameters will be stored
as attributes, elements, and other configuration options.

=head1 METHODS

=head2 process

See L<Catalyst::View::process>

=cut

sub process {
    my ($self, $c) = @_;

    my $encoding = exists $c->stash->{encoding} ? $c->stash->{encoding} : 'utf-8';

    my $content = hash2xml $c->stash->{response}, encoding => $encoding;

    $c->response->content_type("text/xml; charset=" . $encoding);
    $c->response->body($content);
    1;
}

=head1 AUTHOR

Andrii Kostenko, C<< <andrey@kostenko.name> >>

=head1 ACKNOWLEDGEMENTS

This module based on L<Catalyst::View::XML::Generator>

=head1 BUGS

Please report any bugs or feature requests to C<bug-catalyst-view-xml-hash-lx at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Catalyst-View-XML-Hash-LX>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View>, L<XML::Hash::LX>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Catalyst::View::XML::Hash::LX

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Catalyst-View-XML-Hash-LX>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Catalyst-View-XML-Hash-LX>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Catalyst-View-XML-Hash-LX>

=item * Search CPAN

L<http://search.cpan.org/dist/Catalyst-View-XML-Hash-LX/>

=item * Download the source from Github

L<http://github.com/gugu/Catalyst-View-XML-Hash-LX/>

=back

=head1 COPYRIGHT & LICENSE

Copyright (c) 2011 Andrii Kostenko

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
