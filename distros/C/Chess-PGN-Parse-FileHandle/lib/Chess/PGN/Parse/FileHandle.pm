package Chess::PGN::Parse::FileHandle;

use warnings;
use strict;

use Chess::PGN::Parse;

=head1 NAME

Chess::PGN::Parse::FileHandle - Parse PGN from a FileHandle

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';
our @ISA = qw(Chess::PGN::Parse);

=head1 SYNOPSIS

    use Chess::PGN::Parse::FileHandle;

    # read from a gzip'ed file with gunzipping first
    open my $pgn_gz, "<:gzip", "my_pgns.pgn.gz" or die $!;

    my $pgn = Chess::PGN::Parse::FileHandle->new($pgn_gz);
    while ($pgn->read_game()) {
        # Process the file like you would with Chess::PGN::Parse
        ...
    }

=head1 DESCRIPTION

After getting tired of having to repeatedly C<gzip> and C<gunzip> PGN
files to process through C<Chess::PGN::Parse>, I decided there had to 
be an easier way.  Well, this is it.  This module is simple subclass
of C<Chess::PGN::Parse> that allows C<FILECHANDLE>s as a parameter.

=head1 FUNCTIONS

=head2 new FILEHANDLE

Returns a new C<Chess::PGN::Parse::FileHandle> object, ready to read from
C<FILEHANDLE>.

The remaining methods of this class are inherited directly from
C<Chess::PGN::Parse>.

=cut

sub new {
    my ($class, $fh) = @_; 
    my $self = $class->SUPER::new('');
    $self->{fh} = \$fh;
    return bless $self, $class;
}

=head1 NOTES

This is a naughty module that peeks at the internals of another module.
It could easily break if changes are made to C<Chess::PGN::Parse>.

=head1 AUTHOR

Steve Peters, C<< <steve@fisharerojo.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-chess-pgn-parse-filehandle@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Chess-PGN-Parse-FileHandle>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGMENTS

Giuseppe Maxia for C<Chess::PGN::Parse>

=head1 COPYRIGHT & LICENSE

Copyright 2005 Steve Peters, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Chess::PGN::Parse::FileHandle
