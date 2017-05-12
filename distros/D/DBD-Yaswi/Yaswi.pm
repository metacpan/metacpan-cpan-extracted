package DBD::Yaswi;
     
use strict;
use warnings;

use DBI;

our $VERSION="0.01";

use Language::Prolog::Types::overload;
use Language::Prolog::Yaswi qw(:query :load);

swi_inline <<PROLOG;

:- module(dbd, [ dbd_prepare/6,
		 dbd_map_query/3,
		 op(1180, fx, find),
		 op(1180, fx, insert),
		 op(1190, xfx, where) ]).

:- op(1190, fx, find).
:- op(1180, xfx, where).

marks_to_vars(St, St1, M, T) :-
	(   var(St)
	->  St1 = St,
	    M = T
	;   (   atomic(St)
	    ->	(   St = '?'
		->  St1 = V,
		    M = [V|T]
		;   St1 = St,
		    M = T )
	    ;	(   St = [H|L]
		->  marks_to_vars(H, H1, M, T1),
		    marks_to_vars(L, L1, T1, T),
		    St1 = [H1|L1]
		;   St =.. [F|A],
		    marks_to_vars(A, A1, M, T),
		    St1 =.. [F|A1] ) ) ).

var_names(Exp, B, Exp1) :-
	(   var(Exp)
	->  var_name(B, Exp, Exp1)
	;   (   atomic(Exp)
	    ->	Exp1 = Exp
	    ;	(   Exp=[H|T]
		->  var_names(H, B, H1),
		    var_names(T, B, T1),
		    Exp1=[H1|T1]
		;   (	Exp =.. [N|Args]
		    ->	var_names(Args, B, Args1),
			Exp1 =.. [N|Args1] ) ) ) ).

var_name([], _, N) :-
	gensym('\$UV#', N).
var_name([N=BV|M], V, N1) :-
	(   BV == V
	->  N1 = N
	;   var_name(M, V, N1) ).


dbd_prepare(Text, Query, Marks, Names, Vars, B) :-
	atom_to_term(Text, St, B),
	marks_to_vars(St, St1, Marks, []),
	(   dbd_map_query(St1, Query, Vars),
	    var_names(Vars, B, Names)
	->  true
	;   throw(dbd_error(bad_query(Text))) ).

:- multifile(dbd_map_query/3).
dbd_map_query(where(Action, Condition), (Condition, Query), Vars) :-
	dbd_map_query(Action, Query, Vars).
dbd_map_query(find(Vars), true, Vars).
dbd_map_query(insert(Pred), assert(Pred), [assert(Pred)]).
	
% end of prolog code

PROLOG


my $drh;

sub driver {
    return $drh if $drh;
    my ($class, $attr)=@_;
    $class .= '::dr';

    $drh = DBI::_new_drh($class,
			 { Name => 'Yaswi',
			   Version => $VERSION,
			   Attribution => 'DBD::Yaswi by Salvador Fandiño' })
	or return undef;
    return $drh;
}


package DBD::Yaswi::dr;
our $imp_data_size = 0;


sub connect {
    my ($drh, $dr_dsn, $user, $auth, $attr)=@_;
    my ($outer, $dbh) = DBI::_new_dbh($drh, {Name=>$dr_dsn});

    my $driver_prefix = "yaswi_";

    return $outer;
}

sub data_sources {
    my ($dhr, $attr) = @-;
    my @list = ('dbi:Yaswi:user');
    return @list;
	
}


package DBD::Yaswi::db;
our $imp_data_size = 0;

use Language::Prolog::Yaswi ':query';
use Language::Prolog::Types ':short';

my $active_sth;

sub prepare {

    my ($dbh, $statement, @attribs) = @_;
    my ($outer, $sth) = DBI::_new_sth($dbh, {Statement => $statement});

    $active_sth->finish() if $active_sth;

    my @vs = Vs qw(Q M N V B);
    my ($query, $marks, $names, $vars, $binds) =
      swi_find_one( F(dbd_prepare => $statement, @vs), @vs);

    my $u=0;
    $_->rename('_$Par'.$u++) for (@$marks);
    $_->farg(1)->rename($_->farg(0)) for (@$binds);

    # $|=1; print $query;

    $sth->STORE(NUM_OF_PARAMS => $marks->length);
    $sth->STORE(NUM_OF_FIELDS => $vars->length);
    $sth->{yaswi_marks} = $marks;
    $sth->{yaswi_vars} = $vars;
    $sth->{yaswi_query} = $query;
    $sth->{yaswi_params} = L(@$marks);
    return $outer;
}

sub commit {
    my ($dbh) = @_;
    if ($dbh->FETCH('Warn')) {
	warn("Commit ineffective while AutoCommit is on");
    }
    0;
}

sub rollback {
    my ($dbh) = @_;
    if ($dbh->FETCH('Warn')) {
	warn("Rollback ineffective while AutoCommit is on");
    }
    0;
}

sub STORE {
    my ($dbh, $attr, $val) = @_;
    if ($attr eq 'AutoCommit') {
	if (!$val) { die "Can't disable AutoCommit"; }
	return 1;
    }
    if ($attr =~ m/^yaswi_/) {
	$dbh->{$attr} = $val;
	return 1;
    }
    $dbh->SUPER::STORE($attr, $val);
}

sub FETCH {
    my ($dbh, $attr) = @_;
    if ($attr eq 'AutoCommit') { return 1; }
    if ($attr =~ m/^yaswi_/) {
	return $dbh->{$attr};
    }
    $dbh->SUPER::FETCH($attr);
}

package DBD::Yaswi::st;
our $imp_data_size = 0;

use Language::Prolog::Yaswi ':query';
use Language::Prolog::Types qw(F L);

sub bind_param {
    my ($sth, $pNum, $val, $attr) = @_;
    my $params = $sth->{yaswi_params};
    $params->[$pNum-1] = $val;
    1;
}

sub execute {
    my ($sth, @bind_values) = @_;

    $sth->finish if $sth->FETCH('Active');

    my $params = (@bind_values) ?
	L(@bind_values) : $sth->{yaswi_params};

    my $numParam = $sth->FETCH('NUM_OF_PARAMS');

    return $sth->set_err(1, "Wrong number of parameters")
	if $params->length != $numParam;

    my @q = ( F('=', $sth->{yaswi_marks}, $params),
	      $sth->{yaswi_query} );

    # print "query=@q\n";

    swi_set_query @q
	or die "unable to create query";

    if (swi_next) {
	$sth->{yaswi_cached}=swi_vars($sth->{yaswi_vars});
	$sth->STORE(Active => 1);
	$active_sth=$sth;
	return '0E0';
    }
    return undef
}

sub fetchrow_arrayref {
    my ($sth)=@_;
    $sth->FETCH('Active')
	or die "query not active";

    if (exists $sth->{yaswi_cached}) {
	return $sth->_set_fbav(delete $sth->{yaswi_cached});
    }
    if (swi_next) {
	return $sth->_set_fbav(swi_vars($sth->{yaswi_vars}))
    }
    else {
	$sth->STORE(Active=>0);
	$active_sth=undef;
	return undef
    }
}

sub DESTROY {
    my $sth = shift;
    $sth->finish if $sth->FETCH('Active');
}

*fetch = \&fetchrow_arrayref; # required alias for fetchrow_arrayref

sub finish {
    my ($sth)=@_;
    if ($sth->FETCH('Active')) {
	delete $sth->{yaswi_cached};
	swi_cut;
	$sth->STORE(Active => 0);
	$active_sth=undef;
    }
}

1;


__END__

=head1 NAME

DBD::Yaswi - A DBI interface to SWI-Prolog

=head1 SYNOPSYS

  use DBI;
  my $db=DBI->connect('dbi:Yaswi:user');
  my $sth=$db->prepare('find [X, Y] where Z=[1,2,3,4,5], \
		        member(X,Z), member(Y,Z), X>Y');
  $sth->execute;
  while(my @r=$sth->fetchrow_array) {
      printf "X=%_ Y=%_\n", @r;
  }

  my $sth1=$db->prepare('find [X,Y] where Z=(?),\
		         member(X, Z), member(Y, Z), \
		         X>Y, \+ member(Y, (?))');
  $sth1->execute([1..100],
		 [map{int(100*rand)}1..30]);
   while(my @r=$sth->fetchrow_array) {
       printf "X=%_ Y=%_\n", @r;
  }

  $sth2=$db->prepare('insert foo(?)');
  foreach (qw(foo bar doo moz goo too)) {
      $sth2->execute($_);
  }
  

=head1 AUTHOR

Salvador Fandiño, E<lt>sfandino@yahoo.comE<gt>


=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Salvador Fandiño

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
