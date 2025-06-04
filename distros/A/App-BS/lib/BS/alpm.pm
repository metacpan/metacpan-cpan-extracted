use Object::Pad ':experimental(:all)';

package BS::alpm;
role BS::alpm : does(BS::Common);

use utf8;
use v5.40;

use Data::Printer;

use Inline C               => config => enable => autowrap => myextlib =>
  '/usr/lib/libalpm.so.15' => libs   =>
  '-lalpm -lalpm_list -lalpm_depends -lalpm_packages';

##use Inline C => "alpm_initialize();";

#APPLY {
#    alpm_initialize();
#    BS::alpm::alpm_initialize();
#}

method print_self {

    #say BS::alpm::alpm_initialize();
    #say Dumper($self);
    warn np $self if $self->debug // $ENV{DEBUG};
}
