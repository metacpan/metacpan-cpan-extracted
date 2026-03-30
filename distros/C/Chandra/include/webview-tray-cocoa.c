/*
 * webview-tray-cocoa.c — macOS system tray (NSStatusBar) backend
 *
 * Uses the Objective-C runtime via objc_msgSend, matching the pattern
 * established in webview-cocoa.c.
 */

/* NSStatusBar constants */
#define NSVariableStatusItemLength (-1.0)
#define NSSquareStatusItemLength   (-2.0)

/* Forward: tray menu item action handler */
static void tray_menu_item_action(id self, SEL cmd, id sender);

/* Private data for the cocoa tray */
struct webview_tray_cocoa {
  id status_item;    /* NSStatusItem */
  id menu;           /* NSMenu */
  id delegate_class; /* Registered ObjC class for click handling */
  id delegate;       /* Instance */
};

static void tray_build_menu(struct webview_tray *t, id menu,
                            struct webview_tray_item *items, int count);

static id tray_create_menu_for_items(struct webview_tray *t,
                                     struct webview_tray_item *items, int count) {
  id menu = ((id(*)(id, SEL))objc_msgSend)(
      ((id(*)(id, SEL))objc_msgSend)((id)objc_getClass("NSMenu"),
                                     sel_registerName("alloc")),
      sel_registerName("init"));
  ((void(*)(id, SEL, BOOL))objc_msgSend)(menu,
      sel_registerName("setAutoenablesItems:"), NO);
  tray_build_menu(t, menu, items, count);
  return menu;
}

static void tray_build_menu(struct webview_tray *t, id menu,
                            struct webview_tray_item *items, int count) {
  struct webview_tray_cocoa *priv = (struct webview_tray_cocoa *)t->_priv;
  for (int i = 0; i < count; i++) {
    struct webview_tray_item *it = &items[i];
    if (it->is_separator) {
      id sep = ((id(*)(id, SEL))objc_msgSend)(
          (id)objc_getClass("NSMenuItem"),
          sel_registerName("separatorItem"));
      ((void(*)(id, SEL, id))objc_msgSend)(menu,
          sel_registerName("addItem:"), sep);
      continue;
    }
    id title = get_nsstring(it->label ? it->label : "");
    id item = ((id(*)(id, SEL))objc_msgSend)(
        (id)objc_getClass("NSMenuItem"), sel_registerName("alloc"));
    ((void(*)(id, SEL, id, SEL, id))objc_msgSend)(item,
        sel_registerName("initWithTitle:action:keyEquivalent:"),
        title,
        it->submenu_count > 0 ? (SEL)NULL : sel_registerName("trayMenuAction:"),
        get_nsstring(""));

    if (it->submenu_count <= 0) {
      ((void(*)(id, SEL, id))objc_msgSend)(item,
          sel_registerName("setTarget:"), priv->delegate);
      /* Store item id as tag */
      ((void(*)(id, SEL, long))objc_msgSend)(item,
          sel_registerName("setTag:"), (long)it->id);
    }

    if (it->is_disabled) {
      ((void(*)(id, SEL, BOOL))objc_msgSend)(item,
          sel_registerName("setEnabled:"), NO);
    }
    if (it->is_checked) {
      ((void(*)(id, SEL, long))objc_msgSend)(item,
          sel_registerName("setState:"), 1L); /* NSOnState = 1 */
    }

    if (it->submenu_count > 0 && it->submenu) {
      id submenu = tray_create_menu_for_items(t, it->submenu, it->submenu_count);
      ((void(*)(id, SEL, id))objc_msgSend)(submenu,
          sel_registerName("setTitle:"), title);
      ((void(*)(id, SEL, id))objc_msgSend)(item,
          sel_registerName("setSubmenu:"), submenu);
    }

    ((void(*)(id, SEL, id))objc_msgSend)(menu,
        sel_registerName("addItem:"), item);
  }
}

/* ObjC action handler for tray menu items */
static void tray_menu_item_action(id self, SEL cmd, id sender) {
  (void)self; (void)cmd;
  /* Get the webview_tray pointer stored as associated object on the delegate */
  struct webview_tray *t = (struct webview_tray *)
      (uintptr_t)((long(*)(id, SEL))objc_msgSend)(sender, sel_registerName("tag"));

  /* The tag encodes the item_id; but we stored the tray pointer on the delegate.
     Actually, the tag stores the item's id field. We get the tray from the delegate's
     associated object. */
  long item_id = ((long(*)(id, SEL))objc_msgSend)(sender, sel_registerName("tag"));

  /* Retrieve the tray struct from the delegate (self) via objc_getAssociatedObject */
  void *tray_ptr = (void *)objc_getAssociatedObject(self, "webview_tray");
  if (tray_ptr) {
    t = (struct webview_tray *)tray_ptr;
    if (t->menu_cb) {
      t->menu_cb(t->w, (int)item_id);
    }
  }
}

WEBVIEW_API int webview_tray_create(struct webview_tray *t) {
  struct webview_tray_cocoa *priv = (struct webview_tray_cocoa *)calloc(1, sizeof(*priv));
  if (!priv) return -1;
  t->_priv = priv;

  /* Create a delegate class for handling menu actions */
  priv->delegate_class = objc_allocateClassPair(
      (Class)objc_getClass("NSObject"), "ChandraTrayDelegate", 0);
  if (priv->delegate_class) {
    class_addMethod(priv->delegate_class, sel_registerName("trayMenuAction:"),
                    (IMP)tray_menu_item_action, "v@:@");
    objc_registerClassPair(priv->delegate_class);
  }
  priv->delegate = ((id(*)(id, SEL))objc_msgSend)(
      ((id(*)(id, SEL))objc_msgSend)(priv->delegate_class,
                                     sel_registerName("alloc")),
      sel_registerName("init"));

  /* Store tray pointer as associated object on delegate */
  objc_setAssociatedObject(priv->delegate, "webview_tray",
                           (id)(uintptr_t)t, OBJC_ASSOCIATION_ASSIGN);

  /* Get system status bar and create status item */
  id status_bar = ((id(*)(id, SEL))objc_msgSend)(
      (id)objc_getClass("NSStatusBar"),
      sel_registerName("systemStatusBar"));

  priv->status_item = ((id(*)(id, SEL, double))objc_msgSend)(status_bar,
      sel_registerName("statusItemWithLength:"), NSVariableStatusItemLength);
  /* Retain it so it doesn't get released */
  ((void(*)(id, SEL))objc_msgSend)(priv->status_item, sel_registerName("retain"));

  /* Set tooltip */
  if (t->tooltip) {
    id button = ((id(*)(id, SEL))objc_msgSend)(priv->status_item,
        sel_registerName("button"));
    if (button) {
      ((void(*)(id, SEL, id))objc_msgSend)(button,
          sel_registerName("setToolTip:"), get_nsstring(t->tooltip));
    }
  }

  /* Set icon if provided */
  if (t->icon_path && strlen(t->icon_path) > 0) {
    id icon = ((id(*)(id, SEL, id))objc_msgSend)(
        ((id(*)(id, SEL))objc_msgSend)((id)objc_getClass("NSImage"),
                                       sel_registerName("alloc")),
        sel_registerName("initWithContentsOfFile:"),
        get_nsstring(t->icon_path));
    if (icon) {
      /* Template image adapts to dark/light menu bar */
      ((void(*)(id, SEL, BOOL))objc_msgSend)(icon,
          sel_registerName("setTemplate:"), YES);
      /* Resize to menu bar size (18x18) */
      CGSize sz = {18, 18};
      ((void(*)(id, SEL, CGSize))objc_msgSend)(icon,
          sel_registerName("setSize:"), sz);
      id button = ((id(*)(id, SEL))objc_msgSend)(priv->status_item,
          sel_registerName("button"));
      if (button) {
        ((void(*)(id, SEL, id))objc_msgSend)(button,
            sel_registerName("setImage:"), icon);
      }
    }
  } else {
    /* No icon — use tooltip text as title */
    id button = ((id(*)(id, SEL))objc_msgSend)(priv->status_item,
        sel_registerName("button"));
    if (button) {
      ((void(*)(id, SEL, id))objc_msgSend)(button,
          sel_registerName("setTitle:"),
          get_nsstring(t->tooltip ? t->tooltip : "App"));
    }
  }

  /* Build and attach menu */
  priv->menu = tray_create_menu_for_items(t, t->items, t->item_count);
  ((void(*)(id, SEL, id))objc_msgSend)(priv->status_item,
      sel_registerName("setMenu:"), priv->menu);

  return 0;
}

WEBVIEW_API void webview_tray_update(struct webview_tray *t) {
  if (!t || !t->_priv) return;
  struct webview_tray_cocoa *priv = (struct webview_tray_cocoa *)t->_priv;

  /* Update tooltip */
  if (t->tooltip) {
    id button = ((id(*)(id, SEL))objc_msgSend)(priv->status_item,
        sel_registerName("button"));
    if (button) {
      ((void(*)(id, SEL, id))objc_msgSend)(button,
          sel_registerName("setToolTip:"), get_nsstring(t->tooltip));
    }
  }

  /* Update icon */
  if (t->icon_path && strlen(t->icon_path) > 0) {
    id icon = ((id(*)(id, SEL, id))objc_msgSend)(
        ((id(*)(id, SEL))objc_msgSend)((id)objc_getClass("NSImage"),
                                       sel_registerName("alloc")),
        sel_registerName("initWithContentsOfFile:"),
        get_nsstring(t->icon_path));
    if (icon) {
      ((void(*)(id, SEL, BOOL))objc_msgSend)(icon,
          sel_registerName("setTemplate:"), YES);
      CGSize sz = {18, 18};
      ((void(*)(id, SEL, CGSize))objc_msgSend)(icon,
          sel_registerName("setSize:"), sz);
      id button = ((id(*)(id, SEL))objc_msgSend)(priv->status_item,
          sel_registerName("button"));
      if (button) {
        ((void(*)(id, SEL, id))objc_msgSend)(button,
            sel_registerName("setImage:"), icon);
      }
    }
  }

  /* Rebuild menu */
  id new_menu = tray_create_menu_for_items(t, t->items, t->item_count);
  ((void(*)(id, SEL, id))objc_msgSend)(priv->status_item,
      sel_registerName("setMenu:"), new_menu);
  priv->menu = new_menu;
}

WEBVIEW_API void webview_tray_destroy(struct webview_tray *t) {
  if (!t || !t->_priv) return;
  struct webview_tray_cocoa *priv = (struct webview_tray_cocoa *)t->_priv;

  /* Remove status item from status bar */
  id status_bar = ((id(*)(id, SEL))objc_msgSend)(
      (id)objc_getClass("NSStatusBar"),
      sel_registerName("systemStatusBar"));
  ((void(*)(id, SEL, id))objc_msgSend)(status_bar,
      sel_registerName("removeStatusItem:"), priv->status_item);
  ((void(*)(id, SEL))objc_msgSend)(priv->status_item,
      sel_registerName("release"));

  free(priv);
  t->_priv = NULL;
}
