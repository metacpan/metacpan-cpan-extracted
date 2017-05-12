package MAB2::Writer::Handle;

our $VERSION = '0.14';

use strict;
use Moo::Role;
use Carp qw(croak);
use Encode qw(find_encoding);
use Scalar::Util qw(blessed openhandle);

has encoding => (
    is  => 'rw',
    isa => sub {
        find_encoding($_[0]) or croak "encoding \"$_[0]\" is not a valid encoding";
    },
    default => sub { 'UTF-8' },
);

has file => (
    is  => 'rw',
    isa => sub {
        croak 'expect file!' unless defined $_[0];
    },
    trigger => \&_set_fh,
);

has fh => (
    is  => 'rw',
    isa => sub {
        my $ishandle = eval { fileno( $_[0] ); };
        croak 'expect filehandle or object with method print!'
            unless !$@ and defined $ishandle
            or ( blessed $_[0] && $_[0]->can('print') );
    },
    default => sub { \*STDOUT }
);

sub _set_fh {
    my ($self) = @_;

    my $encoding = $self->encoding;
    open my $fh, ">:encoding($encoding)", $self->file
        or croak 'could not open file!';
    $self->fh($fh);
}

sub close_fh {
    my ($self) = @_;

    close $self->{fh};
}

sub write {
    my ($self, @records) = @_;

    foreach my $record (@records) {
        $record = $record->{record} if ref $record eq 'HASH';
        $self->_write_record($record);
    }
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MAB2::Writer::Handle - Utility class for common MAB2::Writer arguments and methods.

=head1 Arguments

=over

=item C<file>

Path to file.

=item C<fh>

Open filehandle.

=item C<encoding>

Set encoding.

=back

=head1 METHODS

=head2 _set_fh()

Open filehandle (with specified encoding) from file. 

=head2 close_fh()

Close filehandle.

=head2 write()

Write record to filehandle. 

=head1 AUTHOR

Johann Rolschewski <jorol@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Johann Rolschewski.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
