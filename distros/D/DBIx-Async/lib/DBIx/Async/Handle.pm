package DBIx::Async::Handle;
$DBIx::Async::Handle::VERSION = '0.003';
use strict;
use warnings;

=head1 NAME

DBIx::Async::Handle - statement handle for L<DBIx::Async>

=head1 VERSION

version 0.003

=head1 DESCRIPTION

Some L<DBIx::Async> methods (L<DBIx::Async/prepare> for example)
return statement handles. Those statement handles are supposed to
behave something like L<DBI>'s statement handles. Where they don't,
this is either a limitation of the async interface or a bug. Please
report if the latter.

=cut

use Variable::Disposition qw(retain_future);

=head1 METHODS

=cut

=head2 new

Returns $self.

=cut

sub new { my $class = shift; bless { @_ }, $class }

=head2 dbh

Returns the database handle which created this statement handle.

=cut

sub dbh { shift->{dbh} }

=head2 execute

Executes this statement handle, takes an optional list of bind parameters.

Returns a L<Future> which will resolve when the statement completes.

=cut

sub execute {
	my $self = shift;
	my @param = @_;
	$self->{execute} = $self->{prepare}->then(sub {
		my $id = shift->{id};
		$self->dbh->queue({ op => 'execute', id => $id, param => \@param });
	});
}

=head2 finish

Marks this statement handle as finished.

Returns a L<Future> which will resolve when the statement is finished.

=cut

sub finish {
	my $self = shift;
	my @param = @_;
	die "execute has not yet completed?" unless $self->{execute} && $self->{execute}->is_ready;

	retain_future $self->{execute}->then(sub {
		my $id = shift->{id};
		$self->dbh->queue({ op => 'finish', id => $id });
	});
}

=head2 fetchrow_hashref

Fetch a single row, returning the results as a hashref.

Since the data won't necessarily be ready immediately, this returns
a L<Future> which will resolve with the requested hashref.

=cut

sub fetchrow_hashref {
	my $self = shift;
	die "fetch on a handle which has not been executed" unless $self->{execute};
	retain_future $self->{execute}->then(sub {
		my $id = shift->{id};
		$self->dbh->queue({
			op => 'fetchrow_hashref',
			id => $id
		});
	})->transform(done => sub { shift->{data} // () })
}

=head2 iterate

A helper method for iterating over results.

Takes two parameters:

=over 4

=item * $method - the method to call, for example L</fetchrow_hashref>

=item * $code - the code to run for each result

=back

 $sth->iterate(
  fetchrow_hashref => sub {
   
  }
 )

Returns $self.

=cut

sub iterate {
	my $self = shift;
	my $method = shift;
	my $code = shift;
	my $f = $self->dbh->loop->new_future;
	my $step;
	$step = sub {
		return $f->done unless @_;
		$self->$method->on_done($step);
		$code->(@_);
	};
	$self->$method->on_done($step);
	retain_future $f;
}

1;

__END__

=head1 TODO

=over 4

=item * There are many other ->fetch* variants. Add them.

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2015. Licensed under the same terms as Perl itself.
