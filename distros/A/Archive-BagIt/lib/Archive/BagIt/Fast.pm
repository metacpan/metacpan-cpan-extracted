package Archive::BagIt::Fast;
use strict;
use warnings;
use Carp qw( carp croak );
use Time::HiRes qw( time );
use Moo;
use IO::AIO ();
use Net::SSLeay ();
extends "Archive::BagIt";


our $VERSION = '0.086'; # VERSION

# ABSTRACT: A module to use L<IO::AIO> to get better performance


sub BEGIN {
    Net::SSLeay::OpenSSL_add_all_digests();
}

sub _XXX_digest {
    my $digestobj = shift;
    my $data_ref = shift;
    my $data = ${ $data_ref };
    my $md  = Net::SSLeay::EVP_get_digestbyname($digestobj->name);
    my $internal_digest = Net::SSLeay::EVP_MD_CTX_create();
    Net::SSLeay::EVP_DigestInit($internal_digest, $md);
    Net::SSLeay::EVP_DigestUpdate($internal_digest, $data);
    my $result = Net::SSLeay::EVP_DigestFinal($internal_digest);
    Net::SSLeay::EVP_MD_CTX_destroy($internal_digest);
    my $digest = unpack('H*', $result);
    return $digest;

}

sub sysread_based_digest {
    my $digestobj = shift;
    my $fh = shift;
    my $filesize = shift;
    my $data;
    sysread $fh, $data, $filesize;
    return _XXX_digest( $digestobj, \$data);
}

sub mmap_based_digest {
    my $digestobj = shift;
    my $fh = shift;
    my $filesize = shift;
    my $data='';
    if ($filesize > 0) {
        if (! IO::AIO::mmap $data, $filesize, IO::AIO::PROT_READ, IO::AIO::MAP_SHARED, $fh) {
            carp "mmap fails, fall back to sysread";
            sysread $fh, $data, $filesize;
        };
    }
    return _XXX_digest($digestobj, \$data);
}

has 'digest_callback' => (
    is      => 'ro',
    lazy    => 1,

    builder => sub {
        my ($self) = shift;
        #my $sub = sub {
        #    my ($digestobj, $filename) = @_;
        #    open(my $fh, "<:raw", "$filename") or croak ("Cannot open $filename, $!");
        #    binmode($fh);
        #    my $digest = $digestobj->get_hash_string($fh);
        #    close $fh || croak("could not close file '$filename', $!");
        #    return $digest;
        #};
        my $sub = sub {
            my $digestobj = shift;
            my $filename =shift;
            my $opts = shift;
            my $MMAP_MIN = $opts->{mmap_min} || 8000000;
            my $filesize = -s $filename;
            open(my $fh, "<:raw", "$filename") or croak ("Cannot open $filename, $!");
            $self->{stats}->{files}->{"$filename"}->{size}= $filesize;
            $self->{stats}->{size} += $filesize;
            my $start_time = time();
            my $digest;
            if ($filesize < $MMAP_MIN ) {
                return sysread_based_digest($digestobj, $fh, $filesize);
            }
            elsif ( $filesize < 1500000000) {
                return mmap_based_digest($digestobj, $fh, $filesize);
            }
            else {
                $digest = $digestobj->get_hash_string($fh);
            }
            my $finish_time = time();
            $self->{stats}->{files}->{"$filename"}->{verify_time}= ($finish_time - $start_time);
            $self->{stats}->{verify_time} += ($finish_time-$start_time);
            close($fh);
            return $digest;
        };
        return $sub;
    }
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Fast - A module to use L<IO::AIO> to get better performance

=head1 VERSION

version 0.086

=head1 NAME

Archive::BagIt::Fast - For people who are willing to rely on some other modules in order to get better performance

=head1 HINTs

Use this module only if you have *measured* that your environment has a benefit. The results vary highly depending on
typical file size, filesystem and storage systems.

=head1 METHODS

=over

=item digest_callback()

register a callback function with method to calculate and return all digests for a a list of files using a Digest-object. This method implements fast
file access using memory mapped I/O by L<IO::AIO>.

=item mmap_based_digest($digestobj, $fh, $filesize)

internal funtion which uses mmap to calculate digest. Called by C<digest_callback>

=item sysread_based_digest($digestobj, $fh, $filesize)

internal function which uses sysread to calculate digest. Called by C<digest_callback>

=back

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Andreas Romeyke <cpan@andreas.romeyke.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Rob Schmidt <rjeschmi@gmail.com>, William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
