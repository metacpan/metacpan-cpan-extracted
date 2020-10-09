/*  This is an inclusion for Curses.c.
**
**
**  CursesFun.c -- the functions
**
**  This is an inclusion for Curses.c
**
**  Copyright (c) 1994-2000  William Setzer
**
**  You may distribute under the terms of either the Artistic License
**  or the GNU General Public License, as specified in the README file.
*/

/* curs_addch */

XS(XS_Curses_addch)
{
    dXSARGS;
#ifdef C_ADDCH
    c_countargs("addch", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ch  = c_sv2chtype(ST(c_arg));
    int ret = c_mret == ERR ? ERR : waddch(win, ch);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("addch");
    XSRETURN(0);
#endif
}

XS(XS_Curses_echochar)
{
    dXSARGS;
#ifdef C_ECHOCHAR
    c_countargs("echochar", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ch  = c_sv2chtype(ST(c_arg));
    int ret = c_mret == ERR ? ERR : wechochar(win, ch);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("echochar");
    XSRETURN(0);
#endif
}


/* curs_addchstr */

XS(XS_Curses_addchstr)
{
    dXSARGS;
#ifdef C_ADDCHSTR
    c_countargs("addchstr", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype *str = (chtype *)SvPV_nolen(ST(c_arg));
    int ret = c_mret == ERR ? ERR : waddchstr(win, str);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("addchstr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_addchnstr)
{
    dXSARGS;
#ifdef C_ADDCHNSTR
    c_countargs("addchnstr", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype *str = (chtype *)SvPV_nolen(ST(c_arg));
    int n   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : waddchnstr(win, str, n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("addchnstr");
    XSRETURN(0);
#endif
}


/* curs_addstr */

XS(XS_Curses_addstr)
{
    dXSARGS;
#ifdef C_ADDSTR
    c_countargs("addstr", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    char *  str = (char *)SvPV_nolen(ST(c_arg));
    int ret = c_mret == ERR ? ERR : waddstr(win, str);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("addstr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_addnstr)
{
    dXSARGS;
#ifdef C_ADDNSTR
    c_countargs("addnstr", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    char *  str = (char *)SvPV_nolen(ST(c_arg));
    int n   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : waddnstr(win, str, n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("addnstr");
    XSRETURN(0);
#endif
}


/* curs_attr */

XS(XS_Curses_attroff)
{
    dXSARGS;
#ifdef C_ATTROFF
    c_countargs("attroff", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int attrs   = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : wattroff(win, attrs);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("attroff");
    XSRETURN(0);
#endif
}

XS(XS_Curses_attron)
{
    dXSARGS;
#ifdef C_ATTRON
    c_countargs("attron", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int attrs   = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : wattron(win, attrs);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("attron");
    XSRETURN(0);
#endif
}

XS(XS_Curses_attrset)
{
    dXSARGS;
#ifdef C_ATTRSET
    c_countargs("attrset", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int attrs   = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : wattrset(win, attrs);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("attrset");
    XSRETURN(0);
#endif
}

XS(XS_Curses_standend)
{
    dXSARGS;
#ifdef C_STANDEND
    c_countargs("standend", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : (int)wstandend(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("standend");
    XSRETURN(0);
#endif
}

XS(XS_Curses_standout)
{
    dXSARGS;
#ifdef C_STANDOUT
    c_countargs("standout", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : (int)wstandout(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("standout");
    XSRETURN(0);
#endif
}

XS(XS_Curses_attr_get)
{
    dXSARGS;
#ifdef C_ATTR_GET
    c_countargs("attr_get", items, 3);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    attr_t  attrs   = 0;
    short   color   = 0;
    void *  opts    = 0;
    int ret = c_mret == ERR ? ERR : wattr_get(win, &attrs, &color, opts);
    
    sv_setiv(ST(c_arg), (IV)attrs);;
    sv_setiv(ST(c_arg+1), (IV)color);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("attr_get");
    XSRETURN(0);
#endif
}

XS(XS_Curses_attr_off)
{
    dXSARGS;
#ifdef C_ATTR_OFF
    c_countargs("attr_off", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    attr_t  attrs   = (attr_t)SvIV(ST(c_arg));
    void *  opts    = 0;
    int ret = c_mret == ERR ? ERR : wattr_off(win, attrs, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("attr_off");
    XSRETURN(0);
#endif
}

XS(XS_Curses_attr_on)
{
    dXSARGS;
#ifdef C_ATTR_ON
    c_countargs("attr_on", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    attr_t  attrs   = (attr_t)SvIV(ST(c_arg));
    void *  opts    = 0;
    int ret = c_mret == ERR ? ERR : wattr_on(win, attrs, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("attr_on");
    XSRETURN(0);
#endif
}

XS(XS_Curses_attr_set)
{
    dXSARGS;
#ifdef C_ATTR_SET
    c_countargs("attr_set", items, 3);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    attr_t  attrs   = (attr_t)SvIV(ST(c_arg));
    short   color   = (short)SvIV(ST(c_arg+1));
    void *  opts    = 0;
    int ret = c_mret == ERR ? ERR : wattr_set(win, attrs, color, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("attr_set");
    XSRETURN(0);
#endif
}

XS(XS_Curses_chgat)
{
    dXSARGS;
#ifdef C_CHGAT
    /* Our 4th argument is meaningless.  It mirrors the meaningless "opts"
       argument in the Curses C library.

       In Perl Curses 1.16, we tried reducing this to 3 as a user thought
       a 3-argument call ought to work, and we thought this number might
       just be the _minimum_ argument count.  Well, it's not.  So for
       backward compatibility if nothing else, it has to be 4.  Fixed
       back to 4 in 1.18.
    */
    c_countargs("chgat", items, 4);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int n   = (int)SvIV(ST(c_arg));
    attr_t  attrs   = (attr_t)SvIV(ST(c_arg+1));
    short   color   = (short)SvIV(ST(c_arg+2));
    void *  opts    = 0;
    int ret = c_mret == ERR ? ERR : wchgat(win, n, attrs, color, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("chgat");
    XSRETURN(0);
#endif
}

XS(XS_Curses_COLOR_PAIR)
{
    dXSARGS;
#ifdef C_COLOR_PAIR
    c_exactargs("COLOR_PAIR", items, 1);
    {
    int n   = (int)SvIV(ST(0));
    int ret = COLOR_PAIR(n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("COLOR_PAIR");
    XSRETURN(0);
#endif
}

XS(XS_Curses_PAIR_NUMBER)
{
    dXSARGS;
#ifdef C_PAIR_NUMBER
    c_exactargs("PAIR_NUMBER", items, 1);
    {
    int attrs   = (int)SvIV(ST(0));
    int ret = PAIR_NUMBER(attrs);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("PAIR_NUMBER");
    XSRETURN(0);
#endif
}


/* curs_beep */

XS(XS_Curses_beep)
{
    dXSARGS;
#ifdef C_BEEP
    c_exactargs("beep", items, 0);
    {
    int ret = beep();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("beep");
    XSRETURN(0);
#endif
}

XS(XS_Curses_flash)
{
    dXSARGS;
#ifdef C_FLASH
    c_exactargs("flash", items, 0);
    {
    int ret = flash();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("flash");
    XSRETURN(0);
#endif
}


/* curs_bkgd */

XS(XS_Curses_bkgd)
{
    dXSARGS;
#ifdef C_BKGD
    c_countargs("bkgd", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ch  = c_sv2chtype(ST(c_arg));
    int ret = c_mret == ERR ? ERR : wbkgd(win, ch);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("bkgd");
    XSRETURN(0);
#endif
}

XS(XS_Curses_bkgdset)
{
    dXSARGS;
#ifdef C_BKGDSET
    c_countargs("bkgdset", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ch  = c_sv2chtype(ST(c_arg));
    
    if (c_mret == OK) { wbkgdset(win, ch); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("bkgdset");
    XSRETURN(0);
#endif
}

XS(XS_Curses_getbkgd)
{
    dXSARGS;
#ifdef C_GETBKGD
    c_countargs("getbkgd", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ret = c_mret == ERR ? ERR : getbkgd(win);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getbkgd");
    XSRETURN(0);
#endif
}


/* curs_border */

XS(XS_Curses_border)
{
    dXSARGS;
#ifdef C_BORDER
    c_countargs("border", items, 8);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ls  = c_sv2chtype(ST(c_arg));
    chtype  rs_ = c_sv2chtype(ST(c_arg+1));
    chtype  ts  = c_sv2chtype(ST(c_arg+2));
    chtype  bs  = c_sv2chtype(ST(c_arg+3));
    chtype  tl  = c_sv2chtype(ST(c_arg+4));
    chtype  tr  = c_sv2chtype(ST(c_arg+5));
    chtype  bl  = c_sv2chtype(ST(c_arg+6));
    chtype  br  = c_sv2chtype(ST(c_arg+7));
    int ret = c_mret == ERR ? ERR : wborder(win, ls, rs_, ts, bs, tl, tr, bl, br);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("border");
    XSRETURN(0);
#endif
}

XS(XS_Curses_box)
{
    dXSARGS;
#ifdef C_BOX
    c_countargs("box", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  verch   = c_sv2chtype(ST(c_arg));
    chtype  horch   = c_sv2chtype(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : box(win, verch, horch);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("box");
    XSRETURN(0);
#endif
}

XS(XS_Curses_hline)
{
    dXSARGS;
#ifdef C_HLINE
    c_countargs("hline", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ch  = c_sv2chtype(ST(c_arg));
    int n   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : whline(win, ch, n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("hline");
    XSRETURN(0);
#endif
}

XS(XS_Curses_vline)
{
    dXSARGS;
#ifdef C_VLINE
    c_countargs("vline", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ch  = c_sv2chtype(ST(c_arg));
    int n   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : wvline(win, ch, n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("vline");
    XSRETURN(0);
#endif
}


/* curs_clear */

XS(XS_Curses_erase)
{
    dXSARGS;
#ifdef C_ERASE
    c_countargs("erase", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : werase(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("erase");
    XSRETURN(0);
#endif
}

XS(XS_Curses_clear)
{
    dXSARGS;
#ifdef C_CLEAR
    c_countargs("clear", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : wclear(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("clear");
    XSRETURN(0);
#endif
}

XS(XS_Curses_clrtobot)
{
    dXSARGS;
#ifdef C_CLRTOBOT
    c_countargs("clrtobot", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : wclrtobot(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("clrtobot");
    XSRETURN(0);
#endif
}

XS(XS_Curses_clrtoeol)
{
    dXSARGS;
#ifdef C_CLRTOEOL
    c_countargs("clrtoeol", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : wclrtoeol(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("clrtoeol");
    XSRETURN(0);
#endif
}


/* curs_color */

XS(XS_Curses_start_color)
{
    dXSARGS;
#ifdef C_START_COLOR
    c_exactargs("start_color", items, 0);
    {
    int ret = start_color();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("start_color");
    XSRETURN(0);
#endif
}

XS(XS_Curses_init_pair)
{
    dXSARGS;
#ifdef C_INIT_PAIR
    c_exactargs("init_pair", items, 3);
    {
    short   pair    = (short)SvIV(ST(0));
    short   f   = (short)SvIV(ST(1));
    short   b   = (short)SvIV(ST(2));
    int ret = init_pair(pair, f, b);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("init_pair");
    XSRETURN(0);
#endif
}

XS(XS_Curses_init_color)
{
    dXSARGS;
#ifdef C_INIT_COLOR
    c_exactargs("init_color", items, 4);
    {
    short   color   = (short)SvIV(ST(0));
    short   r   = (short)SvIV(ST(1));
    short   g   = (short)SvIV(ST(2));
    short   b   = (short)SvIV(ST(3));
    int ret = init_color(color, r, g, b);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("init_color");
    XSRETURN(0);
#endif
}

XS(XS_Curses_has_colors)
{
    dXSARGS;
#ifdef C_HAS_COLORS
    c_exactargs("has_colors", items, 0);
    {
    bool    ret = has_colors();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("has_colors");
    XSRETURN(0);
#endif
}

XS(XS_Curses_can_change_color)
{
    dXSARGS;
#ifdef C_CAN_CHANGE_COLOR
    c_exactargs("can_change_color", items, 0);
    {
    bool    ret = can_change_color();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("can_change_color");
    XSRETURN(0);
#endif
}

XS(XS_Curses_color_content)
{
    dXSARGS;
#ifdef C_COLOR_CONTENT
    c_exactargs("color_content", items, 4);
    {
    short   color   = (short)SvIV(ST(0));
    short   r   = 0;
    short   g   = 0;
    short   b   = 0;
    int ret = color_content(color, &r, &g, &b);
    
    sv_setiv(ST(1), (IV)r);;
    sv_setiv(ST(2), (IV)g);;
    sv_setiv(ST(3), (IV)b);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("color_content");
    XSRETURN(0);
#endif
}

XS(XS_Curses_pair_content)
{
    dXSARGS;
#ifdef C_PAIR_CONTENT
    c_exactargs("pair_content", items, 3);
    {
    short   pair    = (short)SvIV(ST(0));
    short   f   = 0;
    short   b   = 0;
    int ret = pair_content(pair, &f, &b);
    
    sv_setiv(ST(1), (IV)f);;
    sv_setiv(ST(2), (IV)b);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("pair_content");
    XSRETURN(0);
#endif
}


/* curs_delch */

XS(XS_Curses_delch)
{
    dXSARGS;
#ifdef C_DELCH
    c_countargs("delch", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : wdelch(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("delch");
    XSRETURN(0);
#endif
}


/* curs_deleteln */

XS(XS_Curses_deleteln)
{
    dXSARGS;
#ifdef C_DELETELN
    c_countargs("deleteln", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : wdeleteln(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("deleteln");
    XSRETURN(0);
#endif
}

XS(XS_Curses_insdelln)
{
    dXSARGS;
#ifdef C_INSDELLN
    c_countargs("insdelln", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int n   = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : winsdelln(win, n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("insdelln");
    XSRETURN(0);
#endif
}

XS(XS_Curses_insertln)
{
    dXSARGS;
#ifdef C_INSERTLN
    c_countargs("insertln", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : winsertln(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("insertln");
    XSRETURN(0);
#endif
}


/* curs_getch */

XS(XS_Curses_getch)
{
    dXSARGS;
#ifdef C_GETCH
    c_countargs("getch", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ret = c_mret == ERR ? ERR : wgetch(win);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getch");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ungetch)
{
    dXSARGS;
#ifdef C_UNGETCH
    c_exactargs("ungetch", items, 1);
    {
    chtype  ch  = c_sv2chtype(ST(0));
    int ret = ungetch(ch);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("ungetch");
    XSRETURN(0);
#endif
}

XS(XS_Curses_has_key)
{
    dXSARGS;
#ifdef C_HAS_KEY
    c_exactargs("has_key", items, 1);
    {
    int ch  = (int)SvIV(ST(0));
    int ret = has_key(ch);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("has_key");
    XSRETURN(0);
#endif
}

XS(XS_Curses_KEY_F)
{
    dXSARGS;
#ifdef C_KEY_F
    c_exactargs("KEY_F", items, 1);
    {
    int n   = (int)SvIV(ST(0));
    chtype  ret = KEY_F(n);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("KEY_F");
    XSRETURN(0);
#endif
}


/* curs_getstr */

XS(XS_Curses_getstr)
{
    dXSARGS;
#ifdef C_GETSTR
    c_countargs("getstr", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    char *  str = (char *)sv_grow(ST(c_arg), 250);
    int ret = c_mret == ERR ? ERR : wgetstr(win, str);
    
    c_setchar(ST(c_arg), str);
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getstr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_getnstr)
{
    dXSARGS;
#ifdef C_GETNSTR
    c_countargs("getnstr", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int n   = (int)SvIV(ST(c_arg+1));
    char *  str = (char *)sv_grow(ST(c_arg), n+1);
    int ret = c_mret == ERR ? ERR : wgetnstr(win, str, n);
    
    c_setchar(ST(c_arg), str);
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getnstr");
    XSRETURN(0);
#endif
}


/* curs_getyx */

XS(XS_Curses_getyx)
{
    dXSARGS;
#ifdef C_GETYX
    c_countargs("getyx", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = 0;
    int x   = 0;
    
    if (c_mret == OK) { getyx(win, y, x); }
    sv_setiv(ST(c_arg), (IV)y);;
    sv_setiv(ST(c_arg+1), (IV)x);;
    }
    XSRETURN(0);
#else
    c_fun_not_there("getyx");
    XSRETURN(0);
#endif
}

XS(XS_Curses_getparyx)
{
    dXSARGS;
#ifdef C_GETPARYX
    c_countargs("getparyx", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = 0;
    int x   = 0;
    
    if (c_mret == OK) { getparyx(win, y, x); }
    sv_setiv(ST(c_arg), (IV)y);;
    sv_setiv(ST(c_arg+1), (IV)x);;
    }
    XSRETURN(0);
#else
    c_fun_not_there("getparyx");
    XSRETURN(0);
#endif
}

XS(XS_Curses_getbegyx)
{
    dXSARGS;
#ifdef C_GETBEGYX
    c_countargs("getbegyx", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = 0;
    int x   = 0;
    
    if (c_mret == OK) { getbegyx(win, y, x); }
    sv_setiv(ST(c_arg), (IV)y);;
    sv_setiv(ST(c_arg+1), (IV)x);;
    }
    XSRETURN(0);
#else
    c_fun_not_there("getbegyx");
    XSRETURN(0);
#endif
}

XS(XS_Curses_getmaxyx)
{
    dXSARGS;
#ifdef C_GETMAXYX
    c_countargs("getmaxyx", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = 0;
    int x   = 0;
    
    if (c_mret == OK) { getmaxyx(win, y, x); }
    sv_setiv(ST(c_arg), (IV)y);;
    sv_setiv(ST(c_arg+1), (IV)x);;
    }
    XSRETURN(0);
#else
    c_fun_not_there("getmaxyx");
    XSRETURN(0);
#endif
}


/* curs_inch */

XS(XS_Curses_inch)
{
    dXSARGS;
#ifdef C_INCH
    c_countargs("inch", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ret = c_mret == ERR ? ERR : winch(win);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("inch");
    XSRETURN(0);
#endif
}


/* curs_inchstr */

XS(XS_Curses_inchstr)
{
    dXSARGS;
#ifdef C_INCHSTR
    c_countargs("inchstr", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype *str = (chtype *)sv_grow(ST(c_arg), (250)*sizeof(chtype));
    int ret = c_mret == ERR ? ERR : winchstr(win, str);
    
    c_setchtype(ST(c_arg), str);
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("inchstr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_inchnstr)
{
    dXSARGS;
#ifdef C_INCHNSTR
    c_countargs("inchnstr", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int n   = (int)SvIV(ST(c_arg+1));
    chtype *str = (chtype *)sv_grow(ST(c_arg), (n+1)*sizeof(chtype));
    int ret = c_mret == ERR ? ERR : winchnstr(win, str, n);
    
    c_setchtype(ST(c_arg), str);
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("inchnstr");
    XSRETURN(0);
#endif
}


/* curs_initscr */

XS(XS_Curses_initscr)
{
    dXSARGS;
#ifdef C_INITSCR
    c_exactargs("initscr", items, 0);
    {
    WINDOW *    ret = initscr();
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("initscr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_endwin)
{
    dXSARGS;
#ifdef C_ENDWIN
    c_exactargs("endwin", items, 0);
    {
    int ret = endwin();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("endwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_isendwin)
{
    dXSARGS;
#ifdef C_ISENDWIN
    c_exactargs("isendwin", items, 0);
    {
    int ret = isendwin();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("isendwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_newterm)
{
    dXSARGS;
#ifdef C_NEWTERM
    c_exactargs("newterm", items, 3);
    {
    char *  type    = ST(0) != &PL_sv_undef ? (char *)SvPV_nolen(ST(0)) : NULL;

    /* IoIFP() returns a FILE * with some Perl cores, and PerlIo with
       others.  We need FILE *.  PerlIO_findFILE() takes either a FILE * or
       PerlIo as input and returns a FILE *.
    */
    FILE *  outfd   = PerlIO_findFILE(IoIFP(sv_2io(ST(1))));
    FILE *  infd    = PerlIO_findFILE(IoIFP(sv_2io(ST(2))));
    SCREEN *    ret = newterm(type, outfd, infd);
    
    ST(0) = sv_newmortal();
    c_screen2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("newterm");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_term)
{
    dXSARGS;
#ifdef C_SET_TERM
    c_exactargs("set_term", items, 1);
    {
    SCREEN *new = c_sv2screen(ST(0), 0);
    SCREEN *    ret = set_term(new);
    
    ST(0) = sv_newmortal();
    c_screen2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_term");
    XSRETURN(0);
#endif
}

XS(XS_Curses_delscreen)
{
    dXSARGS;
#ifdef C_DELSCREEN
    c_exactargs("delscreen", items, 1);
    {
    SCREEN *sp  = c_sv2screen(ST(0), 0);
    
    delscreen(sp);
    }
    XSRETURN(0);
#else
    c_fun_not_there("delscreen");
    XSRETURN(0);
#endif
}


/* curs_inopts */

#ifdef C_INTCBREAK
XS(XS_Curses_cbreak)
{
    dXSARGS;
#ifdef C_CBREAK
    c_exactargs("cbreak", items, 0);
    {
    int ret = cbreak();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("cbreak");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_cbreak)
{
    dXSARGS;
#ifdef C_CBREAK
    c_exactargs("cbreak", items, 0);
    {
    cbreak();
    }
    XSRETURN(0);
#else
    c_fun_not_there("cbreak");
    XSRETURN(0);
#endif
}

#endif
#ifdef C_INTNOCBREAK
XS(XS_Curses_nocbreak)
{
    dXSARGS;
#ifdef C_NOCBREAK
    c_exactargs("nocbreak", items, 0);
    {
    int ret = nocbreak();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("nocbreak");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_nocbreak)
{
    dXSARGS;
#ifdef C_NOCBREAK
    c_exactargs("nocbreak", items, 0);
    {
    nocbreak();
    }
    XSRETURN(0);
#else
    c_fun_not_there("nocbreak");
    XSRETURN(0);
#endif
}

#endif
#ifdef C_INTECHO
XS(XS_Curses_echo)
{
    dXSARGS;
#ifdef C_ECHO
    c_exactargs("echo", items, 0);
    {
    int ret = echo();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("echo");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_echo)
{
    dXSARGS;
#ifdef C_ECHO
    c_exactargs("echo", items, 0);
    {
    echo();
    }
    XSRETURN(0);
#else
    c_fun_not_there("echo");
    XSRETURN(0);
#endif
}

#endif
#ifdef C_INTNOECHO
XS(XS_Curses_noecho)
{
    dXSARGS;
#ifdef C_NOECHO
    c_exactargs("noecho", items, 0);
    {
    int ret = noecho();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("noecho");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_noecho)
{
    dXSARGS;
#ifdef C_NOECHO
    c_exactargs("noecho", items, 0);
    {
    noecho();
    }
    XSRETURN(0);
#else
    c_fun_not_there("noecho");
    XSRETURN(0);
#endif
}

#endif
XS(XS_Curses_halfdelay)
{
    dXSARGS;
#ifdef C_HALFDELAY
    c_exactargs("halfdelay", items, 1);
    {
    int tenths  = (int)SvIV(ST(0));
    int ret = halfdelay(tenths);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("halfdelay");
    XSRETURN(0);
#endif
}

XS(XS_Curses_intrflush)
{
    dXSARGS;
#ifdef C_INTRFLUSH
    c_countargs("intrflush", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : intrflush(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("intrflush");
    XSRETURN(0);
#endif
}

XS(XS_Curses_keypad)
{
    dXSARGS;
#ifdef C_KEYPAD
    c_countargs("keypad", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : keypad(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("keypad");
    XSRETURN(0);
#endif
}

XS(XS_Curses_meta)
{
    dXSARGS;
#ifdef C_META
    c_countargs("meta", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : meta(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("meta");
    XSRETURN(0);
#endif
}

XS(XS_Curses_nodelay)
{
    dXSARGS;
#ifdef C_NODELAY
    c_countargs("nodelay", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : nodelay(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("nodelay");
    XSRETURN(0);
#endif
}

XS(XS_Curses_notimeout)
{
    dXSARGS;
#ifdef C_NOTIMEOUT
    c_countargs("notimeout", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : notimeout(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("notimeout");
    XSRETURN(0);
#endif
}

#ifdef C_INTRAW
XS(XS_Curses_raw)
{
    dXSARGS;
#ifdef C_RAW
    c_exactargs("raw", items, 0);
    {
    int ret = raw();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("raw");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_raw)
{
    dXSARGS;
#ifdef C_RAW
    c_exactargs("raw", items, 0);
    {
    raw();
    }
    XSRETURN(0);
#else
    c_fun_not_there("raw");
    XSRETURN(0);
#endif
}

#endif
#ifdef C_INTNORAW
XS(XS_Curses_noraw)
{
    dXSARGS;
#ifdef C_NORAW
    c_exactargs("noraw", items, 0);
    {
    int ret = noraw();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("noraw");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_noraw)
{
    dXSARGS;
#ifdef C_NORAW
    c_exactargs("noraw", items, 0);
    {
    noraw();
    }
    XSRETURN(0);
#else
    c_fun_not_there("noraw");
    XSRETURN(0);
#endif
}

#endif
XS(XS_Curses_qiflush)
{
    dXSARGS;
#ifdef C_QIFLUSH
    c_exactargs("qiflush", items, 0);
    {
    qiflush();
    }
    XSRETURN(0);
#else
    c_fun_not_there("qiflush");
    XSRETURN(0);
#endif
}

XS(XS_Curses_noqiflush)
{
    dXSARGS;
#ifdef C_NOQIFLUSH
    c_exactargs("noqiflush", items, 0);
    {
    noqiflush();
    }
    XSRETURN(0);
#else
    c_fun_not_there("noqiflush");
    XSRETURN(0);
#endif
}

XS(XS_Curses_timeout)
{
    dXSARGS;
#ifdef C_TIMEOUT
    c_countargs("timeout", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int delay   = (int)SvIV(ST(c_arg));
    
    if (c_mret == OK) { wtimeout(win, delay); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("timeout");
    XSRETURN(0);
#endif
}

XS(XS_Curses_typeahead)
{
    dXSARGS;
#ifdef C_TYPEAHEAD
    c_exactargs("typeahead", items, 1);
    {
    int fd  = (int)SvIV(ST(0));
    int ret = typeahead(fd);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("typeahead");
    XSRETURN(0);
#endif
}


/* curs_insch */

XS(XS_Curses_insch)
{
    dXSARGS;
#ifdef C_INSCH
    c_countargs("insch", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    chtype  ch  = c_sv2chtype(ST(c_arg));
    int ret = c_mret == ERR ? ERR : winsch(win, ch);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("insch");
    XSRETURN(0);
#endif
}


/* curs_insstr */

XS(XS_Curses_insstr)
{
    dXSARGS;
#ifdef C_INSSTR
    c_countargs("insstr", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    char *  str = (char *)SvPV_nolen(ST(c_arg));
    int ret = c_mret == ERR ? ERR : winsstr(win, str);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("insstr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_insnstr)
{
    dXSARGS;
#ifdef C_INSNSTR
    c_countargs("insnstr", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    char *  str = (char *)SvPV_nolen(ST(c_arg));
    int n   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : winsnstr(win, str, n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("insnstr");
    XSRETURN(0);
#endif
}


/* curs_instr */

XS(XS_Curses_instr)
{
    dXSARGS;
#ifdef C_INSTR
    c_countargs("instr", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    char *  str = (char *)sv_grow(ST(c_arg), 250);
    int ret = c_mret == ERR ? ERR : winstr(win, str);
    
    c_setchar(ST(c_arg), str);
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("instr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_innstr)
{
    dXSARGS;
#ifdef C_INNSTR
    c_countargs("innstr", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int n   = (int)SvIV(ST(c_arg+1));
    char *  str = (char *)sv_grow(ST(c_arg), n+1);
    int ret = c_mret == ERR ? ERR : winnstr(win, str, n);
    
    c_setchar(ST(c_arg), str);
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("innstr");
    XSRETURN(0);
#endif
}


/* curs_kernel */

XS(XS_Curses_def_prog_mode)
{
    dXSARGS;
#ifdef C_DEF_PROG_MODE
    c_exactargs("def_prog_mode", items, 0);
    {
    int ret = def_prog_mode();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("def_prog_mode");
    XSRETURN(0);
#endif
}

XS(XS_Curses_def_shell_mode)
{
    dXSARGS;
#ifdef C_DEF_SHELL_MODE
    c_exactargs("def_shell_mode", items, 0);
    {
    int ret = def_shell_mode();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("def_shell_mode");
    XSRETURN(0);
#endif
}

XS(XS_Curses_reset_prog_mode)
{
    dXSARGS;
#ifdef C_RESET_PROG_MODE
    c_exactargs("reset_prog_mode", items, 0);
    {
    int ret = reset_prog_mode();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("reset_prog_mode");
    XSRETURN(0);
#endif
}

XS(XS_Curses_reset_shell_mode)
{
    dXSARGS;
#ifdef C_RESET_SHELL_MODE
    c_exactargs("reset_shell_mode", items, 0);
    {
    int ret = reset_shell_mode();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("reset_shell_mode");
    XSRETURN(0);
#endif
}

XS(XS_Curses_resetty)
{
    dXSARGS;
#ifdef C_RESETTY
    c_exactargs("resetty", items, 0);
    {
    int ret = resetty();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("resetty");
    XSRETURN(0);
#endif
}

XS(XS_Curses_savetty)
{
    dXSARGS;
#ifdef C_SAVETTY
    c_exactargs("savetty", items, 0);
    {
    int ret = savetty();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("savetty");
    XSRETURN(0);
#endif
}

#ifdef C_INTGETSYX
XS(XS_Curses_getsyx)
{
    dXSARGS;
#ifdef C_GETSYX
    c_exactargs("getsyx", items, 2);
    {
    int y   = 0;
    int x   = 0;
    int ret = getsyx(y, x);
    
    sv_setiv(ST(0), (IV)y);;
    sv_setiv(ST(1), (IV)x);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getsyx");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_getsyx)
{
    dXSARGS;
#ifdef C_GETSYX
    c_exactargs("getsyx", items, 2);
    {
    int y   = 0;
    int x   = 0;
    
    getsyx(y, x);
    sv_setiv(ST(0), (IV)y);;
    sv_setiv(ST(1), (IV)x);;
    }
    XSRETURN(0);
#else
    c_fun_not_there("getsyx");
    XSRETURN(0);
#endif
}

#endif
#ifdef C_INTSETSYX
XS(XS_Curses_setsyx)
{
    dXSARGS;
#ifdef C_SETSYX
    c_exactargs("setsyx", items, 2);
    {
    int y   = (int)SvIV(ST(0));
    int x   = (int)SvIV(ST(1));
    int ret = setsyx(y, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("setsyx");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_setsyx)
{
    dXSARGS;
#ifdef C_SETSYX
    c_exactargs("setsyx", items, 2);
    {
    int y   = (int)SvIV(ST(0));
    int x   = (int)SvIV(ST(1));
    
    setsyx(y, x);
    }
    XSRETURN(0);
#else
    c_fun_not_there("setsyx");
    XSRETURN(0);
#endif
}

#endif
XS(XS_Curses_curs_set)
{
    dXSARGS;
#ifdef C_CURS_SET
    c_exactargs("curs_set", items, 1);
    {
    int visibility  = (int)SvIV(ST(0));
    int ret = curs_set(visibility);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("curs_set");
    XSRETURN(0);
#endif
}

XS(XS_Curses_napms)
{
    dXSARGS;
#ifdef C_NAPMS
    c_exactargs("napms", items, 1);
    {
    int ms  = (int)SvIV(ST(0));
    int ret = napms(ms);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("napms");
    XSRETURN(0);
#endif
}


/* curs_move */

XS(XS_Curses_move)
{
    dXSARGS;
#ifdef C_MOVE
    c_countargs("move", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = (int)SvIV(ST(c_arg));
    int x   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : wmove(win, y, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("move");
    XSRETURN(0);
#endif
}


/* curs_outopts */

XS(XS_Curses_clearok)
{
    dXSARGS;
#ifdef C_CLEAROK
    c_countargs("clearok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : clearok(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("clearok");
    XSRETURN(0);
#endif
}

#ifdef C_INTIDLOK
XS(XS_Curses_idlok)
{
    dXSARGS;
#ifdef C_IDLOK
    c_countargs("idlok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : idlok(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("idlok");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_idlok)
{
    dXSARGS;
#ifdef C_IDLOK
    c_countargs("idlok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    
    if (c_mret == OK) { idlok(win, bf); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("idlok");
    XSRETURN(0);
#endif
}

#endif
XS(XS_Curses_idcok)
{
    dXSARGS;
#ifdef C_IDCOK
    c_countargs("idcok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    
    if (c_mret == OK) { idcok(win, bf); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("idcok");
    XSRETURN(0);
#endif
}

XS(XS_Curses_immedok)
{
    dXSARGS;
#ifdef C_IMMEDOK
    c_countargs("immedok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    
    if (c_mret == OK) { immedok(win, bf); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("immedok");
    XSRETURN(0);
#endif
}

XS(XS_Curses_leaveok)
{
    dXSARGS;
#ifdef C_LEAVEOK
    c_countargs("leaveok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : leaveok(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("leaveok");
    XSRETURN(0);
#endif
}

XS(XS_Curses_setscrreg)
{
    dXSARGS;
#ifdef C_SETSCRREG
    c_countargs("setscrreg", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int top = (int)SvIV(ST(c_arg));
    int bot = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : wsetscrreg(win, top, bot);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("setscrreg");
    XSRETURN(0);
#endif
}

XS(XS_Curses_scrollok)
{
    dXSARGS;
#ifdef C_SCROLLOK
    c_countargs("scrollok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : scrollok(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scrollok");
    XSRETURN(0);
#endif
}

#ifdef C_INTNL
XS(XS_Curses_nl)
{
    dXSARGS;
#ifdef C_NL
    c_exactargs("nl", items, 0);
    {
    int ret = nl();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("nl");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_nl)
{
    dXSARGS;
#ifdef C_NL
    c_exactargs("nl", items, 0);
    {
    nl();
    }
    XSRETURN(0);
#else
    c_fun_not_there("nl");
    XSRETURN(0);
#endif
}

#endif
#ifdef C_INTNONL
XS(XS_Curses_nonl)
{
    dXSARGS;
#ifdef C_NONL
    c_exactargs("nonl", items, 0);
    {
    int ret = nonl();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("nonl");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_nonl)
{
    dXSARGS;
#ifdef C_NONL
    c_exactargs("nonl", items, 0);
    {
    nonl();
    }
    XSRETURN(0);
#else
    c_fun_not_there("nonl");
    XSRETURN(0);
#endif
}

#endif

/* curs_overlay */

XS(XS_Curses_overlay)
{
    dXSARGS;
#ifdef C_OVERLAY
    c_exactargs("overlay", items, 2);
    {
    WINDOW *srcwin  = c_sv2window(ST(0), 0);
    WINDOW *dstwin  = c_sv2window(ST(1), 1);
    int ret = overlay(srcwin, dstwin);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("overlay");
    XSRETURN(0);
#endif
}

XS(XS_Curses_overwrite)
{
    dXSARGS;
#ifdef C_OVERWRITE
    c_exactargs("overwrite", items, 2);
    {
    WINDOW *srcwin  = c_sv2window(ST(0), 0);
    WINDOW *dstwin  = c_sv2window(ST(1), 1);
    int ret = overwrite(srcwin, dstwin);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("overwrite");
    XSRETURN(0);
#endif
}

XS(XS_Curses_copywin)
{
    dXSARGS;
#ifdef C_COPYWIN
    c_exactargs("copywin", items, 9);
    {
    WINDOW *srcwin  = c_sv2window(ST(0), 0);
    WINDOW *dstwin  = c_sv2window(ST(1), 1);
    int sminrow = (int)SvIV(ST(2));
    int smincol = (int)SvIV(ST(3));
    int dminrow = (int)SvIV(ST(4));
    int dmincol = (int)SvIV(ST(5));
    int dmaxrow = (int)SvIV(ST(6));
    int dmaxcol = (int)SvIV(ST(7));
    int overlay = (int)SvIV(ST(8));
    int ret = copywin(srcwin, dstwin, sminrow, smincol, dminrow, dmincol, dmaxrow, dmaxcol, overlay);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("copywin");
    XSRETURN(0);
#endif
}


/* curs_pad */

XS(XS_Curses_newpad)
{
    dXSARGS;
#ifdef C_NEWPAD
    c_exactargs("newpad", items, 2);
    {
    int lines_  = (int)SvIV(ST(0));
    int cols    = (int)SvIV(ST(1));
    WINDOW *    ret = newpad(lines_, cols);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("newpad");
    XSRETURN(0);
#endif
}

XS(XS_Curses_subpad)
{
    dXSARGS;
#ifdef C_SUBPAD
    c_exactargs("subpad", items, 5);
    {
    WINDOW *orig    = c_sv2window(ST(0), 0);
    int lines_  = (int)SvIV(ST(1));
    int cols    = (int)SvIV(ST(2));
    int beginy  = (int)SvIV(ST(3));
    int beginx  = (int)SvIV(ST(4));
    WINDOW *    ret = subpad(orig, lines_, cols, beginy, beginx);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("subpad");
    XSRETURN(0);
#endif
}

XS(XS_Curses_prefresh)
{
    dXSARGS;
#ifdef C_PREFRESH
    c_exactargs("prefresh", items, 7);
    {
    WINDOW *pad = c_sv2window(ST(0), 0);
    int pminrow = (int)SvIV(ST(1));
    int pmincol = (int)SvIV(ST(2));
    int sminrow = (int)SvIV(ST(3));
    int smincol = (int)SvIV(ST(4));
    int smaxrow = (int)SvIV(ST(5));
    int smaxcol = (int)SvIV(ST(6));
    int ret = prefresh(pad, pminrow, pmincol, sminrow, smincol, smaxrow, smaxcol);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("prefresh");
    XSRETURN(0);
#endif
}

XS(XS_Curses_pnoutrefresh)
{
    dXSARGS;
#ifdef C_PNOUTREFRESH
    c_exactargs("pnoutrefresh", items, 7);
    {
    WINDOW *pad = c_sv2window(ST(0), 0);
    int pminrow = (int)SvIV(ST(1));
    int pmincol = (int)SvIV(ST(2));
    int sminrow = (int)SvIV(ST(3));
    int smincol = (int)SvIV(ST(4));
    int smaxrow = (int)SvIV(ST(5));
    int smaxcol = (int)SvIV(ST(6));
    int ret = pnoutrefresh(pad, pminrow, pmincol, sminrow, smincol, smaxrow, smaxcol);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("pnoutrefresh");
    XSRETURN(0);
#endif
}

XS(XS_Curses_pechochar)
{
    dXSARGS;
#ifdef C_PECHOCHAR
    c_exactargs("pechochar", items, 2);
    {
    WINDOW *pad = c_sv2window(ST(0), 0);
    chtype  ch  = c_sv2chtype(ST(1));
    int ret = pechochar(pad, ch);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("pechochar");
    XSRETURN(0);
#endif
}


/* curs_printw */

/* done in perl */

/* curs_refresh */

XS(XS_Curses_refresh)
{
    dXSARGS;
#ifdef C_REFRESH
    c_countargs("refresh", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : wrefresh(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("refresh");
    XSRETURN(0);
#endif
}

XS(XS_Curses_noutrefresh)
{
    dXSARGS;
#ifdef C_NOUTREFRESH
    c_countargs("noutrefresh", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : wnoutrefresh(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("noutrefresh");
    XSRETURN(0);
#endif
}

XS(XS_Curses_doupdate)
{
    dXSARGS;
#ifdef C_DOUPDATE
    c_exactargs("doupdate", items, 0);
    {
    int ret = doupdate();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("doupdate");
    XSRETURN(0);
#endif
}

XS(XS_Curses_redrawwin)
{
    dXSARGS;
#ifdef C_REDRAWWIN
    c_countargs("redrawwin", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : redrawwin(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("redrawwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_redrawln)
{
    dXSARGS;
#ifdef C_REDRAWLN
    c_countargs("redrawln", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int beg_line    = (int)SvIV(ST(c_arg));
    int num_lines   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : wredrawln(win, beg_line, num_lines);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("redrawln");
    XSRETURN(0);
#endif
}


/* curs_scanw */

/* done in perl */

/* curs_scr_dump */

XS(XS_Curses_scr_dump)
{
    dXSARGS;
#ifdef C_SCR_DUMP
    c_exactargs("scr_dump", items, 1);
    {
    char *  filename    = (char *)SvPV_nolen(ST(0));
    int ret = scr_dump(filename);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scr_dump");
    XSRETURN(0);
#endif
}

XS(XS_Curses_scr_restore)
{
    dXSARGS;
#ifdef C_SCR_RESTORE
    c_exactargs("scr_restore", items, 1);
    {
    char *  filename    = (char *)SvPV_nolen(ST(0));
    int ret = scr_restore(filename);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scr_restore");
    XSRETURN(0);
#endif
}

XS(XS_Curses_scr_init)
{
    dXSARGS;
#ifdef C_SCR_INIT
    c_exactargs("scr_init", items, 1);
    {
    char *  filename    = (char *)SvPV_nolen(ST(0));
    int ret = scr_init(filename);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scr_init");
    XSRETURN(0);
#endif
}

XS(XS_Curses_scr_set)
{
    dXSARGS;
#ifdef C_SCR_SET
    c_exactargs("scr_set", items, 1);
    {
    char *  filename    = (char *)SvPV_nolen(ST(0));
    int ret = scr_set(filename);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scr_set");
    XSRETURN(0);
#endif
}


/* curs_scroll */

XS(XS_Curses_scroll)
{
    dXSARGS;
#ifdef C_SCROLL
    c_countargs("scroll", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : scroll(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scroll");
    XSRETURN(0);
#endif
}

XS(XS_Curses_scrl)
{
    dXSARGS;
#ifdef C_SCRL
    c_countargs("scrl", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int n   = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : wscrl(win, n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scrl");
    XSRETURN(0);
#endif
}


/* curs_slk */

XS(XS_Curses_slk_init)
{
    dXSARGS;
#ifdef C_SLK_INIT
    c_exactargs("slk_init", items, 1);
    {
    int fmt = (int)SvIV(ST(0));
    int ret = slk_init(fmt);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_init");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_set)
{
    dXSARGS;
#ifdef C_SLK_SET
    c_exactargs("slk_set", items, 3);
    {
    int labnum  = (int)SvIV(ST(0));
    char *  label   = (char *)SvPV_nolen(ST(1));
    int fmt = (int)SvIV(ST(2));
    int ret = slk_set(labnum, label, fmt);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_set");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_refresh)
{
    dXSARGS;
#ifdef C_SLK_REFRESH
    c_exactargs("slk_refresh", items, 0);
    {
    int ret = slk_refresh();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_refresh");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_noutrefresh)
{
    dXSARGS;
#ifdef C_SLK_NOUTREFRESH
    c_exactargs("slk_noutrefresh", items, 0);
    {
    int ret = slk_noutrefresh();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_noutrefresh");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_label)
{
    dXSARGS;
#ifdef C_SLK_LABEL
    c_exactargs("slk_label", items, 1);
    {
    int labnum  = (int)SvIV(ST(0));
    char *  ret = slk_label(labnum);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_label");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_clear)
{
    dXSARGS;
#ifdef C_SLK_CLEAR
    c_exactargs("slk_clear", items, 0);
    {
    int ret = slk_clear();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_clear");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_restore)
{
    dXSARGS;
#ifdef C_SLK_RESTORE
    c_exactargs("slk_restore", items, 0);
    {
    int ret = slk_restore();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_restore");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_touch)
{
    dXSARGS;
#ifdef C_SLK_TOUCH
    c_exactargs("slk_touch", items, 0);
    {
    int ret = slk_touch();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_touch");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_attron)
{
    dXSARGS;
#ifdef C_SLK_ATTRON
    c_exactargs("slk_attron", items, 1);
    {
    chtype  attrs   = c_sv2chtype(ST(0));
    int ret = slk_attron(attrs);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_attron");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_attrset)
{
    dXSARGS;
#ifdef C_SLK_ATTRSET
    c_exactargs("slk_attrset", items, 1);
    {
    chtype  attrs   = c_sv2chtype(ST(0));
    int ret = slk_attrset(attrs);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_attrset");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_attr)
{
    dXSARGS;
#ifdef C_SLK_ATTR
    c_exactargs("slk_attr", items, 0);
    {
    attr_t  ret = slk_attr();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_attr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_attroff)
{
    dXSARGS;
#ifdef C_SLK_ATTROFF
    c_exactargs("slk_attroff", items, 1);
    {
    chtype  attrs   = c_sv2chtype(ST(0));
    int ret = slk_attroff(attrs);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_attroff");
    XSRETURN(0);
#endif
}

XS(XS_Curses_slk_color)
{
    dXSARGS;
#ifdef C_SLK_COLOR
    c_exactargs("slk_color", items, 1);
    {
    short   color_pair_number   = (short)SvIV(ST(0));
    int ret = slk_color(color_pair_number);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("slk_color");
    XSRETURN(0);
#endif
}


/* curs_termattrs */

XS(XS_Curses_baudrate)
{
    dXSARGS;
#ifdef C_BAUDRATE
    c_exactargs("baudrate", items, 0);
    {
    int ret = baudrate();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("baudrate");
    XSRETURN(0);
#endif
}

XS(XS_Curses_erasechar)
{
    dXSARGS;
#ifdef C_ERASECHAR
    c_exactargs("erasechar", items, 0);
    {
    char    ret = erasechar();
    
    ST(0) = sv_newmortal();
    sv_setpvn(ST(0), (char *)&ret, 1);
    }
    XSRETURN(1);
#else
    c_fun_not_there("erasechar");
    XSRETURN(0);
#endif
}

XS(XS_Curses_has_ic)
{
    dXSARGS;
#ifdef C_HAS_IC
    c_exactargs("has_ic", items, 0);
    {
    int ret = has_ic();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("has_ic");
    XSRETURN(0);
#endif
}

XS(XS_Curses_has_il)
{
    dXSARGS;
#ifdef C_HAS_IL
    c_exactargs("has_il", items, 0);
    {
    int ret = has_il();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("has_il");
    XSRETURN(0);
#endif
}

XS(XS_Curses_killchar)
{
    dXSARGS;
#ifdef C_KILLCHAR
    c_exactargs("killchar", items, 0);
    {
    char    ret = killchar();
    
    ST(0) = sv_newmortal();
    sv_setpvn(ST(0), (char *)&ret, 1);
    }
    XSRETURN(1);
#else
    c_fun_not_there("killchar");
    XSRETURN(0);
#endif
}

#ifdef C_LONG0ARGS
XS(XS_Curses_longname)
{
    dXSARGS;
#ifdef C_LONGNAME
    c_exactargs("longname", items, 0);
    {
    char *  ret = longname();
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("longname");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_longname)
{
    dXSARGS;
#ifdef C_LONGNAME
    c_exactargs("longname", items, 2);
    {
    char *  a   = (char *)SvPV_nolen(ST(0));
    char *  b   = (char *)SvPV_nolen(ST(1));
    char *  ret = longname(a, b);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("longname");
    XSRETURN(0);
#endif
}

#endif

XS(XS_Curses_termattrs)
{
    dXSARGS;
#ifdef C_TERMATTRS
    c_exactargs("termattrs", items, 0);
    {
    chtype  ret = termattrs();
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("termattrs");
    XSRETURN(0);
#endif
}

XS(XS_Curses_termname)
{
    dXSARGS;
#ifdef C_TERMNAME
    c_exactargs("termname", items, 0);
    {
    char *  ret = termname();
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("termname");
    XSRETURN(0);
#endif
}


/* curs_touch */

XS(XS_Curses_touchwin)
{
    dXSARGS;
#ifdef C_TOUCHWIN
    c_countargs("touchwin", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : touchwin(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("touchwin");
    XSRETURN(0);
#endif
}

#ifdef C_TOUCH3ARGS
XS(XS_Curses_touchline)
{
    dXSARGS;
#ifdef C_TOUCHLINE
    c_countargs("touchline", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int start   = (int)SvIV(ST(c_arg));
    int count   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : touchline(win, start, count);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("touchline");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_touchline)
{
    dXSARGS;
#ifdef C_TOUCHLINE
    c_countargs("touchline", items, 3);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = (int)SvIV(ST(c_arg));
    int sx  = (int)SvIV(ST(c_arg+1));
    int ex  = (int)SvIV(ST(c_arg+2));
    int ret = c_mret == ERR ? ERR : touchline(win, y, sx, ex);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("touchline");
    XSRETURN(0);
#endif
}

#endif

XS(XS_Curses_untouchwin)
{
    dXSARGS;
#ifdef C_UNTOUCHWIN
    c_countargs("untouchwin", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : untouchwin(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("untouchwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_touchln)
{
    dXSARGS;
#ifdef C_TOUCHLN
    c_countargs("touchln", items, 3);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = (int)SvIV(ST(c_arg));
    int n   = (int)SvIV(ST(c_arg+1));
    int changed = (int)SvIV(ST(c_arg+2));
    int ret = c_mret == ERR ? ERR : wtouchln(win, y, n, changed);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("touchln");
    XSRETURN(0);
#endif
}

XS(XS_Curses_is_linetouched)
{
    dXSARGS;
#ifdef C_IS_LINETOUCHED
    c_countargs("is_linetouched", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int line    = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : is_linetouched(win, line);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("is_linetouched");
    XSRETURN(0);
#endif
}

XS(XS_Curses_is_wintouched)
{
    dXSARGS;
#ifdef C_IS_WINTOUCHED
    c_countargs("is_wintouched", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : is_wintouched(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("is_wintouched");
    XSRETURN(0);
#endif
}


/* curs_util */



XS(XS_Curses_unctrl) {

    dXSARGS;
#ifdef C_UNCTRL
    c_exactargs("unctrl", items, 1);
    {
        chtype const ch = c_sv2chtype(ST(0));
        const char * const ret = unctrl(ch);
    
        ST(0) = sv_newmortal();
        sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("unctrl");
    XSRETURN(0);
#endif
}



XS(XS_Curses_keyname)
{
    dXSARGS;
#ifdef C_KEYNAME
    c_exactargs("keyname", items, 1);
    {
    int k   = (int)SvIV(ST(0));
    char *  ret = (char *)keyname(k);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("keyname");
    XSRETURN(0);
#endif
}

#ifdef C_INTFILTER
XS(XS_Curses_filter)
{
    dXSARGS;
#ifdef C_FILTER
    c_exactargs("filter", items, 0);
    {
    int ret = filter();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("filter");
    XSRETURN(0);
#endif
}

#else
XS(XS_Curses_filter)
{
    dXSARGS;
#ifdef C_FILTER
    c_exactargs("filter", items, 0);
    {
    filter();
    }
    XSRETURN(0);
#else
    c_fun_not_there("filter");
    XSRETURN(0);
#endif
}

#endif
XS(XS_Curses_use_env)
{
    dXSARGS;
#ifdef C_USE_ENV
    c_exactargs("use_env", items, 1);
    {
    bool    bf  = (int)SvIV(ST(0));
    
    use_env(bf);
    }
    XSRETURN(0);
#else
    c_fun_not_there("use_env");
    XSRETURN(0);
#endif
}

XS(XS_Curses_putwin)
{
    dXSARGS;
#ifdef C_PUTWIN
    c_exactargs("putwin", items, 2);
    {
    WINDOW *win = c_sv2window(ST(0), 0);
    /* See explanation of PerlIO_findFILE in newterm() */
    FILE *  filep   = PerlIO_findFILE(IoIFP(sv_2io(ST(1))));
    int ret = putwin(win, filep);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("putwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_getwin)
{
    dXSARGS;
#ifdef C_GETWIN
    c_exactargs("getwin", items, 1);
    {
    /* See explanation of PerlIO_findFILE in newterm() */
    FILE *  filep   = PerlIO_findFILE(IoIFP(sv_2io(ST(0))));
    WINDOW *    ret = getwin(filep);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_delay_output)
{
    dXSARGS;
#ifdef C_DELAY_OUTPUT
    c_exactargs("delay_output", items, 1);
    {
    int ms  = (int)SvIV(ST(0));
    int ret = delay_output(ms);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("delay_output");
    XSRETURN(0);
#endif
}

XS(XS_Curses_flushinp)
{
    dXSARGS;
#ifdef C_FLUSHINP
    c_exactargs("flushinp", items, 0);
    {
    int ret = flushinp();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("flushinp");
    XSRETURN(0);
#endif
}


/* curs_window */

XS(XS_Curses_newwin)
{
    dXSARGS;
#ifdef C_NEWWIN
    c_exactargs("newwin", items, 4);
    {
    int nlines  = (int)SvIV(ST(0));
    int ncols   = (int)SvIV(ST(1));
    int beginy  = (int)SvIV(ST(2));
    int beginx  = (int)SvIV(ST(3));
    WINDOW *    ret = newwin(nlines, ncols, beginy, beginx);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("newwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_delwin)
{
    dXSARGS;
#ifdef C_DELWIN
    c_countargs("delwin", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : delwin(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("delwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_mvwin)
{
    dXSARGS;
#ifdef C_MVWIN
    c_countargs("mvwin", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = (int)SvIV(ST(c_arg));
    int x   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : mvwin(win, y, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("mvwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_subwin)
{
    dXSARGS;
#ifdef C_SUBWIN
    c_countargs("subwin", items, 4);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int nlines  = (int)SvIV(ST(c_arg));
    int ncols   = (int)SvIV(ST(c_arg+1));
    int beginy  = (int)SvIV(ST(c_arg+2));
    int beginx  = (int)SvIV(ST(c_arg+3));
    WINDOW *    ret = c_mret == ERR ? NULL : subwin(win, nlines, ncols, beginy, beginx);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("subwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_derwin)
{
    dXSARGS;
#ifdef C_DERWIN
    c_countargs("derwin", items, 4);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int nlines  = (int)SvIV(ST(c_arg));
    int ncols   = (int)SvIV(ST(c_arg+1));
    int beginy  = (int)SvIV(ST(c_arg+2));
    int beginx  = (int)SvIV(ST(c_arg+3));
    WINDOW *    ret = c_mret == ERR ? NULL : derwin(win, nlines, ncols, beginy, beginx);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("derwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_mvderwin)
{
    dXSARGS;
#ifdef C_MVDERWIN
    c_countargs("mvderwin", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int par_y   = (int)SvIV(ST(c_arg));
    int par_x   = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : mvderwin(win, par_y, par_x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("mvderwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_dupwin)
{
    dXSARGS;
#ifdef C_DUPWIN
    c_countargs("dupwin", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    WINDOW *    ret = c_mret == ERR ? NULL : dupwin(win);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("dupwin");
    XSRETURN(0);
#endif
}

XS(XS_Curses_syncup)
{
    dXSARGS;
#ifdef C_SYNCUP
    c_countargs("syncup", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    
    if (c_mret == OK) { wsyncup(win); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("syncup");
    XSRETURN(0);
#endif
}

XS(XS_Curses_syncok)
{
    dXSARGS;
#ifdef C_SYNCOK
    c_countargs("syncok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    int ret = c_mret == ERR ? ERR : syncok(win, bf);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("syncok");
    XSRETURN(0);
#endif
}

XS(XS_Curses_cursyncup)
{
    dXSARGS;
#ifdef C_CURSYNCUP
    c_countargs("cursyncup", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    
    if (c_mret == OK) { wcursyncup(win); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("cursyncup");
    XSRETURN(0);
#endif
}

XS(XS_Curses_syncdown)
{
    dXSARGS;
#ifdef C_SYNCDOWN
    c_countargs("syncdown", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    
    if (c_mret == OK) { wsyncdown(win); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("syncdown");
    XSRETURN(0);
#endif
}


/* ncurses extension functions */

XS(XS_Curses_getmouse)
{
    dXSARGS;
#ifdef C_GETMOUSE
    c_exactargs("getmouse", items, 1);
    {
    MEVENT *event   = (MEVENT *)sv_grow(ST(0), 2 * sizeof(MEVENT));
    int ret = getmouse(event);
    
    c_setmevent(ST(0));
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getmouse");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ungetmouse)
{
    dXSARGS;
#ifdef C_UNGETMOUSE
    c_exactargs("ungetmouse", items, 1);
    {
    MEVENT *event   = (MEVENT *)SvPV_nolen(ST(0));
    int ret = ungetmouse(event);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("ungetmouse");
    XSRETURN(0);
#endif
}

XS(XS_Curses_mousemask)
{
    dXSARGS;
#ifdef C_MOUSEMASK
    c_exactargs("mousemask", items, 2);
    {
    mmask_t newmask = (mmask_t)SvIV(ST(0));
    mmask_t oldmask = 0;
    mmask_t ret = mousemask(newmask, &oldmask);
    
    sv_setiv(ST(1), (IV)oldmask);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("mousemask");
    XSRETURN(0);
#endif
}

XS(XS_Curses_enclose)
{
    dXSARGS;
#ifdef C_ENCLOSE
    c_countargs("enclose", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int y   = (int)SvIV(ST(c_arg));
    int x   = (int)SvIV(ST(c_arg+1));
    /* We don't have any way to return an error, so if we couldn't move the
       window, we just say the window does not enclose the location.
    */
    bool    ret = c_mret == ERR ? false : wenclose(win, y, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("enclose");
    XSRETURN(0);
#endif
}

XS(XS_Curses_mouse_trafo)
{
    dXSARGS;
#ifdef C_MOUSE_TRAFO
    c_countargs("mouse_trafo", items, 3);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int pY  = 0;
    int pX  = 0;
    bool    to_screen   = (int)SvIV(ST(c_arg+2));
    bool    ret = c_mret == ERR ? false : wmouse_trafo(win, &pY, &pX, to_screen);
    
    sv_setiv(ST(c_arg), (IV)pY);;
    sv_setiv(ST(c_arg+1), (IV)pX);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("mouse_trafo");
    XSRETURN(0);
#endif
}

XS(XS_Curses_mouseinterval)
{
    dXSARGS;
#ifdef C_MOUSEINTERVAL
    c_exactargs("mouseinterval", items, 1);
    {
    int erval   = (int)SvIV(ST(0));
    int ret = mouseinterval(erval);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("mouseinterval");
    XSRETURN(0);
#endif
}

XS(XS_Curses_BUTTON_RELEASE)
{
    dXSARGS;
#ifdef C_BUTTON_RELEASE
    c_exactargs("BUTTON_RELEASE", items, 2);
    {
    mmask_t e   = (mmask_t)SvIV(ST(0));
    int x   = (int)SvIV(ST(1));
    int ret = BUTTON_RELEASE(e, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("BUTTON_RELEASE");
    XSRETURN(0);
#endif
}

XS(XS_Curses_BUTTON_PRESS)
{
    dXSARGS;
#ifdef C_BUTTON_PRESS
    c_exactargs("BUTTON_PRESS", items, 2);
    {
    mmask_t e   = (mmask_t)SvIV(ST(0));
    int x   = (int)SvIV(ST(1));
    int ret = BUTTON_PRESS(e, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("BUTTON_PRESS");
    XSRETURN(0);
#endif
}

XS(XS_Curses_BUTTON_CLICK)
{
    dXSARGS;
#ifdef C_BUTTON_CLICK
    c_exactargs("BUTTON_CLICK", items, 2);
    {
    mmask_t e   = (mmask_t)SvIV(ST(0));
    int x   = (int)SvIV(ST(1));
    int ret = BUTTON_CLICK(e, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("BUTTON_CLICK");
    XSRETURN(0);
#endif
}

XS(XS_Curses_BUTTON_DOUBLE_CLICK)
{
    dXSARGS;
#ifdef C_BUTTON_DOUBLE_CLICK
    c_exactargs("BUTTON_DOUBLE_CLICK", items, 2);
    {
    mmask_t e   = (mmask_t)SvIV(ST(0));
    int x   = (int)SvIV(ST(1));
    int ret = BUTTON_DOUBLE_CLICK(e, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("BUTTON_DOUBLE_CLICK");
    XSRETURN(0);
#endif
}

XS(XS_Curses_BUTTON_TRIPLE_CLICK)
{
    dXSARGS;
#ifdef C_BUTTON_TRIPLE_CLICK
    c_exactargs("BUTTON_TRIPLE_CLICK", items, 2);
    {
    mmask_t e   = (mmask_t)SvIV(ST(0));
    int x   = (int)SvIV(ST(1));
    int ret = BUTTON_TRIPLE_CLICK(e, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("BUTTON_TRIPLE_CLICK");
    XSRETURN(0);
#endif
}

XS(XS_Curses_BUTTON_RESERVED_EVENT)
{
    dXSARGS;
#ifdef C_BUTTON_RESERVED_EVENT
    c_exactargs("BUTTON_RESERVED_EVENT", items, 2);
    {
    mmask_t e   = (mmask_t)SvIV(ST(0));
    int x   = (int)SvIV(ST(1));
    int ret = BUTTON_RESERVED_EVENT(e, x);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("BUTTON_RESERVED_EVENT");
    XSRETURN(0);
#endif
}


XS(XS_Curses_use_default_colors)
{
    dXSARGS;
#ifdef C_USE_DEFAULT_COLORS
    c_exactargs("use_default_colors", items, 0);
    {
    int ret = use_default_colors();
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("use_default_colors");
    XSRETURN(0);
#endif
}

XS(XS_Curses_assume_default_colors)
{
    dXSARGS;
#ifdef C_ASSUME_DEFAULT_COLORS
    c_exactargs("assume_default_colors", items, 2);
    {
    int fg  = (int)SvIV(ST(0));
    int bg  = (int)SvIV(ST(1));
    int ret = assume_default_colors(fg, bg);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("assume_default_colors");
    XSRETURN(0);
#endif
}

XS(XS_Curses_define_key)
{
    dXSARGS;
#ifdef C_DEFINE_KEY
    c_exactargs("define_key", items, 2);
    {
    char *  definition  = (char *)SvPV_nolen(ST(0));
    int keycode = (int)SvIV(ST(1));
    int ret = define_key(definition, keycode);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("define_key");
    XSRETURN(0);
#endif
}

XS(XS_Curses_keybound)
{
    dXSARGS;
#ifdef C_KEYBOUND
    c_exactargs("keybound", items, 2);
    {
    int keycode = (int)SvIV(ST(0));
    int count   = (int)SvIV(ST(1));
    char *  ret = keybound(keycode, count);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("keybound");
    XSRETURN(0);
#endif
}

XS(XS_Curses_keyok)
{
    dXSARGS;
#ifdef C_KEYOK
    c_exactargs("keyok", items, 2);
    {
    int keycode = (int)SvIV(ST(0));
    bool    enable  = (int)SvIV(ST(1));
    int ret = keyok(keycode, enable);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("keyok");
    XSRETURN(0);
#endif
}

XS(XS_Curses_resizeterm)
{
    dXSARGS;
#ifdef C_RESIZETERM
    c_exactargs("resizeterm", items, 2);
    {
    int lines   = (int)SvIV(ST(0));
    int cols    = (int)SvIV(ST(1));
    int ret = resizeterm(lines, cols);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("resizeterm");
    XSRETURN(0);
#endif
}

XS(XS_Curses_resize)
{
    dXSARGS;
#ifdef C_RESIZE
    c_countargs("resize", items, 2);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int lines_  = (int)SvIV(ST(c_arg));
    int columns = (int)SvIV(ST(c_arg+1));
    int ret = c_mret == ERR ? ERR : wresize(win, lines_, columns);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("resize");
    XSRETURN(0);
#endif
}


/* DEC curses, I think */

XS(XS_Curses_getmaxy)
{
    dXSARGS;
#ifdef C_GETMAXY
    c_countargs("getmaxy", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : getmaxy(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getmaxy");
    XSRETURN(0);
#endif
}

XS(XS_Curses_getmaxx)
{
    dXSARGS;
#ifdef C_GETMAXX
    c_countargs("getmaxx", items, 0);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    int ret = c_mret == ERR ? ERR : getmaxx(win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getmaxx");
    XSRETURN(0);
#endif
}


/* old BSD curses calls */

XS(XS_Curses_flusok)
{
    dXSARGS;
#ifdef C_FLUSOK
    c_countargs("flusok", items, 1);
    {
    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    int c_mret  = c_x ? c_domove(win, ST(c_x-1), ST(c_x)) : OK;
    bool    bf  = (int)SvIV(ST(c_arg));
    
    if (c_mret == OK) { flusok(win, bf); }
    }
    XSRETURN(0);
#else
    c_fun_not_there("flusok");
    XSRETURN(0);
#endif
}

XS(XS_Curses_getcap)
{
    dXSARGS;
#ifdef C_GETCAP
    c_exactargs("getcap", items, 1);
    {
    char *  term    = (char *)SvPV_nolen(ST(0));
    char *  ret = (char *)getcap(term);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("getcap");
    XSRETURN(0);
#endif
}

XS(XS_Curses_touchoverlap)
{
    dXSARGS;
#ifdef C_TOUCHOVERLAP
    c_exactargs("touchoverlap", items, 2);
    {
    WINDOW *src = c_sv2window(ST(0), 0);
    WINDOW *dst = c_sv2window(ST(1), 1);
    int ret = touchoverlap(src, dst);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("touchoverlap");
    XSRETURN(0);
#endif
}


/* Panel functions */

XS(XS_Curses_new_panel)
{
    dXSARGS;
#ifdef C_NEW_PANEL
    c_exactargs("new_panel", items, 1);
    {
    WINDOW *win = c_sv2window(ST(0), 0);
    PANEL * ret = new_panel(win);
    
    ST(0) = sv_newmortal();
    c_panel2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("new_panel");
    XSRETURN(0);
#endif
}

XS(XS_Curses_bottom_panel)
{
    dXSARGS;
#ifdef C_BOTTOM_PANEL
    c_exactargs("bottom_panel", items, 1);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    int ret = bottom_panel(pan);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("bottom_panel");
    XSRETURN(0);
#endif
}

XS(XS_Curses_top_panel)
{
    dXSARGS;
#ifdef C_TOP_PANEL
    c_exactargs("top_panel", items, 1);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    int ret = top_panel(pan);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("top_panel");
    XSRETURN(0);
#endif
}

XS(XS_Curses_show_panel)
{
    dXSARGS;
#ifdef C_SHOW_PANEL
    c_exactargs("show_panel", items, 1);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    int ret = show_panel(pan);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("show_panel");
    XSRETURN(0);
#endif
}

XS(XS_Curses_update_panels)
{
    dXSARGS;
#ifdef C_UPDATE_PANELS
    c_exactargs("update_panels", items, 0);
    {
    update_panels();
    }
    XSRETURN(0);
#else
    c_fun_not_there("update_panels");
    XSRETURN(0);
#endif
}

XS(XS_Curses_hide_panel)
{
    dXSARGS;
#ifdef C_HIDE_PANEL
    c_exactargs("hide_panel", items, 1);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    int ret = hide_panel(pan);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("hide_panel");
    XSRETURN(0);
#endif
}

XS(XS_Curses_panel_window)
{
    dXSARGS;
#ifdef C_PANEL_WINDOW
    c_exactargs("panel_window", items, 1);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    WINDOW *    ret = panel_window(pan);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("panel_window");
    XSRETURN(0);
#endif
}

XS(XS_Curses_replace_panel)
{
    dXSARGS;
#ifdef C_REPLACE_PANEL
    c_exactargs("replace_panel", items, 2);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    WINDOW *window  = c_sv2window(ST(1), 1);
    int ret = replace_panel(pan, window);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("replace_panel");
    XSRETURN(0);
#endif
}

XS(XS_Curses_move_panel)
{
    dXSARGS;
#ifdef C_MOVE_PANEL
    c_exactargs("move_panel", items, 3);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    int starty  = (int)SvIV(ST(1));
    int startx  = (int)SvIV(ST(2));
    int ret = move_panel(pan, starty, startx);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("move_panel");
    XSRETURN(0);
#endif
}

XS(XS_Curses_panel_hidden)
{
    dXSARGS;
#ifdef C_PANEL_HIDDEN
    c_exactargs("panel_hidden", items, 1);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    int ret = panel_hidden(pan);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("panel_hidden");
    XSRETURN(0);
#endif
}

XS(XS_Curses_panel_above)
{
    dXSARGS;
#ifdef C_PANEL_ABOVE
    c_exactargs("panel_above", items, 1);
    {
    PANEL * pan = ST(0) != &PL_sv_undef ? c_sv2panel(ST(0), 0) : NULL;
    PANEL * ret = panel_above(pan);
    
    ST(0) = sv_newmortal();
    c_panel2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("panel_above");
    XSRETURN(0);
#endif
}

XS(XS_Curses_panel_below)
{
    dXSARGS;
#ifdef C_PANEL_BELOW
    c_exactargs("panel_below", items, 1);
    {
    PANEL * pan = ST(0) != &PL_sv_undef ? c_sv2panel(ST(0), 0) : NULL;
    PANEL * ret = panel_below(pan);
    
    ST(0) = sv_newmortal();
    c_panel2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("panel_below");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_panel_userptr)
{
    dXSARGS;
#ifdef C_SET_PANEL_USERPTR
    c_exactargs("set_panel_userptr", items, 2);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    char *  ptr = (char *)SvPV_nolen(ST(1));
    int ret = set_panel_userptr(pan, ptr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_panel_userptr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_panel_userptr)
{
    dXSARGS;
#ifdef C_PANEL_USERPTR
    c_exactargs("panel_userptr", items, 1);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    char *  ret = (char *)panel_userptr(pan);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("panel_userptr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_del_panel)
{
    dXSARGS;
#ifdef C_DEL_PANEL
    c_exactargs("del_panel", items, 1);
    {
    PANEL * pan = c_sv2panel(ST(0), 0);
    int ret = del_panel(pan);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("del_panel");
    XSRETURN(0);
#endif
}


/* Menu functions */

/* menu_attributes */

XS(XS_Curses_set_menu_fore)
{
    dXSARGS;
#ifdef C_SET_MENU_FORE
    c_exactargs("set_menu_fore", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    chtype  attr    = c_sv2chtype(ST(1));
    int ret = set_menu_fore(menu, attr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_fore");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_fore)
{
    dXSARGS;
#ifdef C_MENU_FORE
    c_exactargs("menu_fore", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    chtype  ret = menu_fore(menu);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_fore");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_menu_back)
{
    dXSARGS;
#ifdef C_SET_MENU_BACK
    c_exactargs("set_menu_back", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    chtype  attr    = c_sv2chtype(ST(1));
    int ret = set_menu_back(menu, attr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_back");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_back)
{
    dXSARGS;
#ifdef C_MENU_BACK
    c_exactargs("menu_back", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    chtype  ret = menu_back(menu);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_back");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_menu_grey)
{
    dXSARGS;
#ifdef C_SET_MENU_GREY
    c_exactargs("set_menu_grey", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    chtype  attr    = c_sv2chtype(ST(1));
    int ret = set_menu_grey(menu, attr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_grey");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_grey)
{
    dXSARGS;
#ifdef C_MENU_GREY
    c_exactargs("menu_grey", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    chtype  ret = menu_grey(menu);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_grey");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_menu_pad)
{
    dXSARGS;
#ifdef C_SET_MENU_PAD
    c_exactargs("set_menu_pad", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int pad = (int)SvIV(ST(1));
    int ret = set_menu_pad(menu, pad);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_pad");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_pad)
{
    dXSARGS;
#ifdef C_MENU_PAD
    c_exactargs("menu_pad", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int ret = menu_pad(menu);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_pad");
    XSRETURN(0);
#endif
}


/* menu_cursor */

XS(XS_Curses_pos_menu_cursor)
{
    dXSARGS;
#ifdef C_POS_MENU_CURSOR
    c_exactargs("pos_menu_cursor", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int ret = pos_menu_cursor(menu);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("pos_menu_cursor");
    XSRETURN(0);
#endif
}


/* menu_driver */

XS(XS_Curses_menu_driver)
{
    dXSARGS;
#ifdef C_MENU_DRIVER
    c_exactargs("menu_driver", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int c   = (int)SvIV(ST(1));
    int ret = menu_driver(menu, c);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_driver");
    XSRETURN(0);
#endif
}


/* menu_format */

XS(XS_Curses_set_menu_format)
{
    dXSARGS;
#ifdef C_SET_MENU_FORMAT
    c_exactargs("set_menu_format", items, 3);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int rows    = (int)SvIV(ST(1));
    int cols    = (int)SvIV(ST(2));
    int ret = set_menu_format(menu, rows, cols);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_format");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_format)
{
    dXSARGS;
#ifdef C_MENU_FORMAT
    c_exactargs("menu_format", items, 3);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int rows    = 0;
    int cols    = 0;
    
    menu_format(menu, &rows, &cols);
    sv_setiv(ST(1), (IV)rows);;
    sv_setiv(ST(2), (IV)cols);;
    }
    XSRETURN(0);
#else
    c_fun_not_there("menu_format");
    XSRETURN(0);
#endif
}


/* menu_items */

XS(XS_Curses_set_menu_items)
{
    dXSARGS;
#ifdef C_SET_MENU_ITEMS
    c_exactargs("set_menu_items", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    ITEM ** items   = (ITEM **)SvPV_nolen(ST(1));
    int ret = set_menu_items(menu, items);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_items");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_items)
{
    dXSARGS;
#ifdef C_MENU_ITEMS
    c_exactargs("menu_items", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    ITEM ** ret = menu_items(menu);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), (char *)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_items");
    XSRETURN(0);
#endif
}

XS(XS_Curses_item_count)
{
    dXSARGS;
#ifdef C_ITEM_COUNT
    c_exactargs("item_count", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int ret = item_count(menu);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_count");
    XSRETURN(0);
#endif
}


/* menu_mark */

XS(XS_Curses_set_menu_mark)
{
    dXSARGS;
#ifdef C_SET_MENU_MARK
    c_exactargs("set_menu_mark", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    char *  mark    = (char *)SvPV_nolen(ST(1));
    int ret = set_menu_mark(menu, mark);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_mark");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_mark)
{
    dXSARGS;
#ifdef C_MENU_MARK
    c_exactargs("menu_mark", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    char *  ret = (char *)menu_mark(menu);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_mark");
    XSRETURN(0);
#endif
}



XS(XS_Curses_new_menu)
{
    dXSARGS;
#ifdef C_NEW_MENU
    c_exactargs("new_menu", items, 1);
    {
        ITEM ** items   = (ITEM **)SvPV_nolen(ST(0));
        MENU *  ret = new_menu(items);
    
        ST(0) = sv_newmortal();
        c_menu2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("new_menu");
    XSRETURN(0);
#endif
}



XS(XS_Curses_free_menu)
{
    dXSARGS;
#ifdef C_FREE_MENU
    c_exactargs("free_menu", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int ret = free_menu(menu);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("free_menu");
    XSRETURN(0);
#endif
}


/* menu_opts */

XS(XS_Curses_menu_opts)
{
    dXSARGS;
#ifdef C_MENU_OPTS
    c_exactargs("menu_opts", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int ret = menu_opts(menu);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_opts");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_menu_opts)
{
    dXSARGS;
#ifdef C_SET_MENU_OPTS
    c_exactargs("set_menu_opts", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = set_menu_opts(menu, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_opts");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_opts_on)
{
    dXSARGS;
#ifdef C_MENU_OPTS_ON
    c_exactargs("menu_opts_on", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = menu_opts_on(menu, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_opts_on");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_opts_off)
{
    dXSARGS;
#ifdef C_MENU_OPTS_OFF
    c_exactargs("menu_opts_off", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = menu_opts_off(menu, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_opts_off");
    XSRETURN(0);
#endif
}


/* menu_pattern */

XS(XS_Curses_set_menu_pattern)
{
    dXSARGS;
#ifdef C_SET_MENU_PATTERN
    c_exactargs("set_menu_pattern", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    char *  pattern = (char *)SvPV_nolen(ST(1));
    int ret = set_menu_pattern(menu, pattern);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_pattern");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_pattern)
{
    dXSARGS;
#ifdef C_MENU_PATTERN
    c_exactargs("menu_pattern", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    char *  ret = menu_pattern(menu);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_pattern");
    XSRETURN(0);
#endif
}


/* menu_post */

XS(XS_Curses_post_menu)
{
    dXSARGS;
#ifdef C_POST_MENU
    c_exactargs("post_menu", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int ret = post_menu(menu);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("post_menu");
    XSRETURN(0);
#endif
}

XS(XS_Curses_unpost_menu)
{
    dXSARGS;
#ifdef C_UNPOST_MENU
    c_exactargs("unpost_menu", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int ret = unpost_menu(menu);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("unpost_menu");
    XSRETURN(0);
#endif
}


/* menu_userptr */

XS(XS_Curses_set_menu_userptr)
{
    dXSARGS;
#ifdef C_SET_MENU_USERPTR
    c_exactargs("set_menu_userptr", items, 2);
    {
    MENU *  item    = c_sv2menu(ST(0), 0);
    char *  userptr = (char *)SvPV_nolen(ST(1));
    int ret = set_menu_userptr(item, userptr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_userptr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_userptr)
{
    dXSARGS;
#ifdef C_MENU_USERPTR
    c_exactargs("menu_userptr", items, 1);
    {
    MENU *  item    = c_sv2menu(ST(0), 0);
    char *  ret = menu_userptr(item);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_userptr");
    XSRETURN(0);
#endif
}


/* menu_win */

XS(XS_Curses_set_menu_win)
{
    dXSARGS;
#ifdef C_SET_MENU_WIN
    c_exactargs("set_menu_win", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    WINDOW *win = c_sv2window(ST(1), 1);
    int ret = set_menu_win(menu, win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_win");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_win)
{
    dXSARGS;
#ifdef C_MENU_WIN
    c_exactargs("menu_win", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    WINDOW *    ret = menu_win(menu);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_win");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_menu_sub)
{
    dXSARGS;
#ifdef C_SET_MENU_SUB
    c_exactargs("set_menu_sub", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    WINDOW *win = c_sv2window(ST(1), 1);
    int ret = set_menu_sub(menu, win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_sub");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_sub)
{
    dXSARGS;
#ifdef C_MENU_SUB
    c_exactargs("menu_sub", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    WINDOW *    ret = menu_sub(menu);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_sub");
    XSRETURN(0);
#endif
}

XS(XS_Curses_scale_menu)
{
    dXSARGS;
#ifdef C_SCALE_MENU
    c_exactargs("scale_menu", items, 3);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int rows    = 0;
    int cols    = 0;
    int ret = scale_menu(menu, &rows, &cols);
    
    sv_setiv(ST(1), (IV)rows);;
    sv_setiv(ST(2), (IV)cols);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scale_menu");
    XSRETURN(0);
#endif
}


/* menu_item_current */

XS(XS_Curses_set_current_item)
{
    dXSARGS;
#ifdef C_SET_CURRENT_ITEM
    c_exactargs("set_current_item", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    ITEM *  item    = c_sv2item(ST(1), 1);
    int ret = set_current_item(menu, item);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_current_item");
    XSRETURN(0);
#endif
}

XS(XS_Curses_current_item)
{
    dXSARGS;
#ifdef C_CURRENT_ITEM
    c_exactargs("current_item", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    ITEM *  ret = current_item(menu);
    
    ST(0) = sv_newmortal();
    c_item2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("current_item");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_top_row)
{
    dXSARGS;
#ifdef C_SET_TOP_ROW
    c_exactargs("set_top_row", items, 2);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int row = (int)SvIV(ST(1));
    int ret = set_top_row(menu, row);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_top_row");
    XSRETURN(0);
#endif
}

XS(XS_Curses_top_row)
{
    dXSARGS;
#ifdef C_TOP_ROW
    c_exactargs("top_row", items, 1);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int ret = top_row(menu);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("top_row");
    XSRETURN(0);
#endif
}

XS(XS_Curses_item_index)
{
    dXSARGS;
#ifdef C_ITEM_INDEX
    c_exactargs("item_index", items, 1);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    int ret = item_index(item);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_index");
    XSRETURN(0);
#endif
}


/* menu_item_name */

XS(XS_Curses_item_name)
{
    dXSARGS;
#ifdef C_ITEM_NAME
    c_exactargs("item_name", items, 1);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    char *  ret = (char *)item_name(item);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_name");
    XSRETURN(0);
#endif
}

XS(XS_Curses_item_description)
{
    dXSARGS;
#ifdef C_ITEM_DESCRIPTION
    c_exactargs("item_description", items, 1);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    char *  ret = (char *)item_description(item);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_description");
    XSRETURN(0);
#endif
}


/* menu_item_new */

XS(XS_Curses_new_item)
{
    dXSARGS;
#ifdef C_NEW_ITEM
    c_exactargs("new_item", items, 2);
    {
        char *  name    = (char *)SvPV_nolen(ST(0));
        char *  descr   = (char *)SvPV_nolen(ST(1));

        ITEM *  ret = new_item(name, descr);
    
        ST(0) = sv_newmortal();
        c_item2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("new_item");
    XSRETURN(0);
#endif
}

XS(XS_Curses_free_item)
{
    dXSARGS;
#ifdef C_FREE_ITEM
    c_exactargs("free_item", items, 1);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    int ret = free_item(item);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("free_item");
    XSRETURN(0);
#endif
}


/* menu_item_opts */

XS(XS_Curses_set_item_opts)
{
    dXSARGS;
#ifdef C_SET_ITEM_OPTS
    c_exactargs("set_item_opts", items, 2);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = set_item_opts(item, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_item_opts");
    XSRETURN(0);
#endif
}

XS(XS_Curses_item_opts_on)
{
    dXSARGS;
#ifdef C_ITEM_OPTS_ON
    c_exactargs("item_opts_on", items, 2);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = item_opts_on(item, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_opts_on");
    XSRETURN(0);
#endif
}

XS(XS_Curses_item_opts_off)
{
    dXSARGS;
#ifdef C_ITEM_OPTS_OFF
    c_exactargs("item_opts_off", items, 2);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = item_opts_off(item, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_opts_off");
    XSRETURN(0);
#endif
}

XS(XS_Curses_item_opts)
{
    dXSARGS;
#ifdef C_ITEM_OPTS
    c_exactargs("item_opts", items, 1);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    int ret = item_opts(item);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_opts");
    XSRETURN(0);
#endif
}


/* menu_item_userptr */

XS(XS_Curses_item_userptr)
{
    dXSARGS;
#ifdef C_ITEM_USERPTR
    c_exactargs("item_userptr", items, 1);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    char *  ret = (char *)item_userptr(item);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_userptr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_item_userptr)
{
    dXSARGS;
#ifdef C_SET_ITEM_USERPTR
    c_exactargs("set_item_userptr", items, 2);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    char *  ptr = (char *)SvPV_nolen(ST(1));
    int ret = set_item_userptr(item, ptr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_item_userptr");
    XSRETURN(0);
#endif
}


/* menu_item_value */

XS(XS_Curses_set_item_value)
{
    dXSARGS;
#ifdef C_SET_ITEM_VALUE
    c_exactargs("set_item_value", items, 2);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    bool    val = (int)SvIV(ST(1));
    int ret = set_item_value(item, val);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_item_value");
    XSRETURN(0);
#endif
}

XS(XS_Curses_item_value)
{
    dXSARGS;
#ifdef C_ITEM_VALUE
    c_exactargs("item_value", items, 1);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    bool    ret = item_value(item);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_value");
    XSRETURN(0);
#endif
}


/* menu_item_visible */

XS(XS_Curses_item_visible)
{
    dXSARGS;
#ifdef C_ITEM_VISIBLE
    c_exactargs("item_visible", items, 1);
    {
    ITEM *  item    = c_sv2item(ST(0), 0);
    bool    ret = item_visible(item);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("item_visible");
    XSRETURN(0);
#endif
}


/* ncurses menu extension functions */

XS(XS_Curses_menu_request_name)
{
    dXSARGS;
#ifdef C_MENU_REQUEST_NAME
    c_exactargs("menu_request_name", items, 1);
    {
    int request = (int)SvIV(ST(0));
    char *  ret = (char *)menu_request_name(request);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_request_name");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_request_by_name)
{
    dXSARGS;
#ifdef C_MENU_REQUEST_BY_NAME
    c_exactargs("menu_request_by_name", items, 1);
    {
    char *  name    = (char *)SvPV_nolen(ST(0));
    int ret = menu_request_by_name(name);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_request_by_name");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_menu_spacing)
{
    dXSARGS;
#ifdef C_SET_MENU_SPACING
    c_exactargs("set_menu_spacing", items, 4);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int descr   = (int)SvIV(ST(1));
    int rows    = (int)SvIV(ST(2));
    int cols    = (int)SvIV(ST(3));
    int ret = set_menu_spacing(menu, descr, rows, cols);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_menu_spacing");
    XSRETURN(0);
#endif
}

XS(XS_Curses_menu_spacing)
{
    dXSARGS;
#ifdef C_MENU_SPACING
    c_exactargs("menu_spacing", items, 4);
    {
    MENU *  menu    = c_sv2menu(ST(0), 0);
    int descr   = 0;
    int rows    = 0;
    int cols    = 0;
    int ret = menu_spacing(menu, &descr, &rows, &cols);
    
    sv_setiv(ST(1), (IV)descr);;
    sv_setiv(ST(2), (IV)rows);;
    sv_setiv(ST(3), (IV)cols);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("menu_spacing");
    XSRETURN(0);
#endif
}


/* Form functions */

/* form_cursor */

XS(XS_Curses_pos_form_cursor)
{
    dXSARGS;
#ifdef C_POS_FORM_CURSOR
    c_exactargs("pos_form_cursor", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int ret = pos_form_cursor(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("pos_form_cursor");
    XSRETURN(0);
#endif
}


/* form_data */

XS(XS_Curses_data_ahead)
{
    dXSARGS;
#ifdef C_DATA_AHEAD
    c_exactargs("data_ahead", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    bool    ret = data_ahead(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("data_ahead");
    XSRETURN(0);
#endif
}

XS(XS_Curses_data_behind)
{
    dXSARGS;
#ifdef C_DATA_BEHIND
    c_exactargs("data_behind", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    bool    ret = data_behind(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("data_behind");
    XSRETURN(0);
#endif
}


/* form_driver */

XS(XS_Curses_form_driver)
{
    dXSARGS;
#ifdef C_FORM_DRIVER
    c_exactargs("form_driver", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int c   = (int)SvIV(ST(1));
    int ret = form_driver(form, c);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_driver");
    XSRETURN(0);
#endif
}


/* form_field */

XS(XS_Curses_set_form_fields)
{
    dXSARGS;
#ifdef C_SET_FORM_FIELDS
    c_exactargs("set_form_fields", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    FIELD **fields  = (FIELD **)SvPV_nolen(ST(1));
    int ret = set_form_fields(form, fields);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_form_fields");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_fields)
{
    dXSARGS;
#ifdef C_FORM_FIELDS
    c_exactargs("form_fields", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    FIELD **    ret = form_fields(form);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), (char *)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_fields");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_count)
{
    dXSARGS;
#ifdef C_FIELD_COUNT
    c_exactargs("field_count", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int ret = field_count(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_count");
    XSRETURN(0);
#endif
}

XS(XS_Curses_move_field)
{
    dXSARGS;
#ifdef C_MOVE_FIELD
    c_exactargs("move_field", items, 3);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int frow    = (int)SvIV(ST(1));
    int fcol    = (int)SvIV(ST(2));
    int ret = move_field(field, frow, fcol);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("move_field");
    XSRETURN(0);
#endif
}


/* form_new */

XS(XS_Curses_new_form) {
    dXSARGS;
#ifdef C_NEW_FORM
    c_exactargs("new_form", items, 1);
    {
        FIELD ** fields  = (FIELD **)SvPV_nolen(ST(0));
        FORM *  ret = new_form(fields);
        
        ST(0) = sv_newmortal();
        c_form2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("new_form");
    XSRETURN(0);
#endif
}

XS(XS_Curses_free_form)
{
    dXSARGS;
#ifdef C_FREE_FORM
    c_exactargs("free_form", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int ret = free_form(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("free_form");
    XSRETURN(0);
#endif
}


/* form_new_page */

XS(XS_Curses_set_new_page)
{
    dXSARGS;
#ifdef C_SET_NEW_PAGE
    c_exactargs("set_new_page", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    bool    new_page_flag   = (int)SvIV(ST(1));
    int ret = set_new_page(field, new_page_flag);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_new_page");
    XSRETURN(0);
#endif
}

XS(XS_Curses_new_page)
{
    dXSARGS;
#ifdef C_NEW_PAGE
    c_exactargs("new_page", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    bool    ret = new_page(field);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("new_page");
    XSRETURN(0);
#endif
}


/* form_opts */

XS(XS_Curses_set_form_opts)
{
    dXSARGS;
#ifdef C_SET_FORM_OPTS
    c_exactargs("set_form_opts", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = set_form_opts(form, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_form_opts");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_opts_on)
{
    dXSARGS;
#ifdef C_FORM_OPTS_ON
    c_exactargs("form_opts_on", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = form_opts_on(form, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_opts_on");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_opts_off)
{
    dXSARGS;
#ifdef C_FORM_OPTS_OFF
    c_exactargs("form_opts_off", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = form_opts_off(form, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_opts_off");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_opts)
{
    dXSARGS;
#ifdef C_FORM_OPTS
    c_exactargs("form_opts", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int ret = form_opts(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_opts");
    XSRETURN(0);
#endif
}


/* form_page */

XS(XS_Curses_set_current_field)
{
    dXSARGS;
#ifdef C_SET_CURRENT_FIELD
    c_exactargs("set_current_field", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    FIELD * field   = c_sv2field(ST(1), 1);
    int ret = set_current_field(form, field);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_current_field");
    XSRETURN(0);
#endif
}

XS(XS_Curses_current_field)
{
    dXSARGS;
#ifdef C_CURRENT_FIELD
    c_exactargs("current_field", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    FIELD * ret = current_field(form);
    
    ST(0) = sv_newmortal();
    c_field2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("current_field");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_form_page)
{
    dXSARGS;
#ifdef C_SET_FORM_PAGE
    c_exactargs("set_form_page", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int n   = (int)SvIV(ST(1));
    int ret = set_form_page(form, n);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_form_page");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_page)
{
    dXSARGS;
#ifdef C_FORM_PAGE
    c_exactargs("form_page", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int ret = form_page(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_page");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_index)
{
    dXSARGS;
#ifdef C_FIELD_INDEX
    c_exactargs("field_index", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int ret = field_index(field);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_index");
    XSRETURN(0);
#endif
}


/* form_post */

XS(XS_Curses_post_form)
{
    dXSARGS;
#ifdef C_POST_FORM
    c_exactargs("post_form", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int ret = post_form(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("post_form");
    XSRETURN(0);
#endif
}

XS(XS_Curses_unpost_form)
{
    dXSARGS;
#ifdef C_UNPOST_FORM
    c_exactargs("unpost_form", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int ret = unpost_form(form);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("unpost_form");
    XSRETURN(0);
#endif
}


/* form_userptr */

XS(XS_Curses_set_form_userptr)
{
    dXSARGS;
#ifdef C_SET_FORM_USERPTR
    c_exactargs("set_form_userptr", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    char *  userptr = (char *)SvPV_nolen(ST(1));
    int ret = set_form_userptr(form, userptr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_form_userptr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_userptr)
{
    dXSARGS;
#ifdef C_FORM_USERPTR
    c_exactargs("form_userptr", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    char *  ret = form_userptr(form);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_userptr");
    XSRETURN(0);
#endif
}


/* form_win */

XS(XS_Curses_set_form_win)
{
    dXSARGS;
#ifdef C_SET_FORM_WIN
    c_exactargs("set_form_win", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    WINDOW *win = c_sv2window(ST(1), 1);
    int ret = set_form_win(form, win);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_form_win");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_win)
{
    dXSARGS;
#ifdef C_FORM_WIN
    c_exactargs("form_win", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    WINDOW *    ret = form_win(form);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_win");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_form_sub)
{
    dXSARGS;
#ifdef C_SET_FORM_SUB
    c_exactargs("set_form_sub", items, 2);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    WINDOW *sub = c_sv2window(ST(1), 1);
    int ret = set_form_sub(form, sub);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_form_sub");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_sub)
{
    dXSARGS;
#ifdef C_FORM_SUB
    c_exactargs("form_sub", items, 1);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    WINDOW *    ret = form_sub(form);
    
    ST(0) = sv_newmortal();
    c_window2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_sub");
    XSRETURN(0);
#endif
}

XS(XS_Curses_scale_form)
{
    dXSARGS;
#ifdef C_SCALE_FORM
    c_exactargs("scale_form", items, 3);
    {
    FORM *  form    = c_sv2form(ST(0), 0);
    int rows    = 0;
    int cols    = 0;
    int ret = scale_form(form, &rows, &cols);
    
    sv_setiv(ST(1), (IV)rows);;
    sv_setiv(ST(2), (IV)cols);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("scale_form");
    XSRETURN(0);
#endif
}


/* form_field_attributes */

XS(XS_Curses_set_field_fore)
{
    dXSARGS;
#ifdef C_SET_FIELD_FORE
    c_exactargs("set_field_fore", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    chtype  attr    = c_sv2chtype(ST(1));
    int ret = set_field_fore(field, attr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_field_fore");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_fore)
{
    dXSARGS;
#ifdef C_FIELD_FORE
    c_exactargs("field_fore", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    chtype  ret = field_fore(field);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_fore");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_field_back)
{
    dXSARGS;
#ifdef C_SET_FIELD_BACK
    c_exactargs("set_field_back", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    chtype  attr    = c_sv2chtype(ST(1));
    int ret = set_field_back(field, attr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_field_back");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_back)
{
    dXSARGS;
#ifdef C_FIELD_BACK
    c_exactargs("field_back", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    chtype  ret = field_back(field);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_back");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_field_pad)
{
    dXSARGS;
#ifdef C_SET_FIELD_PAD
    c_exactargs("set_field_pad", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int pad = (int)SvIV(ST(1));
    int ret = set_field_pad(field, pad);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_field_pad");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_pad)
{
    dXSARGS;
#ifdef C_FIELD_PAD
    c_exactargs("field_pad", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    chtype  ret = field_pad(field);
    
    ST(0) = sv_newmortal();
    c_chtype2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_pad");
    XSRETURN(0);
#endif
}


/* form_field_buffer */

XS(XS_Curses_set_field_buffer)
{
    dXSARGS;
#ifdef C_SET_FIELD_BUFFER
    c_exactargs("set_field_buffer", items, 3);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int buf = (int)SvIV(ST(1));
    char *  value   = (char *)SvPV_nolen(ST(2));
    int ret = set_field_buffer(field, buf, value);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_field_buffer");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_buffer)
{
    dXSARGS;
#ifdef C_FIELD_BUFFER
    c_exactargs("field_buffer", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int buffer  = (int)SvIV(ST(1));
    char *  ret = field_buffer(field, buffer);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_buffer");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_field_status)
{
    dXSARGS;
#ifdef C_SET_FIELD_STATUS
    c_exactargs("set_field_status", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    bool    status  = (int)SvIV(ST(1));
    int ret = set_field_status(field, status);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_field_status");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_status)
{
    dXSARGS;
#ifdef C_FIELD_STATUS
    c_exactargs("field_status", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    bool    ret = field_status(field);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_status");
    XSRETURN(0);
#endif
}

XS(XS_Curses_set_max_field)
{
    dXSARGS;
#ifdef C_SET_MAX_FIELD
    c_exactargs("set_max_field", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int max = (int)SvIV(ST(1));
    int ret = set_max_field(field, max);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_max_field");
    XSRETURN(0);
#endif
}


/* form_field_info */

XS(XS_Curses_field_info)
{
    dXSARGS;
#ifdef C_FIELD_INFO
    c_exactargs("field_info", items, 7);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int rows    = 0;
    int cols    = 0;
    int frow    = 0;
    int fcol    = 0;
    int nrow    = 0;
    int nbuf    = 0;
    int ret = field_info(field, &rows, &cols, &frow, &fcol, &nrow, &nbuf);
    
    sv_setiv(ST(1), (IV)rows);;
    sv_setiv(ST(2), (IV)cols);;
    sv_setiv(ST(3), (IV)frow);;
    sv_setiv(ST(4), (IV)fcol);;
    sv_setiv(ST(5), (IV)nrow);;
    sv_setiv(ST(6), (IV)nbuf);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_info");
    XSRETURN(0);
#endif
}

XS(XS_Curses_dynamic_field_info)
{
    dXSARGS;
#ifdef C_DYNAMIC_FIELD_INFO
    c_exactargs("dynamic_field_info", items, 4);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int rows    = 0;
    int cols    = 0;
    int max = 0;
    int ret = dynamic_field_info(field, &rows, &cols, &max);
    
    sv_setiv(ST(1), (IV)rows);;
    sv_setiv(ST(2), (IV)cols);;
    sv_setiv(ST(3), (IV)max);;
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("dynamic_field_info");
    XSRETURN(0);
#endif
}


/* form_field_just */

XS(XS_Curses_set_field_just)
{
    dXSARGS;
#ifdef C_SET_FIELD_JUST
    c_exactargs("set_field_just", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int justif  = (int)SvIV(ST(1));
    int ret = set_field_just(field, justif);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_field_just");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_just)
{
    dXSARGS;
#ifdef C_FIELD_JUST
    c_exactargs("field_just", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int ret = field_just(field);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_just");
    XSRETURN(0);
#endif
}


/* form_field_new */

XS(XS_Curses_new_field)
{
    dXSARGS;
#ifdef C_NEW_FIELD
    c_exactargs("new_field", items, 6);
    {
        int const height    = (int)SvIV(ST(0));
        int const width     = (int)SvIV(ST(1));
        int const toprow    = (int)SvIV(ST(2));
        int const leftcol   = (int)SvIV(ST(3));
        int const offscreen = (int)SvIV(ST(4));
        int const nbuffers  = (int)SvIV(ST(5));
        FIELD * ret = new_field(height, width, toprow, leftcol, offscreen, nbuffers);
        ST(0) = sv_newmortal();
        c_field2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("new_field");
    XSRETURN(0);
#endif
}

XS(XS_Curses_dup_field)
{
    dXSARGS;
#ifdef C_DUP_FIELD
    c_exactargs("dup_field", items, 3);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int toprow  = (int)SvIV(ST(1));
    int leftcol = (int)SvIV(ST(2));
    FIELD * ret = dup_field(field, toprow, leftcol);
    
    ST(0) = sv_newmortal();
    c_field2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("dup_field");
    XSRETURN(0);
#endif
}

XS(XS_Curses_link_field)
{
    dXSARGS;
#ifdef C_LINK_FIELD
    c_exactargs("link_field", items, 3);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int toprow  = (int)SvIV(ST(1));
    int leftcol = (int)SvIV(ST(2));
    FIELD * ret = link_field(field, toprow, leftcol);
    
    ST(0) = sv_newmortal();
    c_field2sv(ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("link_field");
    XSRETURN(0);
#endif
}

XS(XS_Curses_free_field)
{
    dXSARGS;
#ifdef C_FREE_FIELD
    c_exactargs("free_field", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int ret = free_field(field);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("free_field");
    XSRETURN(0);
#endif
}


/* form_field_opts */

XS(XS_Curses_set_field_opts)
{
    dXSARGS;
#ifdef C_SET_FIELD_OPTS
    c_exactargs("set_field_opts", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = set_field_opts(field, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_field_opts");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_opts_on)
{
    dXSARGS;
#ifdef C_FIELD_OPTS_ON
    c_exactargs("field_opts_on", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = field_opts_on(field, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_opts_on");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_opts_off)
{
    dXSARGS;
#ifdef C_FIELD_OPTS_OFF
    c_exactargs("field_opts_off", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int opts    = (int)SvIV(ST(1));
    int ret = field_opts_off(field, opts);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_opts_off");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_opts)
{
    dXSARGS;
#ifdef C_FIELD_OPTS
    c_exactargs("field_opts", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    int ret = field_opts(field);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_opts");
    XSRETURN(0);
#endif
}


/* form_field_userptr */

XS(XS_Curses_set_field_userptr)
{
    dXSARGS;
#ifdef C_SET_FIELD_USERPTR
    c_exactargs("set_field_userptr", items, 2);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    char *  userptr = (char *)SvPV_nolen(ST(1));
    int ret = set_field_userptr(field, userptr);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("set_field_userptr");
    XSRETURN(0);
#endif
}

XS(XS_Curses_field_userptr)
{
    dXSARGS;
#ifdef C_FIELD_USERPTR
    c_exactargs("field_userptr", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    char *  ret = field_userptr(field);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_userptr");
    XSRETURN(0);
#endif
}


/* form_field_validation */

XS(XS_Curses_field_arg)
{
    dXSARGS;
#ifdef C_FIELD_ARG
    c_exactargs("field_arg", items, 1);
    {
    FIELD * field   = c_sv2field(ST(0), 0);
    char *  ret = field_arg(field);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("field_arg");
    XSRETURN(0);
#endif
}


/* ncurses form extension functions */

XS(XS_Curses_form_request_name)
{
    dXSARGS;
#ifdef C_FORM_REQUEST_NAME
    c_exactargs("form_request_name", items, 1);
    {
    int request = (int)SvIV(ST(0));
    char *  ret = (char *)form_request_name(request);
    
    ST(0) = sv_newmortal();
    sv_setpv((SV*)ST(0), ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_request_name");
    XSRETURN(0);
#endif
}

XS(XS_Curses_form_request_by_name)
{
    dXSARGS;
#ifdef C_FORM_REQUEST_BY_NAME
    c_exactargs("form_request_by_name", items, 1);
    {
    char *  name    = (char *)SvPV_nolen(ST(0));
    int ret = form_request_by_name(name);
    
    ST(0) = sv_newmortal();
    sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_fun_not_there("form_request_by_name");
    XSRETURN(0);
#endif
}

