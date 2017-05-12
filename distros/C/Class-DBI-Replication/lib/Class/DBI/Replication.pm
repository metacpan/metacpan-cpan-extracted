package Class::DBI::Replication;

use strict;
use vars qw($VERSION);
$VERSION = '0.01';

# 5.005's base won't work well with multiple inheritance
# so Class::DBI should come first
use base qw(Class::DBI Class::Data::Inheritable);
use Carp::Assert;

sub set_master {
    my($class, $data_source, $user, $password, $attr) = @_;

    # master is 'Main', in Class::DBI
    $class->SUPER::set_db('Main', $data_source, $user, $password, $attr);
}

__PACKAGE__->mk_classdata('__Slaves');
__PACKAGE__->__Slaves(-1);

sub set_slaves {
    my($class, @slaves) = @_;
    
    for my $slave (@slaves) {
	$class->set_slave($slave);
    }

    # This could be run-time!
    $class->_set_db_slaves;
}

sub set_slave {
    my($class, $slave) = @_;
    
    assert(ref($slave) eq 'ARRAY') if DEBUG;
    
    my $howmany = $class->__Slaves;
    $class->SUPER::set_db("Slaves_" . ++$howmany, @{$slave});
    $class->__Slaves($howmany);
}

sub _set_db_slaves {
    my $class = shift;

    no strict 'refs';
    *{$class . '::db_Slaves'} = $class->_pick_slaves;
}

sub _pick_slaves {
    my $class = shift;

    # You should specify at least one slave
    assert($class->__Slaves >= 0);

    return sub {
	my $class = shift;
	my $picked = int rand($class->__Slaves + 1);
	my $dbmeth = "db_Slaves_$picked";
	$class->$dbmeth(@_);
    };
}


__PACKAGE__->set_sql('GetMeFromMaster', <<"", 'Main');
SELECT %s
FROM   %s
WHERE  %s = ?

sub retrieve {
    my($proto, $id) = @_;
    my($class) = ref $proto || $proto;

    # Class::DBI does SELECT after INSERT
    unless ( caller->isa('Class::DBI') ) {
	return $class->SUPER::retrieve($id);
    }

    my($id_col) = $class->columns('Primary');

    my $data;
    eval {
        my $sth = $class->sql_GetMeFromMaster(
	    join(', ', $class->columns('Essential')),
	    $class->table,
	    $class->columns('Primary')
	);
        $sth->execute($id);
        $data = $sth->fetchrow_hashref;
        $sth->finish;
    };
    if ($@) {
        $class->DBIwarn($id, 'GetMe');
        return;
    }

    return unless defined $data;
    return $class->construct($data);
}


# Below is what I have to deal with.
# Other ones should be gone to Master, thus no cnange is required.

__PACKAGE__->set_sql('GetMe', <<"", 'Slaves');
SELECT %s
FROM   %s
WHERE  %s = ?

__PACKAGE__->set_sql('Search', <<"", 'Slaves');
SELECT  %s 
FROM    %s
WHERE   %s = ?

__PACKAGE__->set_sql('SearchLike', <<"", 'Slaves');
SELECT    %s
FROM      %s
WHERE     %s LIKE ?

1;
__END__

=head1 NAME

Class::DBI::Replication - Class::DBI for replicated database

=head1 SYNOPSIS

  package Film;
  use base qw(Class::DBI::Replication);
    
  Film->set_master('dbi:mysql:host=master', $user, $pw);
  Film->set_slaves(
      [ 'dbi:mysql:host=slave1', $user, $pw ],
      [ 'dbi:mysql:host=slave2', $user, $pw ],
  );


=head1 DESCRIPTION

Classs::DBI::Replication extends Class::DBI's persistence for
replicated databases.

The idea is very simple. SELECT from slaves, INSERT/UPDATE/DELETE to
master.

From http://www.mysql.com/doc/R/e/Replication_FAQ.html,

  Q: What should I do to prepare my client code to use
  performance-enhancing replication?

  A: If the part of your code that is responsible for database access
  has been properly abstracted/modularized, converting it to run with
  the replicated setup should be very smooth and easy - just change
  the implementation of your database access to read from some slave
  or the master, and to always write to the master.

With Class::DBI::Replication, it can be done easily!


=head1 METHODS

=over 4

=item set_master

  Film->set_master($datasource, $user, $password, \%attr);

This spcifies your master database. INSERT/UPDATE/DELETE are done only
to this database. Some SELECT queries also done to master for
concurrency problem.

If you don't want master to be distinct from slaves in SELECT queries,
put master in slaves, too.

=item set_slaves

  Film->set_slaves(
       [ 'dbi:mysql:host=slave1', $user, $password, \%attr ],
       [ 'dbi:mysql:host=slave2', $user, $password, \%attr ],
  );

This specifies your slave databases. SELECT are done to these
databases randomly. If you don't specify slaves, all queries are gone
to master, as always.

=back

=head1 TODO

=over 4

=item *

More docs

=item *

More testing

=item *

retrieve() adter create() problem. Currently, SELECT calls inside
Class::DBI are done to master database.

=item *

Concurrency problems

=item *

Customizable slave picking algorithm like Round-Robin

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Class::DBI>, L<Class::DBI::mysql>

=cut
