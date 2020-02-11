# ************************************************************************* 
# Copyright (c) 2014-2020, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package App::CELL::Test;

use strict;
use warnings;
use 5.012;

use App::CELL::Log qw( $log );
use File::Spec;

=head1 NAME

App::CELL::Test - functions for unit testing 


=head1 SYNOPSIS

    use App::CELL::Test;

    App::CELL::Test::cleartmpdir();
    my $tmpdir = App::CELL::Test::mktmpdir();
    App::CELL::Test::touch_files( $tmpdir, 'foo', 'bar', 'baz' );
    my $booltrue = App::CELL::Test::cmp_arrays(
        [ 0, 1, 2 ], [ 0, 1, 2 ]
    );
    my $boolfalse = App::CELL::Test::cmp_arrays(
        [ 0, 1, 2 ], [ 'foo', 'bar', 'baz' ]
    );


=head1 DESCRIPTION

The C<App::CELL::Test> module provides a number of special-purpose functions for
use in CELL's test suite. 



=head1 EXPORTS

This module exports the following routines:
    cleartmpdir
    cmp_arrays
    mktmpdir
    populate_file
    touch_files

=cut 

use Exporter qw( import );
our @EXPORT_OK = qw( cleartmpdir cmp_arrays mktmpdir populate_file 
                     touch_files _touch );



=head1 PACKAGE VARIABLES

=cut

our $tdo;  # temporary directory object



=head1 FUNCTIONS


=head2 mktmpdir

Creates the App::CELL testing directory in a temporary directory
(obtained using L<File::Temp>) and returns the path to this directory in
the payload of a status object.

=cut

sub mktmpdir {

    use Try::Tiny;

    try { 
        use File::Temp;
        $tdo = File::Temp->newdir();
    }
    catch {
        my $errmsg = $_ || '';
        $errmsg =~ s/\n//g;
        $errmsg =~ s/\012/ -- /g;
        return App::CELL::Status->new( level => 'ERR',
            code => 'CELL_CREATE_TMPDIR_FAIL',
            args => [ $errmsg ],
        );
    };
    $log->debug( "Created temporary directory" . $tdo );
    return App::CELL::Status->ok( $tdo->dirname );
}


=head2 cleartmpdir

DESTROYs the temporary directory object (see L<File::Temp>).

=cut

sub cleartmpdir { 
    $tdo->DESTROY if defined $tdo;
    return App::CELL::Status->ok;
}


=head3 _touch

Touch a file

=cut

sub _touch {
    my ( $file ) = @_;
    my $now = time;

    utime ($now, $now, $file)
                || open my $fh, ">>", $file
                || warn ("Couldn't touch file: $!\n");
} 


=head2 touch_files

"Touch" some files. Takes: directory path and list of files to "touch" in
that directory. Returns number of files successfully touched.

=cut

sub touch_files { 
    my ( $dirspec, @file_list ) = @_;
    use Try::Tiny;

    my $count = @file_list;
    try {
        foreach my $file ( map { File::Spec->catfile( $dirspec, $_ ); } @file_list ) {
            _touch( $file );
        }
    }
    catch {
        my $errmsg = $_;
        $errmsg =~ s/\n//g;
        $errmsg =~ s/\012/ -- /g;
        $errmsg = "Attempting to 'touch' $count files in $dirspec . . . failure: $errmsg";
        $log->debug( $errmsg );
        print STDERR $errmsg, "\n";
        return 0;
    };
    $log->debug( "Attempting to 'touch' $count files in $dirspec . . .  success" );
    return $count;
}


=head2 populate_file 

Takes filename (full path) and contents (as a string, potentially
containing newlines) to write to it. If the file exists, it is first
unlinked. Then the routine creates the file and populates it with
the contents. Returns true if something was written, or false if not.

=cut

sub populate_file {
    my ( $full_path, $contents ) = @_;
    unlink $full_path;
    {
        _touch( $full_path ) or die "Could not touch $full_path";
    }
    return 0 unless -f $full_path and -W $full_path;
    return 0 unless $contents;
    open(my $fh, '>', $full_path ) or die "Could not open file: $!";
    print $fh $contents;
    close $fh;
    return length $contents;
}

=head2 cmp_arrays

Compare two arrays of unique elements, order doesn't matter. 
Takes: two array references
Returns: true (they have the same elements) or false (they differ).

=cut

sub cmp_arrays {
    my ( $ref1, $ref2 ) = @_;
        
    $log->debug( "cmp_arrays: we were asked to compare two arrays:");
    $log->debug( "ARRAY #1: " . join( ',', @$ref1 ) );
    $log->debug( "ARRAY #2: " . join( ',', @$ref2 ) );

    # convert them into hashes
    my ( %ref1, %ref2 );
    map { $ref1{ $_ } = ''; } @$ref1;
    map { $ref2{ $_ } = ''; } @$ref2;

    # make a copy of ref1
    my %ref1_copy = %ref1;

    # for each element of ref1, if it matches an element in ref2, delete
    # the element from _BOTH_ 
    foreach ( keys( %ref1_copy ) ) {
        if ( exists( $ref2{ $_ } ) ) {
            delete $ref1{ $_ };
            delete $ref2{ $_ };
        }
    }

    # if the two arrays are the same, the number of keys in both hashes should
    # be zero
    $log->debug( "cmp_arrays: after comparison, hash #1 has " . keys( %ref1 )
    . " elements and hash #2 has " . keys ( %ref2 ) . " elements" );
    if ( keys( %ref1 ) == 0 and keys( %ref2 ) == 0 ) {
        return 1;
    } else {
        return 0;
    }
}

1;
