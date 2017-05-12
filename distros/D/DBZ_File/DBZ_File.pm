package DBZ_File;

BEGIN {
    if ($] >= 5.002) {
	use strict;
    }
}
use Carp;
use vars qw($VERSION @ISA);

require DynaLoader;

@ISA = qw(DynaLoader);

$VERSION = '1.1';

bootstrap DBZ_File $VERSION;

sub DELETE {
    croak "DBZ_File::DELETE not implemented";
}
sub FIRSTKEY {
    croak "DBZ_File::FIRSTKEY not implemented";
}
sub NEXTKEY {
    croak "DBZ_File::NEXTKEY not implemented";
}

1;

__END__

=head1 NAME

DBZ_File - Tied access to dbz files

=head1 SYNOPSIS

 use DBZ_File;

 tie(%hist,DBZ_File,'/usr/lib/news/history');  # must exist
 tie(%hist,DBZ_File,'/usr/lib/news/history', O_CREAT, 0664);  # create OK

 $history_file_offset = %hist{$message_id};
 %hist{$message_id} = $history_file_offset;

 untie(%hist);

=head1 DESCRIPTION

B<DBZ_File> allows perl programs to read and write a B<dbz> database,
such as the news history file.

The fetch and store functions handle all the B<dbz> quirks, such as
including a null character at the end of the key and translating the
offset to/from a datum.  It also calls the dbzfetch and dbzstore
functions, which means that the key gets the same upper-/lower- case
processing that is done by the news system.

=head1 BUGS

You cannot delete a hash entry, or enumerate the keys since
B<dbz> doesn't support the functions necessary to support the
DELETE, FIRSTKEY, and NEXTKEY tied array functions.  If you
attempt to use one of these features, you'll get a fatal error.

When creating a new database, the flags and umask are ignored by
B<dbz>, however they must both be non-zero for the command to
indicate that a create is OK.

You can't use multiple B<dbz>-tied arrays at the same time since B<dbz>
can only open one database.  If you try, the tie call returns a failure.

This module is probably not compatible with any previous (partial)
versions of B<dbz> support.  The reason for this is that they either
required the appending of a null character to the key (ick) or the
use of pack/unpack to be used with the offset value (yuck).

=head1 EXAMPLE

    use DBZ_File;

    tie(%hist, DBZ_File, '/usr/lib/news/history') or die $!;
    open(HFP, '+</usr/lib/news/history') or die $!;

    # Find an entry and output its line from the history file
    if (defined($pos = $hist{'<1234@clari.net>'})) {
	seek(HFP, $pos, 0);
	$_ = <HFP>;
	print;
    }

    # Write a new entry at the EOF
    seek(HFP, 0, 2);
    $msgid = '<54321@clari.net>';
    $hist{$msgid} = tell(HFP);
    print HFP "$msgid\t", time, "~-~0\n";

    close(HFP);
    untie(%hist);

=head1 AUTHOR

DBZ_File was written by Wayne Davison <wayne@clari.net>.  It is
based on the NDBM_File module with a few ideas derived from an old
alpha release written by Ian Phillipps <ian@pipex.net>.  The dbz
module has many names on it, and is copyright 1988 Jon Zeeff.

=cut
