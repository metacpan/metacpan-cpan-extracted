package Acrux::DBI::Tx;
use strict;
use utf8;

=encoding utf8

=head1 NAME

Acrux::DBI::Tx - Transaction

=head1 SYNOPSIS

    use Acrux::DBI::Tx;

    my $tx = Acrux::DBI::Tx->new( dbi => $dbi );
    # . . .
    $tx->commit;

=head1 DESCRIPTION

This is a scope guard for L<Acrux::DBI> transactions

=head1 ATTRIBUTES

This class implements the following attributes

=head2 dbi

    dbi => $dbi

The object this transaction belongs to. Note that this attribute is weakened

=head1 METHODS

This class implements the following methods

=head2 commit

    $tx->commit;

Commit transaction.

=head2 new

    my $tx = Acrux::DBI::Tx->new( dbi => $dbi );
    my $tx = Acrux::DBI::Tx->new( { dbi => $dbi } );

Construct a new transaction object

=head1 HISTORY

See C<Changes> file

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<Mojo::mysql>, L<Mojo::Pg>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<https://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2026 D&D Corporation

=head1 LICENSE

This program is distributed under the terms of the Artistic License Version 2.0

See the C<LICENSE> file or L<https://opensource.org/license/artistic-2-0> for details

=cut

sub new {
    my $class = shift;
    my $args = scalar(@_) ? scalar(@_) > 1 ? {@_} : {%{$_[0]}} : {};
    my $self  = bless {
            dbi         => $args->{dbi},
            rollback    => $args->{rollback} // 1,
        }, $class;
    $self->{dbi}->begin;
    return $self;
}
sub commit {
    my $self = shift;
    $self->{dbi}->commit if $self->{rollback};
    $self->{rollback} = 0;
}
sub DESTROY {
    my $self = shift;
    if ($self->{rollback} && (my $dbi = $self->{dbi})) { $dbi->rollback }
}

1;

__END__
