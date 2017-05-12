require 5.003;

=head1 NAME

DBIx::OracleSequence - interface to Oracle sequences via DBI.

=head1 DESCRIPTION

DBIx::OracleSequence is an object oriented interface to Oracle Sequences via DBI.  A sequence is an Oracle database object from which multiple users may generate unique integers. You might use sequences to automatically generate primary key values.  See http://technet.oracle.com/doc/server.815/a68003/01_03sch.htm#1203 for the full story on Oracle sequences.  Note that you must register to access this URL, but registration is free.

=head1 SYNOPSIS

    use DBIx::OracleSequence;

    $oracleDbh = DBI->connect("dbi:Oracle:SID", 'login', 'password');

    my $seq = new DBIx::OracleSequence($oracleDbh,'my_sequence_name');

    $seq->create();                 # create a new sequence with default parms
    $seq->incrementBy(5);           # alter the seq to increment by 5

    my $nextVal = $seq->nextval();  # get the next sequence value
    my $currval = $seq->currval();  # retrieve the current sequence value
    $seq->print();                  # print information about the sequence

    # connect to a sequence that already exists
    my $seq2 = new DBIx::OracleSequence($oracleDbh,'preexisting_seq');
    $seq2->print();
    $seq2->drop();                  # get rid of it

    # see if sequence name 'foo' exists
    my $seq3 = new DBIx::OracleSequence($oracleDbh);
    die "Doesn't exist!\n" unless $seq3->sequenceNameExists('foo');
    $seq3->name('foo');             # attach to it
    $seq3->print;


=head1 NOTE

The constructor is lazy, so if you want to alter the defaults for a sequence, you need to use the maxvalue(), cache(), incrementBy(), etc. methods after constructing your sequence.

You can access an existing Oracle sequence by calling the constructor with the existing sequence name as the second parameter.  To create a new sequence, call the constructor with your new sequence name as the second parameter, then call the create() method.

The OracleSequence object holds no state about the Oracle sequence (well, except for its name.) Instead it just serves as a passthrough to the Oracle DDL to create, drop, and set and get information about a sequence.

=cut

{
package DBIx::OracleSequence;
use strict;
use DBD::Oracle;
use vars qw($VERSION);

$VERSION = sprintf("%d.%02d", q$Revision: 0.4 $ =~ /(\d+)\.(\d+)/);

# private helper method
sub _getSeqAttribute {
  my $self = shift;
  my $attribute = uc(shift);
  my $seq = $self->{SEQ};
  my $sql = "select $attribute from user_sequences where SEQUENCE_NAME='$seq'";
  my $rv = $self->{DBH}->selectrow_array($sql);
}

=head1 METHODS

=over 4

=item

new($dbh,$S) - construct a new sequence with name $S

=item

new($dbh) - construct a new sequence without naming it yet

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self  = {};
  $self->{DBH} = shift;
  $self->{SEQ} = uc(shift) if(@_); # Oracle likes uppercase
  bless ($self, $class);
  return $self;
}

=item

name($S) - set the sequence name

=item

name() - get the sequence name

=cut

sub name {
  my $self = shift;
  $self->{SEQ} = uc(shift) if(@_);
  $self->{SEQ};
}

=item

create() - create a new sequence.  Must have already called new().  Sequence will start with 1.

=item

create($N) - create a new sequence.  Must have already called new().  Sequence will start with $N

=cut

sub create {
  my $self = shift;
  my $seq = $self->{SEQ};

  # Carin found this bug.  Pass optional sequence starting point.  Defaults to 1.
  my $startWith = shift || '1';
  $self->{DBH}->do("create sequence $seq start with $startWith");
}

=item

currval() - return the current sequence value.  Note that for a brand new sequence, Oracle requires one reference to nextval before currval is valid.

=cut

sub currval {
  my $self = shift;
  my $seq = $self->{SEQ};
  my $rv = $self->{DBH}->selectrow_array("select $seq.currval from dual");
}

=item

nextval() - return the next sequence value

=cut

sub nextval {
  my $self = shift;
  my $seq = $self->{SEQ};
  my $rv = $self->{DBH}->selectrow_array("select $seq.nextval from dual");
}

=item

reset() - drop and recreate the sequence with default parms

=cut

sub reset {
  my $self = shift;
  $self->drop();
  $self->create();
}

=item

incrementBy($N) - alter sequence to increment by $N

=item

incrementBy() - return the current sequence's INCREMENT_BY value

=cut

sub incrementBy {
  my $self = shift;
  my $inc = shift;
  my $seq = $self->{SEQ};
  $self->{DBH}->do("alter sequence $seq increment by $inc") if $inc;
  $self->_getSeqAttribute("INCREMENT_BY");
}

=item

maxvalue($N) - alter sequence setting maxvalue to $N

=item

maxvalue() - return the current sequence's maxvalue

=cut

sub maxvalue {
  my $self = shift;
  my $max = shift;
  my $seq = $self->{SEQ};
  $self->{DBH}->do("alter sequence $seq maxvalue $max") if $max;
  $self->_getSeqAttribute("MAX_VALUE");
}

=item

minvalue($N) - alter sequence setting minvalue to $N

=item

minvalue() - return the current sequence's minvalue

=cut

sub minvalue {
  my $self = shift;
  my $min = shift;
  my $seq = $self->{SEQ};
  $self->{DBH}->do("alter sequence $seq minvalue $min") if $min;
  $self->_getSeqAttribute("MIN_VALUE");
}

=item

cache($N) - alter sequence to cache the next $N values

=item

cache() - return the current sequence's cache size

=cut

sub cache {
  my $self = shift;
  my $cacheVal = shift;
  my $seq = $self->{SEQ};
  $self->{DBH}->do("alter sequence $seq cache $cacheVal") if $cacheVal;
  $self->_getSeqAttribute("CACHE_SIZE");
}

=item

nocache() - alter sequence to not cache values

=cut

sub nocache {
  my $self = shift;
  my $seq = $self->{SEQ};
  $self->{DBH}->do("alter sequence $seq nocache");
  $self->_getSeqAttribute("CACHE_SIZE");
}

=item

cycle('Y')/cycle('N') - alter sequence to cycle/not cycle after reaching maxvalue instead of returning an error.  Note that cycle('N') and nocycle() are equivalent.

=item

cycle() - return the current sequence's cycle flag

=cut

sub cycle {
  my $self = shift;
  my $seq = $self->{SEQ};
  my $cycle_flag = shift;

  if (defined($cycle_flag)) {
    $self->{DBH}->do("alter sequence $seq cycle") if $cycle_flag eq 'Y';
    $self->{DBH}->do("alter sequence $seq nocycle") if $cycle_flag eq 'N';
  }
  $self->_getSeqAttribute("CYCLE_FLAG")
}

=item

nocycle() - alter sequence to return an error after reaching maxvalue instead of cycling

=cut

sub nocycle {
  my $self = shift;
  my $seq = $self->{SEQ};
  $self->{DBH}->do("alter sequence $seq nocycle");
  $self->_getSeqAttribute("CYCLE_FLAG");
}

=item

order('Y')/order('N') - alter sequence to guarantee/not guarantee that sequence numbers are generated in the order of their request.  Note that order('N') and noorder() are equivalent.

=item

order() - return current sequence's order flag

=cut

sub order {
  my $self = shift;
  my $seq = $self->{SEQ};
  my $order_flag = shift;

  if (defined($order_flag)) {
    $self->{DBH}->do("alter sequence $seq order") if $order_flag eq 'Y';
    $self->{DBH}->do("alter sequence $seq noorder") if $order_flag eq 'N';
  }
  $self->_getSeqAttribute("ORDER_FLAG");
}

=item

noorder() - alter sequence to not guarantee that sequence numbers are generated in order of request

=cut

sub noorder {
  my $self = shift;
  my $seq = $self->{SEQ};
  $self->{DBH}->do("alter sequence $seq noorder");
  $self->_getSeqAttribute("ORDER_FLAG");
}

=item

sequenceNameExists() - return 0 if current sequence's name does not already exist as a sequence name, non-zero if it does

=item

sequenceNameExists($S) - return 0 if $S does not exist as a sequence name, non-zero if it does

=cut

sub sequenceNameExists {
  my $self = shift;
  my $sequenceName = (uc shift) || $self->{SEQ};
  my $rv = grep(/^$sequenceName$/,@{$self->getSequencesAref});
}

=item

getSequencesAref() - return an arrayRef of all existing sequence names in the current schema

=cut

sub getSequencesAref {
  my $self = shift;
  my $seqArrayRef = $self->{DBH}->selectcol_arrayref("select sequence_name from user_sequences");
}

=item

printSequences() - print all existing sequence names in the current schema

=cut

sub printSequences {
  my $self = shift;
  print join(" ",@{$self->getSequencesAref}), "\n";
}

=item

info() - return a string containing information about the sequence

=cut

sub info {
  my $self = shift;
  my $seq = $self->{SEQ};
  my $sql = q(select * from user_sequences where SEQUENCE_NAME=?);
  my $sth = $self->{DBH}->prepare($sql);

  $sth->execute($seq);

  my $i=0;
  my $column;
  my $rv;
  foreach $column ($sth->fetchrow_array) {
    $rv .= $sth->{NAME}->[$i++] . "=$column\n";
  }
  $rv;
}

=item

print() - print a string containing information about the sequence

=cut

sub print {
  my $self = shift;

  print "\n", $self->info();
}

=item

drop() - drop the sequence

=cut

sub drop {
  my $self = shift;
  my $seq = $self->{SEQ};
  $self->{DBH}->do("drop sequence $seq");
}

}
1;

=back

=head1 COPYRIGHT

Copyright (c) 1999 Doug Bloebaum. All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 AUTHOR

Doug Bloebaum E<lt>bloebaum@dma.orgE<gt>
