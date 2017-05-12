package t::Object::ReadOnly;

use Class::InsideOut qw/readonly new/;

readonly name => my %name;
readonly age => my %age;

1;
