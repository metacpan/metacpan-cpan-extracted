########################################
# test classes for basics transients
########################################
package Transients;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(name sex id id_mod3 name_prefix sex_word list);
%AUTODB=(collection=>'Transients', 
	 keys=>qq(name string, id integer, id_mod3 int, list list(int)),
	 transients=>qq(name_prefix sex_word id_mod3 list));
Class::AutoClass::declare;

sub _init_self {
 my ($self,$class,$args)=@_;
 return unless $class eq __PACKAGE__;    # to prevent subclasses from re-running this
 $self->sex($self->id % 2? 'M': 'F');
 $self->name_prefix($self->name.' prefix');
 $self->sex_word($self->sex eq 'M'? 'male': 'female');
 $self->id_mod3($self->id % 3);
 $self->list([$self->{id_mod3},($self->{id_mod3}+1)%3]);
}

1;
