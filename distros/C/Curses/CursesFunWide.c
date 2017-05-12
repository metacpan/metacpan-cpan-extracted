/* This is an inclusion for Curses.c */

/* Combined Normal/Wide-Character Functions */

/* April 2014, Edgar Fuﬂ, Mathematisches Institut der Universit‰t Bonn,
   <ef@math.uni-bonn.de>
*/



XS(XS_CURSES_getchar) {
    dXSARGS;
    c_countargs("getchar", items, 0);

    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    if (c_x)
        if (c_domove(win, ST(c_x-1), ST(c_x)) == ERR)
            XSRETURN_UNDEF;
#ifdef C_GET_WCH
    wint_t wch;
    int ret = wget_wch(win, &wch);
    if (ret == OK) {
        ST(0) = sv_newmortal();
        c_wchar2sv(ST(0), wch);
        XSRETURN(1);
    } else if (ret == KEY_CODE_YES) {
        XST_mUNDEF(0);
        ST(1) = sv_newmortal();
        sv_setiv(ST(1), (IV)wch);
        XSRETURN(2);
    } else {
        XSRETURN_UNDEF;
    }
#else
    int key = wgetch(win);
    if (key == ERR) {
        XSRETURN_UNDEF;
    } else if (key < KEY_MIN) {
        ST(0) = sv_newmortal();
        c_wchar2sv(ST(0), key);
        XSRETURN(1);
    } else {
        XST_mUNDEF(0);
        ST(1) = sv_newmortal();
        sv_setiv(ST(1), (IV)key);
        XSRETURN(2);
    }
#endif
}

XS(XS_CURSES_ungetchar) {
    dXSARGS;
    c_exactargs("ungetchar", items, 1);
    wint_t wc = c_sv2wchar(ST(0));
    if (wc == WEOF)
        XSRETURN_NO;
#ifdef C_UNGET_WCH
    int ret;
    ret = unget_wch(wc);
    if (ret == OK)
        XSRETURN_YES;
    else
        XSRETURN_NO;
#else
    if (wc > 0xff)
        XSRETURN_NO;
    else {
        int ret;
        ret = ungetch(wc);
        if (ret == OK)
            XSRETURN_YES;
        else
            XSRETURN_NO;
    }
#endif
}

XS(XS_CURSES_getstring) {
    dXSARGS;
    c_countargs("getstring", items, 0);

    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    if (c_x)
        if (c_domove(win, ST(c_x-1), ST(c_x)) == ERR)
            XSRETURN_UNDEF;
#ifdef C_GETN_WSTR
    wchar_t buf[1000];
    if (wgetn_wstr(win, (wint_t *)buf, (sizeof buf/sizeof *buf) - 1) == ERR)
        XSRETURN_UNDEF;
    ST(0) = sv_newmortal();
    c_wstr2sv(ST(0), buf);
    XSRETURN(1);
#else
    unsigned char buf[1000];
    if (wgetnstr(win, (char *)buf, (sizeof buf/sizeof *buf) - 1) == ERR)
        XSRETURN_UNDEF;
    ST(0) = sv_newmortal();
    c_bstr2sv(ST(0), buf);
    XSRETURN(1);
#endif
}

XS(XS_CURSES_addstring) {
    dXSARGS;
    c_countargs("addstring", items, 1);

    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    if (c_x)
        if (c_domove(win, ST(c_x-1), ST(c_x)) == ERR)
            XSRETURN_NO;
#ifdef C_ADDNWSTR
    int ret;
    size_t len;
    wint_t *wstr = c_sv2wstr(ST(c_arg), &len);
    if (wstr == NULL)
        XSRETURN_NO;
    ret = waddnwstr(win, wstr, len);
    free(wstr);
    if (ret == OK)
        XSRETURN_YES;
    else
        XSRETURN_NO;
#else
    int ret;
    size_t len;
    int need_free;
    unsigned char *bstr = c_sv2bstr(ST(c_arg), &len, &need_free);
    if (bstr == NULL)
        XSRETURN_NO;
    ret = waddnstr(win, (char *)bstr, len);
    if (need_free) free(bstr);
    if (ret == OK)
        XSRETURN_YES;
    else
        XSRETURN_NO;
#endif
}

XS(XS_CURSES_insstring) {
    dXSARGS;
    c_countargs("insstring", items, 1);

    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    if (c_x)
        if (c_domove(win, ST(c_x-1), ST(c_x)) == ERR)
            XSRETURN_NO;
#ifdef C_INS_NWSTR
    int ret;
    size_t len;
    wint_t *wstr = c_sv2wstr(ST(c_arg), &len);
    if (wstr == NULL)
        XSRETURN_NO;
    ret = wins_nwstr(win, wstr, len);
    free(wstr);
    if (ret == OK)
        XSRETURN_YES;
    else
        XSRETURN_NO;
#else
    int ret;
    size_t len;
    int need_free;
    unsigned char *bstr = c_sv2bstr(ST(c_arg), &len, &need_free);
    if (bstr == NULL)
        XSRETURN_NO;
    ret = winsnstr(win, (char *)bstr, len);
    if (need_free) free(bstr);
    if (ret == OK)
        XSRETURN_YES;
    else
        XSRETURN_NO;
#endif
}

XS(XS_CURSES_instring) {
    int x, y;
    dXSARGS;
    c_countargs("instring", items, 0);

    WINDOW *win = c_win ? c_sv2window(ST(0), 0) : stdscr;
    if (c_x)
        if (c_domove(win, ST(c_x-1), ST(c_x)) == ERR)
            XSRETURN_UNDEF;
    getmaxyx(win, y, x); /* Macro: not &y, &x! */
#ifdef C_INNWSTR
    int ret;
    wchar_t *buf = malloc((x + 1) * sizeof *buf);
    if (buf == NULL) croak("insstring: malloc");
    ret = winnwstr(win, buf, x);
    if (ret == ERR) {
        free(buf);
        XSRETURN_UNDEF;
    }
    ST(0) = sv_newmortal();
    c_wstr2sv(ST(0), buf);
    free(buf);
    XSRETURN(1);
#else
    int ret;
    unsigned char *buf = malloc(x + 1);
    if (buf == NULL) croak("insstring: malloc");
    ret = winnstr(win, (char *)buf, x);
    if (ret == ERR) {
        free(buf);
        XSRETURN_UNDEF;
    }
    ST(0) = sv_newmortal();
    c_bstr2sv(ST(0), buf);
    free(buf);
    XSRETURN(1);
#endif
}
