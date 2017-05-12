package autoclass_103::Parent;
use strict;
use Class::AutoClass;
use vars
  qw(@ISA @AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
@ISA              = qw(Class::AutoClass);
@AUTO_ATTRIBUTES  = qw(name sex address dob a _b c d z real);
@OTHER_ATTRIBUTES = qw(b age);
@CLASS_ATTRIBUTES = qw(species population class_hash);
%SYNONYMS         = ( gender => 'sex', whatisya => 'sex', syn=>'real' );
%DEFAULTS = (
              a          => 'parent',
              b          => 'virtual parent',
              c          => 'default set in parent, used in kids',
              z          => 'default that is never used',
              species    => 'Dipodomys gravipes',
              population => 42,
              class_hash => {
                              this  => 'that',
                              these => 'those',
              }
);
Class::AutoClass::declare(__PACKAGE__);

sub _init_self {
 my ( $self, $class, $args ) = @_;
 return
   unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this

}
sub age { print "Calculate age from dob. NOT YET IMPLEMENTED\n"; undef }
# NG 05-12-07. virtual attribute for regression test
sub b {
  my $self=shift;
  @_? $self->_b(@_): $self->_b(@_);
}
1;
