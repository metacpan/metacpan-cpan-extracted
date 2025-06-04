use Object::Pad ':experimental(:all)';

package App::BS::pkgdepends;

class App::BS::pkgdepends
  : isa(App::BS::CLI);

use BS::Ext::pactree;

use utf8;
use v5.40;

field $queue : mutator : param = [];

method run (%runopts) {
    $self->print_self if $ENV{DEBUG};

    foreach my $pkg (@$queue) {
        state $sync = $self->cliopts->{sync};

        print __CLASS__->list_deps(
            $pkg, $self->cliopts->%*, %runopts, sync => $sync
          ),
          $pkg ne $$queue[-1]
          ? ( $self->cliopts->{delimiter} // "\n\n" )
          : "\n";

        $sync = 0 unless $self->cliopts->{sync} == -1;
    }
}
