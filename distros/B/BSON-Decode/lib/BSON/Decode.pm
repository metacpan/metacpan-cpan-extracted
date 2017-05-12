package BSON::Decode;

use 5.006;
use strict;
use warnings;
use Carp qw(carp croak);

=head1 NAME

BSON::Decode - Decode BSON file and return a perl data structure!

=head1 VERSION

Version 0.06

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

A small module to parse BSON file to a perl structure

 my $file = shift;
 open( my $INF ,$file);
 my $bs = BSON::Decode->new($INF);

 say Dumper $bs->fetch(); # read first element
 say Dumper $bs->fetch(); # read second element
 $bs->rewind();# rewind the filehandle
 say Dumper $bs->fetch_all(); # read all element in an ARRAY
 close $INF;



=cut

=head1 DESCRIPTION

 This is a pure perl BSON decoder. It is simple and without any dependencies.
 (It was mandatory to allow use in an embeded system)
 The main use is to compare 2 BSON files

 Some of the  BSON grammar's element are not implemented

 \x06 	Undefined (value)  Deprecated
 \x0C   DBPointer          Deprecated
 \x0E                      Deprecated

For binary content (\x05)
 The data is uuencoded as value of the subtype.

=cut

=head1 METHOD

=head2 new

 Instanciate the parser.

 By default the parser read from STDIN (unix filter).
 In that case no rewind is possible. Only sequential read.
 my $bs = BSON::Decode->new();
 It is possible to pass an argument to the constructor to chose another source.

=head3 filehandle

 an open filehandle from where to read the BSON data:
 open( my $INF ,$file);
 my $bs = BSON::Decode->new($INF);

=cut

=head3 file name

 this a path to an existing BSON file:
 my $bs = BSON::Decode->new($file);

=cut

=head3 scalar

 a perl scalar with the BSON data:
 my $bs = BSON::Decode->new($bson);

=cut

sub new {
    my $class = shift;

    my $self = {};
    bless( $self, $class );
    $self->{fh} = shift // '';
    my $valid = 0;
    {
        local $@ = "";
        my $fd = eval { fileno $self->{fh} };
        $valid = !$@ && defined $fd;
    }
    if ( !$valid ) {
        if ( -f $self->{fh} ) {
            my $f_name = delete $self->{fh};
            open $self->{fh}, '<', $f_name;
        } elsif ( length $self->{fh} ) {
            $self->{buffer} = $self->{buffer_bck} = delete $self->{fh};
        } else {
            $self->{fh}    = *STDIN;
            $self->{stdin} = 1;
        }
    }
    binmode( $self->{fh} ) if exists $self->{fh};

    $self->{func} = {
        1 => sub {    ## 64-bit float
            my ( $bson, $name ) = @_;
            my $data = substr( $$bson, 0, 8, '' );
            return unpack( "d", $data );
        },
        2 => sub {    ## UTF-8 string
            my ( $bson, $name ) = @_;
            my $size = unpack( "i", substr( $$bson, 0, 4, '' ) );
            my $data = substr( $$bson, 0, $size - 1, '' );

            return unpack( "a*", $data );
        },
        3 => sub {    ## Embedded document
            my ( $bson, $name ) = @_;
            my $size = unpack( "i", substr( $$bson, 0, 4, '' ) );
            return $self->_document( $bson, $size - 4 );
        },
        4 => sub {    ## Array
            my ( $bson, $name ) = @_;
            my $size = unpack( "i", substr( $$bson, 0, 4, '' ) );
            my $r = $self->_document( $bson, $size - 4 );
            my @t;
            foreach my $k ( sort keys %$r ) {
                push @t, $r->{$k} if $k =~ /^\d+$/;
            }
            return \@t;
        },
        5 => sub {    ##       Binary data
            my ( $bson, $name ) = @_;
            my $size = unpack( "i", substr( $$bson, 0, 4, '' ) );
            my $subtype = substr( $$bson, 0, 1, '' );
            my $binary = pack( 'u', substr( $$bson, 0, $size, '' ) );
            return ( $subtype => $binary );
        },
        7 => sub {    ## ObjectId
            my ( $bson, $name ) = @_;
            my $data = substr( $$bson, 0, 12, '' );
            return unpack( "H*", $data );
        },
        8 => sub {    ## Boolean
            my ( $bson, $name ) = @_;
            my $data = substr( $$bson, 0, 1, '' );
            return oct( "0x" . unpack( "H*", $data ) );
        },
        9 => sub {    ## UTC datetime
            my ( $bson, $name ) = @_;
            my $data = substr( $$bson, 0, 8, '' );
            return unpack( "q", $data );
        },
        10 => sub {    ## Null value
            my ( $bson, $name ) = @_;
            return 'null';
        },
        11 => sub {    ## REGEX
            my ( $bson, $name ) = @_;
            my $regex = unpack( "Z*", $$bson );
            substr $$bson, 0, length($regex) + 1, '';
            my $regex_options = unpack( "Z*", $$bson );
            substr $$bson, 0, length($regex_options) + 1, '';
            return '/' . $regex . '/' . $regex_options;
        },
        13 => sub {    ## javascript code
            my ( $bson, $name ) = @_;
            my $size = unpack( "i", substr( $$bson, 0, 4, '' ) );
            my $data = substr( $$bson, 0, $size - 1, '' );
            return unpack( "a*", $data );
        },
        16 => sub {    ## 32-bit integer
            my ( $bson, $name ) = @_;
            my $data = substr( $$bson, 0, 4, '' );
            return unpack( "i", $data );
        },
        17 => sub {    ## timestamp
            my ( $bson, $name ) = @_;
            my $data = substr( $$bson, 0, 8, '' );
            return unpack( "Q", $data );
        },
        18 => sub {    ## 64-bit integer
            my ( $bson, $name ) = @_;
            my $data = substr( $$bson, 0, 8, '' );
            return unpack( "Q", $data );

        },
        19 => sub {    ## 128-bit integer
            my ( $bson, $name ) = @_;
            my $data = substr( $$bson, 0, 16, '' );
            return unpack( "Q", $data );
        },
        127 => sub {    ## MAX key
            my ( $bson, $name ) = @_;
            return 'maxkey';
        },
        255 => sub {    ## MIN key
            my ( $bson, $name ) = @_;
            return 'minkey';
        }
    };
    return $self;
}

=head2 fetch_all

 Parse the BSON data and return an ARRAY with each element in a perl structure.
 The parsing is done from the current position.
 e.g.
    my $bs = BSON::Decode->new($bson_data);
    my $bson = $bs->fetch_all();

 If a parameter is provided, this override the parameter from the class new
 And allow a one line fetch_all like this:
 my $bson = BSON::Decode->fetch_all('t/test1.bson');

=cut

sub fetch_all {
    my ($self, $input) = @_;

    $self=$self->new($input) if ($input);
    my @all;
    $self->{item_nbr} = 0;
    if ( $self->{fh} ) {
        push @all, $self->fetch() while ( !eof $self->{fh} );
    } else {
        push @all, $self->fetch() while ( $self->{buffer} );
    }
    return \@all;
}

=head2 fetch

 Parse the BSON data and return the next element in a perl structure.
 e.g.
    my $bs = BSON::Decode->new($bson_data);
    my $bson = $bs->fetch();

=cut

sub fetch {
    my ($self) = @_;
    $self->{item_nbr}++;
    my $res;
    my $sizebits;
    my $bson;
    my $size;
    if ( $self->{fh} ) {
        my $n = read( $self->{fh}, $sizebits, 4 );
        carp "error reading size\n" if ( $n != 4 );

        $size = unpack( "i", $sizebits );
        $size -= 4;    # -4 because the size includes itself
        $n = read( $self->{fh}, $bson, $size );
        carp "error reading bson string\n" if ( $n != $size );
    } else {

        $sizebits = substr( $self->{buffer}, 0, 4, '' );
        $size = unpack( "i", $sizebits );
        $size -= 4;
        $bson = substr( $self->{buffer}, 0, $size, '' );
    }
    if ( length $bson ) {
        my $sep = substr( $bson, -1, 1 );
        croak( "Bad record seperator '" . unpack( "H*", $sep ) . "'" ) if ( $sep ne "\x00" );
    }
    $res = $self->_document( \$bson, $size );
    return $res;
}

=head2 rewind

 Rewind the file descriptor ( or buffer ).
 !!! BUT NOT FOR STDIN !!!
 e.g.
    my $bs = BSON::Decode->new($file);
    say Dumper $bs->fetch();

    $bs->rewind();
    say Dumper $bs->fetch_all(); # all from beginning if no rewind read all remaining elements after the first one.

=cut

sub rewind {
    my ($self) = @_;
    if ( $self->{stdin} ) {
        carp("No rewind for STDIN");
    } else {
        if ( exists $self->{fh} ) {
            seek( $self->{fh}, 0, 0 );
        } else {
            $self->{buffer} = $self->{buffer_bck};
        }
    }
    return;
}


sub _document {
    my ( $self, $str, $size ) = @_;
    my $res = {};
    my $bson = substr( $$str, 0, $size, '' );
    if ( length($bson) != $size ) {
        die "error reading bson string " . length($bson) . " != $size\n";
    }
    my $sep = substr( $bson, -1, 1 );
    if ( $sep ne "\x00" ) {
        die("Bad record seperator '$sep'");
    }
    while ( length($bson) ) {
        my $element = oct( "0x" . unpack( "H*", substr( $bson, 0, 1, '' ) ) );
        my $name;
        next if ( $element == 0 );
        $name = unpack( "Z*", $bson );
        substr $bson, 0, length($name) + 1, '';
        if ( exists $self->{func}{$element} ) {
            $res->{$name} = $self->{func}{$element}->( \$bson, $name );
        } else {
            warn "Type $element not implemented for $name";
            last;
        }
    }
    return $res;
}

=head2 delete_hash_deep

 Function to delete some keys matching a regex from a hash in deep (multiple level)
 This allow to compare 2 BSON data but skip some fields.
 e.g.
    use BSON::Decode
    use Text::Diff;
    my @skip = ( lastUpdated$', '(?i)timestamp', '^uptimeMs$' );
    my $codec1 = BSON::Decode->new( $file1 );
    my $bson1  = $codec1->fetch_all();

    my $codec2 = BSON::Decode->new( $file2 );
    my $bson2  = $codec2->fetch_all();

    delete_hash_deep( $bson1, \@skip );
    delete_hash_deep( $bson2, \@skip );

    my $b1 = Dumper($bson1);
    my $b2 = Dumper($bson2);

    my $diff = diff( \$b1, \$b2 );

    say "$all1{$f}; diff=<$diff>" if $diff;


 !!! if the hash is empty, it  stay in the perl structure

=cut

sub delete_hash_deep {
    my ( $hash, $allowed_keys, $clean ) = @_;

    if ( ref($hash) && ref($hash) eq "ARRAY" ) {
        foreach my $h ( 0 .. $#$hash ) {
            delete_hash_deep( $hash->[$h], $allowed_keys, $clean );
            delete $hash->[$h] if ( $clean && ref( $hash->[$h] ) eq 'HASH' && keys %{ $hash->[$h] } == 0 );
        }
    } else {
        if ( ref($hash) eq 'HASH' ) {
            foreach my $k ( keys %{$hash} ) {
                if ( ( grep { $k =~ /$_/ } @{$allowed_keys} ) ) {
                    delete $hash->{$k};
                    next;
                } else {
                    if ( ref( $hash->{$k} ) ) {
                        if ( ref( $hash->{$k} ) eq "HASH" || ref( $hash->{$k} ) eq "ARRAY" ) {
                            delete_hash_deep( $hash->{$k}, $allowed_keys, $clean );
                            delete $hash->{$k} if ( $clean && ref( $hash->{$k} ) eq 'ARRAY' && scalar @{ $hash->{$k} } == 0 );
                        }
                    }
                }
            }
        }
    }
}

=head1 AUTHOR

DULAUNOY Fabrice, C<< <fabrice at dulaunoy.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-bson-decode at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=BSON-Decode>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc BSON::Decode


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=BSON-Decode>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/BSON-Decode>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/BSON-Decode>

=item * Search CPAN

L<http://search.cpan.org/dist/BSON-Decode/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2016 DULAUNOY Fabrice.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of BSON::Decode
