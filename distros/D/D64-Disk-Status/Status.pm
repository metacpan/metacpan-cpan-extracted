package D64::Disk::Status;

=head1 NAME

D64::Disk::Status - CBM floppy error messages and disk drive status details of miscellaneous Commodore (D64/D71/D81) disk image operations

=head1 SYNOPSIS

  use D64::Disk::Status;

  # Create a new disk status object instance:
  my $status = D64::Disk::Status->new(
    code        => $code,
    error       => $error,
    message     => $message,
    description => $description,
  );

  # Get error code from status object:
  my $code = $status->code();

  # Get error text from status object:
  my $error = $status->error();

  # Get error message from status object:
  my $message = $status->message();

  # Get error description from status object:
  my $describe = $status->description();

=head1 DESCRIPTION

C<D64::Disk::Status> provides a helper class for C<D64::Disk::Layout> module that lets users easily identify CBM floppy error messages and disk drive status details (like error codes, and descriptive diagnostic messages) signalled as a result of miscellaneous Commodore (D64/D71/D81) disk image operations.

=head1 METHODS

=cut

use bytes;
use strict;
use utf8;
use warnings;

our $VERSION = '0.03';

=head2 new

Create a new disk status instance:

  my $status = D64::Disk::Status->new(
    code        => $code,
    error       => $error,
    message     => $message,
    description => $description,
  );

=cut

sub new {
    my ($this, %args) = @_;
    my $class = ref ($this) || $this;
    my $object = $class->_init(%args);
    my $self = bless $object, $class;
    return $self;
}

sub _init {
    my ($class, %args) = @_;

    unless (exists $args{code}) {
        die q{Failed to instantiate status object: Missing error "code" parameter};
    }
    unless (exists $args{error}) {
        die q{Failed to instantiate status object: Missing "error" text parameter};
    }
    unless (exists $args{message}) {
        die q{Failed to instantiate status object: Missing error "message" parameter};
    }
    unless (exists $args{description}) {
        die q{Failed to instantiate status object: Missing error "description" parameter};
    }

    unless ($args{code} =~ m/^\d+$/) {
        die q{Failed to instantiate status object: Invalid error "code" parameter};
    }

    my %object = (
        code        => $args{code},
        error       => $args{error},
        message     => $args{message},
        description => $args{description},
    );

    return \%object;
}

=head2 code

Get error code from status object:

  my $code = $status->code();

=cut

sub code {
    my ($self) = @_;

    return $self->{code};
}

=head2 error

Get error text from status object:

  my $error = $status->error();

=cut

sub error {
    my ($self) = @_;

    return $self->{error};
}

=head2 message

Get error message from status object:

  my $message = $status->message();

=cut

sub message {
    my ($self) = @_;

    return $self->{message};
}

=head2 description

Get error description from status object:

  my $describe = $status->description();

=cut

sub description {
    my ($self) = @_;

    return $self->{description};
}

=head1 BUGS

There are no known bugs at the moment. Please report any bugs or feature requests.

=head1 EXPORT

None. No method is exported into the caller's namespace neither by default nor explicitly.

=head1 SEE ALSO

L<D64::Disk::Layout>, L<D64::Disk::Layout::Dir>, L<D64::Disk::Status::Factory>.

=head1 AUTHOR

Pawel Krol, E<lt>pawelkrol@cpan.orgE<gt>.

=head1 VERSION

Version 0.03 (2013-03-09)

=head1 COPYRIGHT AND LICENSE

Copyright 2013 by Pawel Krol E<lt>pawelkrol@cpan.orgE<gt>.

This library is free open source software; you can redistribute it and/or modify it under the same terms as Perl itself, either Perl version 5.8.6 or, at your option, any later version of Perl 5 you may have available.

PLEASE NOTE THAT IT COMES WITHOUT A WARRANTY OF ANY KIND!

=cut

1;

__END__
