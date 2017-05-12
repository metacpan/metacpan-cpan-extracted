package autoclass_100::Parent;
use strict;
use Class::AutoClass;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
#@ISA              = qw(Class::AutoClass);
@AUTO_ATTRIBUTES  = qw(auto real);
@OTHER_ATTRIBUTES = qw(other);
@CLASS_ATTRIBUTES = qw(class);
%SYNONYMS         = (syn=>'real');
%DEFAULTS = (auto       => 'auto attribute',
	     other      => 'other attribute',
	     class      => 'class attribute',
	     syn        => 'synonym',
	    );
Class::AutoClass::declare;

sub new {
  my $class=shift @_;
  my $self=bless {},$class;
  # emulate what AutoClass does with defaults
  my %defaults=%{Class::AutoClass::DEFAULTS($class)};
  while(my($attr,$default)=each %defaults) {
    $self->$attr($default);
  }
  $self;
}
sub other {
  my $self=shift;
  @_? $self->{_other}=$_[0]: $self->{_other};
}
1;
