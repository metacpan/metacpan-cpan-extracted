package Archive::BagIt::Fast;

use strict;
use warnings;
use parent "Archive::BagIt::Base";

our $VERSION = '0.059'; # VERSION

use IO::AIO;
use Time::HiRes qw(time);

sub calc_digests {
    my ($self, $bagit, $digestobj, $filenames_ref, $opts) = @_;
    my $MMAP_MIN = $opts->{mmap_min} || 8000000;

    my @digest_hashes = map {
        my $localname = $_;
        my $fullname = $bagit ."/". $localname;
        my $tmp;
        open(my $fh, "<:raw", "$fullname") or die ("Cannot open $fullname");
        stat $fh;
        $self->{stats}->{files}->{"$fullname"}->{size}= -s _;
        $self->{stats}->{size} += -s _;
        my $start_time = time();
        my $digest;
        if (-s _ < $MMAP_MIN ) {
            sysread $fh, my $data, -s _;
            $digest = $digestobj->_digest->add($data)->hexdigest;
        }
        elsif ( -s _ < 1500000000) {
            IO::AIO::mmap my $data, -s _, IO::AIO::PROT_READ, IO::AIO::MAP_SHARED, $fh or die "mmap: $!";
            $digest = $digestobj->_digest->add($data)->hexdigest;
        }
        else {
            $digest = $digestobj->_digest->addfile($fh)->hexdigest; # FIXME: use plugins instead
        }
        my $finish_time = time();
        $self->{stats}->{files}->{"$fullname"}->{verify_time}= ($finish_time - $start_time);
        $self->{stats}->{verify_time} += ($finish_time-$start_time);
        close($fh);
        $tmp->{calculated_digest} = $digest;
        $tmp->{local_name} = $localname;
        $tmp->{full_name} = $fullname;
        $tmp;
    } @{$filenames_ref};
    return \@digest_hashes;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Archive::BagIt::Fast

=head1 VERSION

version 0.059

=head1 NAME

Archive::BagIt::Fast

=head1 VERSION

version 0.059

=head1 NAME

Archive::BagIt::Fast - For people who are willing to rely on some other modules in order to get better performance

=head1 HINTs

Use this module only if you have *measured* that your environment has a benefit. The results vary highly depending on
typical file size, filesystem and storage systems.

=head1 METHODS

=over

=item calc_digests($bagit, $digestobj, $filenames_ref, $opts)

Method to calculate and return all digests for a a list of files using a Digest-object. This method implements fast
file access using memory mapped I/O by IO::AIO.

=back

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<https://metacpan.org/module/Archive::BagIt/>.

=head1 SOURCE

The development version is on github at L<https://github.com/Archive-BagIt>
and may be cloned from L<git://github.com/Archive-BagIt.git>

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<http://rt.cpan.org>.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Rob Schmidt <rjeschmi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Rob Schmidt and William Wueppelmann.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
