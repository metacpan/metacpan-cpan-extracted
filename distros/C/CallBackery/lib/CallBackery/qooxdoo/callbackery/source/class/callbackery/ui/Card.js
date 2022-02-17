/* ************************************************************************
   Copyright: 2021 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Fritz Zaucker <fritz.zaucker@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Hin Cred List
 */
qx.Class.define("callbackery.ui.Card", {
    extend:    qx.ui.core.Widget,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embedd
     */
    construct: function(cfg, buttonMap, parentForm) {
        this.base(arguments);
        this._cardCfg      = cfg.cardCfg;
        this._updateAction = cfg.updateAction;
        this.__pluginName  = cfg.name;
        this.__buttonMap   = buttonMap;
        this.__parentForm  = parentForm;
        this._formCfg      = {};
        this.__dataCache   = {};

        this.__actions = [];
        cfg.action.forEach(function(action) {
            if (action.addToContextMenu) {
                this.__actions.push(action);
            }
        }, this);

        this.__buildForm();
    },
    properties: {
        appearance: {
            refine: true,
            init:   "cred-card"
        }
    },
    members: {
        _cardCfg      : null,
        _formCfg      : null,
        _updateAction : null,
        __actions     : null,
        __dataCache   : null,
        __fields      : null,
        __pluginName  : null,
        __buttonMap   : null,
        __parentForm  : null,

        setData: function(data) {
            var cardCfg = this._cardCfg;
            var fld     = this.__fields;
            var last    = this.__dataCache;
            last.id     = data.id;
            for (var k in fld) {
                if (data[k] !== last[k]) {
                    if (fld[k].setModelSelection) { // SelectBox
                        fld[k].setModelSelection([data[k]]);
                    }
                    else { // e.g. TextField
                        if (data[k] == null) {
                            fld[k].setValue('');
                        }
                        else {
                            fld[k].setValue(String(this.xtr(data[k]) || ''));
                        }
                    }
                    last[k] = data[k];
                }
            }
        },

        __createButton: function(label, icon) {
            var btn = new qx.ui.form.Button(label, icon).set({
                alignY:     'bottom',
                height:     32,
                width:      30,
                allowGrowY: false,
                allowGrowX: false,
                padding:    [8, 8, 8, 8]
            });
            return btn;
        },

        __buildForm: function() {
            var fld     = this.__fields = {};
            var cardCfg = this._cardCfg;
            var formCfg = cardCfg.form;

            if (! formCfg) {
                console.error('no formCfg: cardCfg=', cardCfg);
                return;
            }
            // set layout
            var layoutCfg   = cardCfg.layout;
            var layoutClass = qx.ui.layout.Grid; // default
            if (layoutCfg && layoutCfg.class)
                layoutClass = qx.Bootstrap.getByName(layoutCfg.class);
            var layout = new layoutClass;
            if (layoutCfg && layoutCfg.setFunctions) {
                for (const [func, argsArray] of Object.entries(layoutCfg.setFunctions)) {
                    for (let args of argsArray) {
                        layout[func].apply(layout, args);
                    }
                }
            }
            this._setLayout(layout);

            // add form elements
            formCfg.forEach(function(cfg) {
                var labelCfg = cfg.label;
                var fieldCfg = cfg.field;

                // add label
                if (labelCfg) {
                    var label = new qx.ui.basic.Label().set({
                        textColor    : 'material-label',
                        allowShrinkX : true,
                        allowGrowX   : true,
                        font         : 'cardLabel'
                    });
                    if (labelCfg.set) {
                        label.set(labelCfg.set);
                        // canot use set({}) with xtr().
                        // TODO: fix xtr() return
                        if (labelCfg.set.value) {
                            label.setValue(this.xtr(labelCfg.set.value));
                        }
                    }
                    this._add(label, labelCfg.addSet);
                }

                // add field
                if (fieldCfg) {
                    var key = fieldCfg.key;
                    this._formCfg[key] = fieldCfg;
                    var className = fieldCfg.class ? fieldCfg.class : 'TextField';
                    if (! className.match(/^qx/)) {
                        className = 'qx.ui.form.' + className;
                    }
                    var fieldClass = qx.Bootstrap.getByName(className);
                    var field = new fieldClass;
                    if (fieldCfg.set) {
                        field.set(fieldCfg.set);
                    }
                    var event;
                    if (field.setLiveUpdate && ! field.getReadOnly()) { // TextField
                        field.setLiveUpdate(true);
                        event = 'changeValue';
                    }
                    if (field.setModelSelection) { // SelectBox
                        if (fieldCfg.items) {
                            for (let item of fieldCfg.items) {
                                field.add(new qx.ui.form.ListItem(this.xtr(item[1]), null, item[0]));
                            }
                        }
                        event = 'changeSelection';
                    }
                    if (event) {
                        if (event == 'changeSelection') {
                            field.addListener(event, (e) => {
                                let value = e.getData()[0].getModel();
                                this.__parentForm.setSelection({ data : this.__dataCache, key : fieldCfg.key, value : value });
                                if (this.__buttonMap[this._updateAction]) {
                                    this.__buttonMap[this._updateAction].execute();
                                }
                                else {
                                    console.warn('No method for updateCard:', this._updateAction);
                                }
                            });
                        }
                        else {
                            // For input fields we collect multiple fast inputs and only store
                            // if no new input events occur for a certain time
                            let delay = 500; // msec
                            let updateTimer, lastValue;

                            // store input callback for updateTimer
                            let storeInput = () => {
                                updateTimer.stop();
                                let value = field.getValue();
                                if (value === lastValue) {
                                    return;
                                }
                                lastValue = value;
                                this.__parentForm.setSelection({ data : this.__dataCache, selectedField : fieldCfg.key, newValue : value });
                                if (this.__buttonMap[this._updateAction]) {
                                    this.__buttonMap[this._updateAction].execute();
                                }
                                else {
                                    console.warn('No method for updateCard:', this._updateAction);
                                }
                            };

                            // called on inputs into the field
                            field.addListener(event, (e) => {
                                if (updateTimer) {
                                    // delay storing on repeated inputs while timer is running
                                    updateTimer.restart();
                                }
                                else {
                                    // create and start timer on first input
                                    updateTimer = new qx.event.Timer(delay);
                                    updateTimer.addListener("interval", storeInput, this);
                                }
                            });
                        }
                    }
                    this._add(field, fieldCfg.addSet);
                    fld[fieldCfg.key] = field;
                }
            }, this);

            // add action buttons
            this.__actions.forEach(function(action) {
                var btn = this.__createButton(action.label, action.buttonSet.icon);
                btn.addListener('execute', function() {
                    this.__parentForm.setSelection(this.__dataCache);
                    this.__buttonMap[action.key].execute();
                }, this);
                this._add(btn, action.cardAddSet);
            }, this);
        }
    }
});
