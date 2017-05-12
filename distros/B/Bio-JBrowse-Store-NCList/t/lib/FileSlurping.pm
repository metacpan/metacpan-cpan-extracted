=head1 NAME

FileSlurping - utility functions for slurping the contents of files in tests

=head1 FUNCTIONS

All functions below are exportable.

=cut

package FileSlurping;
use strict;
use warnings;

use Carp::Always;

use base 'Exporter';
our @EXPORT_OK = qw( slurp_tree slurp slurp_stream );

use File::Spec;

use File::Next;
use JSON 2 ();


=head2 slurp_tree( $dir )

Slurp an entire file tree full of .json files into a hashref indexed
by the B<relative> file name.  If two directory trees contain the same
files, slurp_tree on each of them will return the same contents.

=cut

sub slurp_tree {
    my ( $dir ) = @_;

    my %data;

    my $output_files_iter = File::Next::files( $dir );
    while( my $file = $output_files_iter->() ) {
        next if $file =~ /\.htaccess$/;
        my $rel = File::Spec->abs2rel( $file, $dir );
        $data{ $rel } = slurp( $file );
    }

    return \%data;
}

=head2 slurp

Slurp a single file and return it.  Uncompresses .jsonz and .gz files,
and decodes the JSON in .json and .jsonz files.

Because adding a dep on L<File::Slurp> for this is silly.

=cut

sub slurp {
    if( @_ > 1 ) {
        @_ = ( File::Spec->catfile( @_ ) );
    }

    my $gzip = $_[0] =~ m!\.(gz|jsonz)$! ? ':gzip' : '';
    my $contents = do {
        open my $f, "<$gzip", $_[0] or die "$! reading $_[0]";
        local $/;
        <$f>;
    };

    if( $_[0] =~ /\.jsonz?$/ ) {
        $contents = JSON::from_json( $contents );
    }

    return $contents;
}


=head2 slurp_stream( $stream )

Slurp an entire stream and return its contents as a list.

=cut

sub slurp_stream {
    my ( $stream ) = @_;
    my @results;
    while( my $f = $stream->() ) {
        push @results, $f;
    }
    return @results;
}


1;
