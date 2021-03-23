/* ************************************************************************
   Copyright: 2017 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
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
    },
    members: {
        __cards    : null,
        __cardList : null,

        _addValidation: function(){
        },
        
        _createTable : function() {
            this.__cards = {};
            var scroll   = new qx.ui.container.Scroll().set({scrollbarX: 'off'});
            this.__cardList = new qx.ui.container.Composite(new qx.ui.layout.VBox(0));
            scroll.add(this.__cardList);
            return scroll;
        },

        setData: function (data){
            if (!Array.isArray(data)) {
                console.warn('data is not an array');
                return;
            }
            var cards = this.__cards;
            var currentKeys = {};
            var that = this;

            var cardActions = [];
            this._cfg.action.forEach(function(action) {
                if (action.addToContextMenu) {
                    cardActions.push(action);
                }
            }, this);
            
            // add new cards
            var buttonMap = this._action.getButtonMap();
            if (data.forEach) {
                data.forEach(function(row){
                    var key = row.id;
                    currentKeys[key] = 1;
                    if (!cards[key]){
                        var card = cards[key] = new callbackery.ui.Card(this._cfg.name, this._cfg.cardCfg, cardActions, buttonMap, that);
                        that.__cardList.addAt(card,0);
                        card.addListener('reloadData',function(){
                            this._loadData();
                        }, that);
                    }
                    cards[key].setData(row);
                },this);
            }
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
