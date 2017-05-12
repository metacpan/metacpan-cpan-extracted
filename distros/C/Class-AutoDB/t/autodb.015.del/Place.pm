package Place;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name address);
@OTHER_ATTRIBUTES=qw(country);
%AUTODB=
  (collections=>
   {Place=>qq(id integer, name string, country string),
   HasName=>qq(id integer, name string)});
Class::AutoClass::declare;

# defaults to USA
sub country {
  my $self=shift;
  @_? $self->{country}=$_[0]: ($self->{country} || 'USA');
}

1;
