package Brackup::Target::Filebased;
use strict;
use warnings;
use base 'Brackup::Target';

# version >= 1.06: 01/23/0123456789abcdef...xxx.chunk
# 256 * 256 directories, then files.  would need 2 billion
# files before leaves have 32k+ files, but at that point
# users are probably using better filesystems if they
# have 2+ billion inodes.
sub chunkpath {
    my ($self, $dig) = @_;
    my @parts;
    my $fulldig = $dig;

    $dig =~ s/^\w+://; # remove the "hashtype:" from beginning
    $fulldig =~ s/:/./g if $self->nocolons; # Convert colons to dots if we've been asked to

    while (length $dig && @parts < 2) {
        $dig =~ s/^([0-9a-f]{2})// or die "Can't get 2 hex digits of $fulldig";
        push @parts, $1;
    }

    return join("/", @parts) . "/$fulldig.chunk";
}

sub metapath {
    my ($self, $name) = @_;

    $name ||= '';

    return "backups/$name";
}

1;
