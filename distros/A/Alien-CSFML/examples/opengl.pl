use strict;
use warnings;
$|++;
use Alien::CSFML;
use ExtUtils::CBuilder;
my $SF  = Alien::CSFML->new( 'C++' => 1 );
my $CC  = ExtUtils::CBuilder->new();
my $SRC = 'opengl.cxx';
open( my $FH, '>', $SRC ) || die '...';
syswrite( $FH, <<'END')   || die '...'; close $FH;
#include <SFML/Window.hpp>
#include <SFML/OpenGL.hpp>

int main()
{
    // create the window
    sf::Window window(sf::VideoMode(800, 600), "OpenGL", sf::Style::Default, sf::ContextSettings(32));
    window.setVerticalSyncEnabled(true);

    // activate the window
    window.setActive(true);

    // load resources, initialize the OpenGL states, ...

    // run the main loop
    bool running = true;
    while (running)
    {
        // handle events
        sf::Event event;
        while (window.pollEvent(event))
        {
            if (event.type == sf::Event::Closed)
            {
                // end the program
                running = false;
            }
            else if (event.type == sf::Event::Resized)
            {
                // adjust the viewport when the window is resized
                glViewport(0, 0, event.size.width, event.size.height);
            }
        }

        // clear the buffers
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // draw...

        // end the current frame (internally swaps the front and back buffers)
        window.display();
    }

    // release resources...

    return 0;
}

END
my $OBJ = $CC->compile( 'C++' => 1, source => $SRC, include_dirs => [ $SF->include_dirs ] );
my $EXE = $CC->link_executable(
    objects            => $OBJ,
    extra_linker_flags => ' -lstdc++ ' . $SF->ldflags(qw[graphics system window]) .

        # Linux:
        ' -lX11 -lXxf86vm -lXrandr -lpthread -ldl -lXinerama -lXcursor -lGLEW -lGL -lm -lXi'
);
print system(
    ( $^O eq 'MSWin32' ? '' : 'LD_LIBRARY_PATH=' . join( ':', '.', $SF->library_path(1) ) . ' ' ) .
        './' . $EXE ) ? 'Aww...' : 'Yay!';
print system( './' . $EXE ) ? 'Aww...' : 'Yay!';
END { unlink grep defined, $SRC, $OBJ, $EXE; }
