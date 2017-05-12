use lib '../../blib';
$|++;
use Alien::FLTK;
use ExtUtils::CBuilder;
my $AF  = Alien::FLTK->new();
my $CC  = ExtUtils::CBuilder->new();
my $SRC = 'hello_world.cxx';
open(my $FH, '>', $SRC) || die '...';
syswrite($FH, <<'END') || die '...'; close $FH;
#include <FL/Fl.H>
#include <FL/Fl_Window.H>
#include <FL/Fl_Box.H>
int main(int argc, char **argv) {
  Fl_Window *window = new Fl_Window(300,180);
  Fl_Box *box = new Fl_Box(FL_UP_BOX, 20, 40, 260, 100, "Hello, World!");
  box->labelfont(FL_BOLD + FL_ITALIC);
  box->labelsize(36);
  box->labeltype(FL_SHADOW_LABEL);
  window->end();
  window->show(argc, argv);
  return Fl::run();
}
END
my $OBJ = $CC->compile('C++'                => 1,
                       source               => $SRC,
                       include_dirs         => [$AF->include_dirs()],
                       extra_compiler_flags => $AF->cxxflags()
);
my $EXE =
    $CC->link_executable(
         objects            => $OBJ,
         extra_linker_flags => '-L' . $AF->library_path . ' ' . $AF->ldflags('gl')
    );
print system('./' . $EXE) ? 'Aww...' : 'Yay!';
END { unlink grep defined, $SRC, $OBJ, $EXE; }
