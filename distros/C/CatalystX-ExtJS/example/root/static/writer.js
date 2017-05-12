/*!
 * Ext JS Library 3.1.0
 * Copyright(c) 2006-2009 Ext JS, LLC
 * licensing@extjs.com
 * http://www.extjs.com/license
 */
// Application instance for showing user-feedback messages.
var App = new Ext.App({});

Ext.Direct.addProvider(Ext.app.REMOTING_API);


// Typical JsonReader.  Notice additional meta-data params for defining the core attributes of your json-response
var reader = new Ext.data.JsonReader({
	idProperty: 'id'
});

// The new DataWriter component.
var writer = new Ext.data.JsonWriter({
    encode: false,
    writeAllFields: true
});

// Typical Store collecting the Proxy, Reader and Writer together.
var store = new Ext.data.DirectStore({
    id: 'user',
	api: {
		create: User.create,
		update: User.update,
		read: User.read,
		destroy: User.destroy
	},
    reader: reader,
    writer: writer,  // <-- plug a DataWriter into the store just as you would a Reader
    autoSave: true // <-- false would delay executing create, update, destroy requests until specifically told to do so with some [save] buton.
});

// load the store immeditately
store.load();

////
// ***New*** centralized listening of DataProxy events "beforewrite", "write" and "writeexception"
// upon Ext.data.DataProxy class.  This is handy for centralizing user-feedback messaging into one place rather than
// attaching listenrs to EACH Store.
//
// Listen to all DataProxy beforewrite events
//

Ext.data.DataProxy.addListener('beforewrite', function(proxy, action) {
    App.setAlert(App.STATUS_NOTICE, "Before " + action);
});

////
// all write events
//
Ext.data.DataProxy.addListener('write', function(proxy, action, result, res, rs) {
    console.log(proxy, action, result, res, rs);
    App.setAlert(true, action + ':' + res.result.message);
});

////
// all exception events
//
Ext.data.DataProxy.addListener('exception', function(proxy, type, action, options, res) {
    if (type === 'remote') {
        Ext.Msg.show({
            title: 'REMOTE EXCEPTION',
            msg: res.message,
            icon: Ext.MessageBox.ERROR,
            buttons: Ext.Msg.OK
        });
    }
});

// A new generic text field
var textField =  new Ext.form.TextField();

// Let's pretend we rendered our grid-columns with meta-data from our ORM framework.
var userColumns =  [
    {header: "ID", width: 40, sortable: true, dataIndex: 'id'},
    {header: "Email", width: 100, sortable: true, dataIndex: 'email', editor: textField},
    {header: "First", width: 50, sortable: true, dataIndex: 'first', editor: textField},
    {header: "Last", width: 50, sortable: true, dataIndex: 'last', editor: textField}
];

Ext.onReady(function() {
    Ext.QuickTips.init();

    // create user.Form instance (@see UserForm.js)
    var userForm = new App.user.Form({
        renderTo: 'user-form',
        listeners: {
            create : function(fpanel, data) {   // <-- custom "create" event defined in App.user.Form class
                var rec = new userGrid.store.recordType(data);
                userGrid.store.insert(0, rec);
            }
        }
    });

    // create user.Grid instance (@see UserGrid.js)
    var userGrid = new App.user.Grid({
        renderTo: 'user-grid',
        store: store,
        columns : userColumns,
        listeners: {
            rowclick: function(g, index, ev) {
                var rec = g.store.getAt(index);
                userForm.loadRecord(rec);
            },
            destroy : function() {
                userForm.getForm().reset();
            }
        }
    });
});