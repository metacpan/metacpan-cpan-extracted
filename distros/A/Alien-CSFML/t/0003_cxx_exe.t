use strict;
use warnings;
BEGIN { chdir '../' if not -d '_build'; }
use Test::More;
use File::Temp;
use lib qw[blib/lib];
use Alien::CSFML;
use ExtUtils::CBuilder;
$|++;
my $CC = ExtUtils::CBuilder->new( quiet => 0 );
my $SF = Alien::CSFML->new( 'C++' => 1 );
my ( $FH, $SRC ) = File::Temp::tempfile(
    'alien_csfml_t0002_XXXX',
    TMPDIR  => 1,
    UNLINK  => 1,
    SUFFIX  => '.cxx',
    CLEANUP => 1
);
syswrite( $FH, <<'END') || BAIL_OUT("Failed to write to $SRC: $!"); close $FH;
#include <SFML/Graphics.hpp>
int main(int argc, char **argv) {
    sf::RenderWindow window(sf::VideoMode(200, 200), "SFML works!");
    sf::CircleShape shape(100.f);
    shape.setFillColor(sf::Color::Green);
    while (window.isOpen()) {
        sf::Event event;
        while (window.pollEvent(event)) {
            if (event.type == sf::Event::Closed)
                window.close();
        }
        window.clear();
        window.draw(shape);
        window.display();
        break;
    }
    return 0;
}
END
my $OBJ = $CC->compile( 'C++' => 1, source => $SRC, include_dirs => [ $SF->include_dirs() ], );
ok( $OBJ, 'Compile' );
my $EXE = $CC->link_executable(
    objects            => $OBJ,
    extra_linker_flags => ' -lstdc++ ' . $SF->ldflags(qw[graphics system window])

        #' -lsfml-audio  -lsfml-network
);
ok( $EXE, 'Link exe' );
ok(
    !system(
        (
            $^O eq 'MSWin32' ? '' :
                ( 'LD_LIBRARY_PATH=' . join( ':', '.', $SF->library_path(1) ) . ' ' )
        ) .
            $EXE
    ),
    sprintf 'Run exe'
) if 0;
unlink $OBJ, $EXE, $SRC;
done_testing;
