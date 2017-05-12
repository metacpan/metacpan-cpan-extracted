package DBIx::Class::Schema::PgLog::Structure;

use base qw/DBIx::Class::Schema/;

use strict;
use warnings;

require DBIx::Class::Schema::PgLog::Structure::Log;
require DBIx::Class::Schema::PgLog::Structure::LogSet;

=head1 NAME

DBIx::Class::Schema::PgLog::Structure

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

Perhaps a little code snippet.

    use DBIx::Class::Schema::PgLog::Structure;

    my $foo = DBIx::Class::Schema::PgLog::Structure->new();
    ...

}

=cut

__PACKAGE__->mk_group_accessors( simple => '_current_logset_container' );

sub _current_logset {
    my $self = shift;
    my $ref  = $self->_current_logset_container;

    return $ref && $ref->{logset};
}

=head2 current_logset

Returns the logset that is currently in process.

This is localized to the scope of each transaction.

=cut

sub current_logset {
    my ( $self, @args ) = @_;

    $self->throw_exception('Cannot set logset manually. Use txn_do.')
        if @args;

    # we only want to create a logset if the action (insert/update/delete)
    # is being run from txn_do -- the txn_do method in
    # DBIx::Class::Schema::PgLog sets local
    # _current_logset_container->{logset} &
    # _current_logset_container->{args} variables in the scope
    # of each transaction
    if (   defined $self->_current_logset_container
        && defined $self->_current_logset_container->{logset} )
    {

        my $id = $self->_current_logset;

        unless ($id) {
			#Add LogSet Here
			my $txn_args = $self->_current_logset_container->{args};
			my $logset_data = {};

			if($txn_args) {
				$logset_data->{Epoch} = exists($txn_args->{Epoch})?$txn_args->{Epoch}:time();
				$logset_data->{UserId} = exists($txn_args->{UserId})?$txn_args->{UserId}:0; 
				$logset_data->{Description} = exists($txn_args->{Description})?$txn_args->{Description}:""; 

				my $logset = $self->resultset('PgLogLogSet')->create( $logset_data );

				$self->_current_logset_container->{logset} = $logset->Id;
				$id = $logset->Id;
			}
        }

        return $id;
    }

    return;
}


sub pg_log_create_log {
	my $self = shift;
	my $log_data = shift;

	my $logset = $self->current_logset;

	if(defined($self->_current_logset_container)) {
		my $txn_args = $self->_current_logset_container->{args};
		if($txn_args && $logset) {
			$log_data->{LogSetId} = $logset; 
			$log_data->{Epoch} = exists($txn_args->{Epoch})?$txn_args->{Epoch}:time();
			$log_data->{UserId} = exists($txn_args->{UserId})?$txn_args->{UserId}:0; 

			$self->resultset('PgLogLog')->create( $log_data );
		}
	}
}

1;


=head1 AUTHOR

Sheeju Alex, C<< <sheeju at exceleron.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dbix-class-pglog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-PgLog>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Schema::PgLog::Structure


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-PgLog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DBIx-Class-PgLog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/DBIx-Class-PgLog>

=item * Search CPAN

L<http://search.cpan.org/dist/DBIx-Class-PgLog/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Sheeju Alex.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of DBIx::Class::Schema::PgLog::Structure
