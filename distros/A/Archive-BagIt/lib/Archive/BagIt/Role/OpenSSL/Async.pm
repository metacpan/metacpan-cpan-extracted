package Archive::BagIt::Role::OpenSSL::Async;
use strict;
use warnings;
use Moo;
use namespace::autoclean;
use IO::Async::Loop;
use IO::Async::Stream;
use Net::SSLeay ();
our $VERSION = '0.086'; # VERSION
# ABSTRACT: handles asynchronous digest calculation using openssl

sub BEGIN {
    Net::SSLeay::OpenSSL_add_all_digests();
    is => 'rw',

}

has 'name' => (
    required => 1,
    is       => 'ro',
);

has '_io_loop' => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        IO::Async::Loop->new
    },
);

has '_digest' => (
    is => 'ro',
    lazy => 1,
    builder => '_init_digest',
    init_arg => undef,
);

sub _init_digest {
    my ($self) = @_;
    my $md  = Net::SSLeay::EVP_get_digestbyname($self->name);
    my $digest = Net::SSLeay::EVP_MD_CTX_create();
    Net::SSLeay::EVP_DigestInit($digest, $md);
    return $digest;
}



sub calc_digest {
    my ($self, $fh, $blksize)=@_;
    my $loop = $self->_io_loop();
    my $stream = IO::Async::Stream->new(
        read_handle       => $fh,
        read_len          => 1000 * $blksize,
        on_read           => sub {
            my ($s, $buffref, $eof) = @_;
            if (defined $$buffref) {
                Net::SSLeay::EVP_DigestUpdate($self->_digest, $$buffref);
                $$buffref = undef;
            }
            return 0;
        },
        on_read_eof       => sub {
            $loop->stop();
        },
        close_on_read_eof => 0,
        on_error          => sub {
            croak (@_);
        }
    );
    $loop->add($stream);
    $loop->run();
    $loop->remove($stream);
    my $result = Net::SSLeay::EVP_DigestFinal($self->_digest);
    Net::SSLeay::EVP_MD_CTX_destroy($self->_digest);
    delete $self->{_digest};
    return unpack('H*', $result);
}


no Moo;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Role::OpenSSL::Async - handles asynchronous digest calculation using openssl

=head1 VERSION

version 0.086

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
