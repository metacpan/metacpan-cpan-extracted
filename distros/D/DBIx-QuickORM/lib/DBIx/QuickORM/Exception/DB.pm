package DBIx::QuickORM::Exception::DB;
use strict;
use warnings;

our $VERSION = '0.000031';

use Object::HashBase qw{
    <kind
    <state
    <native
    <errstr
    <statement
    <message
};

use overload '""' => sub { $_[0]->{+MESSAGE} }, bool => sub { 1 }, fallback => 1;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Exception::DB - A classified database error.

=head1 DESCRIPTION

Every error the database reports on the ORM's handle is thrown as one of
these. C<kind> says what went wrong when the dialect can tell, and
C<retriable> whether running the transaction again may help.

It stringifies to DBI's message, so code matching C<$@> against DBI's text
keeps working. The ORM's own complaints about how it was called stay plain
strings.

=head1 SYNOPSIS

    use Scalar::Util qw/blessed/;

    my $ok  = eval { $orm->insert(users => {email => $email}); 1 };
    my $err = $@;
    unless ($ok) {
        die $err unless blessed($err) && $err->isa('DBIx::QuickORM::Exception::DB');
        return already_registered($email) if ($err->kind // '') eq 'unique_violation';
        die $err;
    }

=head1 ATTRIBUTES

=over 4

=item $kind = $err->kind

What went wrong, as far as the dialect can tell from the error codes, or
undef: C<deadlock>, C<serialization_failure>, C<lock_timeout>,
C<unique_violation>, C<foreign_key_violation>, C<not_null_violation>, or
C<check_violation>.

=item $sqlstate = $err->state

The SQLSTATE the driver reported, or undef. Some drivers report a generic one
(C<S1000>, C<HY000>) for most errors.

=item $code = $err->native

The driver's native error code (DBI's C<err>).

=item $text = $err->errstr

The driver's error text (DBI's C<errstr>).

=item $sql = $err->statement

The SQL the handle last ran, when DBI knows it.

=item $text = $err->message

DBI's message, which the exception stringifies to. Defaults to C<errstr>, or
C<Unknown database error> without one.

=back

=cut

sub init {
    my $self = shift;
    $self->{+MESSAGE} //= $self->{+ERRSTR} // 'Unknown database error';
}

=head1 PUBLIC METHODS

=over 4

=item $bool = $err->retriable

Whether running the transaction again may get past the error.

1 for a deadlock, a serialization failure, or a lock timeout, 0 for the
constraint violations, and undef when the kind is unknown.

=back

=cut

my %RETRIABLE = (
    (map { $_ => 1 } qw/deadlock serialization_failure lock_timeout/),
    (map { $_ => 0 } qw/unique_violation foreign_key_violation not_null_violation check_violation/),
);

sub retriable {
    my $self = shift;
    my $kind = $self->{+KIND};
    return undef unless defined $kind;
    return $RETRIABLE{$kind};
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
