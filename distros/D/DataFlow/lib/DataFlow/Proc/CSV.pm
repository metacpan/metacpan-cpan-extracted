package DataFlow::Proc::CSV;

use strict;
use warnings;

# ABSTRACT: A CSV converting processor

our $VERSION = '1.121830';    # VERSION

use Moose;
extends 'DataFlow::Proc::Converter';

use namespace::autoclean;
use Text::CSV::Encoded;
use MooseX::Aliases;

has 'header' => (
    'is'        => 'rw',
    'isa'       => 'ArrayRef[Maybe[Str]]',
    'predicate' => 'has_header',
    'alias'     => 'headers',
    'handles'   => { 'has_headers' => sub { shift->has_header }, },
);

has 'header_wanted' => (
    'is'      => 'rw',
    'isa'     => 'Bool',
    'lazy'    => 1,
    'default' => sub {
        my $self = shift;
        return 0 if $self->direction eq 'CONVERT_FROM';
        return 1 if $self->has_header;
        return 0;
    },
);

has '+converter' => (
    'lazy'    => 1,
    'default' => sub {
        my $self = shift;
        return $self->has_converter_opts
          ? Text::CSV::Encoded->new( $self->converter_opts )
          : Text::CSV::Encoded->new;
    },
    'handles' => {
        'text_csv'          => sub { shift->converter(@_) },
        'text_csv_opts'     => sub { shift->converter_opts(@_) },
        'has_text_csv_opts' => sub { shift->has_converter_opts },
    },
    'init_arg' => 'text_csv',
);

has '+converter_opts' => ( 'init_arg' => 'text_csv_opts', );

sub _combine {
    my ( $self, $e ) = @_;
    my $status = $self->converter->combine( @{$e} );
    die $self->converter->error_diag unless $status;
    return $self->converter->string;
}

sub _parse {
    my ( $self, $line ) = @_;
    my $ok = $self->converter->parse($line);
    die $self->converter->error_diag unless $ok;
    return [ $self->converter->fields ];
}

sub _policy {
    return shift->direction eq 'CONVERT_TO' ? 'ArrayRef' : 'Scalar';
}

sub _build_subs {
    my $self = shift;
    return {
        'CONVERT_TO' => sub {
            my @res = ();
            if ( $self->header_wanted ) {
                $self->header_wanted(0);
                push @res, $self->_combine( $self->header );
            }

            push @res, $self->_combine($_);
            return @res;
        },
        'CONVERT_FROM' => sub {
            if ( $self->header_wanted ) {
                $self->header_wanted(0);
                $self->header( $self->_parse($_) );
                return;
            }
            return $self->_parse($_);
        },
    };
}

__PACKAGE__->meta->make_immutable;

1;


__END__
=pod

=encoding utf-8

=head1 NAME

DataFlow::Proc::CSV - A CSV converting processor

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

