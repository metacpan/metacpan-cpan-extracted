package Alzabo::Runtime::RowState::Deleted;

use strict;

use Alzabo::Runtime;

BEGIN
{
    no strict 'refs';
    foreach my $meth ( qw( select select_hash refresh update delete id_as_string ) )
    {
        *{__PACKAGE__ . "::$meth"} =
            sub { $_[1]->_no_such_row_error };
    }
}

sub is_potential { 0 }

sub is_live { 0 }

sub is_deleted { 1 }


1;

__END__

=head1 NAME

Alzabo::Runtime::RowState::Deleted - Row objects that have been deleted

=head1 SYNOPSIS

  $row->delete;

=head1 DESCRIPTION

This state is used for deleted rows, any row upon which the
C<delete()> method has been called.

=head1 METHODS

See L<C<Alzabo::Runtime::Row>|Alzabo::Runtime::Row>.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=cut
