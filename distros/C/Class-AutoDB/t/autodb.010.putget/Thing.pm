package Thing;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS %AUTODB);
@AUTO_ATTRIBUTES=qw(id desc);
%AUTODB=1;			# no collections
# NG 10-09-09: discovered that 'declare' was missing. amazing it worked without it...
Class::AutoClass::declare;


1;
