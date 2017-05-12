// Create namespace
Ext.namespace(
    'MyApp',
    'MyApp.Forms',
    'MyApp.Forms.EditRecord',
    'MyApp.Forms.EditRecord.[% form_name %]'
);

// Define dialog for editing record data
MyApp.Forms.EditRecord.[% form_name %] = Ext.extend( MyApp.widgets.dialog.EditRecord, {
    /**
     * @cfg id of record on db (primary key), defaults to 0
     */
    record_pk_id: 0,

    /**
     * @private
     */
    windowNamePrefix: 'EditRecord_[% form_name %]_',

    
    /**
     * @private!
     */
    rest_url: null,

    layout: 'hfit',
    
    initComponent: function() {
        // REST url for getting and setting values
        this.rest_url = '[% form.action %]/' + this.record_pk_id;

        // Get form fields
        this.items = MyApp.Forms.EditRecord.[% form_name %].getEditForm();

        // Connect afterlayout event to load form data
        this.on( 'afterlayout', this.onAfterLayout, this, {single: true} );
        
        MyApp.Forms.EditRecord.[% form_name %].superclass.initComponent.call(this);

    },
    
    onAfterLayout: function() {
        // Gray out the form area when showing a wait message
        this.getForm().waitMsgTarget = this.getEl();

        // The element (this.getEl) is not available earlier, so we initiate
        // the loading of values from here
        this.dataLoad();
    },

    dataLoad: function() {
        this.load({
            url:        this.rest_url
            ,method:    'GET'
            ,waitMsg:   'Loading...'
            ,scope: this
            ,success: this.onDataLoaded
        });
    },

    onDataLoaded: function(form, action) {
[% IF focus_name -%]
        // set focus
        this.getForm().findField('[% focus_name %]').focus(false, 250);
[% END -%]
    },

    handlerApplyChanges: function(_button, _event, _closeWindow) {
        var form = this.getForm();

        // Check if form fields contain valid values
        var valid = form.isValid();

        if (valid) {
            Ext.MessageBox.wait( 'Please wait a moment...', 'Saving company' );

            // save
        }

        return;
    },
    
    handlerReset: function(_button, _event) {
        // Reload data
        this.dataLoad();
    }
});


MyApp.Forms.EditRecord.[% form_name %].openWindow = function (config) {
    config = config || {};
    config.record_pk_id = config.record_pk_id ? config.record_pk_id : 0;

    var window = MyApp.WindowFactory.getWindow({
        width: 800,
        height: 600,
        layout: MyApp.Forms.EditRecord.[% form_name %].prototype.windowLayout,
        name: MyApp.Forms.EditRecord.[% form_name %].prototype.windowNamePrefix + config.record_pk_id,
        itemsConstructor: 'MyApp.Forms.EditRecord.[% form_name %]',
        itemsConstructorConfig: config
    });
    return window;
};

MyApp.Forms.EditRecord.[% form_name %].getEditForm = function(_contact) {

    // Setup main tabpanel
    // We will allways use a form layout with a visible tabpanel, even if we
    // only show one tabpanel
    var MainTabPanel = new Ext.TabPanel({
        defaults:   {
                        frame: true
                    },
        plain:      true,
        activeTab:  0,
        border:     false,
        items:      [% form.render_items %]

    });

    // Return the panel that contains the tabs as main display element
    return [
        MainTabPanel
    ];
};