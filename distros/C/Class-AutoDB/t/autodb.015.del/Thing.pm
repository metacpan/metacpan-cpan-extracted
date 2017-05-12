package Thing;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id desc);
%AUTODB=1;			# no collections
Class::AutoClass::declare;

1;
