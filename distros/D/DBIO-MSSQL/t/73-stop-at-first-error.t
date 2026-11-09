use strict;
use warnings;

use Test::More;

use DBIO::MSSQL::Storage::StopAtFirstError;

# OFFLINE (karr k62). The handle core's void-context populate is given
# (DBIO::MSSQL::Storage::_dbh_execute_for_fetch): execute_for_fetch stops at
# the first failing tuple. What a server then holds is shown live:
# t/74-failed-populate-live.t.
#
# The fake handle executes like DBI's default execute_for_fetch: every tuple,
# the failures recorded in the tuple status as [ err, errstr, state ].

{
  package T::K62::STH;

  sub new { bless { executed => [], calls => [], fail_on => $_[1] }, $_[0] }

  sub execute_for_fetch {
    my ($self, $fetch_tuple, $tuple_status) = @_;
    push @{ $self->{calls} }, 'execute_for_fetch';
    my $ok = 0;
    while (my $tuple = $fetch_tuple->()) {
      push @{ $self->{executed} }, $tuple->[0];
      if ($tuple->[0] eq ($self->{fail_on} // '')) {
        push @$tuple_status, [ 8114, 'Error converting data type', '42000' ];
      }
      else {
        push @$tuple_status, 1;
        $ok++;
      }
    }
    return $self->{fail_on} && grep({ $_ eq $self->{fail_on} } @{ $self->{executed} })
      ? undef : $ok;
  }

  sub bind_param { push @{ $_[0]{calls} }, [ bind_param => @_[1 .. $#_] ]; 1 }
  sub err        { 'the err' }
  sub errstr     { 'the errstr' }
  sub finish     { push @{ $_[0]{calls} }, 'finish'; 1 }
}

sub tuples { my @rows = @_; my $i = 0; sub { $i < @rows ? [ $rows[$i++] ] : undef } }

# the control: without the wrapper the failing tuple does not stop the rest
{
  my $sth = T::K62::STH->new('bad');
  my @status;
  $sth->execute_for_fetch(tuples(qw(a bad c d)), \@status);
  is_deeply $sth->{executed}, [qw(a bad c d)],
    '(control) DBI executes every tuple after a failing one';
}

{
  my $sth     = T::K62::STH->new('bad');
  my $wrapped = DBIO::MSSQL::Storage::StopAtFirstError->new($sth);
  my @status;

  my $rv = $wrapped->execute_for_fetch(tuples(qw(a bad c d)), \@status);

  is_deeply $sth->{executed}, [qw(a bad)],
    'the tuples after the first failing one are not executed';
  is scalar @status, 2, '... the tuple status ends at the failure';
  is ref $status[1], 'ARRAY', '... which is the error entry core looks for';
  is $status[0], 1, '... after the success before it';
  ok !defined $rv, '... and what the handle returned is passed on';
}

{
  my $sth     = T::K62::STH->new('nope');
  my $wrapped = DBIO::MSSQL::Storage::StopAtFirstError->new($sth);
  my @status;

  my $rv = $wrapped->execute_for_fetch(tuples(qw(a b c)), \@status);

  is_deeply $sth->{executed}, [qw(a b c)], 'without a failure every tuple runs';
  is $rv, 3, '... and the result is the handle\'s';
}

{
  my $sth     = T::K62::STH->new('first');
  my $wrapped = DBIO::MSSQL::Storage::StopAtFirstError->new($sth);

  $wrapped->execute_for_fetch(tuples(qw(first b c)), []);
  is_deeply $sth->{executed}, ['first'], 'a failure of the first tuple stops at once';
}

{
  my $sth     = T::K62::STH->new('x');
  my $wrapped = DBIO::MSSQL::Storage::StopAtFirstError->new($sth);

  $wrapped->bind_param(1, 'v', 4);
  is_deeply $sth->{calls}, [ [ bind_param => 1, 'v', 4 ] ],
    'every other method goes to the handle, with its arguments';
  is $wrapped->errstr, 'the errstr', '... and its answer comes back';
  is $wrapped->err,    'the err',    '... for all of them';
  $wrapped->finish;
  is $sth->{calls}[-1], 'finish', '... finish too';

  ok $wrapped->can('execute_for_fetch'), 'it can execute_for_fetch';
  ok $wrapped->can('bind_param'), '... and what the handle can';
  ok !$wrapped->can('no_such_method'), '... and not what it cannot';

  my $status;
  $wrapped->execute_for_fetch(tuples('ok'));
  is_deeply $sth->{executed}, ['ok'], 'without a tuple status of its own it still runs';
}

done_testing;
