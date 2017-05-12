package DBIx::Async::Worker;
$DBIx::Async::Worker::VERSION = '0.003';
use strict;
use warnings;

=head1 NAME

DBIx::Async::Worker - background process for L<DBIx::Async>

=head1 VERSION

version 0.003

=head1 DESCRIPTION

No user-serviceable parts inside. You may want to subclass this
for specific DBD driver support though.

=cut

use DBI;

my %VALID_METHODS;
BEGIN {
	@VALID_METHODS{qw(
		begin_work commit rollback savepoint release
		do
		prepare execute finish
		fetchrow_hashref
	)} = ();
}

my %sth;

=head1 METHODS

=cut

=head2 new

Returns $self.

=cut

sub new { my $class = shift; bless { @_ }, $class }

=head2 ret_ch

=cut

sub ret_ch { shift->{ret_ch} }

=head2 sth_ch

=cut

sub sth_ch { shift->{sth_ch} }

=head2 parent


=cut

sub parent { shift->{parent} }

=head2 connect

=cut

sub connect {
	my $self = shift;
	$self->{dbh} = DBI->connect(
		$self->parent->dsn,
		$self->parent->user,
		$self->parent->pass,
		$self->parent->options
	);
	$self;
}

=head2 do

=cut

sub do : method {
	my $self = shift;
	my $op = shift;
	$self->dbh->do(
		$op->{sql},
		$op->{options},
		@{ $op->{params} || [] }
	);
	return { status => 'ok' };
}

=head2 begin_work

=cut

sub begin_work {
	my $self = shift;
	my $op = shift;
	$self->dbh->begin_work;
	return { status => 'ok' };
}

=head2 commit

=cut

sub commit {
	my $self = shift;
	my $op = shift;
	$self->dbh->commit;
	return { status => 'ok' };
}

=head2 savepoint

=cut

sub savepoint {
	my $self = shift;
	my $op = shift;
	$self->dbh->do(q{savepoint} . (defined $op->{savepoint} ? ' ' . $self->dbh->quote_identifier($op->{savepoint}) : ''));
	return { status => 'ok' };
}

=head2 release

=cut

sub release {
	my $self = shift;
	my $op = shift;
	$self->dbh->do(q{release savepoint } . $self->dbh->quote_identifier($op->{savepoint}));
	return { status => 'ok' };
}

=head2 rollback

=cut

sub rollback {
	my $self = shift;
	my $op = shift;
	$self->dbh->rollback;
	return { status => 'ok' };
}

=head2 prepare

=cut

sub prepare {
	my $self = shift;
	my $op = shift;
	my $sth = $self->dbh->prepare($op->{sql});
	$sth{$sth} = $sth;
	return { status => 'ok', id => "$sth" };
}

=head2 finish

=cut

sub finish {
	my $self = shift;
	my $op = shift;
	my $sth = delete $sth{$op->{id}} or return {
		status => 'fail',
		message => 'invalid ID'
	};
	$sth->finish;
	return { status => 'ok', id => "$sth" };
}

=head2 execute

=cut

sub execute {
	my $self = shift;
	my $op = shift;
	my $sth = $sth{$op->{id}} or return {
		status => 'fail',
		message => 'invalid ID'
	};
	$sth->execute(@{ $op->{param} });
	return { status => 'ok', id => "$sth" };
}

=head2 fetchrow_hashref

=cut

sub fetchrow_hashref {
	my $self = shift;
	my $op = shift;
	my $sth = $sth{$op->{id}} or return {
		status => 'fail',
		message => 'invalid ID'
	};
	my $data = $sth->fetchrow_hashref;
	return { status => 'ok', id => "$sth", data => $data };
}

=head2 dbh

=cut

sub dbh { shift->{dbh} }

=head2 run

=cut

sub run {
	my $self = shift;
	eval {
		$self->connect;
		$self->setup;
		1
	} or do {
		warn "Failure: $@";
	};
	while(my $data = $self->sth_ch->recv) {
		eval {
			my $method = $data->{op};
			my $code = $self->can($method) or die 'unknown operation';
			$self->ret_ch->send($code->($self, $data));
			1
		} or do {
			# warn "err: $_\n";
			$self->ret_ch->send({
				status => 'fail',
				message => $@
			});
		};
	}
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2015. Licensed under the same terms as Perl itself.
