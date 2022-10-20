use lib '../../blib';
use strict;
use warnings;
$|++;
{
    use Alien::CSFML;
    use ExtUtils::CBuilder;
    my $SF  = Alien::CSFML->new( 'C++' => 1 );
    my $CC  = ExtUtils::CBuilder->new();
    my $SRC = 'hello_world.cxx';
    open( my $FH, '>', $SRC ) || die '...';
    syswrite( $FH, <<'END')   || die '...'; close $FH;
#include <SFML/Graphics.hpp>
int main() {
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
    }
    return 0;
}
END
    my $OBJ = $CC->compile( 'C++' => 1, source => $SRC, include_dirs => [ $SF->include_dirs ] );
    my $EXE = $CC->link_executable(
        objects            => $OBJ,
        extra_linker_flags => ' -lstdc++ ' . $SF->ldflags(qw[graphics system window audio])
    );
    print system(
        (
            $^O eq 'MSWin32' ? '' :
                'LD_LIBRARY_PATH=' . join( ':', '.', $SF->library_path() ) . ' '
        ) .
            './' . $EXE
    ) ? 'Aww...' : 'Yay!';
    END { unlink grep defined, $SRC, $OBJ, $EXE; }
}
