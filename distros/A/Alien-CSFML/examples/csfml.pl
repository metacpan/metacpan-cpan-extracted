#use lib '../../blib';
use strict;
use warnings;
$|++;
{
    use Alien::CSFML;
    use ExtUtils::CBuilder;
    my $SF  = Alien::CSFML->new();
    my $CC  = ExtUtils::CBuilder->new();
    my $SRC = 'hello_world.c';
    open( my $FH, '>', $SRC ) || die '...';
    syswrite( $FH, <<'END')   || die '...'; close $FH;
#include <SFML/Audio.h>
#include <SFML/Graphics.h>

 int main()
 {
     sfVideoMode mode = {800, 600, 32};
     sfRenderWindow* window;
     sfTexture* texture;
     sfSprite* sprite;
     sfFont* font;
     sfText* text;
     sfMusic* music;
     sfEvent event;

     /* Create the main window */
     window = sfRenderWindow_create(mode, "SFML window", sfResize | sfClose, NULL);
     if (!window)
         return -1;

     /* Load a sprite to display */
     // https://en.wikipedia.org/wiki/JPEG#/media/File:JPEG_example_JPG_RIP_100.jpg
     texture = sfTexture_createFromFile("JPEG_example_JPG_RIP_100.jpg", NULL);
     if (!texture)
         return -1;
     sprite = sfSprite_create();
     sfSprite_setTexture(sprite, texture, sfTrue);

     /* Create a graphical text to display */
     // https://github.com/googlefonts/roboto/releases
     font = sfFont_createFromFile("Roboto-Regular.ttf");
     if (!font)
         return -1;
     text = sfText_create();
     sfText_setString(text, "Hello SFML");
     sfText_setFont(text, font);
     sfText_setCharacterSize(text, 50);

     /* Load a music to play */
     // https://en.wikipedia.org/wiki/File:Binbeat_sample.ogg
     music = sfMusic_createFromFile("Binbeat_sample.ogg");
     if (!music)
         return -1;

     /* Play the music */
     sfMusic_play(music);

     /* Start the game loop */
     while (sfRenderWindow_isOpen(window))
     {
         /* Process events */
         while (sfRenderWindow_pollEvent(window, &event))
         {
             /* Close window : exit */
             if (event.type == sfEvtClosed)
                 sfRenderWindow_close(window);
         }

         /* Clear the screen */
         sfRenderWindow_clear(window, sfBlack);

         /* Draw the sprite */
         sfRenderWindow_drawSprite(window, sprite, NULL);

         /* Draw the text */
         sfRenderWindow_drawText(window, text, NULL);

         /* Update the window */
         sfRenderWindow_display(window);
     }

     /* Cleanup resources */
     sfMusic_destroy(music);
     sfText_destroy(text);
     sfFont_destroy(font);
     sfSprite_destroy(sprite);
     sfTexture_destroy(texture);
     sfRenderWindow_destroy(window);

     return 0;
 }
END
    my $OBJ = $CC->compile( source => $SRC, include_dirs => [ $SF->include_dirs ] );
    my $EXE = $CC->link_executable(
        objects            => $OBJ,
        extra_linker_flags => $SF->ldflags(qw[graphics system window audio])
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
