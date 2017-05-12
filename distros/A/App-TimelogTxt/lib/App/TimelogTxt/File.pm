package App::TimelogTxt::File;

use warnings;
use strict;

our $VERSION = '0.22';

sub new {
    my ($class, $fh, $start, $end) = @_;

    die "Missing required file handle or file name.\n" unless defined $fh;
    die "Missing required start marker.\n" unless defined $start;
    die "Missing required end marker.\n" unless defined $end;
    if( !ref $fh ) {
        my $name = $fh;
        open( $fh, '<', $name ) or die "Unable to open file '$name': $!\n";
    }

    my $obj = {
        fh => $fh,
        start => $start,
        startlen => length $start,
        end => $end,
        endlen => length $end,
        stage => 0,
    };

    return bless $obj, $class;
}

sub readline {
    my ($self) = @_;

    return if $self->{'stage'} > 1 or eof( $self->{'fh'} );

    my $line;
    if( $self->{'stage'} == 0 )
    {
        0 while( defined( $line = readline $self->{'fh'} ) && substr( $line, 0, $self->{'startlen'} ) lt $self->{'start'} );
        $self->{'stage'} = 1;
    }
    else
    {
        $line = readline $self->{'fh'};
    }

    return $line if !defined $line || substr( $line, 0, $self->{'endlen'} ) lt $self->{'end'};
    $self->{'stage'} = 2;
    return;
}

1;
__END__

=head1 NAME

App::TimelogTxt::File - Simplify reading part of the timelog.txt file

=head1 VERSION

This document describes App::TimelogTxt::File version 0.22

=head1 SYNOPSIS

    use App::TimelogTxt::File;

    my $file = App::TimelogTxt::File->new( 'timelog.txt', '2012-06-01', '2012-06-05' );
    while( defined( $line = $file->readline ) ) {
        # process lines
    }

=head1 DESCRIPTION

An object of this class is a filtered iterator over the lines in the file.
Only the lines between the first instance of the first marker (inclusive)
and the first instance of the second marker (exclusive) are returned by
the readline function.

=head1 INTERFACE

=head2 new( $file, $start, $end )

Create an object representing part of a file. The C<$file> argument gives the
file path. The C<$start> and C<$end> parameters specify the markers for the 
starting and ending parts of the file.

=head2 $f->readline()

Return the next line from the file that meets the criteria. Returns C<undef>
once we reach either the end of file or the C<$end> marker.

=head1 CONFIGURATION AND ENVIRONMENT

App::TimelogTxt::File requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

G. Wade Johnson  C<< gwadej@cpan.org >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, G. Wade Johnson C<< gwadej@cpan.org >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
