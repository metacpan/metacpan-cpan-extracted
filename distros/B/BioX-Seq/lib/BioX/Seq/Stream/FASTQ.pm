package BioX::Seq::Stream::FASTQ;

use strict;
use warnings;

sub _check_type {

    my ($class,$self) = @_;
    return substr($self->{buffer},0,1) eq '@';

}

sub _init {

    my ($self) = @_;

    # First two bytes should not contain line ending chars
    die "Missing ID in initial header (check file format)\n"
        if ($self->{buffer} =~ /[\r\n]/);
    my $fh = $self->{fh};
    $self->{buffer} .= <$fh>;

    # detect line endings for text files based on first line
    # (other solutions, such as using the :crlf layer or s///
    # instead of chomp may be marginally more robust but slow
    # things down too much)
    if ($self->{buffer} =~ /([\r\n]{1,2})$/) {
        $self->{rec_sep} = $1;
    }
    else {
        die "Failed to detect line endings\n";
    }

    return;
    
}

sub next_seq {
    
    my ($self) = @_;
    my $fh = $self->{fh};

    local $/ = $self->{rec_sep};

    my $line = $self->{buffer} // <$fh>;
    return undef if (! defined $line);
    chomp $line;

    my ($id, $desc) = ($line =~ /^\@(\S+)\s*(.+)?$/);
    die "Bad FASTQ ID line\n" if (! defined $id);

    # seq and qual can be multiline (although rare)
    # qual is tricky since it can contain '@' but we compare to the
    # sequence length to know when to stop parsing (must be equal lengths)
    my $seq = <$fh> // die "Bad or missing FASTQ sequence";
    chomp $seq;

    SEQ:
    while (my $line = <$fh>) {
        chomp $line;
        last SEQ if ($line =~ /^\+/);
        $seq .= $line;
    }

    my $seq_len = length $seq;

    QUAL:
    my $qual = <$fh> // die "Bad or missing FASTQ format";
    chomp $qual;

    while ( (length($qual) < $seq_len) && defined (my $line = <$fh>) ) {
        chomp $line;
        $qual .= $line;
    }
    die "Bad FASTQ quality length" if ($seq_len != length($qual));

    $self->{buffer} = undef;

    return BioX::Seq->new($seq, $id, $desc, $qual);

}

1;

__END__

=head1 NAME

BioX::Seq::Stream::FASTQ - the FASTQ parser for C<BioX::Seq:Stream>;

=head1 DESCRIPTION

This module performs robust parsing of FASTQ sequence streams. It is not
intended to be used directly but is called by C<BioX::Seq::Stream> after file
format autodetection. Please see the documentation for that module for more
details.

=head1 CAVEATS AND BUGS

Please report any bugs or feature requests to the issue tracker
at L<https://github.com/jvolkening/p5-BioX-Seq>.

=head1 AUTHOR

Jeremy Volkening <jeremy *at* base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2014-2017 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


