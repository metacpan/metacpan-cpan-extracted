package CPAN::ReleaseHistory::ReleaseIterator;
$CPAN::ReleaseHistory::ReleaseIterator::VERSION = '0.15';
use Moo;
use CPAN::ReleaseHistory;
use CPAN::ReleaseHistory::Release;
use CPAN::DistnameInfo;
use autodie;

has 'history' =>
    (
        is      => 'ro',
        default => sub { return PAUSE::Packages->new(); },
    );

has 'well_formed' =>
    (
        is      => 'ro',
        default => sub { 0 },
    );

has _fh => ( is => 'rw' );

sub next_release
{
    my $self = shift;
    my $fh;
    local $_;

    if (not defined $self->_fh) {
        $fh = $self->history->open_file();

        # skip the header line.
        # TODO: should confirm that it's the format we expect / support
        my $header_line = <$fh>;
        $self->_fh($fh);
    }
    else {
        $fh = $self->_fh;
    }

    RELEASE:
    while (1) {
        my $line = <$fh>;

        if (defined($line)) {
            chomp($line);
            my ($path, $time, $size) = split(/\s+/, $line);
            my @args                 = (path => $path, timestamp => $time, size => $size);

            if ($self->well_formed) {
                my $distinfo = CPAN::DistnameInfo->new($path);

                next RELEASE unless defined($distinfo)
                                 && defined($distinfo->dist)
                                 && defined($distinfo->cpanid);
                push(@args, distinfo => $distinfo);
            }

            return CPAN::ReleaseHistory::Release->new(@args);
        } else {
            return undef;
        }
    }
}

1;

=head1 NAME

CPAN::ReleaseHistory::ReleaseIterator - Release iterator for CPAN::ReleaseHistory.

=head1 DESCRIPTION

B<FOR INTERNAL USE ONLY>

=head1 REPOSITORY

L<https://github.com/neilbowers/CPAN-ReleaseHistory>

=head1 AUTHOR

Neil Bowers E<lt>neilb@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Neil Bowers <neilb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
