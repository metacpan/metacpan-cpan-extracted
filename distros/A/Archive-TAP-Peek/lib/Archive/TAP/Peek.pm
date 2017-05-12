# ABSTRACT: Look into TAP-Archives

package Archive::TAP::Peek;
{
  $Archive::TAP::Peek::VERSION = '0.002';
}

use strict;
use warnings;

use Archive::Extract;
use File::Temp qw( tempdir );
use TAP::Parser;

sub new {
    my $class = shift;

    my %args = @_;

    my $self = { error_found => 0 };

    die "Parameter 'archive' needed" unless exists $args{archive};

    die "$args{archive} not found" unless -f $args{archive};

    my $ae = Archive::Extract->new( archive => $args{archive},
                                    type => 'tgz'
                                  );
    
    die "$args{archive} is not of type 'tgz'" unless $ae->is_tgz;
    
    my $tmpdir = tempdir( CLEANUP => 1 );
    
    $ae->extract( to => $tmpdir ) or die $ae->error;
    
    my $files = $ae->files;
    
    my $outdir = $ae->extract_path;
    
    foreach my $f (@{$files}) {
    
        next unless ( $f =~ /.*\.t$/);
    
        # code from here:
        # http://stackoverflow.com/questions/13781443/capture-and-split-tap-output-result
        my $tap_file = $outdir . '/' . $f; 
        open my $tap_fh, $tap_file or die $!; 
        
        # Can't just pass in the .t file, it will try to execute it.
        my $parser = TAP::Parser->new({
            source => $tap_fh
        }); 
        
        while ( my $result = $parser->next ) {
            # do whatever you like with the $result, like print it back out
            my $line = $result->as_string;

            if ($line =~ /^ok/) {
                # everything is fine... keep going on
            }
            elsif ($line =~ /^not ok/) {
                # oops! error.
                $self->{error_found} = 1;

                # we break here... since we already know there are failures
                last;
            }
            else {
                # some other lines we don't need
            }
        }
    
    }

    bless ($self, $class);

    return $self;
}

sub all_ok {
    my $self = shift;

    if( $self->{error_found} ) {
        return;
    }
    else {
        return 1;
    }
}

1;

__END__

=pod

=head1 NAME

Archive::TAP::Peek - Look into TAP-Archives

=head1 VERSION

version 0.002

=head1 SYNOPSIS

 use Archive::TAP::Peek;

 my $peek = Archive::TAP::Peek->new( archive => 'tests.tar.gz' );

 if( $peek->all_ok ) {
     print "No errors in archive\n";
 }

=encoding utf8

=head1 ABOUT

This is a software library for the I<perl programming language>.

The modul can be of help for you if you have TAP archives (e.g. created with C<prove -a> and now you wish to know something about the outcomes of the test-results inside the archive.

=head1 METHODS

=head2 all_ok

Returns a true value if no errors where found in the archive, otherwise false.

 if( $peek->all_ok ) {
     print "No errors in archive\n";
 }

=head1 BUGS AND LIMITATIONS

Archive gets unpacked into a temproary directory.
Could maybe be made on-the-fly with L<Archive::Peek>.

=head1 SEE ALSO

=over

=item *

L<Test::Harness>

=back

=head1 AUTHOR

Boris Däppen <bdaeppen.perl@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Boris Däppen, plusW.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
