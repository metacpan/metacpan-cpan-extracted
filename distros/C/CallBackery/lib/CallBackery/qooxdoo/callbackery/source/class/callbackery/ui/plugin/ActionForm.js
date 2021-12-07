/* ************************************************************************
   Copyright: 2021 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
              Fritz Zaucker <fritz.zaucker@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Action Form Widget.
 */
qx.Class.define("callbackery.ui.plugin.ActionForm", {
    extend : qx.ui.container.Composite,
    /**
     * create a page for the View Tab with the given title
     *
     * @param cfg {Object} plugin configuration map
     * @param getParentFormData {Function} method to get form data from parent
     */
    construct : function(cfg,getParentFormData) {
        this.base(arguments);
        let buttonClass = qx.ui.form.Button;
        this.setLayout(new qx.ui.layout.VBox(10));
        // handle screenCfg attributes
        if (cfg.introText) {
            this.add(new qx.ui.basic.Label(this.xtr(cfg.introText)).set({rich: true}));
        }
        let grid;
        let gridCfg = cfg.gridCfg;
        if (gridCfg) {
            grid = new qx.ui.layout.Grid(
                gridCfg.spacingX || 10,
                gridCfg.spacingY || 20
            );
        }
        else {
            grid = new qx.ui.layout.Grid(10,20);
        }
        this._grid = grid;
        let form = this._form = new qx.ui.container.Composite(grid);
        this.add(form);
        var btnRow = this._btnRow = new qx.ui.container.Composite(
            new qx.ui.layout.HBox(10, 'right'));
        this.add(btnRow);
        this._buttonMap = {};
        this._buttonSetMap = {};
        this._populate(cfg,buttonClass,getParentFormData);
        this.addOwnedQxObject(grid, 'Action');
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
        _form: null,
        _grid : null,
        _btnRow : null,
        _tableMenu: null,
        _defaultAction: null,
        _buttonMap: null,

        _populate: function(cfg,buttonClass,getParentFormData){
            var menues = {};
            let row = 0, descColumn= 1, btnColumn = 0;
            let gridCfg = cfg.gridCfg;
            let grid = this._grid;
            if (gridCfg && gridCfg.btnWidth) {
                grid.setColumnWidth(btnColumn, gridCfg.btnWidth);
            }
            if (gridCfg && gridCfg.descWidth) {
                grid.setColumnWidth(descColumn, gridCfg.descWidth);
            }
            else {
                grid.setColumnWidth(descColumn, 400);
            }
            cfg.action.forEach(function(btCfg){
                grid.setRowAlign(row, 'right', 'middle');
                var button, menuButton, description;
                var label = btCfg.label ? this.xtr(btCfg.label) : null;
                switch (btCfg.action) {
                    case 'menu':
                        var menu = menues[btCfg.key] = new qx.ui.menu.Menu;
                        if (btCfg.addToMenu != null) { // add submenu to menu
                            button = new qx.ui.menu.Button(label, null, null, menu)
                            menues[btCfg.addToMenu].add(button);
                        }
                        else { // add menu to form
                            grid.setRowAlign(row, 'left', 'middle');
                            button = new qx.ui.form.MenuButton(label, null, menu);
                            this._form.add(button, {row : row, column :  btCfg.btnColumn || btnColumn});
                            if (btCfg.description) {
                                description = new qx.ui.basic.Label(this.xtr(btCfg.description));
                                description.setRich(true);
                                this._form.add(description, { row : row++, column :  btCfg.descColumn || descColumn});
                            }
                        }
                        grid.addOwnedQxObject(button, btCfg.key + 'Button');
                        this._buttonMap[btCfg.key]=button;
                        return;
                        break;
                    case 'submit':
                    case 'popup':
                    case 'wizzard':
                    case 'logout':
                    case 'cancel':
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
                                grid.addOwnedQxObject(menuButton, btCfg.key + 'MenuButton');
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
                    case 'separator':
                        this._form.add(new qx.ui.core.Spacer(btCfg.width || 10, btCfg.height || 10), {row : row++, column : descColumn});
                        break;
                    default:
                        this.debug('Invalid execute action:' + btCfg.action + ' for button', btCfg);
                }
                if (button && btCfg.key) {
                    grid.addOwnedQxObject(button, btCfg.key + 'Button');
                }
                var action = function(){
                    var that = this;
                    if (! button.isEnabled()) {
                        return;
                    }
                    switch (btCfg.action) {
                        case 'submit':
                            var formData = getParentFormData();
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

                            asyncCall();
                            break;
                        case 'cancel':
                            this.fireDataEvent('actionResponse',{action: 'cancel'});
                            break;
                        case 'popup':
                            if (! btCfg.noValidation) { // backward incompatibility work around
                                var formData = getParentFormData();
                                if (formData === false){
                                    callbackery.ui.MsgBox.getInstance().error(
                                        this.tr("Validation Error"),
                                        this.tr("The form can only be submitted when all data fields have valid content.")
                                    );
                                    return;
                                }
                            }
                            var popup = new callbackery.ui.Popup(btCfg,getParentFormData, this);
                            var appRoot = that.getApplicationRoot();
                            popup.addListenerOnce('close',function(){
                                // wait for stuff to happen before we rush into
                                // disposing the popup
                                qx.event.Timer.once(function(){
                                    appRoot.remove(popup);
                                    popup.dispose();
                                    this.fireEvent('popupClosed');
                                },that,100);
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
                            if (btCfg.action == 'cancel') {
                                this._btnRow.add(button);
                            }
                            else {
                                grid.setRowAlign(row, 'left', 'middle');
                                this._form.add(button, {row : row, column : btCfg.btnColumn || btnColumn});
                                if (btCfg.description) {
                                    description = new qx.ui.basic.Label(this.xtr(btCfg.description));
                                    description.setRich(true);
                                    this._form.add(description, {row : row++, column : btCfg.descColumn || descColumn});
                                }
                            }
                        }
                    }
                }
            },this);
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
