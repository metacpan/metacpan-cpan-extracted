/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPLv3 or later
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/**
 * Create a form. The argument to the form
 * widget defines the structure of the form.
 *
 *     [
 *         {
 *           key: 'xyc',             // unique name
 *           label: 'label',
 *           widget: 'text',
 *           cfg: {},                // widget specific configuration
 *           set: {}                 // normal qx porperties to apply
 *          },
 *          ....
 *     ]
 *
 * The following widgets are supported: date, text, selectbox
 *
 *     text: { },
 *     selectBox: { cfg { structure: [ {key: x, title: y}, ...] } },
 *     date: { },                    // following unix tradition, dates are represented in epoc seconds
 *
 * Populate the new form using the setDate method, providing a map
 * with the required data.
 *
 */
qx.Class.define("callbackery.ui.form.Auto", {
    extend : qx.ui.core.Widget,


    /**
     * @param structure {Array} form structure
     * @param layout {Incstance} qooxdoo layout instance
     * @param formRenderer {Class} qooxdoo form render class
     */
    construct : function(structure, layout, formRenderer) {
        this.base(arguments);
        this._setLayout(layout || new qx.ui.layout.Grow());
        var form = this._form = new qx.ui.form.Form();
        this._ctrl = {};
        var formCtrl = new qx.data.controller.Form(null, form);
        this._boxCtrl = {};
        var tm = this._typeMap = {};
        var that = this;
        structure.forEach(function(s){
            var options = {};
            ['note','copyOnTap','copyFailMsg','copySuccessMsg'].forEach(function(prop){
                if (s[prop]){
                    options[prop] = qx.lang.Type.isString(s[prop]) ?
                        that['tr'](s[prop]) : s[prop];
                }
            });
            if (s.widget == 'header') {
                form.addGroupHeader(s.label != null ? this['tr'](s.label) : null,options);
                return;
            }

            if (s.key == null) {
                throw new Error('the key property is required');
            }


            var cfg = s.cfg || {};
            var control;

            switch(s.widget)
            {
                case 'date':
                    control = new qx.ui.form.DateField().set({
                        dateFormat  : new qx.util.format.DateFormat(this.tr("dd.MM.yyyy"))
                    });

                    tm[s.key] = 'date';
                    break;

               case 'dateTime':
                    control = new callbackery.ui.form.DateTime().set({
                        dateFormat  : new qx.util.format.DateFormat(this.tr("dd.MM.yyyy"))
                    });
                    tm[s.key] = 'dateTime';
                    break;

                case 'text':
                case 'time':
                    control = new qx.ui.form.TextField();
                    tm[s.key] = 'text';
                    break;
                case 'password':
                    control = new qx.ui.form.PasswordField();
                    tm[s.key] = 'text';
                    break;
                case 'textArea':
                    control = new qx.ui.form.TextArea();
                    tm[s.key] = 'text';
                    break;
                case 'hiddenText':
                    control = new qx.ui.form.TextField();
                    control.exclude();
                    tm[s.key] = 'text';
                    break;

                case 'checkBox':
                    control = new qx.ui.form.CheckBox();
                    tm[s.key] = 'bool';
                    break;

                case 'selectBox':
                    control = new qx.ui.form.SelectBox();
                    var ctrl = this._boxCtrl[s.key] = new qx.data.controller.List(null, control, 'title');
                    ctrl.setDelegate({
                        bindItem : function(controller, item, index) {
                            controller.bindProperty('key', 'model', null, item, index);
                            controller.bindProperty('title', 'label', null, item, index);
                        }
                    });
                    cfg.structure.forEach(function(item){
                        item.title = item.title != null ? this['tr'](item.title) : null;
                    },this);
                    var sbModel = qx.data.marshal.Json.createModel(cfg.structure ||
                    [ {
                        title : '',
                        key   : null
                    } ]);

                    ctrl.setModel(sbModel);
                    break;

                case 'comboBox':
                    control = new qx.ui.form.ComboBox();
                    var ctrl = this._boxCtrl[s.key] = new qx.data.controller.List(null, control);
                    cfg.structure.forEach(function(item){
                        item = item != null ? this['tr'](item) : null;
                    },this);
                    var sbModel = qx.data.marshal.Json.createModel(cfg.structure || []);
                    ctrl.setModel(sbModel);
                    break;

                default:
                    throw new Error("unknown widget type " + s.widget);
                    break;
            }

            if (s.set) {
                if (s.widget == 'date') {
                    var dateValue = s.set.value;
                    if (dateValue != null) {
                        if (typeof dateValue == 'number') {
                            dateValue *= 1000; // incoming epoch seconds
                        }
                        control.setValue(new Date(dateValue));
                    }
                    delete s.set.value;
                }
                if (s.set.filter){
                    s.set.filter = RegExp(s.filter);
                }
                if (s.set.placeholder){
                    s.set.placeholder = this['tr'](s.set.placeholder);
                }
                if (s.set.label){
                    s.set.label = this['tr'](s.set.label);
                }
                control.set(s.set);
            }

            this._ctrl[s.key] = control;
            form.add(control, s.label != null ? this['tr'](s.label) : null, null, s.key,null,options);

            if (s.widget == 'date') {
                formCtrl.addBindingOptions(s.key, {
                    converter : function(data) {
                        if (/^\d+$/.test(String(data))) {
                            var d = new Date();
                            d.setTime(parseInt(data) * 1000);
                            var d2 = new Date(d.getUTCFullYear(),d.getUTCMonth(),d.getUTCDate(),0,0,0,0);
                            return d2;
                        }
                        if (qx.lang.Type.isDate(data)){
                            return data;
                        }
                        return null;
                    }
                },
                {
                    converter : function(data) {
                        if (qx.lang.Type.isDate(data)) {
                            var d = new Date(Date.UTC(data.getFullYear(),data.getMonth(),data.getDate(),0,0,0,0));
                            return Math.round(d.getTime()/1000);
                        }

                        return null;
                    }
                });
            }
            if (s.widget == 'dateTime') {
                formCtrl.addBindingOptions(s.key, {
                    converter : function(data) {
                        if (/^\d+$/.test(String(data))) {
                            var d = new Date();
                            d.setTime(parseInt(data) * 1000);
                            return d;
                        }
                        if (qx.lang.Type.isDate(data)){
                            return data;
                        }
                        return null;
                    }
                },
                {
                    converter : function(data) {
                        if (qx.lang.Type.isDate(data)) {
                            return Math.round(data.getTime()/1000);
                        }

                        return null;
                    }
                });
            }
        },this);

        var model = this._model = formCtrl.createModel(true);

        model.addListener('changeBubble', function(e) {
            if (!this._settingData) {
                this.fireDataEvent('changeData', this.getData());
            }
        },
        this);

        var formWgt = new (formRenderer)(form);
        var fl = formWgt.getLayout();

        this._add(formWgt);
    },

    events : {
        /**
         * fire when the form changes content and
         * and provide access to the data
         */
        changeData : 'qx.event.type.Data'
    },

    members : {
        _boxCtrl : null,
        _ctrl : null,
        _form : null,
        _model : null,
        _settingData : false,
        _typeMap : null,


        /**
         * TODOC
         *
         * @return {var} TODOC
         */
        validate : function() {
            return this._form.validate();
        },


        /**
         * TODOC
         *
         */
        reset : function() {
            this._form.reset();
        },


        /**
         * get a handle to the control with the given name
         *
         * @param key {var} TODOC
         * @return {var} TODOC
         */
        getControl : function(key) {
            return this._ctrl[key];
        },


        /**
         * fetch the data for this form
         *
         * @return {var} TODOC
         */
        getData : function() {
            return this._getData(this._model);
        },


        /**
         * load new data into the data main model
         *
         * @param data {var} TODOC
         * @param relax {var} TODOC
         */
        setData : function(data, relax) {
            this._setData(this._model, data, relax);
        },


        /**
         * set the data in a selectbox
         *
         * @param box {var} TODOC
         * @param data {var} TODOC
         */
        setSelectBoxData : function(box, data) {
            var model;
            this._settingData = true;
            var ctrl = this._boxCtrl[box];
            var value = ctrl.getSelection().toArray()[0];
            if (data.length == 0) {
                model = qx.data.marshal.Json.createModel([ {
                    title : '',
                    key   : null
                } ]);
            }
            else {
                model = qx.data.marshal.Json.createModel(data);
            }

            ctrl.setModel(model);
            ctrl.setSelection(new qx.data.Array([value]));
            this._settingData = false;
        },


        /**
         * load new data into a model
         * if relax is set unknown properties will be ignored
         *
         * @param model {var} TODOC
         * @param data {var} TODOC
         * @param relax {var} TODOC
         */
        _setData : function(model, data, relax) {
            this._settingData = true;

            for (var key in data) {
                var upkey = qx.lang.String.firstUp(key);
                var setter = 'set' + upkey;
                var getter = 'get' + upkey;
                var value = data[key];
                if (relax && !model[setter]) {
                    continue;
                }

                switch(this._typeMap[key])
                {
                    case 'text':
                        model[setter]((value !== undefined && value !== null) ? String(value) : null);
                        break;

                    case 'bool':
                        if (value === null) {
                            value = false;
                        }
                        model[setter](qx.lang.Type.isBoolean(value) ? value : parseInt(value) != 0);
                        break;

                    case 'date':
                        model[setter](value);
                        break;

                     case 'dateTime':
                        model[setter](value);
                        break;

                      default:
                        model[setter](qx.lang.Type.isNumber(model[getter]()) ? parseInt(value) : value);
                        break;
                }
            }

            this._settingData = false;

            /* only fire ONE if there was an attempt at change */

            this.fireDataEvent('changeData', this.getData());
        },


        /**
         * turn a model object into a plain data structure
         *
         * @param model {var} TODOC
         * @return {var} TODOC
         */
        _getData : function(model) {
            var props = model.constructor.$$properties;
            var data = {};

            for (var key in props) {
                var getter = 'get' + qx.lang.String.firstUp(key);
                data[key] = model[getter]();
            }

            return data;
        }
    }
});
