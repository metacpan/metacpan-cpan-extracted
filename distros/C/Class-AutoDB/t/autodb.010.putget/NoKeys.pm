package NoKeys;
use base qw(Class::AutoClass);
use vars qw(@AUTO_ATTRIBUTES %AUTODB);
@AUTO_ATTRIBUTES=qw(id name no_colls);
%AUTODB=(collections=>'NoKeys');
Class::AutoClass::declare;

1;
