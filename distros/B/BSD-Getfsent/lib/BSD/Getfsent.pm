package BSD::Getfsent;

use strict;
use warnings;
use base qw(Exporter);

use Carp qw(croak);
use IO::File ();

our ($VERSION, @EXPORT_OK, $ENTRIES, $FSTAB);

$VERSION = '0.17';
@EXPORT_OK = qw(getfsent);
$ENTRIES = __PACKAGE__ . '::_fsents';
$FSTAB = '/etc/fstab';

sub getfsent
{
    if (wantarray) {
        no strict 'refs';

        unless (${$ENTRIES}) {
            @{$ENTRIES} = @{_parse_entries()};
            ${$ENTRIES} = 1;
        }

        if (@{$ENTRIES}) {
            return @{shift @{$ENTRIES}};
        }
        else {
            ${$ENTRIES} = 0;
            return ();
        }
    }
    else { return _count_entries() }
}

sub _parse_entries
{
    my @entries;
    my $fh = _open_fh();

    while (local $_ = <$fh>) {
        next if /^\#/;

        chomp;
        my @entry = split;

        if ($entry[3] !~ /,/) {                       # In case element 4, fs_type, doesn't
            splice(@entry, 3, 1, '', $entry[3]);      # contain fs_mntops, insert blank fs_mntops
        }                                             # at index 3 and move fs_type to index 4.
        else {                                        # In case element 4 contains fs_type and
            splice(@entry, 3, 1,                      # fs_mntops, switch fs_mntops to index 3 and
              (reverse split ',', $entry[3], 2));     # fs_type to index 4.
        }

        push @entries, [ @entry ];
    }

    _close_fh($fh);

    return \@entries;
}

sub _count_entries
{
    my $counted_entries;

    my $fh = _open_fh();
    $counted_entries++ while <$fh>;
    _close_fh($fh);

    return $counted_entries;
}

sub _open_fh
{
    my $fh = IO::File->new("<$FSTAB")
      or croak "Can't open $FSTAB: $!";

    return $fh;
}

sub _close_fh
{
    my ($fh) = @_;
    $fh->close;
}

1;
__END__

=head1 NAME

BSD::Getfsent - Get file system descriptor file entry

=head1 SYNOPSIS

 use BSD::Getfsent qw(getfsent);

 while (@entry = getfsent()) {
    print "@entry\n";
 }

=head1 FUNCTIONS

=head2 getfsent

In list context, each file system entry is returned (C<getfsent()>
continuously reads the next line of the F</etc/fstab> file).

The list returned is structured as follows:

 $entry[0]    # block special device name
 $entry[1]    # file system path prefix
 $entry[2]    # type of file system
 $entry[3]    # comma separated mount options
 $entry[4]    # rw, ro, sw, or xx
 $entry[5]    # dump frequency, in days
 $entry[6]    # pass number on parallel fsck

In scalar context, total of entries is returned.

=head1 FILES

F</etc/fstab>

=head1 EXPORT

C<getfsent()> is exportable.

=head1 BUGS & CAVEATS

C<BSD::Getfsent> was, as it name suggests, developed for BSD-like systems.
It may be nevertheless suitable for other UNIX-like systems, including Linux,
but remains untested. Bear in mind, that tests will fail if no F</etc/fstab>
can be found (in order that testing on systems like Windows, where no
F</etc/fstab> exists, doesn't result in a false positive).

=head1 SEE ALSO

fstab(5), getfsent(3)

=head1 AUTHOR

Steven Schubiger <schubiger@cpan.org>

=head1 LICENSE

This program is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
