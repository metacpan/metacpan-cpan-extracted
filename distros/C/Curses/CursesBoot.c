/*
**
**  CursesBoot.c -- the bootstrap function
**
**  This is an inclusion for Curses.c.
**
**  Copyright (c) 1994-2000  William Setzer
**
**  You may distribute under the terms of either the Artistic License
**  or the GNU General Public License, as specified in the README file.
*/

#define C_NEWXS(A,B)   newXS(A,B,file)
#define C_NEWCS(A,B)   newCONSTSUB(stash,A,newSViv(B))

XS(boot_Curses)
{
  int i;

    dXSARGS;
    char *file  = __FILE__;
    HV   *stash = gv_stashpv("Curses", TRUE);
    IV   tmp;
    SV  *t2;

    XS_VERSION_BOOTCHECK;

    /* Functions */

    C_NEWXS("Curses::addch",                  XS_Curses_addch);
    C_NEWXS("Curses::echochar",               XS_Curses_echochar);
    C_NEWXS("Curses::addchstr",               XS_Curses_addchstr);
    C_NEWXS("Curses::addchnstr",              XS_Curses_addchnstr);
    C_NEWXS("Curses::addstr",                 XS_Curses_addstr);
    C_NEWXS("Curses::addnstr",                XS_Curses_addnstr);
    C_NEWXS("Curses::attroff",                XS_Curses_attroff);
    C_NEWXS("Curses::attron",                 XS_Curses_attron);
    C_NEWXS("Curses::attrset",                XS_Curses_attrset);
    C_NEWXS("Curses::standend",               XS_Curses_standend);
    C_NEWXS("Curses::standout",               XS_Curses_standout);
    C_NEWXS("Curses::attr_get",               XS_Curses_attr_get);
    C_NEWXS("Curses::attr_off",               XS_Curses_attr_off);
    C_NEWXS("Curses::attr_on",                XS_Curses_attr_on);
    C_NEWXS("Curses::attr_set",               XS_Curses_attr_set);
    C_NEWXS("Curses::chgat",                  XS_Curses_chgat);
    C_NEWXS("Curses::COLOR_PAIR",             XS_Curses_COLOR_PAIR);
    C_NEWXS("Curses::PAIR_NUMBER",            XS_Curses_PAIR_NUMBER);
    C_NEWXS("Curses::beep",                   XS_Curses_beep);
    C_NEWXS("Curses::flash",                  XS_Curses_flash);
    C_NEWXS("Curses::bkgd",                   XS_Curses_bkgd);
    C_NEWXS("Curses::bkgdset",                XS_Curses_bkgdset);
    C_NEWXS("Curses::getbkgd",                XS_Curses_getbkgd);
    C_NEWXS("Curses::border",                 XS_Curses_border);
    C_NEWXS("Curses::box",                    XS_Curses_box);
    C_NEWXS("Curses::hline",                  XS_Curses_hline);
    C_NEWXS("Curses::vline",                  XS_Curses_vline);
    C_NEWXS("Curses::erase",                  XS_Curses_erase);
    C_NEWXS("Curses::clear",                  XS_Curses_clear);
    C_NEWXS("Curses::clrtobot",               XS_Curses_clrtobot);
    C_NEWXS("Curses::clrtoeol",               XS_Curses_clrtoeol);
    C_NEWXS("Curses::start_color",            XS_Curses_start_color);
    C_NEWXS("Curses::init_pair",              XS_Curses_init_pair);
    C_NEWXS("Curses::init_color",             XS_Curses_init_color);
    C_NEWXS("Curses::has_colors",             XS_Curses_has_colors);
    C_NEWXS("Curses::can_change_color",       XS_Curses_can_change_color);
    C_NEWXS("Curses::color_content",          XS_Curses_color_content);
    C_NEWXS("Curses::pair_content",           XS_Curses_pair_content);
    C_NEWXS("Curses::delch",                  XS_Curses_delch);
    C_NEWXS("Curses::deleteln",               XS_Curses_deleteln);
    C_NEWXS("Curses::insdelln",               XS_Curses_insdelln);
    C_NEWXS("Curses::insertln",               XS_Curses_insertln);
    C_NEWXS("Curses::getch",                  XS_Curses_getch);
    C_NEWXS("Curses::ungetch",                XS_Curses_ungetch);
    C_NEWXS("Curses::has_key",                XS_Curses_has_key);
    C_NEWXS("Curses::KEY_F",                  XS_Curses_KEY_F);
    C_NEWXS("Curses::getstr",                 XS_Curses_getstr);
    C_NEWXS("Curses::getnstr",                XS_Curses_getnstr);
    C_NEWXS("Curses::getyx",                  XS_Curses_getyx);
    C_NEWXS("Curses::getparyx",               XS_Curses_getparyx);
    C_NEWXS("Curses::getbegyx",               XS_Curses_getbegyx);
    C_NEWXS("Curses::getmaxyx",               XS_Curses_getmaxyx);
    C_NEWXS("Curses::inch",                   XS_Curses_inch);
    C_NEWXS("Curses::inchstr",                XS_Curses_inchstr);
    C_NEWXS("Curses::inchnstr",               XS_Curses_inchnstr);
    C_NEWXS("Curses::initscr",                XS_Curses_initscr);
    C_NEWXS("Curses::endwin",                 XS_Curses_endwin);
    C_NEWXS("Curses::isendwin",               XS_Curses_isendwin);
    C_NEWXS("Curses::newterm",                XS_Curses_newterm);
    C_NEWXS("Curses::set_term",               XS_Curses_set_term);
    C_NEWXS("Curses::delscreen",              XS_Curses_delscreen);
#ifdef C_INTCBREAK
    C_NEWXS("Curses::cbreak",                 XS_Curses_cbreak);
#else
    C_NEWXS("Curses::cbreak",                 XS_Curses_cbreak);
#endif
#ifdef C_INTNOCBREAK
    C_NEWXS("Curses::nocbreak",               XS_Curses_nocbreak);
#else
    C_NEWXS("Curses::nocbreak",               XS_Curses_nocbreak);
#endif
#ifdef C_INTECHO
    C_NEWXS("Curses::echo",                   XS_Curses_echo);
#else
    C_NEWXS("Curses::echo",                   XS_Curses_echo);
#endif
#ifdef C_INTNOECHO
    C_NEWXS("Curses::noecho",                 XS_Curses_noecho);
#else
    C_NEWXS("Curses::noecho",                 XS_Curses_noecho);
#endif
    C_NEWXS("Curses::halfdelay",              XS_Curses_halfdelay);
    C_NEWXS("Curses::intrflush",              XS_Curses_intrflush);
    C_NEWXS("Curses::keypad",                 XS_Curses_keypad);
    C_NEWXS("Curses::meta",                   XS_Curses_meta);
    C_NEWXS("Curses::nodelay",                XS_Curses_nodelay);
    C_NEWXS("Curses::notimeout",              XS_Curses_notimeout);
#ifdef C_INTRAW
    C_NEWXS("Curses::raw",                    XS_Curses_raw);
#else
    C_NEWXS("Curses::raw",                    XS_Curses_raw);
#endif
#ifdef C_INTNORAW
    C_NEWXS("Curses::noraw",                  XS_Curses_noraw);
#else
    C_NEWXS("Curses::noraw",                  XS_Curses_noraw);
#endif
    C_NEWXS("Curses::qiflush",                XS_Curses_qiflush);
    C_NEWXS("Curses::noqiflush",              XS_Curses_noqiflush);
    C_NEWXS("Curses::timeout",                XS_Curses_timeout);
    C_NEWXS("Curses::typeahead",              XS_Curses_typeahead);
    C_NEWXS("Curses::insch",                  XS_Curses_insch);
    C_NEWXS("Curses::insstr",                 XS_Curses_insstr);
    C_NEWXS("Curses::insnstr",                XS_Curses_insnstr);
    C_NEWXS("Curses::instr",                  XS_Curses_instr);
    C_NEWXS("Curses::innstr",                 XS_Curses_innstr);
    C_NEWXS("Curses::def_prog_mode",          XS_Curses_def_prog_mode);
    C_NEWXS("Curses::def_shell_mode",         XS_Curses_def_shell_mode);
    C_NEWXS("Curses::reset_prog_mode",        XS_Curses_reset_prog_mode);
    C_NEWXS("Curses::reset_shell_mode",       XS_Curses_reset_shell_mode);
    C_NEWXS("Curses::resetty",                XS_Curses_resetty);
    C_NEWXS("Curses::savetty",                XS_Curses_savetty);
#ifdef C_INTGETSYX
    C_NEWXS("Curses::getsyx",                 XS_Curses_getsyx);
#else
    C_NEWXS("Curses::getsyx",                 XS_Curses_getsyx);
#endif
#ifdef C_INTSETSYX
    C_NEWXS("Curses::setsyx",                 XS_Curses_setsyx);
#else
    C_NEWXS("Curses::setsyx",                 XS_Curses_setsyx);
#endif
    C_NEWXS("Curses::curs_set",               XS_Curses_curs_set);
    C_NEWXS("Curses::napms",                  XS_Curses_napms);
    C_NEWXS("Curses::move",                   XS_Curses_move);
    C_NEWXS("Curses::clearok",                XS_Curses_clearok);
#ifdef C_INTIDLOK
    C_NEWXS("Curses::idlok",                  XS_Curses_idlok);
#else
    C_NEWXS("Curses::idlok",                  XS_Curses_idlok);
#endif
    C_NEWXS("Curses::idcok",                  XS_Curses_idcok);
    C_NEWXS("Curses::immedok",                XS_Curses_immedok);
    C_NEWXS("Curses::leaveok",                XS_Curses_leaveok);
    C_NEWXS("Curses::setscrreg",              XS_Curses_setscrreg);
    C_NEWXS("Curses::scrollok",               XS_Curses_scrollok);
#ifdef C_INTNL
    C_NEWXS("Curses::nl",                     XS_Curses_nl);
#else
    C_NEWXS("Curses::nl",                     XS_Curses_nl);
#endif
#ifdef C_INTNONL
    C_NEWXS("Curses::nonl",                   XS_Curses_nonl);
#else
    C_NEWXS("Curses::nonl",                   XS_Curses_nonl);
#endif
    C_NEWXS("Curses::overlay",                XS_Curses_overlay);
    C_NEWXS("Curses::overwrite",              XS_Curses_overwrite);
    C_NEWXS("Curses::copywin",                XS_Curses_copywin);
    C_NEWXS("Curses::newpad",                 XS_Curses_newpad);
    C_NEWXS("Curses::subpad",                 XS_Curses_subpad);
    C_NEWXS("Curses::prefresh",               XS_Curses_prefresh);
    C_NEWXS("Curses::pnoutrefresh",           XS_Curses_pnoutrefresh);
    C_NEWXS("Curses::pechochar",              XS_Curses_pechochar);
    C_NEWXS("Curses::refresh",                XS_Curses_refresh);
    C_NEWXS("Curses::noutrefresh",            XS_Curses_noutrefresh);
    C_NEWXS("Curses::doupdate",               XS_Curses_doupdate);
    C_NEWXS("Curses::redrawwin",              XS_Curses_redrawwin);
    C_NEWXS("Curses::redrawln",               XS_Curses_redrawln);
    C_NEWXS("Curses::scr_dump",               XS_Curses_scr_dump);
    C_NEWXS("Curses::scr_restore",            XS_Curses_scr_restore);
    C_NEWXS("Curses::scr_init",               XS_Curses_scr_init);
    C_NEWXS("Curses::scr_set",                XS_Curses_scr_set);
    C_NEWXS("Curses::scroll",                 XS_Curses_scroll);
    C_NEWXS("Curses::scrl",                   XS_Curses_scrl);
    C_NEWXS("Curses::slk_init",               XS_Curses_slk_init);
    C_NEWXS("Curses::slk_set",                XS_Curses_slk_set);
    C_NEWXS("Curses::slk_refresh",            XS_Curses_slk_refresh);
    C_NEWXS("Curses::slk_noutrefresh",        XS_Curses_slk_noutrefresh);
    C_NEWXS("Curses::slk_label",              XS_Curses_slk_label);
    C_NEWXS("Curses::slk_clear",              XS_Curses_slk_clear);
    C_NEWXS("Curses::slk_restore",            XS_Curses_slk_restore);
    C_NEWXS("Curses::slk_touch",              XS_Curses_slk_touch);
    C_NEWXS("Curses::slk_attron",             XS_Curses_slk_attron);
    C_NEWXS("Curses::slk_attrset",            XS_Curses_slk_attrset);
    C_NEWXS("Curses::slk_attr",               XS_Curses_slk_attr);
    C_NEWXS("Curses::slk_attroff",            XS_Curses_slk_attroff);
    C_NEWXS("Curses::slk_color",              XS_Curses_slk_color);
    C_NEWXS("Curses::baudrate",               XS_Curses_baudrate);
    C_NEWXS("Curses::erasechar",              XS_Curses_erasechar);
    C_NEWXS("Curses::has_ic",                 XS_Curses_has_ic);
    C_NEWXS("Curses::has_il",                 XS_Curses_has_il);
    C_NEWXS("Curses::killchar",               XS_Curses_killchar);
#ifdef C_LONG0ARGS
    C_NEWXS("Curses::longname",               XS_Curses_longname);
#else
    C_NEWXS("Curses::longname",               XS_Curses_longname);
#endif
    C_NEWXS("Curses::termattrs",              XS_Curses_termattrs);
    C_NEWXS("Curses::termname",               XS_Curses_termname);
    C_NEWXS("Curses::touchwin",               XS_Curses_touchwin);
#ifdef C_TOUCH3ARGS
    C_NEWXS("Curses::touchline",              XS_Curses_touchline);
#else
    C_NEWXS("Curses::touchline",              XS_Curses_touchline);
#endif
    C_NEWXS("Curses::untouchwin",             XS_Curses_untouchwin);
    C_NEWXS("Curses::touchln",                XS_Curses_touchln);
    C_NEWXS("Curses::is_linetouched",         XS_Curses_is_linetouched);
    C_NEWXS("Curses::is_wintouched",          XS_Curses_is_wintouched);
    C_NEWXS("Curses::unctrl",                 XS_Curses_unctrl);
    C_NEWXS("Curses::keyname",                XS_Curses_keyname);
#ifdef C_INTFILTER
    C_NEWXS("Curses::filter",                 XS_Curses_filter);
#else
    C_NEWXS("Curses::filter",                 XS_Curses_filter);
#endif
    C_NEWXS("Curses::use_env",                XS_Curses_use_env);
    C_NEWXS("Curses::putwin",                 XS_Curses_putwin);
    C_NEWXS("Curses::getwin",                 XS_Curses_getwin);
    C_NEWXS("Curses::delay_output",           XS_Curses_delay_output);
    C_NEWXS("Curses::flushinp",               XS_Curses_flushinp);
    C_NEWXS("Curses::newwin",                 XS_Curses_newwin);
    C_NEWXS("Curses::delwin",                 XS_Curses_delwin);
    C_NEWXS("Curses::mvwin",                  XS_Curses_mvwin);
    C_NEWXS("Curses::subwin",                 XS_Curses_subwin);
    C_NEWXS("Curses::derwin",                 XS_Curses_derwin);
    C_NEWXS("Curses::mvderwin",               XS_Curses_mvderwin);
    C_NEWXS("Curses::dupwin",                 XS_Curses_dupwin);
    C_NEWXS("Curses::syncup",                 XS_Curses_syncup);
    C_NEWXS("Curses::syncok",                 XS_Curses_syncok);
    C_NEWXS("Curses::cursyncup",              XS_Curses_cursyncup);
    C_NEWXS("Curses::syncdown",               XS_Curses_syncdown);
    C_NEWXS("Curses::getmouse",               XS_Curses_getmouse);
    C_NEWXS("Curses::ungetmouse",             XS_Curses_ungetmouse);
    C_NEWXS("Curses::mousemask",              XS_Curses_mousemask);
    C_NEWXS("Curses::enclose",                XS_Curses_enclose);
    C_NEWXS("Curses::mouse_trafo",            XS_Curses_mouse_trafo);
    C_NEWXS("Curses::mouseinterval",          XS_Curses_mouseinterval);
    C_NEWXS("Curses::BUTTON_RELEASE",         XS_Curses_BUTTON_RELEASE);
    C_NEWXS("Curses::BUTTON_PRESS",           XS_Curses_BUTTON_PRESS);
    C_NEWXS("Curses::BUTTON_CLICK",           XS_Curses_BUTTON_CLICK);
    C_NEWXS("Curses::BUTTON_DOUBLE_CLICK",    XS_Curses_BUTTON_DOUBLE_CLICK);
    C_NEWXS("Curses::BUTTON_TRIPLE_CLICK",    XS_Curses_BUTTON_TRIPLE_CLICK);
    C_NEWXS("Curses::BUTTON_RESERVED_EVENT",  XS_Curses_BUTTON_RESERVED_EVENT);
    C_NEWXS("Curses::use_default_colors",     XS_Curses_use_default_colors);
    C_NEWXS("Curses::assume_default_colors",  XS_Curses_assume_default_colors);
    C_NEWXS("Curses::define_key",             XS_Curses_define_key);
    C_NEWXS("Curses::keybound",               XS_Curses_keybound);
    C_NEWXS("Curses::keyok",                  XS_Curses_keyok);
    C_NEWXS("Curses::resizeterm",             XS_Curses_resizeterm);
    C_NEWXS("Curses::resize",                 XS_Curses_resize);
    C_NEWXS("Curses::getmaxy",                XS_Curses_getmaxy);
    C_NEWXS("Curses::getmaxx",                XS_Curses_getmaxx);
    C_NEWXS("Curses::flusok",                 XS_Curses_flusok);
    C_NEWXS("Curses::getcap",                 XS_Curses_getcap);
    C_NEWXS("Curses::touchoverlap",           XS_Curses_touchoverlap);
    C_NEWXS("Curses::new_panel",              XS_Curses_new_panel);
    C_NEWXS("Curses::bottom_panel",           XS_Curses_bottom_panel);
    C_NEWXS("Curses::top_panel",              XS_Curses_top_panel);
    C_NEWXS("Curses::show_panel",             XS_Curses_show_panel);
    C_NEWXS("Curses::update_panels",          XS_Curses_update_panels);
    C_NEWXS("Curses::hide_panel",             XS_Curses_hide_panel);
    C_NEWXS("Curses::panel_window",           XS_Curses_panel_window);
    C_NEWXS("Curses::replace_panel",          XS_Curses_replace_panel);
    C_NEWXS("Curses::move_panel",             XS_Curses_move_panel);
    C_NEWXS("Curses::panel_hidden",           XS_Curses_panel_hidden);
    C_NEWXS("Curses::panel_above",            XS_Curses_panel_above);
    C_NEWXS("Curses::panel_below",            XS_Curses_panel_below);
    C_NEWXS("Curses::set_panel_userptr",      XS_Curses_set_panel_userptr);
    C_NEWXS("Curses::panel_userptr",          XS_Curses_panel_userptr);
    C_NEWXS("Curses::del_panel",              XS_Curses_del_panel);
    C_NEWXS("Curses::set_menu_fore",          XS_Curses_set_menu_fore);
    C_NEWXS("Curses::menu_fore",              XS_Curses_menu_fore);
    C_NEWXS("Curses::set_menu_back",          XS_Curses_set_menu_back);
    C_NEWXS("Curses::menu_back",              XS_Curses_menu_back);
    C_NEWXS("Curses::set_menu_grey",          XS_Curses_set_menu_grey);
    C_NEWXS("Curses::menu_grey",              XS_Curses_menu_grey);
    C_NEWXS("Curses::set_menu_pad",           XS_Curses_set_menu_pad);
    C_NEWXS("Curses::menu_pad",               XS_Curses_menu_pad);
    C_NEWXS("Curses::pos_menu_cursor",        XS_Curses_pos_menu_cursor);
    C_NEWXS("Curses::menu_driver",            XS_Curses_menu_driver);
    C_NEWXS("Curses::set_menu_format",        XS_Curses_set_menu_format);
    C_NEWXS("Curses::menu_format",            XS_Curses_menu_format);
    C_NEWXS("Curses::set_menu_items",         XS_Curses_set_menu_items);
    C_NEWXS("Curses::menu_items",             XS_Curses_menu_items);
    C_NEWXS("Curses::item_count",             XS_Curses_item_count);
    C_NEWXS("Curses::set_menu_mark",          XS_Curses_set_menu_mark);
    C_NEWXS("Curses::menu_mark",              XS_Curses_menu_mark);
    C_NEWXS("Curses::new_menu",               XS_Curses_new_menu);
    C_NEWXS("Curses::free_menu",              XS_Curses_free_menu);
    C_NEWXS("Curses::menu_opts",              XS_Curses_menu_opts);
    C_NEWXS("Curses::set_menu_opts",          XS_Curses_set_menu_opts);
    C_NEWXS("Curses::menu_opts_on",           XS_Curses_menu_opts_on);
    C_NEWXS("Curses::menu_opts_off",          XS_Curses_menu_opts_off);
    C_NEWXS("Curses::set_menu_pattern",       XS_Curses_set_menu_pattern);
    C_NEWXS("Curses::menu_pattern",           XS_Curses_menu_pattern);
    C_NEWXS("Curses::post_menu",              XS_Curses_post_menu);
    C_NEWXS("Curses::unpost_menu",            XS_Curses_unpost_menu);
    C_NEWXS("Curses::set_menu_userptr",       XS_Curses_set_menu_userptr);
    C_NEWXS("Curses::menu_userptr",           XS_Curses_menu_userptr);
    C_NEWXS("Curses::set_menu_win",           XS_Curses_set_menu_win);
    C_NEWXS("Curses::menu_win",               XS_Curses_menu_win);
    C_NEWXS("Curses::set_menu_sub",           XS_Curses_set_menu_sub);
    C_NEWXS("Curses::menu_sub",               XS_Curses_menu_sub);
    C_NEWXS("Curses::scale_menu",             XS_Curses_scale_menu);
    C_NEWXS("Curses::set_current_item",       XS_Curses_set_current_item);
    C_NEWXS("Curses::current_item",           XS_Curses_current_item);
    C_NEWXS("Curses::set_top_row",            XS_Curses_set_top_row);
    C_NEWXS("Curses::top_row",                XS_Curses_top_row);
    C_NEWXS("Curses::item_index",             XS_Curses_item_index);
    C_NEWXS("Curses::item_name",              XS_Curses_item_name);
    C_NEWXS("Curses::item_description",       XS_Curses_item_description);
    C_NEWXS("Curses::new_item",               XS_Curses_new_item);
    C_NEWXS("Curses::free_item",              XS_Curses_free_item);
    C_NEWXS("Curses::set_item_opts",          XS_Curses_set_item_opts);
    C_NEWXS("Curses::item_opts_on",           XS_Curses_item_opts_on);
    C_NEWXS("Curses::item_opts_off",          XS_Curses_item_opts_off);
    C_NEWXS("Curses::item_opts",              XS_Curses_item_opts);
    C_NEWXS("Curses::item_userptr",           XS_Curses_item_userptr);
    C_NEWXS("Curses::set_item_userptr",       XS_Curses_set_item_userptr);
    C_NEWXS("Curses::set_item_value",         XS_Curses_set_item_value);
    C_NEWXS("Curses::item_value",             XS_Curses_item_value);
    C_NEWXS("Curses::item_visible",           XS_Curses_item_visible);
    C_NEWXS("Curses::menu_request_name",      XS_Curses_menu_request_name);
    C_NEWXS("Curses::menu_request_by_name",   XS_Curses_menu_request_by_name);
    C_NEWXS("Curses::set_menu_spacing",       XS_Curses_set_menu_spacing);
    C_NEWXS("Curses::menu_spacing",           XS_Curses_menu_spacing);
    C_NEWXS("Curses::pos_form_cursor",        XS_Curses_pos_form_cursor);
    C_NEWXS("Curses::data_ahead",             XS_Curses_data_ahead);
    C_NEWXS("Curses::data_behind",            XS_Curses_data_behind);
    C_NEWXS("Curses::form_driver",            XS_Curses_form_driver);
    C_NEWXS("Curses::set_form_fields",        XS_Curses_set_form_fields);
    C_NEWXS("Curses::form_fields",            XS_Curses_form_fields);
    C_NEWXS("Curses::field_count",            XS_Curses_field_count);
    C_NEWXS("Curses::move_field",             XS_Curses_move_field);
    C_NEWXS("Curses::new_form",               XS_Curses_new_form);
    C_NEWXS("Curses::free_form",              XS_Curses_free_form);
    C_NEWXS("Curses::set_new_page",           XS_Curses_set_new_page);
    C_NEWXS("Curses::new_page",               XS_Curses_new_page);
    C_NEWXS("Curses::set_form_opts",          XS_Curses_set_form_opts);
    C_NEWXS("Curses::form_opts_on",           XS_Curses_form_opts_on);
    C_NEWXS("Curses::form_opts_off",          XS_Curses_form_opts_off);
    C_NEWXS("Curses::form_opts",              XS_Curses_form_opts);
    C_NEWXS("Curses::set_current_field",      XS_Curses_set_current_field);
    C_NEWXS("Curses::current_field",          XS_Curses_current_field);
    C_NEWXS("Curses::set_form_page",          XS_Curses_set_form_page);
    C_NEWXS("Curses::form_page",              XS_Curses_form_page);
    C_NEWXS("Curses::field_index",            XS_Curses_field_index);
    C_NEWXS("Curses::post_form",              XS_Curses_post_form);
    C_NEWXS("Curses::unpost_form",            XS_Curses_unpost_form);
    C_NEWXS("Curses::set_form_userptr",       XS_Curses_set_form_userptr);
    C_NEWXS("Curses::form_userptr",           XS_Curses_form_userptr);
    C_NEWXS("Curses::set_form_win",           XS_Curses_set_form_win);
    C_NEWXS("Curses::form_win",               XS_Curses_form_win);
    C_NEWXS("Curses::set_form_sub",           XS_Curses_set_form_sub);
    C_NEWXS("Curses::form_sub",               XS_Curses_form_sub);
    C_NEWXS("Curses::scale_form",             XS_Curses_scale_form);
    C_NEWXS("Curses::set_field_fore",         XS_Curses_set_field_fore);
    C_NEWXS("Curses::field_fore",             XS_Curses_field_fore);
    C_NEWXS("Curses::set_field_back",         XS_Curses_set_field_back);
    C_NEWXS("Curses::field_back",             XS_Curses_field_back);
    C_NEWXS("Curses::set_field_pad",          XS_Curses_set_field_pad);
    C_NEWXS("Curses::field_pad",              XS_Curses_field_pad);
    C_NEWXS("Curses::set_field_buffer",       XS_Curses_set_field_buffer);
    C_NEWXS("Curses::field_buffer",           XS_Curses_field_buffer);
    C_NEWXS("Curses::set_field_status",       XS_Curses_set_field_status);
    C_NEWXS("Curses::field_status",           XS_Curses_field_status);
    C_NEWXS("Curses::set_max_field",          XS_Curses_set_max_field);
    C_NEWXS("Curses::field_info",             XS_Curses_field_info);
    C_NEWXS("Curses::dynamic_field_info",     XS_Curses_dynamic_field_info);
    C_NEWXS("Curses::set_field_just",         XS_Curses_set_field_just);
    C_NEWXS("Curses::field_just",             XS_Curses_field_just);
    C_NEWXS("Curses::new_field",              XS_Curses_new_field);
    C_NEWXS("Curses::dup_field",              XS_Curses_dup_field);
    C_NEWXS("Curses::link_field",             XS_Curses_link_field);
    C_NEWXS("Curses::free_field",             XS_Curses_free_field);
    C_NEWXS("Curses::set_field_opts",         XS_Curses_set_field_opts);
    C_NEWXS("Curses::field_opts_on",          XS_Curses_field_opts_on);
    C_NEWXS("Curses::field_opts_off",         XS_Curses_field_opts_off);
    C_NEWXS("Curses::field_opts",             XS_Curses_field_opts);
    C_NEWXS("Curses::set_field_userptr",      XS_Curses_set_field_userptr);
    C_NEWXS("Curses::field_userptr",          XS_Curses_field_userptr);
    C_NEWXS("Curses::field_arg",              XS_Curses_field_arg);
    C_NEWXS("Curses::form_request_name",      XS_Curses_form_request_name);
    C_NEWXS("Curses::form_request_by_name",   XS_Curses_form_request_by_name);

#if HAVE_WIDE_XS_FUNCTIONS
    /* Combined Normal/Wide-Character Functions */

    C_NEWXS("Curses::addstring",		XS_CURSES_addstring);
    C_NEWXS("Curses::insstring",		XS_CURSES_insstring);
    C_NEWXS("Curses::instring",			XS_CURSES_instring);
    C_NEWXS("Curses::getchar",			XS_CURSES_getchar);
    C_NEWXS("Curses::ungetchar",		XS_CURSES_ungetchar);
    C_NEWXS("Curses::getstring",		XS_CURSES_getstring);
#endif

    /* Variables masquerading as functions */

    C_NEWXS("Curses::LINES",                  XS_Curses_LINES);
    C_NEWXS("Curses::COLS",                   XS_Curses_COLS);
    C_NEWXS("Curses::stdscr",                 XS_Curses_stdscr);
    C_NEWXS("Curses::curscr",                 XS_Curses_curscr);
    C_NEWXS("Curses::COLORS",                 XS_Curses_COLORS);
    C_NEWXS("Curses::COLOR_PAIRS",            XS_Curses_COLOR_PAIRS);

    /* Variables masquerading as variables */ 

    C_NEWXS("Curses::Vars::DESTROY",          XS_Curses_Vars_DESTROY);
    C_NEWXS("Curses::Vars::FETCH",            XS_Curses_Vars_FETCH);
    C_NEWXS("Curses::Vars::STORE",            XS_Curses_Vars_STORE);
    C_NEWXS("Curses::Vars::TIESCALAR",        XS_Curses_Vars_TIESCALAR);

    /* Constants */

#ifdef ERR
    C_NEWCS("ERR",                            ERR);
#endif
#ifdef OK
    C_NEWCS("OK",                             OK);
#endif
    C_NEWXS("Curses::ACS_BLOCK",              XS_Curses_ACS_BLOCK);
    C_NEWXS("Curses::ACS_BOARD",              XS_Curses_ACS_BOARD);
    C_NEWXS("Curses::ACS_BTEE",               XS_Curses_ACS_BTEE);
    C_NEWXS("Curses::ACS_BULLET",             XS_Curses_ACS_BULLET);
    C_NEWXS("Curses::ACS_CKBOARD",            XS_Curses_ACS_CKBOARD);
    C_NEWXS("Curses::ACS_DARROW",             XS_Curses_ACS_DARROW);
    C_NEWXS("Curses::ACS_DEGREE",             XS_Curses_ACS_DEGREE);
    C_NEWXS("Curses::ACS_DIAMOND",            XS_Curses_ACS_DIAMOND);
    C_NEWXS("Curses::ACS_HLINE",              XS_Curses_ACS_HLINE);
    C_NEWXS("Curses::ACS_LANTERN",            XS_Curses_ACS_LANTERN);
    C_NEWXS("Curses::ACS_LARROW",             XS_Curses_ACS_LARROW);
    C_NEWXS("Curses::ACS_LLCORNER",           XS_Curses_ACS_LLCORNER);
    C_NEWXS("Curses::ACS_LRCORNER",           XS_Curses_ACS_LRCORNER);
    C_NEWXS("Curses::ACS_LTEE",               XS_Curses_ACS_LTEE);
    C_NEWXS("Curses::ACS_PLMINUS",            XS_Curses_ACS_PLMINUS);
    C_NEWXS("Curses::ACS_PLUS",               XS_Curses_ACS_PLUS);
    C_NEWXS("Curses::ACS_RARROW",             XS_Curses_ACS_RARROW);
    C_NEWXS("Curses::ACS_RTEE",               XS_Curses_ACS_RTEE);
    C_NEWXS("Curses::ACS_S1",                 XS_Curses_ACS_S1);
    C_NEWXS("Curses::ACS_S9",                 XS_Curses_ACS_S9);
    C_NEWXS("Curses::ACS_TTEE",               XS_Curses_ACS_TTEE);
    C_NEWXS("Curses::ACS_UARROW",             XS_Curses_ACS_UARROW);
    C_NEWXS("Curses::ACS_ULCORNER",           XS_Curses_ACS_ULCORNER);
    C_NEWXS("Curses::ACS_URCORNER",           XS_Curses_ACS_URCORNER);
    C_NEWXS("Curses::ACS_VLINE",              XS_Curses_ACS_VLINE);
#ifdef A_ALTCHARSET
    C_NEWCS("A_ALTCHARSET",                   A_ALTCHARSET);
#endif
#ifdef A_ATTRIBUTES
    C_NEWCS("A_ATTRIBUTES",                   A_ATTRIBUTES);
#endif
#ifdef A_BLINK
    C_NEWCS("A_BLINK",                        A_BLINK);
#endif
#ifdef A_BOLD
    C_NEWCS("A_BOLD",                         A_BOLD);
#endif
#ifdef A_ITALIC
    C_NEWCS("A_ITALIC",                         A_ITALIC);
#endif
#ifdef A_CHARTEXT
    C_NEWCS("A_CHARTEXT",                     A_CHARTEXT);
#endif
#ifdef A_COLOR
    C_NEWCS("A_COLOR",                        A_COLOR);
#endif
#ifdef A_DIM
    C_NEWCS("A_DIM",                          A_DIM);
#endif
#ifdef A_INVIS
    C_NEWCS("A_INVIS",                        A_INVIS);
#endif
#ifdef A_NORMAL
    C_NEWCS("A_NORMAL",                       A_NORMAL);
#endif
#ifdef A_PROTECT
    C_NEWCS("A_PROTECT",                      A_PROTECT);
#endif
#ifdef A_REVERSE
    C_NEWCS("A_REVERSE",                      A_REVERSE);
#endif
#ifdef A_STANDOUT
    C_NEWCS("A_STANDOUT",                     A_STANDOUT);
#endif
#ifdef A_UNDERLINE
    C_NEWCS("A_UNDERLINE",                    A_UNDERLINE);
#endif
#ifdef COLOR_BLACK
    C_NEWCS("COLOR_BLACK",                    COLOR_BLACK);
#endif
#ifdef COLOR_BLUE
    C_NEWCS("COLOR_BLUE",                     COLOR_BLUE);
#endif
#ifdef COLOR_CYAN
    C_NEWCS("COLOR_CYAN",                     COLOR_CYAN);
#endif
#ifdef COLOR_GREEN
    C_NEWCS("COLOR_GREEN",                    COLOR_GREEN);
#endif
#ifdef COLOR_MAGENTA
    C_NEWCS("COLOR_MAGENTA",                  COLOR_MAGENTA);
#endif
#ifdef COLOR_RED
    C_NEWCS("COLOR_RED",                      COLOR_RED);
#endif
#ifdef COLOR_WHITE
    C_NEWCS("COLOR_WHITE",                    COLOR_WHITE);
#endif
#ifdef COLOR_YELLOW
    C_NEWCS("COLOR_YELLOW",                   COLOR_YELLOW);
#endif
#ifdef KEY_A1
    C_NEWCS("KEY_A1",                         KEY_A1);
#endif
#ifdef KEY_A3
    C_NEWCS("KEY_A3",                         KEY_A3);
#endif
#ifdef KEY_B2
    C_NEWCS("KEY_B2",                         KEY_B2);
#endif
#ifdef KEY_BACKSPACE
    C_NEWCS("KEY_BACKSPACE",                  KEY_BACKSPACE);
#endif
#ifdef KEY_BEG
    C_NEWCS("KEY_BEG",                        KEY_BEG);
#endif
#ifdef KEY_BREAK
    C_NEWCS("KEY_BREAK",                      KEY_BREAK);
#endif
#ifdef KEY_BTAB
    C_NEWCS("KEY_BTAB",                       KEY_BTAB);
#endif
#ifdef KEY_C1
    C_NEWCS("KEY_C1",                         KEY_C1);
#endif
#ifdef KEY_C3
    C_NEWCS("KEY_C3",                         KEY_C3);
#endif
#ifdef KEY_CANCEL
    C_NEWCS("KEY_CANCEL",                     KEY_CANCEL);
#endif
#ifdef KEY_CATAB
    C_NEWCS("KEY_CATAB",                      KEY_CATAB);
#endif
#ifdef KEY_CLEAR
    C_NEWCS("KEY_CLEAR",                      KEY_CLEAR);
#endif
#ifdef KEY_CLOSE
    C_NEWCS("KEY_CLOSE",                      KEY_CLOSE);
#endif
#ifdef KEY_COMMAND
    C_NEWCS("KEY_COMMAND",                    KEY_COMMAND);
#endif
#ifdef KEY_COPY
    C_NEWCS("KEY_COPY",                       KEY_COPY);
#endif
#ifdef KEY_CREATE
    C_NEWCS("KEY_CREATE",                     KEY_CREATE);
#endif
#ifdef KEY_CTAB
    C_NEWCS("KEY_CTAB",                       KEY_CTAB);
#endif
#ifdef KEY_DC
    C_NEWCS("KEY_DC",                         KEY_DC);
#endif
#ifdef KEY_DL
    C_NEWCS("KEY_DL",                         KEY_DL);
#endif
#ifdef KEY_DOWN
    C_NEWCS("KEY_DOWN",                       KEY_DOWN);
#endif
#ifdef KEY_EIC
    C_NEWCS("KEY_EIC",                        KEY_EIC);
#endif
#ifdef KEY_END
    C_NEWCS("KEY_END",                        KEY_END);
#endif
#ifdef KEY_ENTER
    C_NEWCS("KEY_ENTER",                      KEY_ENTER);
#endif
#ifdef KEY_EOL
    C_NEWCS("KEY_EOL",                        KEY_EOL);
#endif
#ifdef KEY_EOS
    C_NEWCS("KEY_EOS",                        KEY_EOS);
#endif
#ifdef KEY_EXIT
    C_NEWCS("KEY_EXIT",                       KEY_EXIT);
#endif
#ifdef KEY_F0
    C_NEWCS("KEY_F0",                         KEY_F0);
#endif
#ifdef KEY_FIND
    C_NEWCS("KEY_FIND",                       KEY_FIND);
#endif
#ifdef KEY_HELP
    C_NEWCS("KEY_HELP",                       KEY_HELP);
#endif
#ifdef KEY_HOME
    C_NEWCS("KEY_HOME",                       KEY_HOME);
#endif
#ifdef KEY_IC
    C_NEWCS("KEY_IC",                         KEY_IC);
#endif
#ifdef KEY_IL
    C_NEWCS("KEY_IL",                         KEY_IL);
#endif
#ifdef KEY_LEFT
    C_NEWCS("KEY_LEFT",                       KEY_LEFT);
#endif
#ifdef KEY_LL
    C_NEWCS("KEY_LL",                         KEY_LL);
#endif
#ifdef KEY_MARK
    C_NEWCS("KEY_MARK",                       KEY_MARK);
#endif
#ifdef KEY_MAX
    C_NEWCS("KEY_MAX",                        KEY_MAX);
#endif
#ifdef KEY_MESSAGE
    C_NEWCS("KEY_MESSAGE",                    KEY_MESSAGE);
#endif
#ifdef KEY_MIN
    C_NEWCS("KEY_MIN",                        KEY_MIN);
#endif
#ifdef KEY_MOVE
    C_NEWCS("KEY_MOVE",                       KEY_MOVE);
#endif
#ifdef KEY_NEXT
    C_NEWCS("KEY_NEXT",                       KEY_NEXT);
#endif
#ifdef KEY_NPAGE
    C_NEWCS("KEY_NPAGE",                      KEY_NPAGE);
#endif
#ifdef KEY_OPEN
    C_NEWCS("KEY_OPEN",                       KEY_OPEN);
#endif
#ifdef KEY_OPTIONS
    C_NEWCS("KEY_OPTIONS",                    KEY_OPTIONS);
#endif
#ifdef KEY_PPAGE
    C_NEWCS("KEY_PPAGE",                      KEY_PPAGE);
#endif
#ifdef KEY_PREVIOUS
    C_NEWCS("KEY_PREVIOUS",                   KEY_PREVIOUS);
#endif
#ifdef KEY_PRINT
    C_NEWCS("KEY_PRINT",                      KEY_PRINT);
#endif
#ifdef KEY_REDO
    C_NEWCS("KEY_REDO",                       KEY_REDO);
#endif
#ifdef KEY_REFERENCE
    C_NEWCS("KEY_REFERENCE",                  KEY_REFERENCE);
#endif
#ifdef KEY_REFRESH
    C_NEWCS("KEY_REFRESH",                    KEY_REFRESH);
#endif
#ifdef KEY_REPLACE
    C_NEWCS("KEY_REPLACE",                    KEY_REPLACE);
#endif
#ifdef KEY_RESET
    C_NEWCS("KEY_RESET",                      KEY_RESET);
#endif
#ifdef KEY_RESTART
    C_NEWCS("KEY_RESTART",                    KEY_RESTART);
#endif
#ifdef KEY_RESUME
    C_NEWCS("KEY_RESUME",                     KEY_RESUME);
#endif
#ifdef KEY_RIGHT
    C_NEWCS("KEY_RIGHT",                      KEY_RIGHT);
#endif
#ifdef KEY_SAVE
    C_NEWCS("KEY_SAVE",                       KEY_SAVE);
#endif
#ifdef KEY_SBEG
    C_NEWCS("KEY_SBEG",                       KEY_SBEG);
#endif
#ifdef KEY_SCANCEL
    C_NEWCS("KEY_SCANCEL",                    KEY_SCANCEL);
#endif
#ifdef KEY_SCOMMAND
    C_NEWCS("KEY_SCOMMAND",                   KEY_SCOMMAND);
#endif
#ifdef KEY_SCOPY
    C_NEWCS("KEY_SCOPY",                      KEY_SCOPY);
#endif
#ifdef KEY_SCREATE
    C_NEWCS("KEY_SCREATE",                    KEY_SCREATE);
#endif
#ifdef KEY_SDC
    C_NEWCS("KEY_SDC",                        KEY_SDC);
#endif
#ifdef KEY_SDL
    C_NEWCS("KEY_SDL",                        KEY_SDL);
#endif
#ifdef KEY_SELECT
    C_NEWCS("KEY_SELECT",                     KEY_SELECT);
#endif
#ifdef KEY_SEND
    C_NEWCS("KEY_SEND",                       KEY_SEND);
#endif
#ifdef KEY_SEOL
    C_NEWCS("KEY_SEOL",                       KEY_SEOL);
#endif
#ifdef KEY_SEXIT
    C_NEWCS("KEY_SEXIT",                      KEY_SEXIT);
#endif
#ifdef KEY_SF
    C_NEWCS("KEY_SF",                         KEY_SF);
#endif
#ifdef KEY_SFIND
    C_NEWCS("KEY_SFIND",                      KEY_SFIND);
#endif
#ifdef KEY_SHELP
    C_NEWCS("KEY_SHELP",                      KEY_SHELP);
#endif
#ifdef KEY_SHOME
    C_NEWCS("KEY_SHOME",                      KEY_SHOME);
#endif
#ifdef KEY_SIC
    C_NEWCS("KEY_SIC",                        KEY_SIC);
#endif
#ifdef KEY_SLEFT
    C_NEWCS("KEY_SLEFT",                      KEY_SLEFT);
#endif
#ifdef KEY_SMESSAGE
    C_NEWCS("KEY_SMESSAGE",                   KEY_SMESSAGE);
#endif
#ifdef KEY_SMOVE
    C_NEWCS("KEY_SMOVE",                      KEY_SMOVE);
#endif
#ifdef KEY_SNEXT
    C_NEWCS("KEY_SNEXT",                      KEY_SNEXT);
#endif
#ifdef KEY_SOPTIONS
    C_NEWCS("KEY_SOPTIONS",                   KEY_SOPTIONS);
#endif
#ifdef KEY_SPREVIOUS
    C_NEWCS("KEY_SPREVIOUS",                  KEY_SPREVIOUS);
#endif
#ifdef KEY_SPRINT
    C_NEWCS("KEY_SPRINT",                     KEY_SPRINT);
#endif
#ifdef KEY_SR
    C_NEWCS("KEY_SR",                         KEY_SR);
#endif
#ifdef KEY_SREDO
    C_NEWCS("KEY_SREDO",                      KEY_SREDO);
#endif
#ifdef KEY_SREPLACE
    C_NEWCS("KEY_SREPLACE",                   KEY_SREPLACE);
#endif
#ifdef KEY_SRESET
    C_NEWCS("KEY_SRESET",                     KEY_SRESET);
#endif
#ifdef KEY_SRIGHT
    C_NEWCS("KEY_SRIGHT",                     KEY_SRIGHT);
#endif
#ifdef KEY_SRSUME
    C_NEWCS("KEY_SRSUME",                     KEY_SRSUME);
#endif
#ifdef KEY_SSAVE
    C_NEWCS("KEY_SSAVE",                      KEY_SSAVE);
#endif
#ifdef KEY_SSUSPEND
    C_NEWCS("KEY_SSUSPEND",                   KEY_SSUSPEND);
#endif
#ifdef KEY_STAB
    C_NEWCS("KEY_STAB",                       KEY_STAB);
#endif
#ifdef KEY_SUNDO
    C_NEWCS("KEY_SUNDO",                      KEY_SUNDO);
#endif
#ifdef KEY_SUSPEND
    C_NEWCS("KEY_SUSPEND",                    KEY_SUSPEND);
#endif
#ifdef KEY_UNDO
    C_NEWCS("KEY_UNDO",                       KEY_UNDO);
#endif
#ifdef KEY_UP
    C_NEWCS("KEY_UP",                         KEY_UP);
#endif
#ifdef KEY_MOUSE
    C_NEWCS("KEY_MOUSE",                      KEY_MOUSE);
#endif
#ifdef KEY_RESIZE
    C_NEWCS("KEY_RESIZE",                     KEY_RESIZE);
#endif
#ifdef KEY_EVENT
    C_NEWCS("KEY_EVENT",                      KEY_EVENT);
#endif
#ifdef BUTTON1_RELEASED
    C_NEWCS("BUTTON1_RELEASED",               BUTTON1_RELEASED);
#endif
#ifdef BUTTON1_PRESSED
    C_NEWCS("BUTTON1_PRESSED",                BUTTON1_PRESSED);
#endif
#ifdef BUTTON1_CLICKED
    C_NEWCS("BUTTON1_CLICKED",                BUTTON1_CLICKED);
#endif
#ifdef BUTTON1_DOUBLE_CLICKED
    C_NEWCS("BUTTON1_DOUBLE_CLICKED",         BUTTON1_DOUBLE_CLICKED);
#endif
#ifdef BUTTON1_TRIPLE_CLICKED
    C_NEWCS("BUTTON1_TRIPLE_CLICKED",         BUTTON1_TRIPLE_CLICKED);
#endif
#ifdef BUTTON1_RESERVED_EVENT
    C_NEWCS("BUTTON1_RESERVED_EVENT",         BUTTON1_RESERVED_EVENT);
#endif
#ifdef BUTTON2_RELEASED
    C_NEWCS("BUTTON2_RELEASED",               BUTTON2_RELEASED);
#endif
#ifdef BUTTON2_PRESSED
    C_NEWCS("BUTTON2_PRESSED",                BUTTON2_PRESSED);
#endif
#ifdef BUTTON2_CLICKED
    C_NEWCS("BUTTON2_CLICKED",                BUTTON2_CLICKED);
#endif
#ifdef BUTTON2_DOUBLE_CLICKED
    C_NEWCS("BUTTON2_DOUBLE_CLICKED",         BUTTON2_DOUBLE_CLICKED);
#endif
#ifdef BUTTON2_TRIPLE_CLICKED
    C_NEWCS("BUTTON2_TRIPLE_CLICKED",         BUTTON2_TRIPLE_CLICKED);
#endif
#ifdef BUTTON2_RESERVED_EVENT
    C_NEWCS("BUTTON2_RESERVED_EVENT",         BUTTON2_RESERVED_EVENT);
#endif
#ifdef BUTTON3_RELEASED
    C_NEWCS("BUTTON3_RELEASED",               BUTTON3_RELEASED);
#endif
#ifdef BUTTON3_PRESSED
    C_NEWCS("BUTTON3_PRESSED",                BUTTON3_PRESSED);
#endif
#ifdef BUTTON3_CLICKED
    C_NEWCS("BUTTON3_CLICKED",                BUTTON3_CLICKED);
#endif
#ifdef BUTTON3_DOUBLE_CLICKED
    C_NEWCS("BUTTON3_DOUBLE_CLICKED",         BUTTON3_DOUBLE_CLICKED);
#endif
#ifdef BUTTON3_TRIPLE_CLICKED
    C_NEWCS("BUTTON3_TRIPLE_CLICKED",         BUTTON3_TRIPLE_CLICKED);
#endif
#ifdef BUTTON3_RESERVED_EVENT
    C_NEWCS("BUTTON3_RESERVED_EVENT",         BUTTON3_RESERVED_EVENT);
#endif
#ifdef BUTTON4_RELEASED
    C_NEWCS("BUTTON4_RELEASED",               BUTTON4_RELEASED);
#endif
#ifdef BUTTON4_PRESSED
    C_NEWCS("BUTTON4_PRESSED",                BUTTON4_PRESSED);
#endif
#ifdef BUTTON4_CLICKED
    C_NEWCS("BUTTON4_CLICKED",                BUTTON4_CLICKED);
#endif
#ifdef BUTTON4_DOUBLE_CLICKED
    C_NEWCS("BUTTON4_DOUBLE_CLICKED",         BUTTON4_DOUBLE_CLICKED);
#endif
#ifdef BUTTON4_TRIPLE_CLICKED
    C_NEWCS("BUTTON4_TRIPLE_CLICKED",         BUTTON4_TRIPLE_CLICKED);
#endif
#ifdef BUTTON4_RESERVED_EVENT
    C_NEWCS("BUTTON4_RESERVED_EVENT",         BUTTON4_RESERVED_EVENT);
#endif
#ifdef BUTTON_CTRL
    C_NEWCS("BUTTON_CTRL",                    BUTTON_CTRL);
#endif
#ifdef BUTTON_SHIFT
    C_NEWCS("BUTTON_SHIFT",                   BUTTON_SHIFT);
#endif
#ifdef BUTTON_ALT
    C_NEWCS("BUTTON_ALT",                     BUTTON_ALT);
#endif
#ifdef ALL_MOUSE_EVENTS
    C_NEWCS("ALL_MOUSE_EVENTS",               ALL_MOUSE_EVENTS);
#endif
#ifdef REPORT_MOUSE_POSITION
    C_NEWCS("REPORT_MOUSE_POSITION",          REPORT_MOUSE_POSITION);
#endif
#ifdef NCURSES_MOUSE_VERSION
    C_NEWCS("NCURSES_MOUSE_VERSION",          NCURSES_MOUSE_VERSION);
#endif
#ifdef E_OK
    C_NEWCS("E_OK",                           E_OK);
#endif
#ifdef E_SYSTEM_ERROR
    C_NEWCS("E_SYSTEM_ERROR",                 E_SYSTEM_ERROR);
#endif
#ifdef E_BAD_ARGUMENT
    C_NEWCS("E_BAD_ARGUMENT",                 E_BAD_ARGUMENT);
#endif
#ifdef E_POSTED
    C_NEWCS("E_POSTED",                       E_POSTED);
#endif
#ifdef E_CONNECTED
    C_NEWCS("E_CONNECTED",                    E_CONNECTED);
#endif
#ifdef E_BAD_STATE
    C_NEWCS("E_BAD_STATE",                    E_BAD_STATE);
#endif
#ifdef E_NO_ROOM
    C_NEWCS("E_NO_ROOM",                      E_NO_ROOM);
#endif
#ifdef E_NOT_POSTED
    C_NEWCS("E_NOT_POSTED",                   E_NOT_POSTED);
#endif
#ifdef E_UNKNOWN_COMMAND
    C_NEWCS("E_UNKNOWN_COMMAND",              E_UNKNOWN_COMMAND);
#endif
#ifdef E_NO_MATCH
    C_NEWCS("E_NO_MATCH",                     E_NO_MATCH);
#endif
#ifdef E_NOT_SELECTABLE
    C_NEWCS("E_NOT_SELECTABLE",               E_NOT_SELECTABLE);
#endif
#ifdef E_NOT_CONNECTED
    C_NEWCS("E_NOT_CONNECTED",                E_NOT_CONNECTED);
#endif
#ifdef E_REQUEST_DENIED
    C_NEWCS("E_REQUEST_DENIED",               E_REQUEST_DENIED);
#endif
#ifdef E_INVALID_FIELD
    C_NEWCS("E_INVALID_FIELD",                E_INVALID_FIELD);
#endif
#ifdef E_CURRENT
    C_NEWCS("E_CURRENT",                      E_CURRENT);
#endif
#ifdef REQ_LEFT_ITEM
    C_NEWCS("REQ_LEFT_ITEM",                  REQ_LEFT_ITEM);
#endif
#ifdef REQ_RIGHT_ITEM
    C_NEWCS("REQ_RIGHT_ITEM",                 REQ_RIGHT_ITEM);
#endif
#ifdef REQ_UP_ITEM
    C_NEWCS("REQ_UP_ITEM",                    REQ_UP_ITEM);
#endif
#ifdef REQ_DOWN_ITEM
    C_NEWCS("REQ_DOWN_ITEM",                  REQ_DOWN_ITEM);
#endif
#ifdef REQ_SCR_ULINE
    C_NEWCS("REQ_SCR_ULINE",                  REQ_SCR_ULINE);
#endif
#ifdef REQ_SCR_DLINE
    C_NEWCS("REQ_SCR_DLINE",                  REQ_SCR_DLINE);
#endif
#ifdef REQ_SCR_DPAGE
    C_NEWCS("REQ_SCR_DPAGE",                  REQ_SCR_DPAGE);
#endif
#ifdef REQ_SCR_UPAGE
    C_NEWCS("REQ_SCR_UPAGE",                  REQ_SCR_UPAGE);
#endif
#ifdef REQ_FIRST_ITEM
    C_NEWCS("REQ_FIRST_ITEM",                 REQ_FIRST_ITEM);
#endif
#ifdef REQ_LAST_ITEM
    C_NEWCS("REQ_LAST_ITEM",                  REQ_LAST_ITEM);
#endif
#ifdef REQ_NEXT_ITEM
    C_NEWCS("REQ_NEXT_ITEM",                  REQ_NEXT_ITEM);
#endif
#ifdef REQ_PREV_ITEM
    C_NEWCS("REQ_PREV_ITEM",                  REQ_PREV_ITEM);
#endif
#ifdef REQ_TOGGLE_ITEM
    C_NEWCS("REQ_TOGGLE_ITEM",                REQ_TOGGLE_ITEM);
#endif
#ifdef REQ_CLEAR_PATTERN
    C_NEWCS("REQ_CLEAR_PATTERN",              REQ_CLEAR_PATTERN);
#endif
#ifdef REQ_BACK_PATTERN
    C_NEWCS("REQ_BACK_PATTERN",               REQ_BACK_PATTERN);
#endif
#ifdef REQ_NEXT_MATCH
    C_NEWCS("REQ_NEXT_MATCH",                 REQ_NEXT_MATCH);
#endif
#ifdef REQ_PREV_MATCH
    C_NEWCS("REQ_PREV_MATCH",                 REQ_PREV_MATCH);
#endif
#ifdef MIN_MENU_COMMAND
    C_NEWCS("MIN_MENU_COMMAND",               MIN_MENU_COMMAND);
#endif
#ifdef MAX_MENU_COMMAND
    C_NEWCS("MAX_MENU_COMMAND",               MAX_MENU_COMMAND);
#endif
#ifdef O_ONEVALUE
    C_NEWCS("O_ONEVALUE",                     O_ONEVALUE);
#endif
#ifdef O_SHOWDESC
    C_NEWCS("O_SHOWDESC",                     O_SHOWDESC);
#endif
#ifdef O_ROWMAJOR
    C_NEWCS("O_ROWMAJOR",                     O_ROWMAJOR);
#endif
#ifdef O_IGNORECASE
    C_NEWCS("O_IGNORECASE",                   O_IGNORECASE);
#endif
#ifdef O_SHOWMATCH
    C_NEWCS("O_SHOWMATCH",                    O_SHOWMATCH);
#endif
#ifdef O_NONCYCLIC
    C_NEWCS("O_NONCYCLIC",                    O_NONCYCLIC);
#endif
#ifdef O_SELECTABLE
    C_NEWCS("O_SELECTABLE",                   O_SELECTABLE);
#endif
#ifdef REQ_NEXT_PAGE
    C_NEWCS("REQ_NEXT_PAGE",                  REQ_NEXT_PAGE);
#endif
#ifdef REQ_PREV_PAGE
    C_NEWCS("REQ_PREV_PAGE",                  REQ_PREV_PAGE);
#endif
#ifdef REQ_FIRST_PAGE
    C_NEWCS("REQ_FIRST_PAGE",                 REQ_FIRST_PAGE);
#endif
#ifdef REQ_LAST_PAGE
    C_NEWCS("REQ_LAST_PAGE",                  REQ_LAST_PAGE);
#endif
#ifdef REQ_NEXT_FIELD
    C_NEWCS("REQ_NEXT_FIELD",                 REQ_NEXT_FIELD);
#endif
#ifdef REQ_PREV_FIELD
    C_NEWCS("REQ_PREV_FIELD",                 REQ_PREV_FIELD);
#endif
#ifdef REQ_FIRST_FIELD
    C_NEWCS("REQ_FIRST_FIELD",                REQ_FIRST_FIELD);
#endif
#ifdef REQ_LAST_FIELD
    C_NEWCS("REQ_LAST_FIELD",                 REQ_LAST_FIELD);
#endif
#ifdef REQ_SNEXT_FIELD
    C_NEWCS("REQ_SNEXT_FIELD",                REQ_SNEXT_FIELD);
#endif
#ifdef REQ_SPREV_FIELD
    C_NEWCS("REQ_SPREV_FIELD",                REQ_SPREV_FIELD);
#endif
#ifdef REQ_SFIRST_FIELD
    C_NEWCS("REQ_SFIRST_FIELD",               REQ_SFIRST_FIELD);
#endif
#ifdef REQ_SLAST_FIELD
    C_NEWCS("REQ_SLAST_FIELD",                REQ_SLAST_FIELD);
#endif
#ifdef REQ_LEFT_FIELD
    C_NEWCS("REQ_LEFT_FIELD",                 REQ_LEFT_FIELD);
#endif
#ifdef REQ_RIGHT_FIELD
    C_NEWCS("REQ_RIGHT_FIELD",                REQ_RIGHT_FIELD);
#endif
#ifdef REQ_UP_FIELD
    C_NEWCS("REQ_UP_FIELD",                   REQ_UP_FIELD);
#endif
#ifdef REQ_DOWN_FIELD
    C_NEWCS("REQ_DOWN_FIELD",                 REQ_DOWN_FIELD);
#endif
#ifdef REQ_NEXT_CHAR
    C_NEWCS("REQ_NEXT_CHAR",                  REQ_NEXT_CHAR);
#endif
#ifdef REQ_PREV_CHAR
    C_NEWCS("REQ_PREV_CHAR",                  REQ_PREV_CHAR);
#endif
#ifdef REQ_NEXT_LINE
    C_NEWCS("REQ_NEXT_LINE",                  REQ_NEXT_LINE);
#endif
#ifdef REQ_PREV_LINE
    C_NEWCS("REQ_PREV_LINE",                  REQ_PREV_LINE);
#endif
#ifdef REQ_NEXT_WORD
    C_NEWCS("REQ_NEXT_WORD",                  REQ_NEXT_WORD);
#endif
#ifdef REQ_PREV_WORD
    C_NEWCS("REQ_PREV_WORD",                  REQ_PREV_WORD);
#endif
#ifdef REQ_BEG_FIELD
    C_NEWCS("REQ_BEG_FIELD",                  REQ_BEG_FIELD);
#endif
#ifdef REQ_END_FIELD
    C_NEWCS("REQ_END_FIELD",                  REQ_END_FIELD);
#endif
#ifdef REQ_BEG_LINE
    C_NEWCS("REQ_BEG_LINE",                   REQ_BEG_LINE);
#endif
#ifdef REQ_END_LINE
    C_NEWCS("REQ_END_LINE",                   REQ_END_LINE);
#endif
#ifdef REQ_LEFT_CHAR
    C_NEWCS("REQ_LEFT_CHAR",                  REQ_LEFT_CHAR);
#endif
#ifdef REQ_RIGHT_CHAR
    C_NEWCS("REQ_RIGHT_CHAR",                 REQ_RIGHT_CHAR);
#endif
#ifdef REQ_UP_CHAR
    C_NEWCS("REQ_UP_CHAR",                    REQ_UP_CHAR);
#endif
#ifdef REQ_DOWN_CHAR
    C_NEWCS("REQ_DOWN_CHAR",                  REQ_DOWN_CHAR);
#endif
#ifdef REQ_NEW_LINE
    C_NEWCS("REQ_NEW_LINE",                   REQ_NEW_LINE);
#endif
#ifdef REQ_INS_CHAR
    C_NEWCS("REQ_INS_CHAR",                   REQ_INS_CHAR);
#endif
#ifdef REQ_INS_LINE
    C_NEWCS("REQ_INS_LINE",                   REQ_INS_LINE);
#endif
#ifdef REQ_DEL_CHAR
    C_NEWCS("REQ_DEL_CHAR",                   REQ_DEL_CHAR);
#endif
#ifdef REQ_DEL_PREV
    C_NEWCS("REQ_DEL_PREV",                   REQ_DEL_PREV);
#endif
#ifdef REQ_DEL_LINE
    C_NEWCS("REQ_DEL_LINE",                   REQ_DEL_LINE);
#endif
#ifdef REQ_DEL_WORD
    C_NEWCS("REQ_DEL_WORD",                   REQ_DEL_WORD);
#endif
#ifdef REQ_CLR_EOL
    C_NEWCS("REQ_CLR_EOL",                    REQ_CLR_EOL);
#endif
#ifdef REQ_CLR_EOF
    C_NEWCS("REQ_CLR_EOF",                    REQ_CLR_EOF);
#endif
#ifdef REQ_CLR_FIELD
    C_NEWCS("REQ_CLR_FIELD",                  REQ_CLR_FIELD);
#endif
#ifdef REQ_OVL_MODE
    C_NEWCS("REQ_OVL_MODE",                   REQ_OVL_MODE);
#endif
#ifdef REQ_INS_MODE
    C_NEWCS("REQ_INS_MODE",                   REQ_INS_MODE);
#endif
#ifdef REQ_SCR_FLINE
    C_NEWCS("REQ_SCR_FLINE",                  REQ_SCR_FLINE);
#endif
#ifdef REQ_SCR_BLINE
    C_NEWCS("REQ_SCR_BLINE",                  REQ_SCR_BLINE);
#endif
#ifdef REQ_SCR_FPAGE
    C_NEWCS("REQ_SCR_FPAGE",                  REQ_SCR_FPAGE);
#endif
#ifdef REQ_SCR_BPAGE
    C_NEWCS("REQ_SCR_BPAGE",                  REQ_SCR_BPAGE);
#endif
#ifdef REQ_SCR_FHPAGE
    C_NEWCS("REQ_SCR_FHPAGE",                 REQ_SCR_FHPAGE);
#endif
#ifdef REQ_SCR_BHPAGE
    C_NEWCS("REQ_SCR_BHPAGE",                 REQ_SCR_BHPAGE);
#endif
#ifdef REQ_SCR_FCHAR
    C_NEWCS("REQ_SCR_FCHAR",                  REQ_SCR_FCHAR);
#endif
#ifdef REQ_SCR_BCHAR
    C_NEWCS("REQ_SCR_BCHAR",                  REQ_SCR_BCHAR);
#endif
#ifdef REQ_SCR_HFLINE
    C_NEWCS("REQ_SCR_HFLINE",                 REQ_SCR_HFLINE);
#endif
#ifdef REQ_SCR_HBLINE
    C_NEWCS("REQ_SCR_HBLINE",                 REQ_SCR_HBLINE);
#endif
#ifdef REQ_SCR_HFHALF
    C_NEWCS("REQ_SCR_HFHALF",                 REQ_SCR_HFHALF);
#endif
#ifdef REQ_SCR_HBHALF
    C_NEWCS("REQ_SCR_HBHALF",                 REQ_SCR_HBHALF);
#endif
#ifdef REQ_VALIDATION
    C_NEWCS("REQ_VALIDATION",                 REQ_VALIDATION);
#endif
#ifdef REQ_NEXT_CHOICE
    C_NEWCS("REQ_NEXT_CHOICE",                REQ_NEXT_CHOICE);
#endif
#ifdef REQ_PREV_CHOICE
    C_NEWCS("REQ_PREV_CHOICE",                REQ_PREV_CHOICE);
#endif
#ifdef MIN_FORM_COMMAND
    C_NEWCS("MIN_FORM_COMMAND",               MIN_FORM_COMMAND);
#endif
#ifdef MAX_FORM_COMMAND
    C_NEWCS("MAX_FORM_COMMAND",               MAX_FORM_COMMAND);
#endif
#ifdef NO_JUSTIFICATION
    C_NEWCS("NO_JUSTIFICATION",               NO_JUSTIFICATION);
#endif
#ifdef JUSTIFY_LEFT
    C_NEWCS("JUSTIFY_LEFT",                   JUSTIFY_LEFT);
#endif
#ifdef JUSTIFY_CENTER
    C_NEWCS("JUSTIFY_CENTER",                 JUSTIFY_CENTER);
#endif
#ifdef JUSTIFY_RIGHT
    C_NEWCS("JUSTIFY_RIGHT",                  JUSTIFY_RIGHT);
#endif
#ifdef O_VISIBLE
    C_NEWCS("O_VISIBLE",                      O_VISIBLE);
#endif
#ifdef O_ACTIVE
    C_NEWCS("O_ACTIVE",                       O_ACTIVE);
#endif
#ifdef O_PUBLIC
    C_NEWCS("O_PUBLIC",                       O_PUBLIC);
#endif
#ifdef O_EDIT
    C_NEWCS("O_EDIT",                         O_EDIT);
#endif
#ifdef O_WRAP
    C_NEWCS("O_WRAP",                         O_WRAP);
#endif
#ifdef O_BLANK
    C_NEWCS("O_BLANK",                        O_BLANK);
#endif
#ifdef O_AUTOSKIP
    C_NEWCS("O_AUTOSKIP",                     O_AUTOSKIP);
#endif
#ifdef O_NULLOK
    C_NEWCS("O_NULLOK",                       O_NULLOK);
#endif
#ifdef O_PASSOK
    C_NEWCS("O_PASSOK",                       O_PASSOK);
#endif
#ifdef O_STATIC
    C_NEWCS("O_STATIC",                       O_STATIC);
#endif
#ifdef O_NL_OVERLOAD
    C_NEWCS("O_NL_OVERLOAD",                  O_NL_OVERLOAD);
#endif
#ifdef O_BS_OVERLOAD
    C_NEWCS("O_BS_OVERLOAD",                  O_BS_OVERLOAD);
#endif

    /* traceon(); */
    ST(0) = &PL_sv_yes;
    XSRETURN(1);
}
