# Copyright (c) 2007-2012 David Caldwell,  All Rights Reserved. -*- perl -*-

package Darcs::Inventory::Patch; use base qw(Class::Accessor::Fast); use warnings; use strict;

use Digest::SHA qw(sha1_hex);
use Time::Local qw(timegm);
use POSIX qw(strftime);
use IPC::Run qw(run);

Darcs::Inventory::Patch->mk_accessors(qw(date raw_date author undo name long hash file raw));

sub darcs_date_str($) { strftime "%a %b %e %H:%M:%S %Z %Y", localtime $_[0] }

sub date_from_darcs($) {
    $_[0] =~ /(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2})/ or die "Couldn't parse date: $_[0]";
    my ($y,$m,$d,$h,$min,$s) = ($1,$2,$3,$4,$5,$6);
    timegm($s,$min,$h,$d,$m-1,$y);
}

sub parse_patch($) {
    my @line = split /\n/, $_[0];
    my %patch;
    ($patch{file} = $1, pop @line) if $line[-1] =~ /^hash: ([0-9]{10}-[0-9a-f]{64})$/;
    @patch{qw(name meta long)} = (shift @line, shift @line, join "", map substr("$_\n",1), @line);
    chomp $patch{long};
    # Jim Radford <radford@golemgroup.com>**20061013045032] 
    $patch{meta} =~ /^(.*)\*([-*])(\d{14})/ or die __PACKAGE__.": Internal Error--Couldn't parse patch:\n$_[0]\n";
    @patch{qw(author undo date raw_date raw)} = ($1, !!($2 eq '-'), date_from_darcs($3), $3, $_[0]);

    # This hash code comes from reading this: http://wiki.darcs.net/DarcsWiki/NamedPatch
    # Which roughly documents the make_filename function in darcs' src/Darcs/Patch/Info.lhs file.
    my $hashee = join('', @patch{qw(name author raw_date long)}).($patch{undo} ? 't' : 'f');
    $hashee =~ s/\n//g;
    #$patch{computed} = $hashee;
    $patch{hash} = $patch{raw_date}. '-' .substr(sha1_hex($patch{author}), 0, 5). '-' . sha1_hex($hashee).'.gz';
    $patch{file} ||= $patch{hash};
    %patch;
}

sub new($$) {
    my ($class, $patch_string) = @_;
    my %patch = parse_patch($patch_string);
    return bless { %patch }, $class;
}

sub darcs_date($) {
    darcs_date_str $_[0]->date
}

sub as_string($) {
    my ($p) = @_;
    my $s = sprintf("%s %s\n  %s %s\n%s\n", $p->darcs_date, $p->author, $p->undo ? 'UNDO:' : '*', $p->name, $p->long);
    $s =~ s/^Ignore-this:\s+[0-9a-f]+\n//m;
    $s;
}

sub diff($) {
    my ($self) = @_;
    my $error;
    run([qw(darcs diff -u --match), "hash ".$self->hash], '>', \$self->{diff}, '2>', \$error) or die "$error\n"
        unless defined $self->{diff};
    return $self->{diff};
}

sub diffstat($) {
    my ($self) = @_;
    unless ($self->{diffstat}) {
        my $diff = $self->diff;
        my $error;
        run([qw(diffstat)], '<', \$diff, '>', \$self->{diffstat}, '2>', \$error) or die "$error\n";
    }
    $self->{diffstat};
}

use overload '""' => \&as_string;

1;
__END__

=head1 NAME

Darcs::Inventory::Patch - Object interface to patches read from the darcs inventory file

=head1 SYNOPSIS

    use Darcs::Inventory;
    $i = Darcs::Inventory->new("darcs_repo_dir");
    for ($i->patches) {
        print $_->date, "\n";         # eg: 1193248123
        print $_->darcs_date, "\n";   # eg: 'Wed Oct 24 10:48:43 PDT 2007'
        print $_->raw_date, "\n";     # eg: '20071024174843'
        print $_->author, "\n";       # eg: 'David Caldwell <david@porkrind.org>'
        print $_->undo, "\n";         # a boolean
        print $_->name, "\n";         # First line of recorded message
        print $_->long, "\n";         # Rest of recorded message (including newlines)
        print $_->hash, "\n";         # eg: '20071024174843-c490e-9dab450fd814405d8391c2cff7a4bce33c6a8234.gz'
        print $_->file, "\n";         # eg: '0000001672-d672e8c18c22cbd4cc8e65fe80a39e68384133083b0f623ae5d57cc563e5630b'
                                      # (Usually found in "_darcs/patches/")
        print $_->raw, "\n";          # The unparsed lines from the inventory for this patch
        print $_->as_string, \n";     # The friendly darcs output (like in `darcs changes')
        print "$_\n";                 # Same as above.
        print $_->diff, \n";          # Runs `darcs' to compute the universal diff of the patch.
        print $_->diffstat, \n";      # Runs `diffstat' on $_->diff output.
    }

    # Or, if you want to do it by hand for some reason:
    use Darcs::Inventory::Patch;
    @raw = Darcs::Inventory::read("darcs_repo_dir/_darcs/inventory");
    $patch = Darcs::Inventory::Patch->new($raw[0]);

=head1 DESCRIPTION

Darcs::Inventory::Patch is an object oriented interface to darcs
inventory patches.

=head1 FUNCTIONS

=over 4

=item Darcs::Inventory::Patch->new($patch_lines)

This parses the lines from a darcs inventory file of patch and returns
an object to use for querying.

You probably don't want to use this function directly. Instead, use
B<< L<Darcs::Inventory>->new >> or B<< L<Darcs::Inventory>->load >> to
parse the whole inventory.

=item $patch->date

This returns the time of the patch in "integer seconds since the
epoch" format (GMT timezone). For instance: C<1193248123>.

=item $patch->raw_date

The date from the inventory file (as a string). It will look something
like this: C<"20071024174843">.

=item $patch->darcs_date

The date in darcs format as a string. It will look something like
this: C<"Wed Oct 24 10:48:43 PDT 2007">

=item $patch->author

The author string.

=item $patch->undo

This is true if it is an inverted (or undo) patch created by old
versions of "darcs rollback". The newer darcs' rollback command
works differently and doesn't set this bit any more.

=item $patch->name

This returns the first line of the record comment as a string (with no newline).

=item $patch->long

This contains the long part of the record comment (lines 2 and on) as
a string (with no newline on the last line).

=item $patch->hash

This is a the hash of the patch. You can use this in darcs' B<--match> option:

  darcs diff --match="hash $hash"

=item $patch->file

This is the filename of the patch. This is where the actual patch
contents go. It is usually found in F<_darcs/patches/$file>.

=item $patch->raw

This is the unparsed patch lines from the inventory file.

=item $patch->as_string

This returns the patch in friendly darcs text form, a la `C<darcs changes>'.

=item "$patch"

Stringifying the patch will also give you the same results of B<< $patch->as_string >>.

=item $patch->diff

This returns the universal diff of a patch. This is implented by running
"darcs diff -u --match "hash $patch->hash" and collecting the output.

=item $patch->diffstat

This returns the diffstat of a patch. This requires the external
program "diffstat" as it is implemented by running diffstat with the
output of $patch->diff.

=back

=head1 SEE ALSO

L<Darcs::Inventory>

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2007-2012 David Caldwell

=head1 AUTHOR

David Caldwell <david@porkrind.org>

=cut
