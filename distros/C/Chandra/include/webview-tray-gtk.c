/*
 * webview-tray-gtk.c — Linux system tray (GtkStatusIcon) backend
 *
 * Uses GtkStatusIcon (deprecated but widely supported) with GtkMenu.
 * Falls back gracefully if no system tray is available.
 */

struct webview_tray_gtk {
  GtkStatusIcon *icon;
  GtkWidget *menu;
};

/* Forward */
static void tray_gtk_activate(GtkStatusIcon *icon, gpointer user_data);
static void tray_gtk_popup(GtkStatusIcon *icon, guint button,
                           guint activate_time, gpointer user_data);

/* Menu item activation callback */
static void tray_gtk_menu_item_activated(GtkMenuItem *menuitem,
                                         gpointer user_data) {
  int *item_data = (int *)user_data;
  /* item_data[0] = item_id, item_data[1..] = pointer to tray */
  /* We pack item_id and tray pointer together */
  (void)menuitem;
  /* This approach is fragile. Instead, use g_object_set_data. */
}

/* Alternative: use g_object_set_data to attach callback info */
struct tray_gtk_cb_data {
  struct webview_tray *tray;
  int item_id;
};

static void tray_gtk_item_activated(GtkMenuItem *menuitem, gpointer data) {
  (void)menuitem;
  struct tray_gtk_cb_data *cb = (struct tray_gtk_cb_data *)data;
  if (cb && cb->tray && cb->tray->menu_cb) {
    cb->tray->menu_cb(cb->tray->w, cb->item_id);
  }
}

static GtkWidget *tray_gtk_build_menu(struct webview_tray *t,
                                       struct webview_tray_item *items,
                                       int count) {
  GtkWidget *menu = gtk_menu_new();
  for (int i = 0; i < count; i++) {
    struct webview_tray_item *it = &items[i];
    GtkWidget *mi;

    if (it->is_separator) {
      mi = gtk_separator_menu_item_new();
    } else if (it->is_checked) {
      mi = gtk_check_menu_item_new_with_label(it->label ? it->label : "");
      gtk_check_menu_item_set_active(GTK_CHECK_MENU_ITEM(mi), TRUE);
    } else {
      mi = gtk_menu_item_new_with_label(it->label ? it->label : "");
    }

    if (it->is_disabled) {
      gtk_widget_set_sensitive(mi, FALSE);
    }

    if (it->submenu_count > 0 && it->submenu && !it->is_separator) {
      GtkWidget *sub = tray_gtk_build_menu(t, it->submenu, it->submenu_count);
      gtk_menu_item_set_submenu(GTK_MENU_ITEM(mi), sub);
    } else if (!it->is_separator) {
      /* Connect signal for leaf items */
      struct tray_gtk_cb_data *cb = (struct tray_gtk_cb_data *)
          g_malloc(sizeof(struct tray_gtk_cb_data));
      cb->tray = t;
      cb->item_id = it->id;
      g_signal_connect_data(G_OBJECT(mi), "activate",
                            G_CALLBACK(tray_gtk_item_activated),
                            cb, (GClosureNotify)g_free, 0);
    }

    gtk_menu_shell_append(GTK_MENU_SHELL(menu), mi);
  }
  gtk_widget_show_all(menu);
  return menu;
}

static void tray_gtk_activate(GtkStatusIcon *icon, gpointer user_data) {
  (void)icon;
  struct webview_tray *t = (struct webview_tray *)user_data;
  /* Left click — invoke item 0 if it exists, or just show menu */
  if (t->menu_cb && t->item_count > 0) {
    t->menu_cb(t->w, -1); /* -1 = tray icon clicked */
  }
}

static void tray_gtk_popup(GtkStatusIcon *icon, guint button,
                           guint activate_time, gpointer user_data) {
  struct webview_tray *t = (struct webview_tray *)user_data;
  struct webview_tray_gtk *priv = (struct webview_tray_gtk *)t->_priv;
  if (priv->menu) {
    gtk_menu_popup(GTK_MENU(priv->menu), NULL, NULL,
                   gtk_status_icon_position_menu, icon, button, activate_time);
  }
}

WEBVIEW_API int webview_tray_create(struct webview_tray *t) {
  struct webview_tray_gtk *priv = (struct webview_tray_gtk *)
      calloc(1, sizeof(*priv));
  if (!priv) return -1;
  t->_priv = priv;

  /* Create status icon */
  if (t->icon_path && strlen(t->icon_path) > 0) {
    priv->icon = gtk_status_icon_new_from_file(t->icon_path);
  } else {
    priv->icon = gtk_status_icon_new_from_stock(GTK_STOCK_INFO);
  }

  if (t->tooltip) {
    gtk_status_icon_set_tooltip_text(priv->icon, t->tooltip);
  }

  gtk_status_icon_set_visible(priv->icon, TRUE);

  /* Build context menu */
  priv->menu = tray_gtk_build_menu(t, t->items, t->item_count);

  /* Connect signals */
  g_signal_connect(G_OBJECT(priv->icon), "activate",
                   G_CALLBACK(tray_gtk_activate), t);
  g_signal_connect(G_OBJECT(priv->icon), "popup-menu",
                   G_CALLBACK(tray_gtk_popup), t);

  return 0;
}

WEBVIEW_API void webview_tray_update(struct webview_tray *t) {
  if (!t || !t->_priv) return;
  struct webview_tray_gtk *priv = (struct webview_tray_gtk *)t->_priv;

  /* Update icon */
  if (t->icon_path && strlen(t->icon_path) > 0) {
    gtk_status_icon_set_from_file(priv->icon, t->icon_path);
  }

  /* Update tooltip */
  if (t->tooltip) {
    gtk_status_icon_set_tooltip_text(priv->icon, t->tooltip);
  }

  /* Rebuild menu */
  if (priv->menu) {
    gtk_widget_destroy(priv->menu);
  }
  priv->menu = tray_gtk_build_menu(t, t->items, t->item_count);
}

WEBVIEW_API void webview_tray_destroy(struct webview_tray *t) {
  if (!t || !t->_priv) return;
  struct webview_tray_gtk *priv = (struct webview_tray_gtk *)t->_priv;

  if (priv->menu) {
    gtk_widget_destroy(priv->menu);
  }
  if (priv->icon) {
    gtk_status_icon_set_visible(priv->icon, FALSE);
    g_object_unref(priv->icon);
  }
  free(priv);
  t->_priv = NULL;
}
