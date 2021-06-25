package Archive::BagIt::Fast;
use strict;
use warnings;
use IO::AIO ();
use Carp qw( croak );
use Time::HiRes qw( time );
use Moo;
extends "Archive::BagIt";

our $VERSION = '0.075'; # VERSION

# ABSTRACT: A module to use IO::AIO to het better performance


has 'digest_callback' => (
    is      => 'ro',
    lazy    => 1,
    builder => sub {
        my ($self) = shift;
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
            my $data;
            if ($filesize < $MMAP_MIN ) {
                sysread $fh, $data, $filesize;
                Net::SSLeay::EVP_DigestUpdate($digestobj->_digest, $data);
                my $result = Net::SSLeay::EVP_DigestFinal($digestobj->_digest);
                Net::SSLeay::EVP_MD_CTX_destroy($digestobj->_digest);
                delete $digestobj->{_digest};
                $digest = unpack('H*', $result);
            }
            elsif ( $filesize < 1500000000) {
                IO::AIO::mmap $data, $filesize, IO::AIO::PROT_READ, IO::AIO::MAP_SHARED, $fh or croak "mmap: $!";
                Net::SSLeay::EVP_DigestUpdate($digestobj->_digest, $data);
                my $result = Net::SSLeay::EVP_DigestFinal($digestobj->_digest);
                Net::SSLeay::EVP_MD_CTX_destroy($digestobj->_digest);
                delete $digestobj->{_digest};
                $digest = unpack('H*', $result);
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

Archive::BagIt::Fast - A module to use IO::AIO to het better performance

=head1 VERSION

version 0.075

=head1 NAME

Archive::BagIt::Fast - For people who are willing to rely on some other modules in order to get better performance

=head1 HINTs

Use this module only if you have *measured* that your environment has a benefit. The results vary highly depending on
typical file size, filesystem and storage systems.

=head1 METHODS

=over

=item digest_callback()

register a callback function with method to calculate and return all digests for a a list of files using a Digest-object. This method implements fast
file access using memory mapped I/O by IO::AIO.

=back

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Rob Schmidt and William Wueppelmann and Andreas Romeyke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
