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
    extend : qx.ui.container.Composite,
    /**
     * create a page for the View Tab with the given title
     *
     * @param cfg {Object} plugin configuration map
     * @param buttonClass {Class} class to be used for action buttons
     * @param layout {Class} qooxdoo layout for this container
     * @param getFormData {Function} method to get form data
     * @param plugin {Class} visualization widget to embedd
     */
    construct : function(cfg,buttonClass,layout,getFormData, plugin) {
        this.base(arguments, layout);
        this._plugin = plugin;
        this._buttonMap = {};
        this._buttonSetMap = {};
        this._cfg = cfg;
        this._populate(cfg,buttonClass,getFormData);
        plugin.addOwnedQxObject(this, 'Action');
        this.addListener('actionResponse',function(e){
            var data = e.getData();
            // ignore empty actions responses
            if (!data){
                return;
            }
            switch (data.action){
                case 'logout':
                    callbackery.data.Server.getInstance().callAsyncSmartBusy(function(ret) {
                        if (window.console){
                            window.console.log('last words from the server "'+ret+'"');
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
                case 'reloadStatus':
                case 'reload':
                    break;
                default:
                    console.error('Unknown action:', data.action);
                    break;
            }
        },this);
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
        _plugin : null,
        _tableMenu: null,
        _defaultAction: null,
        _buttonMap: null,
        _print: function(content, left, top) {
            var win = window.open('', '_blank');
            var doc = win.document;
            doc.open();
            doc.write(content);
            doc.close();
            win.onafterprint=function() {
                win.close();
            }
            win.print();
        },
        _populate: function(cfg,buttonClass,getFormData){
            var tm = this._tableMenu = new qx.ui.menu.Menu;
            var menues = {};
            let plugin = this._plugin;
            cfg.action.forEach(function(btCfg){
                var button, menuButton;
                var label = btCfg.label ? this.xtr(btCfg.label) : null;
                switch (btCfg.action) {
                    case 'menu':
                        var menu = menues[btCfg.key] = new qx.ui.menu.Menu;
                        if (btCfg.addToMenu != null) { // add submenu to menu
                            button = new qx.ui.menu.Button(label, null, null, menu)
                            menues[btCfg.addToMenu].add(button);
                        }
                        else { // add menu to form
                            button = new qx.ui.form.MenuButton(label, null, menu);
                            this.add(button);
                        }
                        if (btCfg.key) {
                            let btnId = btCfg.key + 'Button';
                            this.addOwnedQxObject(button, btnId);
                            this._buttonMap[btCfg.key]=button;
                        }
                        return;
                        break;
                    case 'save':
                    case 'submitVerify':
                    case 'submit':
                    case 'popup':
                    case 'wizzard':
                    case 'logout':
                    case 'cancel':
                    case 'download':
                        if (btCfg.addToMenu != null) {
                            button = new qx.ui.menu.Button(label);
                        }
                        else {
                            button = new buttonClass(label);
                        }
                        if (btCfg.key){
                            this._buttonMap[btCfg.key]=button;
                        }
                        if (btCfg.buttonSet) {
                            var bs = btCfg.buttonSet;
                            if (bs.label) {
                                bs.label = this.xtr(bs.label);
                            }
                            button.set(bs);
                            if (btCfg.key){
                                this._buttonSetMap[btCfg.key]=bs;
                            }
                        }

                        if ( btCfg.addToContextMenu) {
                            menuButton = new qx.ui.menu.Button(label);
                            if (btCfg.key) {
                                let btnId = btCfg.key + 'MenuButton'
                                this.addOwnedQxObject(menuButton, btnId);
                            }
                            [
                                'Enabled',
                                'Visibility',
                                'Icon',
                                'Label'
                            ].forEach(function(Prop){
                                var prop = Prop.toLowerCase();
                                button.addListener('change'+Prop,function(e){
                                    menuButton['set'+Prop](e.getData());
                                },this);
                                if (btCfg.buttonSet && prop in btCfg.buttonSet){
                                    menuButton['set'+Prop](btCfg.buttonSet[prop]);
                                }
                            },this);
                        }
                        break;
                    case 'refresh':
                        var timer = qx.util.TimerManager.getInstance();
                        var timerId;
                        this.addListener('appear',function(){
                            timerId = timer.start(function(){
                                this.fireDataEvent('actionResponse',{action: 'reloadStatus'});
                            }, btCfg.interval * 1000, this);
                        }, this);
                        this.addListener('disappear',function(){
                            if (timerId) {
                                timer.stop(timerId);
                                timerId = null;
                            }
                        }, this);
                        break;
                    case 'autoSubmit':
                        var autoTimer = qx.util.TimerManager.getInstance();
                        var autoTimerId;
                        this.addListener('appear',function(){
                            var key = btCfg.key;
                            var that = this;
                            autoTimerId = autoTimer.start(function(){
                                var formData = getFormData();
                                callbackery.data.Server.getInstance().callAsync(function(ret){
                                    that.fireDataEvent('actionResponse',ret || {});
                                },'processPluginData',cfg.name,{ "key": key, "formData": formData });
                            }, btCfg.interval * 1000, this);
                        }, this);
                        this.addListener('disappear',function(){
                            if (autoTimerId) {
                                autoTimer.stop(autoTimerId);
                                autoTimerId = null;
                            }
                        }, this);
                        break;
                    case 'upload':
                        button = this._makeUploadButton(cfg,btCfg,getFormData);
                        break;
                    case 'separator':
                        this.add(new qx.ui.core.Spacer(10,10));
                        break;
                    default:
                        this.debug('Invalid execute action:' + btCfg.action + ' for button', btCfg);
                }
                if (button && btCfg.key) {
                    let btnId = btCfg.key + 'Button';
                    this.addOwnedQxObject(button, btnId);
                }
                var action = function(){
                    var that = this;
                    if (! button.isEnabled()) {
                        return;
                    }
                    switch (btCfg.action) {
                        case 'save':
                            var formData = getFormData();
                            var key = btCfg.key;
                            callbackery.data.Server.getInstance().callAsync(function(ret){
                                that.fireDataEvent('actionResponse',ret || {});
                            },'processPluginData',cfg.name,{ "key": key, "formData": formData });
                            break;
                        case 'submitVerify':
                        case 'submit':
                            var formData = getFormData();
                            if (formData === false){
                                callbackery.ui.MsgBox.getInstance().error(
                                    this.tr("Validation Error"),
                                    this.tr("The form can only be submitted when all data fields have valid content.")
                                );
                                return;
                            }
                            var key = btCfg.key;
                            var asyncCall = function(){
                                callbackery.data.Server.getInstance().callAsyncSmartBusy(function(ret){
                                    that.fireDataEvent('actionResponse',ret || {});
                                },'processPluginData',cfg.name,{ "key": key, "formData": formData });
                            };

                            if (btCfg.action == 'submitVerify'){
                                var title = btCfg.label != null ? btCfg.label : btCfg.key;
                                callbackery.ui.MsgBox.getInstance().yesno(
                                    this.xtr(title),
                                    this.xtr(btCfg.question)
                                )
                                .addListenerOnce('choice',function(e){
                                    if (e.getData() == 'yes'){
                                        asyncCall();
                                    }
                                },this);
                            }
                            else {
                                asyncCall();
                            }
                            break;
                        case 'download':
                            var formData = getFormData();
                            if (formData === false){
                                callbackery.ui.MsgBox.getInstance().error(
                                    this.tr("Validation Error"),
                                    this.tr("The form can only be submitted when all data fields have valid content.")
                                );
                                return;
                            }
                            var key = btCfg.key;
                            callbackery.data.Server.getInstance().callAsyncSmart(function(cookie){
                                var iframe = new qx.ui.embed.Iframe().set({
                                    width: 100,
                                    height: 100
                                });
                                iframe.addListener('load',function(e){
                                    var response = {
                                        exception: {
                                            message: String(that.tr("No Data")),
                                            code: 9999
                                        }
                                    };
                                    try {
                                        response = qx.lang.Json.parse(iframe.getBody().innerHTML);
                                    } catch (e){};
                                    if (response.exception){
                                        callbackery.ui.MsgBox.getInstance().error(
                                            that.tr("Download Exception"),
                                            that.xtr(response.exception.message) + " ("+ response.exception.code +")"
                                        );
                                    }
                                    that.getApplicationRoot().remove(iframe);
                                });
                                iframe.setSource(
                                    'download'
                                    +'?key='+key
                                    +'&xsc='+encodeURIComponent(cookie)
                                    +'&name='+cfg.name
                                    +'&formData='+encodeURIComponent(qx.lang.Json.stringify(formData))
                                );
                                that.getApplicationRoot().add(iframe,{top: -1000,left: -1000});
                            },'getSessionCookie');
                            break;
                        case 'cancel':
                            this.fireDataEvent('actionResponse',{action: 'cancel'});
                            break;
                        case 'wizzard':
                            var parent = that.getLayoutParent();
                            while (! parent.classname.match(/Page|Popup/) ) {
                                parent = parent.getLayoutParent();
                            }
                            // This could in principal work for Page although.
                            if (parent.classname.match(/Popup/)) { // parent already exists, replace content
                                parent.replaceContent(btCfg,getFormData);
                                break;
                            }
                            // fall through intended to create first popup content
                        case 'popup':
                            if (! btCfg.noValidation) { // backward incompatibility work around
                                var formData = getFormData();
                                if (formData === false){
                                    callbackery.ui.MsgBox.getInstance().error(
                                        this.tr("Validation Error"),
                                        this.tr("The form can only be submitted when all data fields have valid content.")
                                    );
                                    return;
                                }
                            }
                            var popup = new callbackery.ui.Popup(btCfg,getFormData, this);

                            var appRoot = that.getApplicationRoot();
                    
                            popup.addListenerOnce('close',function(){
                                // wait for stuff to happen before we rush into
                                // disposing the popup
                                qx.event.Timer.once(function(){
                                    appRoot.remove(popup);
                                    popup.dispose();
                                    this.fireEvent('popupClosed');
                                },that,100);
                                if (!(btCfg.options && btCfg.options.noReload)){
                                    this.fireDataEvent('actionResponse',{action: ( btCfg.options && btCfg.options.reloadStatusOnClose ) ? 'reloadStatus' : 'reload'});
                                }
                            },that);
                            popup.open();
                            break;
                        case 'logout':
                            that.fireDataEvent('actionResponse',{action: 'logout'});
                            break;

                        default:
                            this.debug('Invalid execute action:' + btCfg.action);
                    }
                }; // var action = function() { ... };

                if (btCfg.defaultAction){
                    this._defaultAction = action;
                }
                if (button){
                    button.addListener('execute',action,this);
                    if (btCfg.addToMenu) {
                        menues[btCfg.addToMenu].add(button);
                    }
                    else {
                        if (btCfg.addToToolBar !== false) {
                            this.add(button);
                        }
                    }
                }
                if (menuButton){
                    menuButton.addListener('execute',action,this);
                    this._tableMenu.add(menuButton);
                }
            },this);
        },
        _makeUploadButton: function(cfg,btCfg,getFormData){
            var button;
            var label = btCfg.label ? this.xtr(btCfg.label) : null;
            if (btCfg.btnClass == 'toolbar') {
                button = new callbackery.ui.form.UploadToolbarButton(label);
            }
            else {
                button = new callbackery.ui.form.UploadButton(label);
            }
            if (btCfg.key){
                this._buttonMap[btCfg.key]=button;
            }
            if (btCfg.buttonSet) {
                var bs = btCfg.buttonSet;
                if (bs.label) {
                    bs.label = this.xtr(bs.label);
                }
                button.set(bs);
                if (btCfg.key){
                    this._buttonSetMap[btCfg.key]=bs;
                }
            }
            var serverCall = callbackery.data.Server.getInstance();
            var key = btCfg.key;
            var name = cfg.name;
            button.addListener('changeFileSelection',function(e){
                var fileList = e.getData();
                var formData = getFormData();
                if(formData && fileList) {
                    var form = new FormData();
                    form.append('name',name);
                    form.append('key',key);
                    form.append('file',fileList[0]);
                    form.append('formData',qx.lang.Json.stringify(formData));
                    var that = this;
                    serverCall.callAsyncSmart(function(cookie){
                        form.append('xsc',cookie);
                        that._uploadForm(form);
                    },'getSessionCookie');
                } else {
                    callbackery.ui.MsgBox.getInstance().error(
                        this.tr("Upload Exception"),
                        this.tr("Make sure to select a file and properly fill the form")
                    );
                }
            },this);

            
            return button;
        },

        _uploadForm: function(form){
            var req = new qx.io.request.Xhr("upload",'POST').set({
                requestData: form
            });
            req.addListener('success',function(e) {
                var response = req.getResponse();
                if (response.exception){
                    callbackery.ui.MsgBox.getInstance().error(
                        this.tr("Upload Exception"),
                        this.xtr(response.exception.message) 
                            + " ("+ response.exception.code +")"
                    );
                } else {
                    this.fireDataEvent('actionResponse',response);
                }
                req.dispose();
            },this);
            req.addListener('fail',function(e){
                var response = {};
                try {
                    response = req.getResponse();
                }
                catch(e){
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
                        + " ("+ response.exception.code +")"
                );
                req.dispose();
            });
            req.send();
        },

        getTableContextMenu: function(){
            return this._tableMenu;
        },

        getDefaultAction: function(){
            return this._defaultAction;
        },
        getButtonMap: function(){
            return this._buttonMap;
        },
        getButtonSetMap: function(){
            return this._buttonSetMap;
        }
    },
    destruct : function() {
        if (! this._buttonMap) {
            return;
        }
        for (const [key, btn] of Object.entries(this._buttonMap)) {
            btn.destroy();
        }
    }
});
