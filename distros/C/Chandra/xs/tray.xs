MODULE = Chandra    PACKAGE = Chandra

int
_tray_create(self, icon_path, tooltip, menu_json, callback)
    PerlChandra *self
    const char *icon_path
    const char *tooltip
    const char *menu_json
    SV *callback
PREINIT:
    int result;
CODE:
    /* Parse menu_json into tray items */
    memset(&self->tray, 0, sizeof(self->tray));
    self->tray.w = &self->wv;
    self->tray.icon_path = savepv(icon_path);
    self->tray.tooltip = savepv(tooltip);
    self->tray.item_count = 0;

    /* Parse the JSON menu structure:
       [{"id":1,"label":"Show"},{"separator":1},{"id":2,"label":"Quit"}] */
    if (menu_json && strlen(menu_json) > 2) {
        const char *p = menu_json;
        int item_idx = 0;

        while (*p && item_idx < WEBVIEW_TRAY_MAX_ITEMS) {
            while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') p++;

            if (*p == '[') { p++; continue; }
            if (*p == ']') break;
            if (*p == ',') { p++; continue; }

            if (*p == '{') {
                struct webview_tray_item *it = &self->tray.items[item_idx];
                memset(it, 0, sizeof(*it));
                p++;

                while (*p && *p != '}') {
                    while (*p == ' ' || *p == ',' || *p == '\t' || *p == '\n') p++;
                    if (*p == '}') break;
                    if (*p != '"') { p++; continue; }

                    p++;
                    const char *key_start = p;
                    while (*p && *p != '"') p++;
                    int key_len = p - key_start;
                    p++;

                    while (*p == ' ' || *p == ':') p++;

                    if (key_len == 2 && strncmp(key_start, "id", 2) == 0) {
                        it->id = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 5 && strncmp(key_start, "label", 5) == 0) {
                        if (*p == '"') {
                            p++;
                            const char *val_start = p;
                            while (*p && *p != '"') {
                                if (*p == '\\') p++;
                                p++;
                            }
                            int val_len = p - val_start;
                            char *label = (char *)malloc(val_len + 1);
                            memcpy(label, val_start, val_len);
                            label[val_len] = '\0';
                            it->label = label;
                            if (*p == '"') p++;
                        }
                    } else if (key_len == 9 && strncmp(key_start, "separator", 9) == 0) {
                        it->is_separator = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 8 && strncmp(key_start, "disabled", 8) == 0) {
                        it->is_disabled = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 7 && strncmp(key_start, "checked", 7) == 0) {
                        it->is_checked = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else {
                        while (*p && *p != ',' && *p != '}') p++;
                    }
                }
                if (*p == '}') p++;
                item_idx++;
            } else {
                p++;
            }
        }
        self->tray.item_count = item_idx;
    }

    /* Set up callback */
    if (callback && SvOK(callback) && SvROK(callback)) {
        if (self->tray_callback) {
            SvREFCNT_dec(self->tray_callback);
        }
        self->tray_callback = SvREFCNT_inc(callback);
        self->tray.menu_cb = tray_menu_cb;
    } else {
        self->tray.menu_cb = NULL;
    }

    result = webview_tray_create(&self->tray);
    self->tray_active = (result == 0) ? 1 : 0;
    RETVAL = result;
OUTPUT:
    RETVAL

void
_tray_update(self, icon_path, tooltip, menu_json)
    PerlChandra *self
    const char *icon_path
    const char *tooltip
    const char *menu_json
CODE:
    if (!self->tray_active) return;

    if (self->tray.icon_path) Safefree((char *)self->tray.icon_path);
    if (self->tray.tooltip) Safefree((char *)self->tray.tooltip);
    self->tray.icon_path = savepv(icon_path);
    self->tray.tooltip = savepv(tooltip);

    {
        int i;
        for (i = 0; i < self->tray.item_count; i++) {
            if (self->tray.items[i].label) {
                free((char *)self->tray.items[i].label);
                self->tray.items[i].label = NULL;
            }
        }
    }

    self->tray.item_count = 0;
    if (menu_json && strlen(menu_json) > 2) {
        const char *p = menu_json;
        int item_idx = 0;
        while (*p && item_idx < WEBVIEW_TRAY_MAX_ITEMS) {
            while (*p == ' ' || *p == '\t' || *p == '\n' || *p == '\r') p++;
            if (*p == '[') { p++; continue; }
            if (*p == ']') break;
            if (*p == ',') { p++; continue; }
            if (*p == '{') {
                struct webview_tray_item *it = &self->tray.items[item_idx];
                memset(it, 0, sizeof(*it));
                p++;
                while (*p && *p != '}') {
                    while (*p == ' ' || *p == ',' || *p == '\t' || *p == '\n') p++;
                    if (*p == '}') break;
                    if (*p != '"') { p++; continue; }
                    p++;
                    const char *key_start = p;
                    while (*p && *p != '"') p++;
                    int key_len = p - key_start;
                    p++;
                    while (*p == ' ' || *p == ':') p++;
                    if (key_len == 2 && strncmp(key_start, "id", 2) == 0) {
                        it->id = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 5 && strncmp(key_start, "label", 5) == 0) {
                        if (*p == '"') {
                            p++;
                            const char *val_start = p;
                            while (*p && *p != '"') { if (*p == '\\') p++; p++; }
                            int val_len = p - val_start;
                            char *label = (char *)malloc(val_len + 1);
                            memcpy(label, val_start, val_len);
                            label[val_len] = '\0';
                            it->label = label;
                            if (*p == '"') p++;
                        }
                    } else if (key_len == 9 && strncmp(key_start, "separator", 9) == 0) {
                        it->is_separator = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 8 && strncmp(key_start, "disabled", 8) == 0) {
                        it->is_disabled = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else if (key_len == 7 && strncmp(key_start, "checked", 7) == 0) {
                        it->is_checked = atoi(p);
                        while (*p && *p != ',' && *p != '}') p++;
                    } else {
                        while (*p && *p != ',' && *p != '}') p++;
                    }
                }
                if (*p == '}') p++;
                item_idx++;
            } else {
                p++;
            }
        }
        self->tray.item_count = item_idx;
    }

    webview_tray_update(&self->tray);

void
_tray_destroy(self)
    PerlChandra *self
CODE:
    if (self->tray_active) {
        webview_tray_destroy(&self->tray);
        self->tray_active = 0;
        if (self->tray.icon_path) {
            Safefree((char *)self->tray.icon_path);
            self->tray.icon_path = NULL;
        }
        if (self->tray.tooltip) {
            Safefree((char *)self->tray.tooltip);
            self->tray.tooltip = NULL;
        }
        if (self->tray_callback) {
            SvREFCNT_dec(self->tray_callback);
            self->tray_callback = NULL;
        }
    }

int
_tray_active(self)
    PerlChandra *self
CODE:
    RETVAL = self->tray_active;
OUTPUT:
    RETVAL
