/*  cdemo.c
**
**  Copyright (c) 1994-2000  William Setzer
**
**  You may distribute under the terms of either the Artistic License
**  or the GNU General Public License, as specified in the README file.
*/

#include "CursesDef.h"
#include "c-config.h"
#ifdef VMS
#include <unistd.h>  /* not in perl.h ??? */
#endif
#ifdef WIN32
#include <Windows.h>
#endif

static void
sleepSeconds(unsigned int seconds) {

#ifdef WIN32
    Sleep(seconds * 1000);
#else
    sleep(seconds);
#endif
}



int
main(unsigned int  const argc,
     const char ** const argv) {

    WINDOW *b;
    chtype ch;
    char str[250];
    int m, n;

    initscr();
    b = subwin(stdscr, 10, 20, 3, 3);

    noecho();
    cbreak();

    move(0, 0);
    addstr("ref b = <something C won't do>");
    move(1, 1);
    addstr("fooalpha");

#ifdef C_ATTRON
#  ifdef A_BOLD
    attron(A_BOLD);
#  endif
#endif
    move(2, 5);
    addstr("bold  ");
#ifdef C_ATTRON
#  ifdef A_REVERSE
    attron(A_REVERSE);
#  endif
#endif
    addstr("bold+reverse");
#ifdef C_ATTRSET
#  ifdef A_NORMAL
    attrset(A_NORMAL);
#  endif
#endif
    addstr("  normal  (if your curses can do these modes)");

    move(6, 1);
    addstr("do12345678901234567890n't worry be happy");
#ifdef C_BOX
    box(b, '|', '-');
#endif
    wstandout(b);
    move(2, 2);
    waddstr(b, "ping");
    wstandend(b);
    move(4, 4);
    waddstr(b, "pong");

    wmove(b, 3, 3);
    move(6, 3);
    wdeleteln(b);
    insertln();

    move(4, 5);
    wdelch(b);
    move(7, 8);
    insch('a');

#ifdef C_KEYPAD
    keypad(stdscr, 1);
#endif
    move(14, 0);
    addstr("hit a key: ");
    refresh();
    ch = getch();
    move(15, 0);
    printw("you typed: >>%c<<", ch);
    move(17, 0);
    addstr("enter string: ");
    refresh();
    getstr(str);

    move(18, 0);
    printw("you typed: >>%s<<", str);
    getyx(stdscr, m, n);
    move(19, 4);
    printw("y == %d (should be 18), x == %d", m, n);

    ch = mvinch(19, 7);
    move(20, 0);
    printw("The character at (19,7) is an '%c' (should be an '=')", ch);

    move(21, 0);
    addstr("testing KEY_*.  Hit the up arrow on your keyboard: ");
    refresh();
    ch = getch();

#ifdef KEY_UP
    if (ch == KEY_UP) { mvaddstr(22, 0, "KEY_UP was pressed!");         }
    else              { mvaddstr(22, 0, "Something else was pressed."); }
#else
    move(22, 0);
    addstr("You don't seem to have the KEY_UP macro");
#endif

    move(LINES - 1, 0);
    refresh();

    sleepSeconds(5);

    endwin();
}
