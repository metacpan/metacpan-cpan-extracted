# Copyright (c) 2007-2012 David Caldwell,  All Rights Reserved. -*- perl -*-

package Darcs::Inventory; use strict; use warnings;
our $VERSION = '1.7';

use Darcs::Inventory::Patch;

sub read($) {
    my ($filename) = @_;
    my (@patch, $patch);
    open INV, "<", $filename or return undef;
    while (<INV>) {
        next if /^pristine:$/ && !defined $patch;
        $patch[-1] .= "\n$1" if /^(hash: .*)$/ && !defined $patch;
        (push(@patch, $patch . ($1||"")), undef $patch) if s/^(.*\*[-*]\d{14})?\]//;
        $patch = '' if !defined $patch && s/^\s*\[//;
        $patch .= $_ if defined $patch;
    }
    close INV;
    \@patch;
}

sub load($$) {
    my ($class, $filename) = @_;
    my $patch = Darcs::Inventory::read($filename);
    return undef unless $patch;
    bless { patches => [map { new Darcs::Inventory::Patch($_) } @$patch],
            file    => $filename }, $class;
}

sub new($$) {
    my ($class, $repo) = @_;

    my $repo_format = eval {
        local $/;
        open FORMAT, '<', "$repo/_darcs/format" or return "old";
        my $f = <FORMAT>;
        close FORMAT;
        $f
    };
    my $inventory_file = $repo_format =~ /hashed/ ? "$repo/_darcs/hashed_inventory" : "$repo/_darcs/inventory";
    my $inventory = $class->load($inventory_file);
    return undef unless $inventory;
    $inventory->{format} = $repo_format;
    $inventory;
}

sub format($)  { return $_[0]->{format} || "unknown" };
sub file($)    { return $_[0]->{file} };
sub patches($) { return @{$_[0]->{patches}} };

1;
__END__

=head1 NAME

Darcs::Inventory - Read and parse a darcs version 1 or 2 inventory file

=head1 SYNOPSIS

    use Darcs::Inventory;
    $i = Darcs::Inventory->new("path/to/repo");
    $i = Darcs::Inventory->load("path/to/repo/_darcs/inventory");
    for ($i->patches) {
        print $_->info;
    }
    $i->format; # contents of _darcs/format, or "old", or "unknown"
    $i->file;   # The path to the inventory file.

    @raw = Darcs::Inventory::read("_darcs/inventory");
    print $raw[0];         # Prints the unparsed contents of the
                           # first patch in the inventory file.

=head1 DESCRIPTION

    B<Darcs::Inventory> reads an inventory file and returns some
    information on it, including the parsed list of patches in the
    form of B<L<Darcs::Inventory::Patch>> objects.

=head1 FUNCTIONS

=over 4

=item Darcs::Inventory->new("path/to/repo")

This reads the standard inventory from a darcs repo. Don't pass in the
F<_darcs> directory, that is implied. This will return an inventory
object that you can use to do further queries.

=item Darcs::Inventory->load("path/to/repo/_darcs/inventory")

This reads a specific inventory file. It doesn't have to be inside a
F<_darcs> directory, that's just an example. This will return an
inventory object just like B<new> that you can use to do further
queries.

=item $inventory->patches

Returns a list of B<L<Darcs::Inventory::Patch>> objects--one for each
patch in the inventory.

=item $inventory->format

If the $inventory was created with the B<new> function, then this will
return the contents of the F<_darcs/format> file, or "old" if there
was no F<_darcs/format> file in the repo.

If the $inventory was created with the B<load> function, then this
will always return "unknown".

Since this can be multiple lines, the general use case is probably
something like:

 if ($inventory->format =~ /hashed/) its_a_hashed_repo();

=item $inventory->file

This returns the path that was loaded. This is really only helpful
with inventory objects created by the B<new> function since darcs
repos store the inventory in F<_darcs/inventory> or
F<_darcs/hashed_inventory> based on the format.

=item Darcs::Inventory::read("path/to/repo")

This returns a list of strings. Each string is the raw lines of the
inventory file split on patch boundaries, but not yet parsed.

This is probably not very useful to you unless you are doing something
crazy.

=back

=head1 LIMITATIONS

Currently the B<new> function only loads in the main inventory
file. This means it will generally only read patches until the last
tag. Darcs moves patches past the last tag into separate inventory
files as some sort of optimization. This means if you are trying to
diff inventories with B<L<Darcs::Inventory::Diff>> that you can only
diff until the last tag.

Currently the B<load> function does not handle darcs repos in the new
style F<_darcs/inventories/> directory. These file are compressed and
I haven't yet needed to write the code to deal with them.

=head1 SEE ALSO

L<Darcs::Inventory::Patch>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2007-2012 David Caldwell

=head1 AUTHOR

David Caldwell <david@porkrind.org>

=cut
