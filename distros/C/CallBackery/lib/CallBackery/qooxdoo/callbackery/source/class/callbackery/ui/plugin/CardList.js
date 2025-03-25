/* ************************************************************************
   Copyright: 2021 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Fritz Zaucker <fritz.zaucker@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Cardlist Visualization Widget.
 */
qx.Class.define("callbackery.ui.plugin.CardList", {
    extend : callbackery.ui.plugin.Table,
    construct : function(cfg, getParentFormData) {
        this.base(arguments, cfg, getParentFormData);

        // replace setData method of parent class
        this._form['setData'] = qx.lang.Function.bind(this.setData, this);
        this._getParentFormData = getParentFormData;

        this.addListener('actionResponse', function(e){
            let data = e.getData();
            switch (data.action){
            case 'reload':
            case 'dataModified':
                this._loadData();
                break;
            }
        }, this);
    },
    properties: {
        info: {
            init: {},
            nullable: true,
            event: 'changeInfo',
            apply: '_applyInfo'
        }
    },
    members: {
        __cards    : null,
        __cardList : null,
        __info      : null,

        // no validation here
        _addValidation : function() {
        },

        _createInfo() {
            this.__info = new qx.ui.basic.Atom().set({
                padding: [5, 0, 5, 0],
                visibility: 'excluded',
            });
            return this.__info;
        },

        _applyInfo(info, old) {
            if (info && info.label) {
                this.__info.setVisibility('visible');
            }
            else {
                this.__info.setVisibility('excluded');
            }
            this.__info.set(info);
        },

        _createTable : function() {
            this.__cardList = new qx.ui.container.Composite(new qx.ui.layout.VBox(0));
            this.__cards = {};
            let vbox = new qx.ui.container.Composite(new qx.ui.layout.VBox(0));
            vbox.add(this._createInfo());
            let scroll = new qx.ui.container.Scroll().set({scrollbarX: 'off'});
            scroll.add(this.__cardList);
            vbox.add(scroll, {flex: 1});
            this._form.addListener('changeData', this._loadData, this);
            return vbox;
        },

        // called from form appear listener
        _loadData : function() {
            let that = this;
            let rpc = callbackery.data.Server.getInstance();
            let currentFormData = this._form.getData();
            let parentFormData;
            if (this._getParentFormData) {
                 parentFormData = this._getParentFormData();
            }
            let busy = callbackery.ui.Busy.getInstance();
            busy.manifest(this.tr('Loading Card Data'));
            this._loading++;
            rpc.callAsync(function(data,exc){
                if (!exc){
                    if (Array.isArray(data)){
                        // the data is an array of card data
                        that.setData(data,true);
                        that.setInfo(null);
                    }
                    else {
                        // the data is an object with card data and info
                        that.setData(data.data,true);
                        if (data.info) {
                            // label is the translation key
                            data.info.label = that.xtr(data.info.label);
                            that.setInfo(data.info);
                        }
                        else {
                            that.setInfo(null);
                        }
                    }
                    if (that._hasTrigger) {
                        that._reconfForm();
                    }
                }
                else {
                    if (exc.code != 2){ /* 2 is for aborted calls, this happens when the popup is closed */
                        callbackery.ui.MsgBox.getInstance().exc(exc);
                    }
                }
                busy.vanish();
                that._loading--;
            }, 'getPluginData', this._cfg.name, 'getAllCardData', parentFormData, { currentFormData: this._form.getData()});
        },

        // now special handling here
        _loadDataReadOnly: function(){
            this._loadData();
        },

        setData : function (data) {
            if (!Array.isArray(data)) {
                console.warn('data is not an array: data=', data);
                return;
            }
            let cards = this.__cards;
            let currentKeys = {};
            let that = this;

            // add new cards
            let buttonMap = this._action.getButtonMap();
            data.forEach(function(row){
                let key = row.id;
                currentKeys[key] = 1;
                if (!cards[key]){
                    let card = cards[key] = new callbackery.ui.Card(this._cfg, buttonMap, that);
                    that.__cardList.addAt(card, 0);
                }
                let focusedWidget = qx.ui.core.FocusHandler.getInstance().getFocusedWidget();
                let focusParent;
                if (focusedWidget && focusedWidget.getLayoutParent) {
                    focusParent = focusedWidget.getLayoutParent();
                }
                if (cards[key] !== focusParent) {
                    cards[key].setData(row);
                }
            },this);

            // remove deleted cards
            for ( let key in cards ) {
                if (!currentKeys[key]){
                    that.__cardList.remove(cards[key]);
                    if (cards[key]){
                        cards[key].dispose();
                    }
                    delete cards[key];
                }
            }
        }
    }
});
