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

        this.addListener('actionResponse', function(e){
            var data = e.getData();
            switch (data.action){
            case 'reload':
            case 'dataModified':
                this._loadData();
                break;
            }
        }, this);
    },
    members: {
        __cards    : null,
        __cardList : null,

        _addValidation : function() {
        },
        
        _createTable : function() {
            this.__cardList = new qx.ui.container.Composite(new qx.ui.layout.VBox(0));
            this.__cards    = {};
            var scroll      = new qx.ui.container.Scroll().set({scrollbarX: 'off'});
            scroll.add(this.__cardList);

            this._form.addListener('changeData', this._loadData, this);

            return scroll;
        },

        // called from form appear listener
        _loadData : function() {
            var that = this;
            var rpc = callbackery.data.Server.getInstance();
            var currentFormData = this._form.getData();
            var busy = callbackery.ui.Busy.getInstance();
            busy.manifest(this.tr('Loading Card Data'));
            this._loading++;
            rpc.callAsync(function(data,exc){
                if (!exc){
                    that.setData(data,true);
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
            }, 'getPluginData', this._cfg.name, 'allCardData', currentFormData);
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
            var buttonMap = this._action.getButtonMap();
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
            for ( var key in cards ) {
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
