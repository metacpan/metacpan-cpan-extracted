use strict;
use warnings;
package DB::Transaction;
use base qw(Exporter);

our $VERSION = 0.001001; # 0.001.0

our @EXPORT_OK = qw(run_in_transaction);

my %on_error_options = (
	rollback => undef,
	continue => undef,
);

my %transactions_deep;
sub run_in_transaction (&;@) {
	my $code = shift;
	my (%args) = @_;

	my $db_handle = $args{db_handle};
	my $on_error = $args{on_error} || 'rollback';

	die "Don't know how to handle error action '$on_error'\n"
		if ! exists $on_error_options{$on_error};

	local $db_handle->{AutoCommit} = 0;
	local $db_handle->{RaiseError} = 1;

	$transactions_deep{"$db_handle"}++;
	my $error;
	eval {
		$code->();
		$db_handle->commit if $transactions_deep{"$db_handle"} <= 1;
	;1 } || do {
		$error = defined $@ ? $@ : 'an error was encountered in your transaction';
		$db_handle->rollback if $on_error eq 'rollback';
	};
	$@ = $error if defined $error;
	$transactions_deep{"$db_handle"}--;
	delete $transactions_deep{"$db_handle"} if $transactions_deep{"$db_handle"} < 1;

	die $error if defined $error && $on_error eq 'rollback';

	return ! defined $error;
}

1;

__END__

=head1 NAME

DB::Transaction - feather-weight transaction management for your DBI handles

=head1 SYNOPSIS

    use DB::Transaction qw(run_in_transaction);

    my $dbh = My::Application->get_dbh;

    run_in_transaction {
        $dbh->do('
            update risky_business -- in some fashion
        ');
    } db_handle => $dbh, on_error => 'rollback';

=head1 DESCRIPTION

DB::Transaction provides one function: run_in_transaction

=head1 EXPORTS

By default, none. On request, C<run_in_transaction>.

=head2 run_in_transaction BLOCK db_handle => $db_handle, on_error => ['rollback' | 'continue']

Begin a transaction on $db_handle, then run BLOCK. Any errors raised in the
course of executing BLOCK will cause the current transaction to be handled
according to your C<on_error> specification.

C<on_error> may be one of these two options:

=over 4

=item * rollback -- call this dbh's ->rollback method

=item * continue -- just keep on chugging, man!

=back

C<on_error =E<gt> 'rollback'> is the default behavior.

Transactions may be nested, though your underlying database may not support
nested transactions. It's up to you to know whether this is supported or not.

=head1 CONTRIBUTING

To contribute back to this project, log in to your GitHub account and visit
L<http://github.com/shutterstock/perl-db-transaction>, then fork the repository.

Create a feature branch, make your changes, push them back to your fork, and
submit a pull request via GitHub.

    # fork the project in github

    git clone git://github.com/<your-name>/perl-db-transaction.git
    git checkout -b feature-add-spiffy-functionality

    emacs -nw t/spiffy-functionality.t   # hack hack hack
    emacs -nw lib/DB/Transaction.pm      # hack hack hack

    git push feature-add-spiffy-functionality origin

    # submit pull request via github

=head1 AUTHORS

Written by Aaron Cohen <morninded@cpan.org> and Belden Lyman <belden@cpan.org>
at Shutterstock, Inc. Released to CPAN by Shutterstock, Inc.

If you like the idea of working at a company that supports open-source development,
why not checkout our L<jobs page|http://shutterstock.com/jobs.mhtml> and drop us a
line?

=head1 COPYRIGHT AND LICENSE

    (c) 2013 Shutterstock, Inc. All rights reserved.

This library is free software: you may redistribute it and/or modify it under the same terms as Perl itself;
either Perl version 5.8.8 or, at your option, any later version of Perl 5 you may have available.
