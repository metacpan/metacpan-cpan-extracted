package DB::Appgen;

require 5.005_62;
use strict;
use warnings;
use Carp;
use Error;

##
# Package version
#
our $VERSION = '1.02';

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);

# This allows to simplify function-style interface with declaration:
#   use DB::appgen ':all';
#
our %EXPORT_TAGS = (
'file' => [ qw(
	ag_db_open
	ag_db_close
	ag_db_create
	ag_db_rewind
	ag_db_delete
	ag_db_lock
	ag_db_unlock
	) ],
'record' => [ qw(
	ag_db_read
	ag_db_write
	ag_db_release
	ag_db_newrec
	ag_db_delrec
	ag_readnext
	) ],
'field'	=> [ qw(
	ag_delete
	ag_extract
	ag_replace
	ag_insert
	ag_db_stat
	) ]
);
$EXPORT_TAGS{'all'}=[ @{$EXPORT_TAGS{'file'}},
                      @{$EXPORT_TAGS{'record'}},
                      @{$EXPORT_TAGS{'field'}} ];

our @EXPORT_OK = ( @{$EXPORT_TAGS{'all'}} );

##
# Prototypes:
#
sub new ($%);
sub close ($);
sub DESTROY ($);
sub delete_file ($);
sub lock ($);
sub rewind ($);
sub unlock ($);
sub commit ($);
sub release ($);
sub drop ($);
sub next ($%);
sub attributes_number ($);
sub values_number($%);
sub value_length ($%);
sub delete ($%);
sub extract ($%);
sub insert ($%);
sub replace ($%);
sub get_args (@);

##
# Bootstrapping
#
bootstrap DB::Appgen $VERSION;

##
#
# Object oriented interface goes here, while function oriented is loaded
# from .xs definitions dynamically.
#
##

##
# Returns new database reference object.
#
sub new ($%)
{ my $class=shift;
  $class=ref($class) if ref($class);
  my $file;
  my $trunc;
  my $create;
  my $hsize;
  if(@_==1 && ! ref ($_[0]))
   { $file=$_[0];
   }
  else
   { my $args=get_args(\@_);
     $file=$args->{file} || $args->{filename};
     $trunc=$args->{trunc} || $args->{truncate} || 0;
     $create=$args->{create} || 0;
     $hsize=$args->{hsize} || 0;
   }
  throw Error::Simple "${class}::new - no file name given" unless defined $file;
  my $dbh;
  if($create)
   { $dbh=ag_db_create($file,$hsize,$trunc);
     throw Error::Simple "${class}::new - cannot create db=$file" unless $dbh;
   }
  else
   { $dbh=ag_db_open($file);
     throw Error::Simple "${class}::new - cannot open db=$file" unless $dbh;
   }
  my $self=\$dbh;
  bless $self,$class;
}

##
# Closing database - not required, but suggested.
#
sub close ($)
{ my $self=shift;
  my $rc=ag_db_close($$self);
  $rc==0 || throw Error::Simple ref($self)."::close - $!";
  $$self=undef;
  1;
}

##
# Destroying.
#
sub DESTROY ($)
{ my $self=shift;
  $self->close if $$self;
}

##
# Deleting the file
#
sub delete_file ($)
{ my $self=shift;
  my $rc=ag_db_delete($$self);
  $rc==0 || throw Error::Simple ref($self)."::delete_file - $!";
  1;
}

##
# Locking
#
sub lock ($)
{ my $self=shift;
  my $rc=ag_db_lock($$self);
  $rc==0 || throw Error::Simple ref($self)."::lock - $!";
  1;
}

##
# Rewinding
#
sub rewind ($)
{ my $self=shift;
  my $rc=ag_db_rewind($$self);
  $rc==0 || throw Error::Simple ref($self)."::rewind - $!";
  1;
}

##
# Unlocking
#
sub unlock ($)
{ my $self=shift;
  my $rc=ag_db_unlock($$self);
  $rc==0 || throw Error::Simple ref($self)."::unlock - $!";
  1;
}

##
# Moving to the given record. Creating it if "create" argument given.
#
sub seek ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $key=$args->{key} || '';
  my $rc;
  if($args->{create})
   { $rc=ag_db_newrec($$self,$key,$args->{size} || 0);
   }
  else
   { $rc=ag_db_read($$self,$key,$args->{lock} || 0);
   }
  $rc==-1 ? 0 : 1;
}

##
# Commiting changes to the record
#
sub commit ($)
{ my $self=shift;
  my $rc=ag_db_write($$self);
  $rc==0 || throw Error::Simple ref($self)."::commit - $!";
  1;
}

##
# Releasing current record and its lock.
#
sub release ($)
{ my $self=shift;
  my $rc=ag_db_release($$self);
  $rc==0 || throw Error::Simple ref($self)."::release - $!";
  1;
}

##
# Deleting current record.
#
sub drop ($)
{ my $self=shift;
  my $rc=ag_db_delrec($$self);
  $rc==0 || throw Error::Simple ref($self)."::drop - $!";
  1;
}

##
# Moving to next record
#
sub next ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  ag_readnext($$self,$args->{lock} || 0);
}

##
# Number of attributes
#
sub attributes_number ($)
{ my $self=shift;
  ag_db_stat($$self,-1,-1);
}

##
# Number of values
#
sub values_number($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $attr=$args->{attribute} || $args->{attr} || 0;
  ag_db_stat($$self,$attr,-1);
}

##
# Length of field
#
sub value_length ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $attr=$args->{attribute} || $args->{attr} || 0;
  my $value=$args->{value} || $args->{val} || 0;
  ag_db_stat($$self,$attr,$value);
}

##
# Deletes value
#
sub delete ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $attr=$args->{attribute} || $args->{attr} || 0;
  my $value=$args->{value} || $args->{val} || 0;
  my $rc=ag_delete($$self,$attr,$value);
  $rc==0 || throw Error::Simple ref($self)."::delete - $!";
  1;
}

##
# Extracts value
#
sub extract ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $attr=$args->{attribute} || $args->{attr} || 0;
  my $value=$args->{value} || $args->{val} || 0;
  ag_extract($$self,$attr,$value,$args->{size} || 0);
}

##
# Inserts value
#
sub insert ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $attr=$args->{attribute} || $args->{attr} || 0;
  my $value=$args->{value} || $args->{val} || 0;
  my $rc=ag_insert($$self,$attr,$value,$args->{text} || '');
  $rc==0 || throw Error::Simple ref($self)."::insert - $!";
  1;
}

##
# Inserts value
#
sub replace ($%)
{ my $self=shift;
  my $args=get_args(\@_);
  my $attr=$args->{attribute} || $args->{attr} || 0;
  my $value=$args->{value} || $args->{val} || 0;
  my $rc=ag_replace($$self,$attr,$value,$args->{text} || '');
  $rc==0 || throw Error::Simple ref($self)."::replace - $!";
  1;
}

##
# Reads entire attribute returning array of all values even if only one
# exists. Values are numbered from 0, not form 1, be careful!
#
# Returns array reference or array itself in array context.
#
sub attribute ($%)
{ my $self=shift;
  my $attr;
  if(@_==1 && !ref($_[0]))
   { $attr=$_[0] || 0;
   }
  else
   { my $args=get_args(\@_);
     $attr=$args->{attribute} || $args->{attr} || 0;
   }
  my $valnum=$self->values_number(attribute => $attr);
  my @arr;
  for(my $val=0; $val<$valnum; $val++)
   { push @arr,$self->extract(attribute => $attr, value => $val + 1);
   }
  wantarray ? @arr : \@arr;
}

##
# Reads entire current record into array of the following structure:
#  [ 'key',
#    [ 'multi', 'valued', 'attribute' ],
#    'single valued attribute',
#    ...
#  ]
#  
# Returns array reference or array itself in array context.
#
sub record ($)
{ my $self=shift;
  my @data;
  my $na=$self->attributes_number;
  for(my $attr=0; $attr<$na; $attr++)
   { my @ad=$self->attribute($attr);
     next unless @ad;
     $data[$attr]=@ad == 1 ? $ad[0] : \@ad;
   }
  wantarray ? @data : \@data;
}

##
# Gets arguments hash reference from parameters array. Called as:
# sub xxx ($%)
# { my $self=shift;
#   my $args=get_args(\@_);
#
# Allows to call xxx as:
# $self->xxx({a => 1, b => 2});
# and as:
# $self->xxx(a => 1, b => b);
#
sub get_args (@)
{ my $arr=ref($_[0]) eq "ARRAY" ? $_[0] : \@_;
  my $args;
  if(@{$arr} == 1)
   { $args=$arr->[0];
     throw Error::Simple "Not a HASH in arguments" unless ref($args) eq "HASH";
   }
  elsif(! (scalar(@{$arr}) % 2))
   { my %a=@{$arr};
     $args=\%a;
   }
  else
   { throw Error::Simple "Unparsable arguments";
   }
  $args={} unless $args;
  $args;
}

##
# That's it
#
1;
#
#################################################################################
__END__

=head1 NAME

DB::Appgen - Perl interface to APPGEN databases

=head1 SYNOPSIS

Object oriented:

  use DB::Appgen;

  my $db=new DB::Appgen file => "order.db";

  $db->seek(key => 'Test);

  my $data=$db->record;

  print "quantity=", $data->[123]->[2];

  $db->replace(attribute => '1', value => '2', text => 'Test Data 1-2');

  $db->commit;

  $db->close;

Function oriented (mimics appgen C toolkit):

  use DB::Appgen qw(:all);

  my $db=ag_db_open('sales.db');

  ag_db_newrec($db,'Test',0);

  ag_insert($db,1,2,'Test Data 1-2');

  ag_db_write($db);

  ag_db_close($db);

=head1 DESCRIPTION

This is DB::Appgen - low-level functions for APPGEN database
manipulations (you probably already know what appgen is if you loaded
this module, but if you don't please visit http://appgen.com/ - in short
it is the sytem behind these green salesman terminals you see in various
ikeas, sears and so on).

All this was made in about ten hours including reading perlxstut and
perlpod manpages, so do not expect something pretty. Although it appears
to be working OK in my tests.

Whenever possible it is recommended to use object oriented interface to
appgen. The list of all methods and their equivalent functions follows.

=head1 FILE LEVEL METHODS

=head2 $db->close;

=head2 ag_db_close($db);

Closes underlying database handler. Function must be called in order for
the database to be in correct state, while for object oriented method it
is only a recomendation to call it.

Object would be closed by perl's garbage collector if you forget about it.

=head2 $db=new DB::Appgen file => 'filename', create => 1, hsize => 0, truncate => 1;

=head2 ag_db_create('filename', 0, 1);

Creates new database or truncates existing one.

=head2 $db->delete_file;

=head2 ag_db_delete($db)

Deletes the file associated with the database. Be careful!

=head2 $db->lock;

=head2 ag_db_lock($db);

Locks database.

=head2 $db=new DB::Appgen file => 'filename';

=head2 $db=ag_db_open('filename');

Opens existing database.

=head2 $db->rewind;

=head2 ag_db_rewind(*db);

Re-positions I<current record> pointer to the first record in file.

=head2 $db->unlock;

=head2 ag_db_unlock($db);

Unlocks database.

=head1 RECORD LEVEL METHODS

=head2 $db->seek(key => "key", lock => 1);

=head2 ag_db_read($db, "key", $lock);

Attempts to find and, if specified, lock the record by given key. Moves
I<current record> on success. In case of of error current record is not
defined.

=head2 $db->commit;

=head2 ag_db_write($db)

Writes changes made to the current record to the database.

=head2 $db->release;

=head2 ag_db_release($db);

Unlocks I<current record> if it is locked; I<current record> becomes
undefined.

=head2 $db->seek(key => "key", create => 1, size => $size);

=head2 ag_db_newrec($db, "key", $size);

Finds and locks existing records or creates new one. Size can be set to
the total record size in bytes if you know it, otherwise do not supply
it at all.

=head2 $db->drop;

=head2 ag_db_delrec

Deletes I<current record> which must be locked.

=head2 $db->next(lock => 1);

=head2 ag_readnext($db);

Moves I<current record> to the next record in the database in random
order locking it if required. Returns key text or undef if no more
records exist.

=head1 FIELD LEVEL METHODS

=head2 ag_db_stat($db, $attr, $value);

This method determines the size and composition of a field in the
I<current record>. Consult appgen documentation for details.

A number of methods exists to get the same functionality in more
straight forward way:

=over

=item $db->attributes_number;

Returns number of attributes in the I<current record>.

=item $db->values_number(attribute => $attr);

Returns number of values in the given attribute of the I<current record>.

=item $db->value_length(attribute => $attr, value => $value).

Returns length of the given value in the given attribute of the
I<current record>. If value is not set or is zero then length of entire
attribute is returned (for multi-valued attributes this includes value
separators).

=back

=head2 $db->delete(attribute => $attr, value => $value);

=head2 ag_delete($db,$attr,$value);

Deletes given value or attribute in its entirety if no value number is
given. Attributes or values after deleted one are renumbered to fill the
gap, be careful.

=head2 $db->extract(attribute => $attr, value => $value, size => $size);

=head2 ag_extract($db,$attr,$value,$size);

Returns the content of the given value or the given attribute if value
is zero. Size is not required, by default entire string is returned.

=head2 $db->insert(attribute => $attr, value => $value, text => $text);

=head2 ag_insert($db,$attr,$value,$text);

Inserts new field into the I<current record>. If there is already a
field at $attr/$value it is renumbered one higher.

=head2 $db->replace(attribute => $attr, value => $value, text => $text);

=head2 ag_replace($db, $attr, $value, $text);

Replaces the field pointed to by attribute and value. Any fields between
the end of the I<current record> and the specified field will be created
if required.

=head1 SUPPORTING METHODS

=head2 $db->attribute(attribute => $attr);

Reads entire attribute returning array of all values even if only one
exists. B<Values are numbered from 0, not form 1, be careful!>

Returns array reference or array itself in array context.

=head2 $db->record;

Reads entire I<current record> into array of the following structure:
  [ 'key',
    [ 'multi', 'valued', 'attribute' ],
    'single valued attribute',
    ...
   ]

Returns array reference or array itself in array context.
B<Values are numbered from 0, not form 1, be careful!>

=head1 EXPORT

None by default.

=head1 AUTHOR

Copyright (c) 2000 XAO Inc., Andrew Maltsev

=head1 SEE ALSO

http://xao.com/,
http://sourceforge.net/projects/dbappgen/,
http://appgen.com/

=cut
