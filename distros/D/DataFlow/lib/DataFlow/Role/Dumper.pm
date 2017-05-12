package DataFlow::Role::Dumper;

use strict;
use warnings;

# ABSTRACT: A role that provides a facility for dumping data to STDERR

our $VERSION = '1.121830';    # VERSION

use Moose::Role;
use Moose::Autobox;

has '_dumper' => (
    'is'      => 'ro',
    'isa'     => 'CodeRef',
    'lazy'    => 1,
    'default' => sub {
        use Data::Dumper;
        return sub {
            $Data::Dumper::Terse = 1;
            return @_->map( sub { Dumper($_) } )->join(qq{\n});
        };
    },
    'handles' => {
        'prefix_dumper' => sub {
            my ( $self, $prefix, @args ) = @_;
            foreach (@args) {
                print STDERR $prefix . ' ' . $self->_dumper->($_);
            }
        },
        'raw_dumper' => sub {
            my $self = shift;
            print STDERR $self->_dumper->(@_);
        },
    },
);

has 'dump_input' => (
    'is'            => 'ro',
    'isa'           => 'Bool',
    'lazy'          => 1,
    'default'       => 0,
    'documentation' => 'Prints a dump of the input load to STDERR',
);

has 'dump_output' => (
    'is'            => 'ro',
    'isa'           => 'Bool',
    'lazy'          => 1,
    'default'       => 0,
    'documentation' => 'Prints a dump of the output load to STDERR',
);

1;



=pod

=encoding utf-8

=head1 NAME

DataFlow::Role::Dumper - A role that provides a facility for dumping data to STDERR

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


__END__

