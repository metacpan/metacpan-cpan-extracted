/* CatalystX::CRUD::YUI custom JavaScript 

# sync with .pm files
my $VERSION = '0.031';   

*/
YAHOO.namespace('crud');

// global var trackers
YAHOO.crud.TABS         = [];
YAHOO.crud.HISTORY      = [];

// set global array of callbacks to execute on form submit
YAHOO.crud.onFormSubmit = [];


/* use FireBug for debugging if it is available */
if (!YAHOO.crud.log) {
    if (typeof console != 'undefined' && OK2LOG) {
        if (window.console && !console.debug) {
            // safari
            //alert("window.console is defined");
            YAHOO.crud.log = function() { window.console.log(arguments[0]) };
        }
        else if (console.debug) {
            YAHOO.crud.log = function() { console.log.apply( console, arguments ) };
        }
        else {
            alert("no window.console or console.debug");
            YAHOO.crud.log = function() { }; // do nothing
        }
        YAHOO.crud.log("console logger ok");
    }
    else {
        YAHOO.crud.log = function() { YAHOO.log(arguments); }
        YAHOO.crud.log("crud logger aliased to YAHOO.log");
    }
}

var Logger = YAHOO.crud.log;    // shorthand

YAHOO.crud.handleXHRFailure = function(o) {
    alert("error: server failure (status = " + o.status + ")" + ' msg: ' + o.responseText);
};

YAHOO.crud.open_iframe_portal = function(url) {
    //Logger("open url: " + url);
    var Dom = YAHOO.util.Dom;
    var div = Dom.get('iframe_portal_container');
    div.innerHTML = '<iframe style="border:1px solid #aaa" ' + 
                    'id="links_iframe" width="600" height="200" ' +
                    'src="' + url + '" /></iframe>';
    var clicker = Dom.get('portal_clicker');
    YAHOO.crud.toggle_class_hidden(clicker);
    YAHOO.crud.toggle_class_hidden(div);
    YAHOO.crud.toggle_class(div, "padded");
    var resizer = new Ext.Resizable('iframe_portal_container', {
        width: 625,
        height: 225,
        minWidth:100,
        minHeight:50,
        pinned: true,
        resizeChild: true
    });
}

YAHOO.crud.close_iframe_portal = function() {
    var Dom = YAHOO.util.Dom;
    var div = Dom.get('iframe_portal_container');
    var clicker = Dom.get('portal_clicker');
    YAHOO.crud.toggle_class_hidden(clicker);
    YAHOO.crud.toggle_class_hidden(div);
    YAHOO.crud.toggle_class(div, "padded");
    div.innerHTML = '';
}


/*
http://developer.yahoo.com/yui/examples/autocomplete/ac_ysearch_json.html
*/
YAHOO.crud.autocomplete_text_field = function( opts ) {

    this.oACDS = new YAHOO.util.XHRDataSource(opts.url + '?' + opts.params + '&');
    this.oACDS.responseType = YAHOO.util.XHRDataSource.TYPE_JSON;
    this.oACDS.responseSchema = {
        resultsList : 'ResultSet.Result',
        fields      : [ opts.param.c, 'pk' ]
    };
    this.oACDS.maxCacheEntries = opts.cache_size;
    
    var myItemSelectEventHandler = function( oSelf, elItem, oData ) {
        //YAHOO.crud.log('set ' + opts.fname + ' = ' + elItem[2][1]);
        var hiddenField = YAHOO.util.Dom.get(opts.fname);
        hiddenField.value = elItem[2][1];
    };

    // Instantiate AutoComplete
    this.oAutoComp = new YAHOO.widget.AutoComplete(opts.id, opts.container_id, this.oACDS);
    this.oAutoComp.useShadow = true;
    this.oAutoComp.maxResultsDisplayed = opts.limit;
    this.oAutoComp.itemSelectEvent.subscribe(myItemSelectEventHandler);
    this.oAutoComp.queryQuestionMark = false;
    
    // Stub for form validation
    this.validateForm = function() {
        if (opts.validator) {
            return opts.validator();
        }
        else {
            return true;
        }
    };
};

YAHOO.crud.init_histories = function () {

    //YAHOO.crud.log("HISTORY init " + YAHOO.crud.HISTORY.length);

    // set an onReady function that calls each function in our list
    YAHOO.util.History.onReady(function() {
    
        var i;
        for(i=0; i < YAHOO.crud.HISTORY.length; i++) {
            var func = YAHOO.crud.HISTORY[i];
            func();
        }
        
    });
    
    YAHOO.util.History.initialize("yui_history_field", "yui_history_iframe");
}

/* utils */
YAHOO.crud.cancel_action = function (ev) { return false }

/*
do not let ENTER submit the form.
disable all the buttons to prevent double-clicks.
TODO other validation
*/
YAHOO.crud.check_return_key = function(e) {
    var numCharCode;
    var ok;
    
    // assume the best
    ok = true;

    // get event if not passed
    if (!e) {
        e = window.event;
    }
    
    // get character code of key pressed
    if (e.keyCode) numCharCode = e.keyCode;
    else if (e.which) numCharCode = e.which;

    //Logger(numCharCode);
    //Logger(e);
    
    if (numCharCode == 13) {
        ok = false;
    }
        
    return ok;
}

YAHOO.crud.submit_form = function(thisForm) {
    Logger('submit_form() called');
    //Logger(thisForm);
    YAHOO.crud.disable_all_buttons('button');

    if (YAHOO.crud.onFormSubmit) {
        Logger("onFormSubmit");
        for(var i = 0; i< YAHOO.crud.onFormSubmit.length; i++) {
            if(! YAHOO.crud.onFormSubmit[i](thisForm)) {
                YAHOO.crud.enable_all_buttons('button');
                return false;
            }
        }
    }
    
    // for now, always
    return true;
}

YAHOO.crud.hover_class_on_mousemove = function(id) {
    YAHOO.util.Event.addListener(id, 'mouseover', function(ev) {
    
        var elTarget = YAHOO.util.Event.getTarget(ev);
        while(elTarget.id != id) {
            if (elTarget.nodeName.toUpperCase() != "A") {
                elTarget = elTarget.parentNode;
                break;
            }
            if (    YAHOO.util.Dom.hasClass(elTarget, 'yui-pg-page')
                ||  YAHOO.util.Dom.hasClass(elTarget, 'yui-pg-first')
                ||  YAHOO.util.Dom.hasClass(elTarget, 'yui-pg-previous')
                ||  YAHOO.util.Dom.hasClass(elTarget, 'yui-pg-next')
                ||  YAHOO.util.Dom.hasClass(elTarget, 'yui-pg-last')
            ) {
                YAHOO.util.Dom.addClass(elTarget, 'hover');
                break;
            }
            else {
                elTarget = elTarget.parentNode;
            }
        }
    
    });
    YAHOO.util.Event.addListener(id, 'mouseout', function(ev) {
    
        var elTarget = YAHOO.util.Event.getTarget(ev);
        while(elTarget.id != id) {
            if (elTarget.nodeName.toUpperCase() != "A") {
                elTarget = elTarget.parentNode;
                break;
            }
            if (YAHOO.util.Dom.hasClass(elTarget, 'hover')) {
                YAHOO.util.Dom.removeClass(elTarget, 'hover');
                break;
            }
            else {
                elTarget = elTarget.parentNode;
            }
        }
    
    });
}
         
YAHOO.crud.disable_button = function (button) {
    button.oldValue     = button.value;
    button.value        = '...in process...';
    YAHOO.util.Dom.addClass(button, 'disabled');

    if (typeof button.disabled != 'undefined')
        button.disabled = true;
    else if (!button.buttonDisabled)
    {
        button.oldOnclick       = button.onclick;
        button.onclick          = YAHOO.crud.cancel_action;
        button.buttonDisabled   = true;
    }
}

YAHOO.crud.enable_button = function (button) {
    button.value        = button.oldValue;
    YAHOO.util.Dom.removeClass(button, 'disabled');
    
    if (typeof button.disabled != 'undefined')
        button.disabled = false;
    else if (button.buttonDisabled) {
        button.onclick          = button.oldOnclick;
        button.buttonDisabled   = false;
    }
}

YAHOO.crud.enable_all_buttons = function(id) {
    if (!id)
        id = 'addRowButton';
        
    var buttons = YAHOO.util.Dom.getElementsByClassName(id);
    for (var i = 0; i < buttons.length; i++) {
        YAHOO.crud.enable_button(buttons[i]);
    }
}

YAHOO.crud.disable_all_buttons = function(id) {
    if (!id)
        id = 'addRowButton';
        
    var buttons = YAHOO.util.Dom.getElementsByClassName(id);
    for (var i = 0; i < buttons.length; i++) {
        YAHOO.crud.disable_button(buttons[i]);
    }
}

// use 'myclass' and not 'class' because Safari whines
YAHOO.crud.toggle_class = function (id, myclass) {
    var Dom     = YAHOO.util.Dom;
    var e       = Dom.get(id);
    if (Dom.hasClass(e, myclass)) {
        //Logger("removeClass " + myclass + " to " + id);
        Dom.removeClass(e, myclass);
    }
    else {
        //Logger("addClass " + myclass + " to " + id);
        Dom.addClass(e, myclass);
    }
}

YAHOO.crud.toggle_class_hidden = function(id) {
    YAHOO.crud.toggle_class(id, "hidden");
}

YAHOO.crud.toggle_action_buttons = function(id) {
    Logger('toggle action buttons ' + id);
    var Dom = YAHOO.util.Dom;
    var el = Dom.get('crud-buttons');
    if (!id || id == 'main') {
        Dom.removeClass(el,'hidden');
    }
    else {
        Dom.addClass(el,'hidden');
    }
}

YAHOO.crud.init_tabview_history = function() {
    var currentState;
    currentState = YAHOO.util.History.getCurrentState('tabview');
    YAHOO.crud.set_active_tab(currentState);
}

YAHOO.crud.handle_crud_link_click = function(e) {
    var elTarget = YAHOO.util.Event.getTarget(e);
        
    // find the targeted li
    while(elTarget.id != 'crud-links') {
        //YAHOO.crud.log("target = " + elTarget);
        if (elTarget.nodeName.toUpperCase() == "LI") {
            var atag  = elTarget.getElementsByTagName('a')[0];
            var ahref = atag.getAttribute('href');
            var id;
            if (ahref.match(/#/)) {
                id = ahref.match(/#(.+)/)[1];
                // hide the parent record buttons to reduce confusion
                YAHOO.crud.toggle_action_buttons(id);
            }
            else {
                // show the parent record buttons
                YAHOO.crud.toggle_action_buttons();
                return true;
            }
            // manage history
            var currentState;            
            try {
                currentState = YAHOO.util.History.getCurrentState('tabview');
                if (id != currentState) {
                    YAHOO.util.History.navigate('tabview', id);
                }
            }
            catch (err) {
                YAHOO.crud.log("click on " + id);
                YAHOO.crud.set_active_tab(id);
            }
            break;
        }
        else {
            elTarget = elTarget.parentNode;
        }
    }
    return false;
}

YAHOO.crud.new_relTab = function() {
    var t = {
        'grid'        : { 'panel': false, 'opts': false, 'cls': false },
        'chooser'     : { 'panel': false, 'opts': false, 'cls': false },
        'index'       : 0,
        'id'          : '',
        'name'        : ''
    };
    return t;
}

YAHOO.crud.set_active_tab = function(id) {
    if (!id || !YAHOO.util.Dom.get('main-link')) {
        return;
    }

    // if this is not the currently active tab
    // then hide the active one and show this one
    YAHOO.crud.toggle_class(YAHOO.crud.ACTIVE_TAB, "hidden");
    YAHOO.crud.toggle_class(id, "hidden");
    YAHOO.crud.toggle_class(YAHOO.crud.ACTIVE_TAB + '-link', "selected");
    YAHOO.crud.toggle_class(id + '-link', "selected");
    YAHOO.crud.toggle_action_buttons(id);
    
    YAHOO.crud.ACTIVE_TAB = id;
    YAHOO.crud.load_livegrid_by_id(id);
}

YAHOO.crud.load_livegrid_by_id = function(id) {
    // find the LiveGrid and reload data from server
    for(var i = 0; i<YAHOO.crud.TABS.length; i++) {
        if (id == YAHOO.crud.TABS[i].id && YAHOO.crud.TABS[i].grid.panel) {
            // reload each time we see it
            YAHOO.crud.TABS[i].grid.panel.store.reload();    
            break;
        }
    }
}

YAHOO.crud.livegrid_form = function(args) {
    //Logger(args);
    var tab = YAHOO.crud.TABS[args.index];
    //Logger(tab);
    var formId = 'livegrid' + args.index + '-form';

    // fetch the html and insert it
    var req = YAHOO.util.Connect.asyncRequest('GET', args.form,
        {
            success: function(o) {
                if (o.responseText !== undefined) {
                    var Dom = YAHOO.util.Dom;
                    Dom.get(formId).innerHTML = o.responseText;
                    
                    // set form values
                    var cmap     = tab.grid.opts.foreign.column_map;
                    var newForm  = Dom.getElementsByClassName(
                        'crud',
                        'form',
                        Dom.get(formId)
                    )[0];
                    Logger(newForm);
                    var thisOid = tab.grid.opts.parent.oid;
                    var thisOidLabel = tab.grid.opts.parent.oidLabel;
                    var saveButton, resetButton;
                    var cancelButton = document.createElement('button');
                    cancelButton.innerHTML = 'Cancel';
                    Dom.addClass( cancelButton, 'button' );
                    
                    // want to hide the input field for thisOid
                    // and any related autocomplete.
                    for(var i=0; i<newForm.elements.length; i++) {
                        var el = newForm.elements[i];
                        if (el.name == cmap[0] || el.name == ('ac_' + cmap[0])) {
                            el.parentNode.innerHTML = thisOidLabel + 
                                '<input type="hidden" name="' + cmap[0] + '" value="' + thisOid + '" />';
                            continue;
                        }
                        if (el.value == 'Save') {
                            saveButton = el;
                            //Logger("found Save button");
                            continue;
                        }
                        if (el.value == 'Reset') {
                            resetButton = el;
                            //Logger("found Reset button");
                            continue;
                        }
                    }
                    
                    // add a Cancel button
                    //Logger(resetButton);
                    if(Dom.insertAfter(cancelButton, resetButton)) {
                    
                        //Logger("insert Cancel button");
                    
                        YAHOO.util.Event.on(cancelButton, 'click', 
                         function(e) { Dom.get(formId).innerHTML = '' });
                         
                        //Logger("set Cancel button");
                    }
                                                                          
                    newForm.onsubmit = function(e) {
                        //Logger("form submitted");
                        //Logger(e);
                        YAHOO.util.Event.stopEvent(e);  // so submit_form() isn't called
                                                        // TODO call validate_form() here explicitly
                        return false;
                    };
                    
                    //Logger("set form");
                    
                    var respHandler = {
                      success: function(o) {
                        // clear the selection so that the form is not re-loaded
                        tab.grid.panel.getSelectionModel().clearSelections();
                        // reload the grid
                        tab.grid.panel.store.reload();
                        // delete the form
                        Dom.get(formId).innerHTML = '';
                        //Logger('submit OK');
                      },
                      failure: function(o) {
                        //YAHOO.crud.handleXHRFailure(o);
                        alert("Error! Check that the value is not already set for this record.");
                      }
                    };
                    
                    // hijack the save button so we don't actually leave this page.
                    YAHOO.util.Event.on(saveButton, 'click', function(e) {
                        var uri = newForm.action + '?cxc-fmt=json';
                        //alert("uri = " + uri);
                        // make the form submit without leaving the page
                        var ret = YAHOO.util.Connect.setForm(newForm);
                        //Logger(ret);
                        YAHOO.util.Connect.asyncRequest('POST', uri, respHandler);
                    });

                }
                else {
                    alert("unknown server error");
                }
            },
            failure: function(o) {
                YAHOO.crud.handleXHRFailure(o);
            }
        }
    );

}

Ext.namespace('Ext.ux'); // livegrid js requires

if (typeof USE_LIVEGRID_FILTERS != 'undefined') {
// grid filter icons
Ext.menu.RangeMenu.prototype.icons = {
	  gt: 'img/greater_then.png', 
	  lt: 'img/less_then.png',
	  eq: 'img/equals.png'
};
Ext.grid.filter.StringFilter.prototype.icon = 'img/find.png';
}

/* extend the CheckboxSelectionModel to determine if the click action
   was on the checkbox or elsewhere in the row
 */
YAHOO.crud.livegrid_selection_model = Ext.extend(Ext.grid.CheckboxSelectionModel, {
    
    initEvents : function(){
        this.grid.on("cellmousedown", this.handleMouseDown, this);
        this.grid.getGridEl().on(Ext.isIE || Ext.isSafari3 ? "keydown" : "keypress", this.handleKeyDown, this);
    },
    
    checkBoxClicked : false,
    
    handleMouseDown : function(g, row, cell, e){
        if(e.button !== 0 || this.isLocked()){
            return;
        };
        this.select(row,cell);
        e.stopEvent();
    },
        
    select : function(row,cell) {
        //Logger("select row, cell");
        //Logger(row, cell);
        if (cell === 0) {
            this.checkBoxClicked = true;
        }
        else {
            this.checkBoxClicked = false;
        }
        //Logger(this.checkBoxClicked);
        if (this.isSelected(row)){
            this.deselectRow(row);
        }
        else {
            this.selectRow(row, true);
        }
    },
    
    handleKeyDown : function(e){
        if(!e.isNavKeyPress()){
            return;
        }
        var g = this.grid, s = this.selection;
        if(!s){
            e.stopEvent();
            var cell = g.walkCells(0, 0, 1, this.isSelectable,  this);
            if(cell){
                this.select(cell[0], cell[1]);
            }
            return;
        }
        var sm = this;
        var walk = function(row, col, step){
            return g.walkCells(row, col, step, sm.isSelectable,  sm);
        };
        var k = e.getKey(), r = s.cell[0], c = s.cell[1];
        var newCell;

        switch(k){
             case e.TAB:
                 if(e.shiftKey){
                     newCell = walk(r, c-1, -1);
                 }else{
                     newCell = walk(r, c+1, 1);
                 }
             break;
             case e.DOWN:
                 newCell = walk(r+1, c, 1);
             break;
             case e.UP:
                 newCell = walk(r-1, c, -1);
             break;
             case e.RIGHT:
                 newCell = walk(r, c+1, 1);
             break;
             case e.LEFT:
                 newCell = walk(r, c-1, -1);
             break;
             case e.ENTER:
                 if(g.isEditor && !g.editing){
                    g.startEditing(r, c);
                    e.stopEvent();
                    return;
                }
             break;
        };
        if(newCell){
            this.select(newCell[0], newCell[1]);
            e.stopEvent();
        }
    }


});

// based on ext-2.2/examples/form/SearchField.js
YAHOO.crud.livegrid_filter = Ext.extend(Ext.form.TwinTriggerField, {
    initComponent : function(){
        YAHOO.crud.livegrid_filter.superclass.initComponent.call(this);
        this.on('specialkey', function(f, e){
            if(e.getKey() == e.ENTER){
                this.onTrigger2Click();
            }
        }, this);
    },
    
    afterRender : function() {
        YAHOO.crud.livegrid_filter.superclass.afterRender.call(this);
        
        // explicitly set the wrapper width since multiple triggerfields
        // on same page get set to 0width. (ext js bug!?)
        this.wrap.setWidth(this.width);
    
    },

    validationEvent:false,
    validateOnBlur:false,
    trigger1Class:'x-form-clear-trigger',
    trigger2Class:'x-form-search-trigger',
    hideTrigger1:true,
    width:380,
    hasSearch : false,
    paramName : 'cxc-query',

    onTrigger1Click : function(){
        if(this.hasSearch){
            this.el.dom.value = '';
            var o = {start: 0};
            this.store.baseParams = this.store.baseParams || {};
            this.store.baseParams[this.paramName] = '';
            this.store.reload({params:o});
            this.triggers[0].hide();
            this.hasSearch = false;
        }
    },

    onTrigger2Click : function(){
        var v = this.getRawValue();
        if(v.length < 1){
            this.onTrigger1Click();
            return;
        }
        var o = {
            'start':0,
            'cxc-op':'OR',
            'cxc-fuzzy':'1',
            'cxc-query-fields':this.text_fields
        };
        this.store.baseParams = this.store.baseParams || {};
        this.store.baseParams[this.paramName] = v;
        this.store.reload({params:o});
        this.hasSearch = true;
        this.triggers[0].show();
    }
});

// based on http://www.siteartwork.de/livegrid_demo/
YAHOO.crud.new_livegrid = function(index) {

  var tab   = YAHOO.crud.TABS[index];
  var opts  = tab.grid.opts;
  tab.grid.cls = Ext.extend(Ext.ux.grid.livegrid.GridPanel, {
    initComponent : function() {
        var bufferedReader = new Ext.ux.grid.livegrid.JsonReader(
            opts.reader.opts, 
            opts.reader.columns
        );
        
        // override default in order to allow for field names
        // with . (dot) delimiter.
        // we want to allow for response.* but no other *.*
        bufferedReader.getJsonAccessor = function(expr) {
            var re = /^response[\[\.]/;
            return function(expr) {
                try {
                return(re.test(expr))
                    ? new Function("obj", "return obj." + expr)
                    : function(obj){
                        return obj[expr];
                    };
                } catch(e){}
                return Ext.emptyFn;
            };
        }();
        
        this.store = new Ext.ux.grid.livegrid.Store({
            autoLoad   : opts.defer_load ? false : true,
            bufferSize : 200,   // cxc does 200 max by default
            reader     : bufferedReader,
            sortInfo   : {field: opts.sort_by, direction: opts.sort_dir},
            url        : opts.url
        });
        
        /*  support sorting on foreign m2m fields 
            by adding the table prefix where necessary
        */
        this.store.on('beforeload', 
            function(myStore) { 
                var sortInfo = myStore.sortInfo;
                //Logger(sortInfo.field, sortInfo.direction);
                for(var i=0; i<opts.column_defs.length; i++) {
                    var c = opts.column_defs[i];
                    if (c.dataIndex === sortInfo.field
                        && c.sortPrefix
                        && c.sortPrefix.length
                    ) 
                    {
                        //Logger("match: " + c.dataIndex);
                        sortInfo.field = c.sortPrefix + '.' + sortInfo.field;
                        break;
                    }
                }
                //Logger(sortInfo.field, sortInfo.direction);
                //Logger(opts.column_defs);
                //alert("beforeload!");
            }
        );

        this.selModel = 
            new Ext.ux.grid.livegrid.RowSelectionModel({singleSelect: true});

        /**
         * If your bufferSize is small, set this to a value around a third or a quarter
         * of the store's bufferSize (e.g. a value of 25 for a bufferSize of 100;
         * a value of 100 for a bufferSize of 300).
         */
        this.view = new Ext.ux.grid.livegrid.GridView({
            nearLimit : 50,
            loadMask : {
                msg : 'Please wait...'
            }
        });
        
        if (typeof USE_LIVEGRID_FILTERS != 'undefined') {
          this.plugins = filters = new Ext.grid.GridFilters({
            filters:tab.grid.opts.filters,
            buildQuery: YAHOO.crud.build_livegrid_filter_query
          });
          this.bbar = new Ext.ux.grid.livegrid.Toolbar({
            view        : this.view,
            displayInfo : true,
            plugins     : this.plugins
          });
        }
        else {
          this.bbar = new Ext.ux.grid.livegrid.Toolbar({
            view        : this.view,
            displayInfo : true,
            items       : [
                'Filter: ',
                ' ',
                new YAHOO.crud.livegrid_filter({
                    'store': this.store,  // TODO is this correct?
                    'width': 400,
                    'text_fields': opts.text_columns
                })
            ]
          });
        }
         
        tab.grid.cls.superclass.initComponent.call(this);
    }
  });

  YAHOO.util.Event.onDOMReady(function () {
    var gridopts, sm, column_defs;
    
    // must shallow copy so chooser does not get m2m checkbox
    column_defs = [];
    opts.nVisible = 0;
    for (var i=0; i<opts.column_defs.length; i++) {
        column_defs.push(opts.column_defs[i]);
        if (!opts.column_defs[i].hidden) {
            opts.nVisible++;
        }
    }
    if (opts.rm_button) {
      sm = new YAHOO.crud.livegrid_selection_model();
      sm.width = 20;
      column_defs.unshift(sm);
    }
    
    //var filters = new Ext.grid.GridFilters({filters:tab.grid.opts.filters});
    //Logger(filters);
    
    var colModel = new Ext.grid.ColumnModel(column_defs);
    // 260 is left menu width plus padding
    var winWidth = document.body.clientWidth;
    var colAvgWidth = (winWidth - 260) / opts.nVisible;
    
    //Logger("winWidth = " + winWidth);
    //Logger("avgWidth = " + colAvgWidth);
    //Logger("nVisible = " + opts.nVisible);
    
    colModel.defaultWidth = colAvgWidth;
    gridopts = {
        'el'             : opts.div_id,
        'enableDragDrop' : false,
        'cm'             : colModel,
        'loadMask'       : {
            'msg' : 'Loading...'
        },
        'tbar'           : opts.tools,
        'buttonAlign'    : 'center',
        'iconCls'        : 'icon-grid',
        //'plugins'        : new Ext.grid.GridFilters({filters:tab.grid.opts.filters}),
        'title'          : opts.title,
        'height'         : (opts.height || 250),
        'width'          : 'auto'

    };
    if (opts.rm_button) {
        gridopts.sm = sm;
    }

    tab.grid.panel = new tab.grid.cls(gridopts);
    tab.grid.panel.getSelectionModel().on('rowselect', opts.clickhandler);
    tab.grid.panel.getSelectionModel().on('rowdeselect', opts.clickhandler);
    tab.grid.panel.render();

    //Logger("rendered grid " + tab.name);
    if (   YAHOO.crud.LOADGRID 
        && YAHOO.crud.LOADGRID == tab.id
    ) {
        //Logger("load grid " + tab.id);
        tab.grid.panel.store.reload();
    }
  });

}

YAHOO.crud.build_livegrid_filter_query = function(filters) {
    //Logger("build filter query");
    //Logger(filters);
    var p = {};
    for(var i=0, len=filters.length; i<len; i++) {
        var f = filters[i];
        p[f.field] = f.data.value;
	}
    Logger(p);
    return p;
}

YAHOO.crud.add_livegrid_row = function(opts) {

    var chooser = YAHOO.crud.TABS[opts.index].chooser.panel;
    
    // already created. just show it.
    if (chooser) {
        //Logger("chooser already exists");
        chooser.getSelectionModel().clearSelections();
        chooser.show();
        chooser.store.reload();
        return;
    }
    else {
    // create a new_livegrid_chooser
        YAHOO.crud.new_livegrid_chooser(opts.index);
    }
}

YAHOO.crud.handle_chooser_m2m = function(args) {
    //Logger(args);

    var tab = YAHOO.crud.TABS[args.index];
    var pk  = args.r.id;
       
    //Logger('pk = ' + pk);
    
    var url =   tab.grid.opts.parent.url + '/' + 
                tab.grid.opts.foreign.name + '/' + pk + '/add';
                        
    var req = YAHOO.util.Connect.asyncRequest('POST', url,
        {
            success: function(o) {
                if (o.responseText !== undefined) {
                    // reload the parent panel
                    // the visual clue of the Load msg should be enough
                    tab.grid.panel.store.reload();
                }
                else {
                    alert("unknown server error");
                }
            },
            failure: function(o) {
                YAHOO.crud.handleXHRFailure(o);
                tab.chooser.panel.getSelectionModel().clearSelections();
            }
        },
        'x-tunneled-method=PUT'
    );
}

YAHOO.crud.handle_chooser_o2m = function(args) {
    Logger(args);

    var tab = YAHOO.crud.TABS[args.index];
    var pk  = args.r.id;
       
    Logger('pk = ' + pk);
    
    // just need to update the foreign key value(s) in selected row
    var postData = '';
    for(i=1; i<tab.grid.opts.foreign.column_map.length; i+=2) {
        postData += tab.grid.opts.foreign.column_map[i] + 
                    "=" + tab.grid.opts.parent.column_map[i] + '&';
    }
    var url = tab.grid.opts.foreign.url + '/' + 
                pk + '/save?cxc-fmt=json&cxc-o2m=1';
    
    var req = YAHOO.util.Connect.asyncRequest('POST', url,
        {
            success: function(o) {
                if (o.responseText !== undefined) {
                    // reload the parent panel
                    // the visual clue of the Load msg should be enough
                    tab.grid.panel.store.reload();    
                }
                else {
                    alert("unknown server error");
                }
            },
            failure: function(o) {
                YAHOO.crud.handleXHRFailure(o);
            }
        },
        postData + 'x-tunneled-method=POST'
    );

}

/* open a new livegrid dynamically in the page
   populated with records from the related table.
   clicking on a row in the new livegrid adds that
   row to the parent grid and calls back to the server
   to create the record (m2m) or update the FK (o2m).
*/ 
YAHOO.crud.new_livegrid_chooser = function(index) {

  var tab = YAHOO.crud.TABS[index];
  if (!tab) {
    alert("No tab for index " + index);
    return;
  }
  
  Logger(tab);
      
  var clickhandler;
  if (tab.grid.opts.foreign.m2m) {
    clickhandler = function(sm, rowIndex, r) { 
        YAHOO.crud.handle_chooser_m2m(
            {'sm':sm,'rowIndex':rowIndex,'r':r,'index':index}
        );
    }
  }
  else {
    clickhandler = function(sm, rowIndex, r) { 
        YAHOO.crud.handle_chooser_o2m(
            {'sm':sm,'rowIndex':rowIndex,'r':r,'index':index}
        );
    }
  }
    
  tab.chooser.cls = Ext.extend(Ext.ux.grid.livegrid.GridPanel, {
    initComponent : function() {
        var bufferedReader = new Ext.ux.grid.livegrid.JsonReader(
            tab.grid.opts.reader.opts, 
            tab.grid.opts.reader.columns
        );

        // override default in order to allow for field names
        // with . (dot) delimiter.
        // we want to allow for response.* but no other *.*
        bufferedReader.getJsonAccessor = function(expr) {
            var re = /^response[\[\.]/;
            return function(expr) {
                try {
                return(re.test(expr))
                    ? new Function("obj", "return obj." + expr)
                    : function(obj){
                        return obj[expr];
                    };
                } catch(e){}
                return Ext.emptyFn;
            };
        }();
        
        this.store = new Ext.ux.grid.livegrid.Store({
            autoLoad   : true,
            bufferSize : 200,   // cxc does 200 max by default
            reader     : bufferedReader,
            sortInfo   : {field: tab.grid.opts.sort_by, direction: tab.grid.opts.sort_dir },
            url        : tab.grid.opts.foreign.chooser_url
        });

        this.selModel = 
            new Ext.ux.grid.livegrid.RowSelectionModel({singleSelect: true});

        /**
         * If your bufferSize is small, set this to a value around a third or a quarter
         * of the store's bufferSize (e.g. a value of 25 for a bufferSize of 100;
         * a value of 100 for a bufferSize of 300).
         */
        this.view = new Ext.ux.grid.livegrid.GridView({
            nearLimit : 50,
            loadMask : {
                msg : 'Please wait...'
            }
        });
        
        if (typeof USE_LIVEGRID_FILTERS != 'undefined') {
          this.plugins = filters = new Ext.grid.GridFilters({
            filters:tab.grid.opts.filters,
            buildQuery: YAHOO.crud.build_livegrid_filter_query
          });
          this.bbar = new Ext.ux.grid.livegrid.Toolbar({
            view        : this.view,
            displayInfo : true,
            plugins     : this.plugins
          });
        }
        else {
          this.bbar = new Ext.ux.grid.livegrid.Toolbar({
            view        : this.view,
            displayInfo : true,
            items       : [
                'Filter: ',
                ' ',
                new YAHOO.crud.livegrid_filter({
                    'store': this.store,  // TODO is this correct?
                    'width': 200,
                    'text_fields': tab.grid.opts.text_columns
                })
            ]
          });
        }
                
        tab.chooser.cls.superclass.initComponent.call(this);
    }
  });
  var colModel = new Ext.grid.ColumnModel(tab.grid.opts.column_defs);
  colModel.defaultWidth = tab.grid.panel.getColumnModel().defaultWidth;
  tab.chooser.opts = {
        'el'             : tab.grid.opts.div_id + '-chooser',
        'enableDragDrop' : false,
        'collapsible'    : true,
        'cm'             : colModel,
        'loadMask'       : {
            'msg' : 'Loading...'
        },
        'tbar'           : ['-',
            {
            'text'    :'Close this panel',
            'tooltip' :'Close this panel',
            'iconCls' :'remove',
            'handler' : function(btn) {
                tab.chooser.panel.hide();
              }
            }
        ],
        'buttonAlign'    : 'center',
        'iconCls'        : 'icon-grid',
        'title'          : 'Choose ' + tab.grid.opts.title,
        //'plugins'        : new Ext.grid.GridFilters({filters:tab.grid.opts.filters}),
        'hideParent'     : false,
        'height'         : 250,
        'width'          : 'auto'
  };

  tab.chooser.panel = new tab.chooser.cls(tab.chooser.opts);
  tab.chooser.panel.getSelectionModel().on('rowselect', clickhandler);
  tab.chooser.panel.render();
    
}

YAHOO.crud.rm_livegrid_rows = function(args) {
    Logger("rm_livegrid_row");
    Logger(args);
    
    var tab  = YAHOO.crud.TABS[args.index];
    var grid = tab.grid.panel;
    var opts = tab.grid.opts;
    var sm   = grid.getSelectionModel();
    var rows = sm.getSelections();
    
    if (!rows.length) {
        alert("No rows are selected.");
        return;
    }
    
    if (confirm('Are you sure?')) {
       // make ajax calls to break relationships
       
       for (var i=0; i<rows.length; i++) {
            var pk = rows[i].id;
            YAHOO.util.Connect.asyncRequest(
                'POST',
                opts.parent.url + '/' + opts.foreign.name + '/' + pk + '/remove',
                {
                    success: function (o) {
                        if (o.responseText == 'Ok') {
                            //Logger("row removed");
                        } else {
                            alert(o.responseText);
                        }
                    },
                    failure: function (o) {
                        YAHOO.crud.handleXHRFailure(o);
                    }
                },
                'x-tunneled-method=DELETE'
            );
        }
        
        // TODO reload grid, but need to wait till after all rows are removed?
        grid.store.reload();
    }

}

YAHOO.crud.handle_related_livegrid_click = function(args) {
    if (!args.rec) {
        Logger('no row passed on click');
        return;
    }
    
    //Logger(args);
        
    if (args.sm.checkBoxClicked == true) {
        return;
    }
    else {
        //var tab = YAHOO.crud.TABS[args.index];
        //Logger(tab);
        //Logger(args);
        
        var uri = args.url + args.rec.id + '/' + args.action;
        if (args.action == 'livegrid_edit_form') {
        
            // if de-selecting the row, erase the form
            if (!args.sm.isSelected(args.rec)) {
                var formId = 'livegrid' + args.index + '-form';
                YAHOO.util.Dom.get(formId).innerHTML = '';
                return;
            }
        
            YAHOO.crud.livegrid_form({'index':args.index,'form':uri});
        }
        else {
            window.location = uri;
        }
    }
}
    
YAHOO.crud.redirect_location = function(args) {
    var pk_vals  = [];
    for(var i=0; i<args.pk_fields.length; i++) {
        pk_vals[i] = args.r.get(args.pk_fields[i]);
    }
    var pk       = pk_vals.join(';;');
    var newurl   = args.url + pk + '/' + args.action;
    //Logger(newurl);
    window.location = newurl;
}
        

YAHOO.crud.toggle_link = function(id_to_toggle, link_id) {
    YAHOO.crud.toggle_class_hidden(id_to_toggle);
    YAHOO.crud.toggle_class_hidden(link_id);
    return false;   // so the click is not followed on a href
}

YAHOO.crud.datetime_picker = function(id) {
    YAHOO.crud.make_calendar_popup(id, true);
}

YAHOO.crud.date_picker = function(id) {
    YAHOO.crud.make_calendar_popup(id);
}

YAHOO.crud.make_calendar_popup = function(id, set_time) {

    var Dom = YAHOO.util.Dom;

    // Create an Overlay instance to house the Calendar instance
    var oCalendarMenu = new YAHOO.widget.Overlay("calendar_for_" + id, { zIndex: 99 });
    
    /*
         Create an empty body element for the Overlay instance in order 
         to reserve space to render the Calendar instance into.
    */
    oCalendarMenu.setBody("&#32;");
    oCalendarMenu.body.id = "calendarcontainer_" + id;

    // Render the Overlay instance into the Button's parent element
    oCalendarMenu.render(Dom.get(id + "_calendar_container"));
    

    // Align the Overlay
    oCalendarMenu.align();
    
    /*
         Create a Calendar instance and render it into the body 
         element of the Overlay.
    */

    var oCalendar = new YAHOO.widget.Calendar(
        "buttoncalendar_" + id, 
        oCalendarMenu.body.id,
        {
            close: true
        });
    oCalendar.render();
    
    
    /* 
        we have a close button but we want to hide the Overlay,
        not the calendar
    */
    oCalendar.beforeHideEvent.subscribe(function() {
        oCalendarMenu.hide();
        return false;   // prevent calendar from being hidden
    });

    /* 
        Subscribe to the Calendar instance's "changePage" event to 
        keep the Overlay visible when either the previous or next page
        controls are clicked.
    */
    oCalendar.changePageEvent.subscribe(function () {
        window.setTimeout(function () {
            oCalendarMenu.show();
        }, 0);
    });

    /*
        Subscribe to the Calendar instance's "select" event to 
        update the form field when the user
        selects a date.
    */

    oCalendar.selectEvent.subscribe(function (p_sType, p_aArgs) {

        var aDate;
        if (p_aArgs) {
                
            YAHOO.crud.log(p_aArgs);
                
            aDate = p_aArgs[0][0];
            if (aDate[1] < 10)
                aDate[1] = '0' + aDate[1];
            
            if (aDate[2] < 10)
                aDate[2] = '0' + aDate[2];
                
            Dom.get(id).value = aDate.join('-');
            if (set_time) {
                Dom.get(id).value += ' 00:00:00';
            }

        }
        
        // hide calendar once date selected
        oCalendarMenu.hide();
    
    });

}

// based on
// http://developer.yahoo.com/yui/examples/editor/switch_editor_clean.html
// similar to CatalystX::CMS
YAHOO.crud.wysiwygify = function( textareaId, textareaTitle ) {
    var Dom = YAHOO.util.Dom,
        Event = YAHOO.util.Event;
    
    // make a button and stick it above the textarea field
    Logger('Create Button Control (#toggleEditor) ' + textareaId + ' ' + textareaTitle);
    
    var toggleButton = document.createElement('button');
    toggleButton.setAttribute('id', textareaId + '-toggle');
    toggleButton.innerHTML = 'Toggle Editor';
    var myTextarea = Dom.get( textareaId );
    myTextarea.parentNode.insertBefore(toggleButton, myTextarea);
    
    var _button = new YAHOO.widget.Button(toggleButton);
    _button.addClass('toggleEditor');

    var myConfig = {
        height: '300px',
        width: '600px',
        animate: true,
        dompath: true
    };

    var stripHTML = /<\S[^><]*>/g;
    var state = 'on';
    Logger('Set state to on..');

    Logger('Create the Editor..');
    var myEditor = new YAHOO.widget.Editor(textareaId, myConfig);
    myEditor.on('toolbarLoaded', function() {
    
        this.toolbar._titlebar.innerHTML = '';  // no titlebar
    
    }, myEditor, true);
    
    myEditor.render();
    
    // make sure the 'save' button writes changes to textarea
    YAHOO.crud.onFormSubmit.push(
     function() {
        myEditor.saveHTML();   // save gui content in screen to object
        var editorText = myEditor.get('textarea').value;
        var textareaText = Dom.get(textareaId).value;
        //alert(textareaId + " textarea: " + editorText);
        if (editorText != textareaText) {
            alert("editor text mismatch: " + editorText + ' <> ' + textareaText);
        }
        //myEditor.saveHTML();  // do this first above.
        if (editorText.length) {
            myEditor.get('textarea').value = editorText.replace(/<br>/gi, '\n');
        }
        //alert("textarea: " + myEditor.get('textarea').value );
        return true;
     }
    );

    _button.on('click', function(ev) {
        Event.stopEvent(ev);
        if (state == 'on') {
            Logger('state is on, so turn off');
            state = 'off';
            myEditor.saveHTML();
            Logger('Save the Editors HTML');
            myEditor.get('textarea').value = myEditor.get('textarea').value.replace(/<br>/gi, '\n');
            Logger('Strip the HTML markup from the string.');
            Logger('Set Editor container to position: absolute, top: -9999px, left: -9999px. Set textarea visible');

            var fc = myEditor.get('element').previousSibling,
                el = myEditor.get('element');

            Dom.setStyle(fc, 'position', 'absolute');
            Dom.setStyle(fc, 'top', '-9999px');
            Dom.setStyle(fc, 'left', '-9999px');
            myEditor.get('element_cont').removeClass('yui-editor-container');
            Dom.setStyle(el, 'visibility', 'visible');
            Dom.setStyle(el, 'top', '');
            Dom.setStyle(el, 'left', '');
            Dom.setStyle(el, 'position', 'static');
        } else {
            Logger('state is off, so turn on');
            state = 'on';
            Logger('Set Editor container to position: static, top: 0, left: 0. Set textarea to hidden');

            var fc = myEditor.get('element').previousSibling,
                el = myEditor.get('element');

            Dom.setStyle(fc, 'position', 'static');
            Dom.setStyle(fc, 'top', '0');
            Dom.setStyle(fc, 'left', '0');
            Dom.setStyle(el, 'visibility', 'hidden');
            Dom.setStyle(el, 'top', '-9999px');
            Dom.setStyle(el, 'left', '-9999px');
            Dom.setStyle(el, 'position', 'absolute');
            myEditor.get('element_cont').addClass('yui-editor-container');
            Logger('Reset designMode on the Editor');
            myEditor._setDesignMode('on');
            Logger('Inject the HTML from the textarea into the editor');
            myEditor.setEditorHTML(myEditor.get('textarea').value.replace(/\n/g, '<br>'));
        }
    });
}

