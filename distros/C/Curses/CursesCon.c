/*  This file can be automatically generated; changes may be lost.
**
**
**  CursesCon.c -- non-trivial constants
**
**  This is an inclusion for Curses.c
**
**  Copyright (c) 1994-2000  William Setzer
**
**  You may distribute under the terms of either the Artistic License
**  or the GNU General Public License, as specified in the README file.
*/

XS(XS_Curses_ACS_BLOCK)
{
    dXSARGS;
#ifdef ACS_BLOCK
    {
	int	ret = ACS_BLOCK;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_BLOCK");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_BOARD)
{
    dXSARGS;
#ifdef ACS_BOARD
    {
	int	ret = ACS_BOARD;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_BOARD");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_BTEE)
{
    dXSARGS;
#ifdef ACS_BTEE
    {
	int	ret = ACS_BTEE;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_BTEE");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_BULLET)
{
    dXSARGS;
#ifdef ACS_BULLET
    {
	int	ret = ACS_BULLET;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_BULLET");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_CKBOARD)
{
    dXSARGS;
#ifdef ACS_CKBOARD
    {
	int	ret = ACS_CKBOARD;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_CKBOARD");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_DARROW)
{
    dXSARGS;
#ifdef ACS_DARROW
    {
	int	ret = ACS_DARROW;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_DARROW");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_DEGREE)
{
    dXSARGS;
#ifdef ACS_DEGREE
    {
	int	ret = ACS_DEGREE;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_DEGREE");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_DIAMOND)
{
    dXSARGS;
#ifdef ACS_DIAMOND
    {
	int	ret = ACS_DIAMOND;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_DIAMOND");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_HLINE)
{
    dXSARGS;
#ifdef ACS_HLINE
    {
	int	ret = ACS_HLINE;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_HLINE");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_LANTERN)
{
    dXSARGS;
#ifdef ACS_LANTERN
    {
	int	ret = ACS_LANTERN;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_LANTERN");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_LARROW)
{
    dXSARGS;
#ifdef ACS_LARROW
    {
	int	ret = ACS_LARROW;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_LARROW");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_LLCORNER)
{
    dXSARGS;
#ifdef ACS_LLCORNER
    {
	int	ret = ACS_LLCORNER;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_LLCORNER");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_LRCORNER)
{
    dXSARGS;
#ifdef ACS_LRCORNER
    {
	int	ret = ACS_LRCORNER;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_LRCORNER");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_LTEE)
{
    dXSARGS;
#ifdef ACS_LTEE
    {
	int	ret = ACS_LTEE;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_LTEE");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_PLMINUS)
{
    dXSARGS;
#ifdef ACS_PLMINUS
    {
	int	ret = ACS_PLMINUS;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_PLMINUS");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_PLUS)
{
    dXSARGS;
#ifdef ACS_PLUS
    {
	int	ret = ACS_PLUS;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_PLUS");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_RARROW)
{
    dXSARGS;
#ifdef ACS_RARROW
    {
	int	ret = ACS_RARROW;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_RARROW");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_RTEE)
{
    dXSARGS;
#ifdef ACS_RTEE
    {
	int	ret = ACS_RTEE;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_RTEE");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_S1)
{
    dXSARGS;
#ifdef ACS_S1
    {
	int	ret = ACS_S1;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_S1");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_S9)
{
    dXSARGS;
#ifdef ACS_S9
    {
	int	ret = ACS_S9;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_S9");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_TTEE)
{
    dXSARGS;
#ifdef ACS_TTEE
    {
	int	ret = ACS_TTEE;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_TTEE");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_UARROW)
{
    dXSARGS;
#ifdef ACS_UARROW
    {
	int	ret = ACS_UARROW;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_UARROW");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_ULCORNER)
{
    dXSARGS;
#ifdef ACS_ULCORNER
    {
	int	ret = ACS_ULCORNER;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_ULCORNER");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_URCORNER)
{
    dXSARGS;
#ifdef ACS_URCORNER
    {
	int	ret = ACS_URCORNER;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_URCORNER");
    XSRETURN(0);
#endif
}

XS(XS_Curses_ACS_VLINE)
{
    dXSARGS;
#ifdef ACS_VLINE
    {
	int	ret = ACS_VLINE;

	ST(0) = sv_newmortal();
	sv_setiv(ST(0), (IV)ret);
    }
    XSRETURN(1);
#else
    c_con_not_there("ACS_VLINE");
    XSRETURN(0);
#endif
}

