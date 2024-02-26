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
 *           set: {}                 // normal qx properties to apply
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
 * Populate the new form using the setData method, providing a map
 * with the required data.
 *
 */
qx.Class.define("callbackery.ui.form.Auto", {
    extend : qx.ui.core.Widget,


    /**
     * @param structure {Array} form structure
     * @param layout {Instance} qooxdoo layout for this widget
     * @param formRenderer {Class} qooxdoo form render class
     * @param plugin {Object} CallBackery (parent) widget this widget is added to
     */
    construct : function(structure, layout, formRenderer, plugin) {
        this.base(arguments);
        this._settingData = 0;
        this._setLayout(layout || new qx.ui.layout.Grow());
        var form = this._form = new qx.ui.form.Form();
        if (plugin) {
            plugin.addOwnedQxObject(form, 'Form');
        }
        this._ctrl = {};
        var formCtrl = new qx.data.controller.Form(null, form);
        this._boxCtrl = {};
        this._keyToFormKey = {};
        this._formKeyToKey = {};
        this._selectBoxKeyToItem = {};
        var tm = this._typeMap = {};
        var that = this;
        var formKeyIdx = 0;
        structure.forEach(s => {
            var options = {};
            // value binding in qooxdoo does not like keys
            // with strange characters ... (like -)
            if (s.key) {
                formKeyIdx++;
                var formKey = s.key.replace(/[^_a-z]/ig,'');
                if (this._formKeyToKey[formKey]) {
                    formKey += String(formKeyIdx);
                }
                this._keyToFormKey[s.key] = formKey;
                this._formKeyToKey[formKey] = s.key;
            }
            ['note','copyOnTap','copyFailMsg','copySuccessMsg'].forEach(prop => {
                if (s[prop]){
                    options[prop] = qx.lang.Type.isString(s[prop]) 
                    || qx.lang.Type.isArray(s[prop]) ?
                        that.xtr(s[prop]) : s[prop];
                }
            });
            if (s.widget == 'header') {
                var header = options.widget = 
                    new qx.ui.basic.Label().set({
                        font: 'bold'
                    });
                if (s.key) {
                    form.addOwnedQxObject(header, s.key || s.label);
                    this._ctrl[s.key] = header;
                }
                if (s.set){
                    header.set(s.set);
                }
                form.addGroupHeader(s.label != null ? this.xtr(s.label) : '', options);
                return;
            }

            if (s.key == null) {
                throw new Error('the key property is required');
            }


            var cfg = s.cfg || {};
            var control;
            var textWidget = false;
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
                    textWidget = true;
                case 'time':
                    control = new qx.ui.form.TextField();
                    tm[s.key] = 'text';
                    break;
                case 'password':
                    control = new qx.ui.form.PasswordField();
                    tm[s.key] = 'text';
                    break;
                case 'textArea':
                    textWidget = true;
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
                    tm[s.key] = 'selectBox';
                    control = new callbackery.ui.form.VirtualSelectBox().set({
                        // defaults
                        incrementalSearch : false,
                        highlightMode     : 'html',
                    });
                    this._boxCtrl[s.key] = control;
                    control.setLabelPath("title");
                    control.setDelegate({
                        bindItem : function(controller, item, index) {
                            controller.bindProperty('key',   'model', null, item, index);
                            controller.bindProperty('title', 'label', null, item, index);
                        }
                    });
                    this.setSelectBoxData(s.key,cfg.structure);
                    break;

                case 'comboBox':
                    control = new qx.ui.form.ComboBox();
                    var ctrl = this._boxCtrl[s.key] = new qx.data.controller.List(null, control);
                    cfg.structure.forEach(item => {
                        item = item != null ? this.xtr(item) : null;
                    });
                    var sbModel = qx.data.marshal.Json.createModel(cfg.structure || []);
                    ctrl.setModel(sbModel);
                    break;

                default:
                    throw new Error("unknown widget type " + s.widget);
                    break;
            }
            if (textWidget && s.spellcheck){
               control.getContentElement().setAttribute('spellcheck','true');
            }
            if (s.key) {
                form.addOwnedQxObject(control, s.key);
            }
            if (s.autocomplete) {
                var el = control.getContentElement();
                var ac = s.autocomplete;
                el.setAttribute('autocomplete',ac);
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
                ['placeholder','tooltip','label'].forEach(key => {
                    if (key in s.set){
                       s.set[key] = this.xtr(s.set[key]);
                    }
                });
                control.set(s.set);
            }

            this._ctrl[s.key] = control;
            form.add(control, s.label != null ? this.xtr(s.label) : null, null, formKey,null,options);
            if (s.widget == 'date') {
                formCtrl.addBindingOptions(formKey, {
                    converter : function(data) {
                        if (/^-?\d+$/.test(String(data))) {
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
                formCtrl.addBindingOptions(formKey, {
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
        });

        var model = this._model = formCtrl.createModel(true);

        model.addListener('changeBubble', function(e) {
            if (this._settingData == 0) {
                this.fireDataEvent('changeData', this.getData());
            }
        },
        this);

        var formWgt = new (formRenderer)(form);
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
        _settingData :null,
        _typeMap : null,
        _keyToFormKey: null,
        _formKeyToKey: null,
        _selectBoxKeyToItem: null,


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
            let model;
            if (data.length == 0) {
                model = qx.data.marshal.Json.createModel([ {
                    title : '',
                    key   : null
                }]);
            }
            else {
                data.forEach((item,i) => {
                    item.title = item.title != null 
                        ? this.xtr(item.title) 
                        : null;
                });
                model = qx.data.marshal.Json.createModel(data);
            }
            let lookup = {};
            model.forEach((item,idx) => {
                lookup[item.getKey()] = item;
            });
            this._selectBoxKeyToItem[box] = lookup;
            let ctrl  = this._boxCtrl[box];
            let oldItem = ctrl.getValue();
            let newItem = null;
            if (oldItem){
                if (oldItem.getKey) {
                    newItem = lookup[oldItem.getKey()];
                }
                if (!newItem){
                  console.warn(`SelectBox ${box} has no entry for ${oldItem.getKey()} selecting first item.`);
                }
            }
            this._settingData++;
            ctrl.setModel(model);
            ctrl.setValue(newItem);
            this._settingData--;
        },


        /**
         * set the data in a combobox
         *
         * @param box {var} TODOC
         * @param widget {var} TODOC
         * @param data {var} TODOC
         */
        setComboBoxData : function(box, data) {
            let ctrl  = this._boxCtrl[box];
            this._settingData++;
            ctrl.setModel(qx.data.marshal.Json.createModel(data));
            this._settingData--;
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
            this._settingData++;
            for (var key in data) {
                var formKey = this._keyToFormKey[key];
                if (!formKey) {
                    continue;
                }
                var upkey = qx.lang.String.firstUp(formKey);
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

                    case 'dateTime':
                    case 'date':
                        model[setter](value);
                        break;
                        
                    case 'selectBox':
                        let newItem = this._selectBoxKeyToItem[key][value];
                        if (!newItem) {
                            console.warn(`SelectBox ${key} has no entry for ${value} selecting first Item.`);
                        }
                        this._boxCtrl[key].setValue(newItem);
                        break;

                    default:
                        model[setter](qx.lang.Type.isNumber(model[getter]()) ? parseInt(value) : value);
                        break;
                }
            }
            this._settingData--;

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

            for (var formKey in props) {
                var key = this._formKeyToKey[formKey];
                var getter = 'get' + qx.lang.String.firstUp(formKey);
                data[key] = model[getter]();
                // extract selectbox keys
                if (data[key] && data[key].getKey) {
                    data[key] = data[key].getKey();
                }
            }

            return data;
        }
    }
});
