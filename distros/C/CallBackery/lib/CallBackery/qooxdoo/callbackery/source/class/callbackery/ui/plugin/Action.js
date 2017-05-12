/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Abstract Visualization widget.
 */
qx.Class.define("callbackery.ui.plugin.Action", {
    extend : qx.ui.container.Composite,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embedd
     */
    construct : function(cfg,buttonClass,layout,getFormData) {
        this.base(arguments, layout);
        this._populate(cfg,buttonClass,getFormData);
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
                case 'dataSaved':
                case 'showMessage':
                    if (data.title && data.message){
                        callbackery.ui.MsgBox.getInstance().info(this['tr'](data.title),this['tr'](data.message));
                    }
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
        _tableMenu: null,
        _defaultAction: null,
        _populate: function(cfg,buttonClass,getFormData){
            var tm = this._tableMenu =  new qx.ui.menu.Menu;
            cfg.action.forEach(function(btCfg){
                var button;
                var menuButton;
                switch (btCfg.action) {
                    case 'submitVerify':
                    case 'submit':
                    case 'popup':
                    case 'logout':
                    case 'cancel':
                    case 'download':
                        button = new buttonClass(this['tr'](btCfg.label));
                        if ( btCfg.addToContextMenu ){
                             menuButton = new qx.ui.menu.Button(this['tr'](btCfg.label));
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
                            timer.stop(timerId);
                        }, this);
                        break;
                    case 'upload':
                        this._addUploadButton(cfg,btCfg,getFormData);
                        break;
                    case 'separator':
                        this.add(new qx.ui.core.Spacer(10,10));
                        break;
                    default:
                        this.debug('Invalid execute action:' + btCfg.action);
                }
                var action = function(){
                    var that = this;
                    switch (btCfg.action) {
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
                                callbackery.ui.MsgBox.getInstance().yesno(
                                    this['tr'](btCfg.label),
                                    this['tr'](btCfg.question)
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
                            var that = this;
                            callbackery.data.Server.getInstance().callAsyncSmart(function(cookie){
                                var iframe = new qx.ui.embed.Iframe().set({
                                    width: 100,
                                    height: 100
                                });
                                iframe.addListener('load',function(e){
                                    var response = {
                                        exception: {
                                            message: that.tr("No Data"),
                                            code: 9999
                                        }
                                    };
                                    try {
                                        response = qx.lang.Json.parse(iframe.getBody().innerHTML);
                                    } catch (e){};
                                    if (response.exception){
                                        callbackery.ui.MsgBox.getInstance().error(
                                            that.tr("Download Exception"),
                                            that['tr'](response.exception.message) + " ("+ response.exception.code +")"
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
                        case 'popup':
                        var popup = new callbackery.ui.Popup(btCfg,getFormData);
                            popup.addListenerOnce('close',function(){
                                // wait for stuff to happen befor we rush into
                                // disposing the popup
                                qx.event.Timer.once(function(){
                                    this.getApplicationRoot().remove(popup);
                                    popup.dispose();
                                    this.fireEvent('popupClosed');
                                },this,100);
                                if (!(btCfg.options && btCfg.options.noReload)){
                                    this.fireDataEvent('actionResponse',{action: 'reload'});
                                }
                            },this);
                            if (btCfg.set){
                                popup.set(btCfg.set);
                            }
                            popup.open();
                            break;
                        case 'logout':
                            this.fireDataEvent('actionResponse',{action: 'logout'});
                            break;

                        default:
                            this.debug('Invalid execute action:' + btCfg.action);
                    }
                };

                if (btCfg.defaultAction){
                    this._defaultAction = action;
                }
                if (button){
                    button.addListener('execute',action,this);
                    this.add(button);
                }
                if (menuButton){
                    menuButton.addListener('execute',action,this);
                    this._tableMenu.add(menuButton);
                }
            },this);
        },
        _addUploadButton: function(cfg,btCfg,getFormData){
            var form = new uploadwidget.UploadForm('uploadFrm','upload');
            form.setParameter('name',cfg.name);
            form.setParameter('key',btCfg.key);
            form.setLayout(new qx.ui.layout.HBox());
            this.add(form);
            var file;
            if (btCfg.btnClass == 'toolbar') {
                file = new uploadwidget.UploadToolbarButton('file', this['tr'](btCfg.label));
            }
            else {
                file = new uploadwidget.UploadButton('file', this['tr'](btCfg.label));
            }
            form.add(file);
            file.addListener('execute',function(e){
                var formData = getFormData();
                if (formData === false){
                    callbackery.ui.MsgBox.getInstance().error(
                        this.tr("Validation Error"),
                        this.tr("The form can only be submitted when all data fields have valid content.")
                    );
                }
            });
            file.addListener('changeFileName',function(e){
                var formData = getFormData();
                if(formData && e.getData() !='') {
                    form.setParameter('formData',qx.lang.Json.stringify(formData));
                    // console.log(file.getFileName(),file.getFileSize());
                    callbackery.data.Server.getInstance().callAsyncSmart(function(cookie){
                        form.setParameter('xsc',cookie);
                        form.send();
                    },'getSessionCookie');
                }
            },this);

            form.addListener('completed',function(e) {
                form.clear();
                var response = {};
                try {
                    response = qx.lang.Json.parse(form.getIframeTextContent());
                }
                catch(e){
                    response = {
                        exception: {
                            message: e.message,
                            code: 99999
                        }
                    };
                }
                if (response.exception){
                    callbackery.ui.MsgBox.getInstance().error(
                        this.tr("Upload Exception"),
                        this['tr'](response.exception.message) + " ("+ response.exception.code +")"
                    );
                    return;
                }
                if (response){
                    this.fireDataEvent('actionResponse',response || {});
                }
            },this);

        },

        getTableContextMenu: function(){
            return this._tableMenu;
        },

        getDefaultAction: function(){
            return this._defaultAction;
        }
    }
});
