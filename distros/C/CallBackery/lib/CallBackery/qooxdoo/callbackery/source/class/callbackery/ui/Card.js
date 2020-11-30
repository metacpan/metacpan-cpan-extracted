/* ************************************************************************
   Copyright: 2017 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
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
    construct: function(pluginName, cardCfg, actions, buttonMap, parentForm) {
        this.base(arguments);
        this._formCfg     = cardCfg;
        this.__actions    = actions;
        this.__parentForm = parentForm;
        this.__buttonMap  = buttonMap;
        this.__pluginName = pluginName;

        this.__buildForm();
        this.__dataCache = {};
    },
    properties: {
        appearance: {
            refine: true,
            init:   "cred-card"
        }
    },
    events:  {reloadData: 'qx.event.type.Event'},
    members: {
        _formCfg     : null,
        __actions    : null,
        __dataCache  : null,
        __fields     : null,
        __pluginName : null,
        __buttonMap  : null,
        __parentForm : null,

        setData: function(data) {
            var fld = this.__fields;
            var last = this.__dataCache;
            last['id'] = data.id;
            for (var k in fld) {
                if (data[k] !== last[k]) {
                    if (data[k] == null) {
                        fld[k].setValue('');
                    }
                    else {
                        fld[k].setValue(String(this.xtr(data[k]) || ''));
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
            var cardCfg = this._formCfg;
            var formCfg = cardCfg.form;

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
                    var label = new qx.ui.basic.Label(labelCfg.value).set({
                        textColor    : 'material-label',
                        allowShrinkX : true,
                        allowGrowX   : true,
                        font         : 'cardLabel'
                    });
                    if (labelCfg.set) 
                        label.set(labelCfg.set);
                    this._add(label, labelCfg.addSet);
                }

                // add field
                if (fieldCfg) {
                    var fieldClass = qx.ui.form.TextField; // default
                    if (fieldCfg.class) 
                        fieldClass = qx.Bootstrap.getByName(fieldCfg.class);
                    var field = new fieldClass;
                    if (fieldCfg.set)
                        field.set(fieldCfg.set);
                    if (! field.getReadOnly()) {
                        field.addListener('changeValue', this.__updateEntry, this);
                        field.setLiveUpdate(true);
                    }
                    
                    this._add(field, fieldCfg.addSet);
                    fld[fieldCfg.key] = field;
                }
            }, this);

            // add action buttons
            this.__actions.forEach(function(action) {
                var btn = this.__createButton(action.label, action.buttonSet.icon);
                var buttonMap = this.__buttonMap;
                btn.addListener('execute', function() {
                    this.__parentForm.setSelection(this.__dataCache);
                    buttonMap[action.key].execute();
                }, this);
                this._add(btn, action.cardAddSet);
            }, this);
        },

        __updateEntry: function(e) {
            var value = e.getData();
            var rpc = callbackery.data.Server.getInstance();
            this.__parentForm.setSelection({ data : this.__dataCache, newValue : value });
            this.__buttonMap['updateEntry'].execute();
        }

    }
});
