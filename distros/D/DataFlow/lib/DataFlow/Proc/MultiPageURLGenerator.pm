package DataFlow::Proc::MultiPageURLGenerator;

use strict;
use warnings;

# ABSTRACT: A processor that generates multi-paged URL lists

our $VERSION = '1.121830';    # VERSION

use Moose;
extends 'DataFlow::Proc';

use Moose::Autobox;
use namespace::autoclean;
use Carp;

has 'first_page' => (
    'is'      => 'ro',
    'isa'     => 'Int',
    'default' => 1,
);

has 'last_page' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
    'lazy'     => 1,
    'default'  => sub {
        my $self = shift;

        #warn 'last_page';
        confess(q{DataFlow::Proc::MultiPageURLGenerator: paged_url not set!})
          unless $self->has_paged_url;
        return $self->produce_last_page->( $self->_paged_url );
    },
);

# calling convention for the sub:
#   - $self
#   - $url (Str)
has 'produce_last_page' => (
    'is'      => 'ro',
    'isa'     => 'CodeRef',
    'lazy'    => 1,
    'default' => sub { confess(q{produce_last_page not implemented!}); },
);

# calling convention for the sub:
#   - $self
#   - $paged_url (Str)
#   - $page      (Int)
has 'make_page_url' => (
    'is'       => 'ro',
    'isa'      => 'CodeRef',
    'required' => 1,
);

has '_paged_url' => (
    'is'        => 'rw',
    'isa'       => 'Str',
    'predicate' => 'has_paged_url',
    'clearer'   => 'clear_paged_url',
);

sub _build_p {
    my $self = shift;

    return sub {
        my $url = $_;

        $self->_paged_url($url);

        my $first = $self->first_page;
        my $last  = $self->last_page;
        $first = 1 + $last + $first if $first < 0;

        my $result =
          [ $first .. $last ]
          ->map( sub { $self->make_page_url->( $self, $url, $_ ) } );

        $self->clear_paged_url;
        return $result;
    };
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=encoding utf-8

=head1 NAME

DataFlow::Proc::MultiPageURLGenerator - A processor that generates multi-paged URL lists

=head1 VERSION

version 1.121830

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<DataFlow|DataFlow>

=back

=head1 AUTHOR

Alexei Znamensky <russoz@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alexei Znamensky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT
WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER
PARTIES PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND,
EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE. THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE
SOFTWARE IS WITH YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME
THE COST OF ALL NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE LIABLE
TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE THE
SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
DAMAGES.

=cut

