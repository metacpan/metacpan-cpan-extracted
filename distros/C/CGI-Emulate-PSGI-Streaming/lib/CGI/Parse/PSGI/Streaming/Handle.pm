package CGI::Parse::PSGI::Streaming::Handle;
use strict;
use warnings;
our $VERSION = '1.0.1'; # VERSION
use POSIX 'SEEK_SET';
use parent 'Tie::Handle';

# ABSTRACT: internal class for the tied handle


sub TIEHANDLE {
    my ($class,$callback) = @_;

    # our state: the callback, a filehandle, and the buffer it writes
    # to
    my $self = { cb => $callback, buffer => '' };
    open $self->{fh},'>',\($self->{buffer});
    # make it auto-flush, otherwise we run the risk of losing bits of
    # data in WRITE
    my $oldfh = select($self->{fh}); $| = 1; select($oldfh); ## no critic(ProhibitOneArgSelect,RequireLocalizedPunctuationVars)

    return bless $self, $class;
}

sub BINMODE {
    my ($self, $layer) = @_;
    # this is why we have a filehandle, instead of just passing data
    # through: emulating all the binmode combinations is a nightmare;
    # much better to get Perl to handle the mess
    if (@_==2) {
        binmode $self->{fh},$layer;
    }
    else {
        binmode $self->{fh};
    }
}

sub WRITE {
    my ($self,$buf,$len,$offset) = @_;
    # clear the buffer, make the fh print to the beginning of it
    seek( $self->{fh}, 0, SEEK_SET );
    $self->{buffer}='';
    # print! this goes through all the PerlIO layers, so encodings&c
    # just work
    print {$self->{fh}} substr($buf, $offset, $len);

    # invoke the callback with the data
    $self->{cb}->($self->{buffer});
    return $len;
}

sub CLOSE {
    my ($self) = @_;
    close $self->{fh};
    # invoke the callback without data to signal the closing
    $self->{cb}->();
    return 1;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

CGI::Parse::PSGI::Streaming::Handle - internal class for the tied handle

=head1 VERSION

version 1.0.1

=head1 DESCRIPTION

This class is used internally by L<< C<CGI::Parse::PSGI::Streaming>
>>. No user-serviceable parts inside.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@broadbean.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Broadbean.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
