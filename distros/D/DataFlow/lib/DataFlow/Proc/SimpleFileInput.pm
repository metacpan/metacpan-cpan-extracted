package DataFlow::Proc::SimpleFileInput;

use strict;
use warnings;

# ABSTRACT: A processor that reads that from a file

our $VERSION = '1.121830';    # VERSION

use Moose;
extends 'DataFlow::Proc';
with 'DataFlow::Role::File';

use autodie;
use namespace::autoclean;
use Queue::Base;

has '_slurpy_read' => (
    'is'      => 'ro',
    'isa'     => 'CodeRef',
    'lazy'    => 1,
    'default' => sub {
        my $self = shift;
        return sub {
            my $filename = $_;
            open( my $fh, '<', $filename );
            my @slurp = <$fh>;
            close $fh;
            chomp @slurp unless $self->nochomp;

            return [@slurp];
        };
    },
);

has '_fileq' => (
    'is'      => 'ro',
    'isa'     => 'Queue::Base',
    'lazy'    => 1,
    'default' => sub { return Queue::Base->new },
);

has '+allows_undef_input' => (
    'default' => sub {
        my $self = shift;
        return $self->do_slurp ? 0 : 1;
    }
);

sub _build_p {
    my $self = shift;

    return $self->_slurpy_read if $self->do_slurp;

    return sub {
        my $filename = $_;

        # if filename is provided, add it to the queue
        $self->_fileq->add($filename) if defined $filename;

        # if there is no open file
        if ( !$self->has_file ) {
            return if $self->_fileq->empty;
            open( my $fh, '<', $self->_fileq->remove );    ## no critic
            $self->file( [ $fh, '<' ] );
        }

        # read a line
        my $file = $self->file;
        my $line = <$file>;
        chomp $line unless $self->nochomp;
        $self->_check_eof;
        return $line;
    };
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=encoding utf-8

=head1 NAME

DataFlow::Proc::SimpleFileInput - A processor that reads that from a file

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

