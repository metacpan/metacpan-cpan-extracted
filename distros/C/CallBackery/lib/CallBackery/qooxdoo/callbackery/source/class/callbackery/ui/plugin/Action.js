/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Form Action Widget.
 */
qx.Class.define("callbackery.ui.plugin.Action", {
    extend: qx.ui.container.Composite,
    /**
     * create a page for the View Tab with the given title
     *
     * @param cfg {Object} plugin configuration map
     * @param buttonClass {Class} class to be used for action buttons
     * @param layout {Class} qooxdoo layout for this container
     * @param getFormData {Function} method to get form data
     * @param plugin {Class} visualization widget to embedd
     */
    construct(cfg, buttonClass, layout, getFormData, plugin) {
        this.base(arguments, layout);
        this._plugin = plugin;
        this._urlActions = [];
        this._buttonMap = {};
        this._buttonSetMap = {};
        this._menuButtonSetMap = {};
        this._cfg = cfg;
        this._populate(cfg, buttonClass, getFormData);
        plugin.addOwnedQxObject(this, 'Action');
        this.addListener('actionResponse', function (e) {
            var data = e.getData();
            // ignore empty actions responses
            if (!data) {
                return;
            }
            switch (data.action) {
                case 'logout':
                    callbackery.data.Server.getInstance().callAsyncSmartBusy(function (ret) {
                        if (window.console) {
                            window.console.log('last words from the server "' + ret + '"');
                        }
                        document.location.reload(true);
                    }, 'logout');
                    break;
                case 'showMessage':
                    this.warn('Callbackery deprecation: action showMessage should not be used; use cancel|dataSaved|wait instead');
                case 'cancel':
                case 'close':
                case 'dataSaved':
                case 'wait':
                    if (data.message) {
                        let message = this.xtr(data.message);
                        let title = '';
                        if (data.title) {
                            title = this.xtr(data.title);
                        }
                        if (data.htmlWithJS) {
                            let box = new callbackery.ui.HtmlBox(message);
                            let size = data.size;
                            if (size.width) {
                                box.setWidth(size.width);
                            }
                            if (size.height) {
                                box.setHeight(size.height);
                            }
                            box.show();
                        }
                        else {
                            callbackery.ui.MsgBox.getInstance().info(
                                title, message, data.html, data.icons, data.size
                            );
                        }
                    }
                    break;
                case 'print':
                    this._print(data.content);
                    break;
                case 'openLink':
                    const link = document.createElement('a');
                    link.href = data.url;
                    link.target = data.target || '_blank';
                    link.rel = data.rel || 'noopener noreferrer';
                    document.body.appendChild(link);
                    link.click();
                    link.remove();
                    break;
                case 'reloadStatus':
                case 'reload':
                    break;
                default:
                    console.error('Unknown action:', data.action);
                    break;
            }
        }, this);

        // process actions called via URL
        this.addListener('appear', () => {
            let config = callbackery.data.Config.getInstance();
            this._urlActions.forEach(urlAction => {
                let button = urlAction.button;
                let urlValue = config.getUrlConfigValue(urlAction.key);
                if (urlValue && urlValue == urlAction.value) {
                    button.execute();
                    // only do it once for the time being
                    config.removeUrlConfigEntry(urlAction.key);
                }
            });
        }, this);
    },

    events: {
        actionResponse: 'qx.event.type.Data',
        popupClosed: 'qx.event.type.Event'
    },

    properties: {
        selection: {}
    },

    members: {
        _cfg: null,
        _plugin: null,
        _tableMenu: null,
        _defaultAction: null,
        _buttonMap: null,
        _buttonSetMap: null,
        _menuButtonSetMap: null,
        _urlActions: null,
        _mobileMenu: null,
        _print(content, left, top) {
            var win = window.open('', '_blank');
            var doc = win.document;
            doc.open();
            doc.write(content);
            doc.close();
            win.onafterprint = function () {
                win.close();
            }
            win.print();
        },
        _populate(cfg, buttonClass, getFormData) {
            let tm = this._tableMenu = new qx.ui.menu.Menu;
            let mm = this._mobileMenu = new qx.ui.menu.Menu;
            let menues = {};
            let mmMenues = {};
            cfg.action.forEach(function (btCfg) {
                let button, menuButton, mmButton;
                // label for form and context menu buttons
                let label = btCfg.label ? this.xtr(btCfg.label) : null;
                // label for mobile menu buttons
                let menuLabel = btCfg.menuLabel ? this.xtr(btCfg.menuLabel) : null;
                let bs  = btCfg.buttonSet,
                    mbs = btCfg.menuButtonSet;
                if (bs) {
                    if (bs.label) {
                        bs.label = this.xtr(bs.label);
                    }
                }
                if (mbs) {
                    if (mbs.label) {
                        mbs.label = this.xtr(mbs.label);
                    }
                }
                else if (bs) { // use buttonSet as menuButtonSet if no menuButtonSet is given
                    mbs = bs;
                }

                switch (btCfg.action) {
                    case 'menu':
                        let menu = menues[btCfg.key] = new qx.ui.menu.Menu;
                        let mmMenu = mmMenues[btCfg.key] = new qx.ui.menu.Menu;
                        if (btCfg.addToMenu != null) { // add submenu to menu
                            button = new qx.ui.menu.Button(label, null, null, menu)
                            mmButton = new qx.ui.menu.Button(menuLabel || label, null, null, mmMenu)
                            menues[btCfg.addToMenu].add(button);
                            mmMenues[btCfg.addToMenu].add(mmButton);
                        }
                        else { // add menu to form
                            button = new qx.ui.form.MenuButton(label, null, menu);
                            mmButton = new qx.ui.menu.Button(menuLabel || label, null, null, mmMenu);
                            if (bs) {
                                button.set(bs);
                                if (btCfg.key) {
                                    this._buttonSetMap[btCfg.key] = bs;
                                }
                            }
                            if (mbs) {
                                let mbsFiltered = Object.fromEntries(
                                    ['visibility', 'enabled', 'label', 'icon'].filter(key => key in mbs).map(key => [key, mbs[key]])
                                );
                                mmButton.set(mbsFiltered);
                                if (btCfg.key) {
                                    this._menuButtonSetMap[btCfg.key] = mbsFiltered;
                                }
                            }
                            this.add(button);
                            mm.add(mmButton);
                        }
                        if (btCfg.key) {
                            let btnId = btCfg.key
                                + (btCfg.testingIdPostfix ? btCfg.testingIdPostfix : '')
                                + 'Button';
                            this.addOwnedQxObject(button, btnId);
                            let mmBtnId = btCfg.key
                                + (btCfg.testingIdPostfix ? btCfg.testingIdPostfix : '')
                                + 'mmButton';
                            this.addOwnedQxObject(mmButton, mmBtnId);
                        }
                        this._bindButtonProperties(button, mmButton);
                        return;
                    case 'save':
                    case 'submitVerify':
                    case 'submit':
                    case 'popup':
                    case 'wizzard':
                    case 'logout':
                    case 'cancel':
                    case 'download':
                    case 'display':
                        mmButton = new qx.ui.menu.Button(menuLabel || label);
                        if (btCfg.addToMenu != null) {
                            button = new qx.ui.menu.Button(label);
                        }
                        else {
                            button = new buttonClass(label);
                        }
                        if (btCfg.key) {
                            this._buttonMap[btCfg.key] = button;
                            let urlAction = btCfg.urlAction;
                            if (urlAction) {
                                this._urlActions.push({
                                    button: button,
                                    value: urlAction.value,
                                    key: urlAction.key
                                });
                            }
                        }

                        if (bs) {
                            button.set(bs);
                            if (btCfg.key) {
                                this._buttonSetMap[btCfg.key] = bs;
                            }
                        }
                        if (mbs) {
                            let mbsFiltered = Object.fromEntries(
                                ['visibility', 'enabled', 'label', 'icon'].filter(key => key in mbs).map(key => [key, mbs[key]])
                            );
                            mmButton.set(mbsFiltered);
                            if (btCfg.key) {
                                this._menuButtonSetMap[btCfg.key] = mbsFiltered;
                            }
                        }

                        if (btCfg.addToContextMenu) {
                            menuButton = new qx.ui.menu.Button(label);
                            if (btCfg.key) {
                                let btnId = btCfg.key
                                    + (btCfg.testingIdPostfix ? btCfg.testingIdPostfix : '')
                                    + 'MenuButton';
                                this.addOwnedQxObject(menuButton, btnId);
                            }
                            [
                                'Enabled',
                                'Visibility',
                                'Icon',
                                'Label'
                            ].forEach(function (Prop) {
                                var prop = Prop.toLowerCase();
                                button.addListener('change' + Prop, function (e) {
                                    menuButton['set' + Prop](e.getData());
                                }, this);
                                if (btCfg.buttonSet && prop in btCfg.buttonSet) {
                                    menuButton['set' + Prop](btCfg.buttonSet[prop]);
                                }
                            }, this);
                        }
                        break;
                    case 'refresh':
                        var timer = qx.util.TimerManager.getInstance();
                        var timerId;
                        this.addListener('appear', function () {
                            timerId = timer.start(function () {
                                this.fireDataEvent('actionResponse', { action: 'reloadStatus' });
                            }, btCfg.interval * 1000, this);
                        }, this);
                        this.addListener('disappear', function () {
                            if (timerId) {
                                timer.stop(timerId);
                                timerId = null;
                            }
                        }, this);
                        break;
                    case 'autoSubmit':
                        var autoTimer = qx.util.TimerManager.getInstance();
                        var autoTimerId;
                        this.addListener('appear', function () {
                            var key = btCfg.key;
                            var that = this;
                            autoTimerId = autoTimer.start(function () {
                                var formData = getFormData();
                                callbackery.data.Server.getInstance().callAsync(function (ret) {
                                    that.fireDataEvent('actionResponse', ret || {});
                                }, 'processPluginData', cfg.name, { "key": key, "formData": formData });
                            }, btCfg.interval * 1000, this);
                        }, this);
                        this.addListener('disappear', function () {
                            if (autoTimerId) {
                                autoTimer.stop(autoTimerId);
                                autoTimerId = null;
                            }
                        }, this);
                        break;
                    case 'upload':
                        button = this._makeUploadButton(cfg, btCfg, getFormData,
                            buttonClass == qx.ui.toolbar.Button
                                ? qx.ui.toolbar.FileSelectorButton
                                : qx.ui.form.FileSelectorButton);
                        mmButton = this._makeUploadButton(cfg, btCfg, getFormData,
                            callbackery.ui.form.FileSelectorMenuButton);
                        if (btCfg.key) {
                            this._buttonMap[btCfg.key] = button;
                        }
                        break;
                    case 'separator':
                        this.add(new qx.ui.core.Spacer(10, 10));
                        mm.add(new qx.ui.menu.Separator());
                        break;
                    default:
                        this.debug('Invalid execute action:' + btCfg.action + ' for button', btCfg);
                }
                if (button && btCfg.key) {
                    let btnId = btCfg.key
                        + (btCfg.testingIdPostfix ? btCfg.testingIdPostfix : '')
                        + 'Button';
                    this.addOwnedQxObject(button, btnId);
                }
                if (mmButton && btCfg.key) {
                    let mmBtnId = btCfg.key
                        + (btCfg.testingIdPostfix ? btCfg.testingIdPostfix : '')
                        + 'mmButton';
                    this.addOwnedQxObject(mmButton, mmBtnId);
                }
                var action = function () {
                    var that = this;
                    if (!button.isEnabled()) {
                        return;
                    }
                    switch (btCfg.action) {
                        case 'save':
                            var formData = getFormData();
                            var key = btCfg.key;
                            callbackery.data.Server.getInstance().callAsync(function (ret) {
                                that.fireDataEvent('actionResponse', ret || {});
                            }, 'processPluginData', cfg.name, { "key": key, "formData": formData });
                            break;
                        case 'submitVerify':
                        case 'submit':
                            var formData = getFormData();
                            if (formData === false) {
                                callbackery.ui.MsgBox.getInstance().error(
                                    this.tr("Validation Error"),
                                    this.tr("The form can only be submitted when all data fields have valid content.")
                                );
                                return;
                            }
                            var key = btCfg.key;
                            var asyncCall = function () {
                                callbackery.data.Server.getInstance().callAsyncSmartBusy(function (ret) {
                                    that.fireDataEvent('actionResponse', ret || {});
                                }, 'processPluginData', cfg.name, { "key": key, "formData": formData });
                            };

                            if (btCfg.action == 'submitVerify') {
                                var title = btCfg.label != null ? btCfg.label : btCfg.key;
                                callbackery.ui.MsgBox.getInstance().yesno(
                                    this.xtr(title),
                                    this.xtr(btCfg.question)
                                )
                                    .addListenerOnce('choice', function (e) {
                                        if (e.getData() == 'yes') {
                                            asyncCall();
                                        }
                                    }, this);
                            }
                            else {
                                asyncCall();
                            }
                            break;
                        case 'download':
                        case 'display':
                            var formData = getFormData();
                            let busy = callbackery.ui.Busy.getInstance();
                            if (formData === false) {
                                callbackery.ui.MsgBox.getInstance().error(
                                    this.tr("Validation Error"),
                                    this.tr("The form can only be submitted when all data fields have valid content.")
                                );
                                return;
                            }
                            var key = btCfg.key;
                            if (btCfg.busyMessage) {
                                busy.manifest(this.xtr(btCfg.busyMessage));
                            } else {
                                busy.manifest(this.tr('Preparing Download ...'));
                            }
                            callbackery.data.Server.getInstance().callAsyncSmart(function (cookie) {
                                let url = 'download'
                                    + '?name=' + cfg.name
                                    + '&key=' + key
                                    + '&xsc=' + encodeURIComponent(cookie)
                                    + '&formData=' + encodeURIComponent(qx.lang.Json.stringify(formData));
                                if (btCfg.action == 'display') {
                                    window.open(url + '&display=1', '_blank');
                                    return;
                                }
                                var iframe = new qx.ui.embed.Iframe().set({
                                    width: 100,
                                    height: 100
                                });
                                iframe.addListener('load', function (e) {
                                    busy.vanish();
                                    var response = {
                                        exception: {
                                            message: String(that.tr("No Data")),
                                            code: 9999
                                        }
                                    };
                                    try {
                                        // innerHTML is wrapped in `<pre>` tags, which we remove.
                                        let innerHTML = iframe.getBody().innerHTML;
                                        if (innerHTML) {
                                            innerHTML = innerHTML.replace(/^<.*?>/, '');
                                            innerHTML = innerHTML.replace(/<.*?>$/, '');
                                        }
                                        // If there is text left, it should be the json from the server.
                                        // JSON parsing an empty string is an error.
                                        if (innerHTML) {
                                            response = qx.lang.Json.parse(innerHTML);
                                        }
                                        // otherwise remove standard exception.
                                        else {
                                            response = {};
                                        }
                                    } catch (e) { };
                                    if (response.exception) {
                                        callbackery.ui.MsgBox.getInstance().error(
                                            that.tr("Download Exception"),
                                            that.xtr(response.exception.message) + " (" + response.exception.code + ")"
                                        );
                                    }
                                    that.getApplicationRoot().remove(iframe);
                                    if (btCfg.closeAfterDownload) {
                                        that.fireDataEvent('actionResponse', { action: 'cancel' });
                                    }
                                });
                                iframe.setSource(url);
                                that.getApplicationRoot().add(iframe, { top: -1000, left: -1000 });
                            }, 'getSessionCookie');
                            break;
                        case 'cancel':
                            this.fireDataEvent('actionResponse', { action: 'cancel' });
                            break;
                        case 'wizzard':
                            var parent = that.getLayoutParent();
                            while (!parent.classname.match(/Page|Popup/)) {
                                parent = parent.getLayoutParent();
                            }
                            // This could in principal work for Page although.
                            if (parent.classname.match(/Popup/)) { // parent already exists, replace content
                                parent.replaceContent(btCfg, getFormData);
                                break;
                            }
                        // fall through intended to create first popup content
                        case 'popup':
                            if (!btCfg.noValidation) { // backward incompatibility work around
                                var formData = getFormData();
                                if (formData === false) {
                                    callbackery.ui.MsgBox.getInstance().error(
                                        this.tr("Validation Error"),
                                        this.tr("The form can only be submitted when all data fields have valid content.")
                                    );
                                    return;
                                }
                            }
                            var popup = new callbackery.ui.Popup(btCfg, getFormData, this);

                            var appRoot = that.getApplicationRoot();

                            popup.addListenerOnce('close', function () {
                                // wait for stuff to happen before we rush into
                                // disposing the popup
                                qx.event.Timer.once(function () {
                                    appRoot.remove(popup);
                                    popup.dispose();
                                    this.fireEvent('popupClosed');
                                }, that, 100);
                                if (!(btCfg.options && btCfg.options.noReload)) {
                                    this.fireDataEvent('actionResponse', { action: (btCfg.options && btCfg.options.reloadStatusOnClose) ? 'reloadStatus' : 'reload' });
                                }
                            }, that);
                            popup.open();
                            break;
                        case 'logout':
                            that.fireDataEvent('actionResponse', { action: 'logout' });
                            break;

                        default:
                            this.debug('Invalid execute action:' + btCfg.action);
                    }
                }; // var action = function() { ... };

                if (btCfg.defaultAction) {
                    this._defaultAction = action;
                }
                if (button) {
                    // in ios/android buttons do not necessarily get focus when clicked
                    // so we need to do it manually, since this happens on different
                    // browsers, chances are this is not a bug but by design :)

                    // once https://github.com/qooxdoo/qooxdoo/pull/10632 is released
                    // this here can go away
                    button.addListenerOnce('appear',() => {
                      let el = button.getContentElement().getDomElement();
                      button.addListener('touchstart', () => { el.focus(); }, this);
                    });
                    button.addListener('execute', action, this);
                    if (btCfg.addToMenu) {
                        menues[btCfg.addToMenu].add(button);
                    }
                    else {
                        if (btCfg.addToToolBar !== false) {
                            this.add(button);
                        }
                    }
                }
                if (mmButton) {
                    mmButton.addListener('execute', action, this);
                    if (btCfg.addToMenu) {
                        mmMenues[btCfg.addToMenu].add(mmButton);
                    }
                    else {
                        if (btCfg.addToToolBar !== false) {
                            mm.add(mmButton);
                        }
                    }
                }
                if (menuButton) {
                    menuButton.addListener('execute', action, this);
                    tm.add(menuButton);
                }
                if (button && menuButton) {
                    this._bindButtonProperties(button, mmButton);
                }
            }, this);
        },

        _makeUploadButton(cfg, btCfg, getFormData, buttonClass) {
            var button;
            var label = btCfg.label ? this.xtr(btCfg.label) : null;
            if (buttonClass) {
                button = new buttonClass(label);
            }
            else {
                button = new qx.ui.form.FileSelectorButton(label);
            }
            if (btCfg.buttonSet) {
                var bs = btCfg.buttonSet;
                if (bs.label) {
                    bs.label = this.xtr(bs.label);
                }
                button.set(bs);
                if (btCfg.key) {
                    this._buttonSetMap[btCfg.key] = bs;
                }
            }
            var serverCall = callbackery.data.Server.getInstance();
            var key = btCfg.key;
            var name = cfg.name;
            button.addListener('changeFileSelection', function (e) {
                var fileList = e.getData();
                var formData = getFormData();
                if (formData && fileList) {
                    var form = new FormData();
                    form.append('name', name);
                    form.append('key', key);
                    form.append('file', fileList[0]);
                    form.append('formData', qx.lang.Json.stringify(formData));
                    var that = this;
                    serverCall.callAsyncSmart(function (cookie) {
                        form.append('xsc', cookie);
                        that._uploadForm(form,btCfg.busyMessage);
                    }, 'getSessionCookie');
                } else {
                    callbackery.ui.MsgBox.getInstance().error(
                        this.tr("Upload Exception"),
                        this.tr("Make sure to select a file and properly fill the form")
                    );
                }
            }, this);

            return button;
        },

        _uploadForm(form,busyMessage) {
            var req = new qx.io.request.Xhr("upload", 'POST').set({
                requestData: form
            });
            let busy = callbackery.ui.Busy.getInstance();
            req.addListener('success', function (e) {
                busy.vanish();                
                var response = req.getResponse();
                if (response.exception) {
                    callbackery.ui.MsgBox.getInstance().error(
                        this.tr("Upload Exception"),
                        this.xtr(response.exception.message)
                        + " (" + response.exception.code + ")"
                    );
                } else {
                    this.fireDataEvent('actionResponse', response);
                }
                req.dispose();
            }, this);
            req.addListener('fail', function (e) {
                var response = {};
                busy.vanish();
                try {
                    response = req.getResponse();
                }
                catch (e) {
                    response = {
                        exception: {
                            message: e.message,
                            code: 99999
                        }
                    };
                }
                callbackery.ui.MsgBox.getInstance().error(
                    this.tr("Upload Exception"),
                    this.xtr(response.exception.message)
                    + " (" + response.exception.code + ")"
                );
                req.dispose();
            });
            if (busyMessage) {
                busy.manifest(this.xtr(busyMessage));
            } else {
                busy.manifest(this.tr('Uploading File, please wait ...'));
            }
            req.send();
        },

        getTableContextMenu() {
            return this._tableMenu;
        },
        getMobileMenu() {
            return this._mobileMenu;
        },
        getDefaultAction() {
            return this._defaultAction;
        },
        getButtonMap() {
            return this._buttonMap;
        },
        getButtonSetMap() {
            return this._buttonSetMap;
        },
        getMenuButtonSetMap() {
            return this._menuButtonSetMap;
        },
        _bindButtonProperties(button, mmButton) {
            ['visibility', 'enabled', 'label', 'icon'].forEach((prop) => {
                button.bind(prop, mmButton, prop);
            });
        }
    },

    destruct() {
        if (!this._buttonMap) {
            return;
        }
        for (const [key, btn] of Object.entries(this._buttonMap)) {
            btn.destroy();
        }
    },

});
