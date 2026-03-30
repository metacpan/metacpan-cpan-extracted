/*
 * webview-tray-win32.c — Windows system tray (Shell_NotifyIcon) backend
 *
 * Uses the Win32 Shell notification API with popup menus.
 */

#define WM_TRAYICON (WM_USER + 1)

struct webview_tray_win32 {
  NOTIFYICONDATAA nid;
  HMENU menu;
  HWND msg_hwnd;
};

/* Forward */
static LRESULT CALLBACK tray_wndproc(HWND hwnd, UINT msg, WPARAM wParam,
                                     LPARAM lParam);

static HMENU tray_win32_build_menu(struct webview_tray *t,
                                    struct webview_tray_item *items,
                                    int count) {
  HMENU menu = CreatePopupMenu();
  for (int i = 0; i < count; i++) {
    struct webview_tray_item *it = &items[i];
    if (it->is_separator) {
      AppendMenuA(menu, MF_SEPARATOR, 0, NULL);
      continue;
    }

    UINT flags = MF_STRING;
    if (it->is_disabled) flags |= MF_GRAYED;
    if (it->is_checked) flags |= MF_CHECKED;

    if (it->submenu_count > 0 && it->submenu) {
      HMENU sub = tray_win32_build_menu(t, it->submenu, it->submenu_count);
      AppendMenuA(menu, flags | MF_POPUP, (UINT_PTR)sub,
                  it->label ? it->label : "");
    } else {
      AppendMenuA(menu, flags, (UINT_PTR)it->id,
                  it->label ? it->label : "");
    }
  }
  return menu;
}

static LRESULT CALLBACK tray_wndproc(HWND hwnd, UINT msg, WPARAM wParam,
                                     LPARAM lParam) {
  struct webview_tray *t = (struct webview_tray *)
      GetWindowLongPtr(hwnd, GWLP_USERDATA);

  if (msg == WM_TRAYICON) {
    if (LOWORD(lParam) == WM_RBUTTONUP || LOWORD(lParam) == WM_LBUTTONUP) {
      struct webview_tray_win32 *priv = (struct webview_tray_win32 *)t->_priv;
      POINT pt;
      GetCursorPos(&pt);
      SetForegroundWindow(hwnd);
      int cmd = TrackPopupMenu(priv->menu,
                               TPM_RETURNCMD | TPM_NONOTIFY,
                               pt.x, pt.y, 0, hwnd, NULL);
      SendMessage(hwnd, WM_NULL, 0, 0);
      if (cmd > 0 && t->menu_cb) {
        t->menu_cb(t->w, cmd);
      }
    }
    return 0;
  }
  return DefWindowProc(hwnd, msg, wParam, lParam);
}

WEBVIEW_API int webview_tray_create(struct webview_tray *t) {
  struct webview_tray_win32 *priv = (struct webview_tray_win32 *)
      calloc(1, sizeof(*priv));
  if (!priv) return -1;
  t->_priv = priv;

  /* Register a hidden message-only window class for tray messages */
  static int tray_class_registered = 0;
  HINSTANCE hInst = GetModuleHandle(NULL);
  if (!tray_class_registered) {
    WNDCLASSEXA wc;
    ZeroMemory(&wc, sizeof(wc));
    wc.cbSize = sizeof(wc);
    wc.lpfnWndProc = tray_wndproc;
    wc.hInstance = hInst;
    wc.lpszClassName = "Chandra_TrayMsg";
    RegisterClassExA(&wc);
    tray_class_registered = 1;
  }

  priv->msg_hwnd = CreateWindowExA(0, "Chandra_TrayMsg", "", 0,
                                    0, 0, 0, 0,
                                    HWND_MESSAGE, NULL, hInst, NULL);
  SetWindowLongPtr(priv->msg_hwnd, GWLP_USERDATA, (LONG_PTR)t);

  /* Set up NOTIFYICONDATA */
  ZeroMemory(&priv->nid, sizeof(priv->nid));
  priv->nid.cbSize = sizeof(priv->nid);
  priv->nid.hWnd = priv->msg_hwnd;
  priv->nid.uID = 1;
  priv->nid.uFlags = NIF_ICON | NIF_MESSAGE | NIF_TIP;
  priv->nid.uCallbackMessage = WM_TRAYICON;

  /* Load icon */
  if (t->icon_path && strlen(t->icon_path) > 0) {
    priv->nid.hIcon = (HICON)LoadImageA(NULL, t->icon_path,
                                         IMAGE_ICON, 0, 0,
                                         LR_LOADFROMFILE | LR_DEFAULTSIZE);
  }
  if (!priv->nid.hIcon) {
    priv->nid.hIcon = LoadIcon(NULL, IDI_APPLICATION);
  }

  /* Tooltip */
  if (t->tooltip) {
    strncpy(priv->nid.szTip, t->tooltip, sizeof(priv->nid.szTip) - 1);
  }

  Shell_NotifyIconA(NIM_ADD, &priv->nid);

  /* Build menu */
  priv->menu = tray_win32_build_menu(t, t->items, t->item_count);

  return 0;
}

WEBVIEW_API void webview_tray_update(struct webview_tray *t) {
  if (!t || !t->_priv) return;
  struct webview_tray_win32 *priv = (struct webview_tray_win32 *)t->_priv;

  /* Update tooltip */
  if (t->tooltip) {
    strncpy(priv->nid.szTip, t->tooltip, sizeof(priv->nid.szTip) - 1);
  }

  /* Update icon */
  if (t->icon_path && strlen(t->icon_path) > 0) {
    HICON newicon = (HICON)LoadImageA(NULL, t->icon_path,
                                       IMAGE_ICON, 0, 0,
                                       LR_LOADFROMFILE | LR_DEFAULTSIZE);
    if (newicon) {
      priv->nid.hIcon = newicon;
    }
  }

  Shell_NotifyIconA(NIM_MODIFY, &priv->nid);

  /* Rebuild menu */
  if (priv->menu) {
    DestroyMenu(priv->menu);
  }
  priv->menu = tray_win32_build_menu(t, t->items, t->item_count);
}

WEBVIEW_API void webview_tray_destroy(struct webview_tray *t) {
  if (!t || !t->_priv) return;
  struct webview_tray_win32 *priv = (struct webview_tray_win32 *)t->_priv;

  Shell_NotifyIconA(NIM_DELETE, &priv->nid);
  if (priv->menu) {
    DestroyMenu(priv->menu);
  }
  if (priv->msg_hwnd) {
    DestroyWindow(priv->msg_hwnd);
  }
  free(priv);
  t->_priv = NULL;
}
