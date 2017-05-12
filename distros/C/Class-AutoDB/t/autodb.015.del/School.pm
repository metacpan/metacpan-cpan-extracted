package School;
use base qw(Place);
use vars qw(@AUTO_ATTRIBUTES %DEFAULTS);
@AUTO_ATTRIBUTES=qw(subjects);
%DEFAULTS=(subjects=>[]);

Class::AutoClass::declare;

1;
