# Updated version of Chris's dd_freeze_thaw.t
# tests basic freeze/thaw behavior of Dumper to make sure our patch is installed
# update to use Class::AutoDB::Dumper
# package DD_test;
use lib qw(../blib/lib ../blib/arch);
use Class::AutoDB::Dumper;
use Test::More;
use Test::Deep;

my $dumper_class='Class::AutoDB::Dumper';
# my $dumper_class='Data::Dumper';

for my $useperl (0..1) {
  my $DUMPER=$dumper_class->new([undef],['thaw']) ->
    Purity(1)->Indent(1)->Freezer('DUMPER_freeze')->Toaster('DUMPER_thaw');
  $DUMPER->Useperl($useperl);
  my $label=$useperl? 'perl': 'xs';
  
  my $f = new freezable;
  my $t = new unthawable;
  
  $f->other(new unthawable);
  $t->other(new freezable);

  my ($thaw);

  note("-" x 40); 
  note("$label Freezable\n");
  note("-" x 40); 
  my $th1 = $DUMPER->Values([$f])->Dump;
  eval $th1;			#sets $thaw
  if ($@) {
    fail("$label: eval. error is $@");
    diag("$label: skipping rest of freezable tests");
  } else {
    isa_ok($thaw,"freezable");
    is($thaw->fresh, 'nope. frozen and thawed',"$label: freezable changed by freeze/thaw");
    is($f->fresh,'fresh',"$label: original object unchanged by freeze/thaw");
    isnt($thaw->can('DUMPER_thaw'),undef,"$label: freezable can DUMPER_thaw");
    is($thaw->other->can('DUMPER_thaw'),undef,"$label: unthawable can't DUMPER_thaw");
  }
  undef $thaw;

  note("-" x 40);
  note("$label Unfreezable\n");
  note("-" x 40);

  my $th2 = $DUMPER->Values([$t])->Dump; #sets $thaw
  eval $th2;			#sets $thaw
   if ($@) {
    fail("$label: eval. error is $@");
    diag("$label: skipping rest of unfreezable tests");
  } else {
    is($thaw->fresh,'fresh',"$label: unthawable not changed by DUMPER_freeze");
    is($thaw->other->fresh, 'nope. frozen and thawed',"$label: freezable changed by freeze/thaw");
    is($t->other->fresh,'fresh',"$label: original object unchanged by freeze/thaw");
    is($thaw->can('DUMPER_thaw'),undef,"$label: unthawable can't DUMPER_thaw");
    isnt($thaw->other->can('DUMPER_thaw'),undef,"$label: freezable can DUMPER_thaw"); 
 }
}
done_testing();
## freezable package
package freezable;
use Test::More;

sub new {
  my($class)=@_;
  return bless {fresh=>'fresh'},$class; 
}

sub fresh {
 my $self=shift;
 @_? $self->{fresh}=$_[0]: $self->{fresh};
}
sub other {
 my $self=shift;
 @_? $self->{other}=$_[0]: $self->{other};
}
# NG 10-01-01: modified to leave $self unchanged and return desired new value
sub DUMPER_freeze {
  my($self)=@_;
  note(">>> DUMPER_freeze");
  my $copy=bless {},ref $self;
  # force shallow copy
  %$copy=%$self;
  $copy->fresh('nope. frozen and thawed');
  return $copy;
}

sub DUMPER_thaw {
  my($self)=@_;
  note("<<< DUMPER_thaw");
  return $self;
}

sub oid2object {
  shift @_ unless ref($_[0])=~/DBI::/;
  %__PACKAGE__::OID_2_OBJECT=shift @_ if @_;
  return \%$__PACKAGE__::OID_2_OBJECT;
}

## unthawable package (no DUMPER_freeze, DUMPER_thaw method)
package unthawable;
use Test::More;

sub new {
  my($class)=@_;
  return bless {fresh=>'fresh'},$class; 
}

sub fresh {
 my $self=shift;
 @_? $self->{fresh}=$_[0]: $self->{fresh};
}
sub other {
 my $self=shift;
 @_? $self->{other}=$_[0]: $self->{other};
}
