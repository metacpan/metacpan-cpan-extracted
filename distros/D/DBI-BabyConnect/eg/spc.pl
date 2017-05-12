package DataException::Queue;

use DBI::BabyConnect;

# this mini sub-package only knows how to to dequeue
# from our persisted database queue
@ISA=(Queue);
sub new {
	my $type = shift;
	my $db_descriptor = shift;
	my $_ORA_PKG  = 'PKG_DATA_MANAGEMENT';
	my $_QTABLE     = 'TASK_QUEUE';

	my $_bbconn =  DBI::BabyConnect->new($db_descriptor);
	#$_bbconn->HookTracing(">>/tmp/db.log",1);
	$_bbconn->printerror(1);
	$_bbconn->raiseerror(0);
	$_bbconn->autorollback(1);
	$_bbconn->autocommit(1);
	my $this = {
		_bbconn => DBI::BabyConnect->new($db_descriptor),
		_ORA_PKG  => $_ORA_PKG,
		_QTABLE     => $_QTABLE,
	};
	bless $this, $type;
}

sub hasNext {
	my $this = shift;
	my $o = shift;

	my $ORA_PKG = $this->{_ORA_PKG};
	$this{_bbconn}-> spc($o,"$ORA_PKG.spc_DequeueMessage") && return 1;
	return 0;
}
sub getNext {
	my $this = shift;
	my $o = [ {task_key=>1,task_type=>2,task_arguments=>3}, undef,undef,undef];
	
	return undef unless $this-> hasNext($o);
	if (defined $$o{tsq_param}) {
		$this->{task_key}=$$o{task_key};
		$this->{task_type}=$$o{task_type};
		$this->{task_arguments}=$$o{task_arguments};
	}
	return $o;
}

1;

