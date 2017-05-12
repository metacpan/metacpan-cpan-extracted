package DBIx::Async;
# ABSTRACT: database support for IO::Async via DBI
use strict;
use warnings;

use parent qw(IO::Async::Notifier);

our $VERSION = '0.003';

=head1 NAME

DBIx::Async - use L<DBI> with L<IO::Async>

=head1 VERSION

version 0.003

=head1 SYNOPSIS

 #!/usr/bin/env perl 
 use strict;
 use warnings;
 use feature qw(say);
 use IO::Async::Loop;
 use DBIx::Async;
 my $loop = IO::Async::Loop->new;
 say 'Connecting to db';
 $loop->add(my $dbh = DBIx::Async->connect(
   'dbi:SQLite:dbname=:memory:',
   '',
   '', {
     AutoCommit => 1,
     RaiseError => 1,
   }
 ));
 $dbh->do(q{CREATE TABLE tmp(id integer primary key autoincrement, content text)})
 # ... put some values in it
 ->then(sub { $dbh->do(q{INSERT INTO tmp(content) VALUES ('some text'), ('other text') , ('more data')}) })
 # ... and then read them back
 ->then(sub {
   # obviously you'd never really use * in a query like this...
   my $sth = $dbh->prepare(q{select * from tmp});
   $sth->execute;
   # the while($row = fetchrow_hashref) construct isn't a good fit
   # but we attempt to provide something reasonably close using the
   # ->iterate helper
   $sth->iterate(
     fetchrow_hashref => sub {
       my $row = shift;
       say "Row: " . join(',', %$row);
     }
   );
 })->on_done(sub {
   say "Query complete";
 })->on_fail(sub { warn "Failure: @_\n" })->get;

=head1 DESCRIPTION

Wrapper for L<DBI>, for running queries much slower than usual but without blocking.

C<NOTE>: This is an early release, please get in contact via email (see L</AUTHOR>
section) or RT before relying on it for anything.

=head2 PERFORMANCE

Greatly lacking. See C<examples/benchmark.pl>, in one sample run the results looked
like this:

               Rate DBIx::Async DBD::SQLite
 DBIx::Async 1.57/s          --        -89%
 DBD::SQLite 13.8/s        776%          --

If you're doing anything more than occasional light queries, you'd probably be better
off with blocking DBI-based code running in a fork.

=head1 METHODS

Where possible, L<DBI> method signatures are used.

=cut

use IO::Async::Channel;
use IO::Async::Routine;
use Future;
use Module::Load qw();

use Variable::Disposition qw(retain_future);

use DBIx::Async::Handle;

# temporary pending next release of curry
our $_curry_weak = sub {
	my ($invocant, $code) = splice @_, 0, 2;
	Scalar::Util::weaken($invocant) if Scalar::Util::blessed($invocant);
	my @args = @_;
	sub {
		return unless $invocant;
		$invocant->$code(@args => @_)
	}
};

=head2 connect

Constuctor. Sets up our instance with parameters that will be used when we attempt to
connect to the given DSN.

Takes the following options:

=over 4

=item * $dsn - the data source name, should be something like 'dbi:SQLite:dbname=:memory:'

=item * $user - username to connect as

=item * $pass - password to connect with

=item * $opt - any options

=back

Options consist of:

=over 4

=item * RaiseError - set this to 1

=item * AutoCommit - whether to run in AutoCommit mode by default, probably works better
if this is set to 1 as well

=back

C<NOTE>: Despite the name, this method does not initiate a connection. This may change in
a future version, but if this behaviour does change this method will still return C<$self>.

Returns $self.

=cut

sub connect {
	my $class = shift;
	my ($dsn, $user, $pass, $opt) = @_;
	my $self = bless {
		options => {
			RaiseError => 1,
			PrintError => 0,
			AutoCommit => 1,
			%{ $opt || {} },
		},
		pass    => $pass,
		user    => $user,
		dsn     => $dsn,
	}, $class;
	$self
}

=head2 dsn

Returns the DSN used in the L</connect> request.

=cut

sub dsn { shift->{dsn} }

=head2 user

Returns the username used in the L</connect> request.

=cut

sub user { shift->{user} }

=head2 pass

Returns the password used in the L</connect> request.

=cut

sub pass { shift->{pass} }

=head2 options

Returns any options that were set in the L</connect> request.

=cut

sub options { shift->{options} }

=head2 do

Runs a query with optional bind parameters. Takes the following parameters:

=over 4

=item * $sql - the query to run

=item * $options - any options to apply (can be undef)

=item * @params - the parameters to bind (can be empty)

=back

Returns a L<Future> which will resolve when this query completes.

=cut

sub do : method {
	my ($self, $sql, $options, @params) = @_;
	$self->queue({
		op      => 'do',
		sql     => $sql,
		options => $options,
		params  => \@params,
	});
}

=head2 begin_work

Starts a transaction.

Returns a L<Future> which will resolve when this transaction has started.

=cut

sub begin_work {
	my $self = shift;
	$self->queue({ op => 'begin_work' });
}

=head2 commit

Commit the current transaction.

Returns a L<Future> which will resolve when this transaction has been committed.

=cut

sub commit {
	my $self = shift;
	$self->queue({ op => 'commit' });
}

=head2 savepoint

Marks a savepoint. Takes a single parameter: the name to use for the savepoint.

 $dbh->savepoint('here');

Returns a L<Future> which will resolve once the savepoint has been created.

=cut

sub savepoint {
	my $self = shift;
	my $savepoint = shift;
	$self->queue({ op => 'savepoint', savepoint => $savepoint });
}


=head2 release

Releases a savepoint. Takes a single parameter: the name to use for the savepoint.

 $dbh->release('here');

This is similar to L</commit> for the work which has been completed since
the savepoint, although the database state is not updated until the transaction
itself is committed.

Returns a L<Future> which will resolve once the savepoint has been released.

=cut

sub release {
	my $self = shift;
	my $savepoint = shift;
	$self->queue({ op => 'release', savepoint => $savepoint });
}

=head2 rollback

Rolls back this transaction. Takes an optional savepoint which
can be used to roll back to the savepoint rather than cancelling
the entire transaction.

Returns a L<Future> which will resolve once the transaction has been
rolled back.

=cut

sub rollback {
	my $self = shift;
	my $savepoint = shift;
	$self->queue({ op => 'rollback', savepoint => $savepoint });
}

=head2 prepare

Attempt to prepare a query.

Returns the statement handle as a L<DBIx::Async::Handle> instance.

=cut

sub prepare {
	my $self = shift;
	my $sql = shift;
	DBIx::Async::Handle->new(
		dbh     => $self,
		prepare => $self->queue({ op => 'prepare', sql => $sql }),
	);
}

=head1 INTERNAL METHODS

These are unlikely to be of much use in application code.

=cut

=head2 queue

Queue a request. Used internally.

Returns a L<Future>.

=cut

sub queue {
	my $self = shift;
	my ($req, $code) = @_;
	my $f = $self->loop->new_future;
	$self->debug_printf("Sending request [%s]", join ',', map { $_ . '=' . ($req->{$_} // '<undef>') } sort keys %$req);

	$self->sth_ch->send($req);
	$self->ret_ch->recv(
		on_recv => sub {
			my ($ch, $rslt) = @_;
			if($rslt->{status} eq 'ok') {
				$f->done($rslt);
			} else {
				$f->fail($rslt->{message} // 'unknown exception');
			}
		}
	);
	retain_future $f;
}

=head2 worker_class_from_dsn

Attempts to locate a suitable worker subclass, given a DSN.

For example:

 $dbh->worker_class_from_dsn('dbi:SQLite:memory')

should return 'DBIx::Async::Worker::SQLite'.

Note that this method will load the class if it is not already
present.

Returns the class as a string.

=cut

sub worker_class_from_dsn {
	my $self = shift;
	my $dsn = shift;
	my ($dbd) = $dsn =~ /^dbi:([^:]+)(?::|$)/;
	die "Invalid DBD class: $dbd" unless $dbd =~ /^[a-zA-Z0-9]+$/;

	my $loaded;
	my $class;
	for my $subclass ($dbd, 'Default') {
		last if $loaded;
		$class = 'DBIx::Async::Worker::' . $subclass;
		eval {
			Module::Load::load($class);
			$loaded = 1
		} or do {
			# TODO we need proper error handling here,
			# but some DSNs won't have a related worker
			# class, default to something perhaps?
			warn "Failed to load: $@"
		};
	}
	die "Could not find suitable class for $dbd" unless $loaded;
	$class;
}

=head2 sth_ch

The channel used for prepared statements.

=cut

sub sth_ch { shift->{sth_ch} }

=head2 ret_ch

The channel which returns values.

=cut

sub ret_ch { shift->{ret_ch} }

=head2 _add_to_loop

Sets things up when we are added to a loop.

=cut

sub _add_to_loop {
	my ($self, $loop) = @_;

	my $worker = $self->worker_class_from_dsn($self->dsn)->new(
		parent => $self,
		sth_ch => ($self->{sth_ch} = IO::Async::Channel->new),
		ret_ch => ($self->{ret_ch} = IO::Async::Channel->new),
	);
	my $routine = IO::Async::Routine->new(
		channels_in  => [ $self->{sth_ch} ],
		channels_out => [ $self->{ret_ch} ],
		code => sub { $worker->run },
		on_finish => $self->$_curry_weak(sub {
			my $self = shift;
			$self->debug_printf("The routine aborted early with [%s]", $_[-1]);
		}),
	);
	$self->add_child($routine);
}

=head2 _remove_from_loop

Doesn't do anything yet.

=cut

sub _remove_from_loop {
	my $self = shift;
	my ($loop) = @_;
}

1;

__END__

=head1 TODO

=over 4

=item * Much of the L<DBI> API is not yet implemented. Fix this.

=item * Provide a nicer wrapper around transactions.

=item * Consider supporting L<Net::Async::PostgreSQL> and L<Net::Async::MySQL>
natively, might lead to some performance improvements.

=back

=head1 SEE ALSO

=over 4

=item * L<DBI> - the database framework that does all the real work

=item * L<Net::Async::PostgreSQL> - nonblocking interaction with PostgreSQL, not DBI compatible

=back

=head1 AUTHOR

Tom Molesworth <cpan@perlsite.co.uk>

=head1 LICENSE

Copyright Tom Molesworth 2012-2015. Licensed under the same terms as Perl itself.
