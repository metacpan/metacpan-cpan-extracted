/* CatalystX::CMS javascript */
YAHOO.namespace('CMS');

YAHOO.CMS.IDCOUNTER = 0;

var Dom = YAHOO.util.Dom;
var CMS = YAHOO.CMS;
var Logger = YAHOO.console.log;

CMS.add_meta_item = function () {
    var count = CMS.IDCOUNTER++;
    Logger('add_meta_item() called for ' + count);
    var attrs = new YAHOO.util.Element('cms_attrs');
    Logger('found attrs id');
    var item = new YAHOO.util.Element(Dom.get('cms_attrs_template').cloneNode(true));
    item.set('id', 'attr_' + count);
    item.setStyle('display', 'block');
    var inputs = item.getElementsByTagName('input');
    
    for (var i = 0; i < inputs.length; i++) {
        var el = new YAHOO.util.Element(inputs[i]);
        el.set('name', el.get('name') + '_' + count);
        el.on('click', function() { 
            if (   this.get('value') == 'meta name'
                || this.get('value') == 'meta value'
                )
            {
                this.set('value','')
            }
        });
    }
    
    item.appendTo(attrs);
    Logger('appended new tags');
}

// based on http://developer.yahoo.com/yui/examples/editor/switch_editor.html
CMS.init_yui_editor = function() {
    var Event = YAHOO.util.Event;

    Logger('Create Button Controls');
    var save_button     = new YAHOO.widget.Button('save');
    Logger('got save button');
    var cancel_button   = new YAHOO.widget.Button('cancel');
    var toggle_button   = new YAHOO.widget.Button('toggle_editor');
    var preview_button  = new YAHOO.widget.Button('preview');
    var toggle_text     = toggle_button.get('label');
    Logger('made all buttons');

    var myConfig = {
        height: CMS.EDITOR_HEIGHT,
        width:  CMS.EDITOR_WIDTH,
        animate: true,
        dompath: true,
        focusAtStart: true,
        handleSubmit: true,
        resize: true
    };

    Logger('Create the Editor..');
    CMS.Editor = new YAHOO.widget.Editor('editor', myConfig);
    CMS.EDITOR_STATE = 'on';

    Logger('set Editor event listeners');
            
    CMS.Editor.on('afterRender', function() {
        var wrapper = CMS.Editor.get('editor_cont');
        Dom.addClass(wrapper, 'editor-hidden');
    });

    Logger('render Editor');
    CMS.Editor.render();
            
    /* make sure preview and save write any changes back to the YUI editor */
    save_button.on('click', CMS.Editor.saveHTML);
    preview_button.on('click', CMS.Editor.saveHTML);
    
    /* toggle button switches editor to plain textarea */    
    toggle_button.on('click', function(ev) {
        Event.stopEvent(ev);
        if (CMS.EDITOR_STATE == 'on') {
            Logger('state is on, so turn off');
            CMS.EDITOR_STATE = 'off';
            CMS.Editor.saveHTML();
            Logger('Set Editor container to position: absolute');
            Dom.setStyle(CMS.Editor.get('element_cont').get('firstChild'), 'position', 'absolute');
            Dom.setStyle(CMS.Editor.get('element_cont').get('firstChild'), 'top', '-9999px');
            Dom.setStyle(CMS.Editor.get('element_cont').get('firstChild'), 'left', '-9999px');
            CMS.Editor.get('element_cont').removeClass('yui-editor-container');
            Dom.setStyle(CMS.Editor.get('element'), 'visibility', 'visible');
            Dom.setStyle(CMS.Editor.get('element'), 'top', '');
            Dom.setStyle(CMS.Editor.get('element'), 'left', '');
            Dom.setStyle(CMS.Editor.get('element'), 'position', 'static');
        } else {
            Logger('state is off, so turn on');
            CMS.EDITOR_STATE = 'on';
            Logger('Set Editor container to position: static');
            Dom.setStyle(CMS.Editor.get('element_cont').get('firstChild'), 'position', 'static');
            Dom.setStyle(CMS.Editor.get('element_cont').get('firstChild'), 'top', '0');
            Dom.setStyle(CMS.Editor.get('element_cont').get('firstChild'), 'left', '0');
            Dom.setStyle(CMS.Editor.get('element'), 'visibility', 'hidden');
            Dom.setStyle(CMS.Editor.get('element'), 'top', '-9999px');
            Dom.setStyle(CMS.Editor.get('element'), 'left', '-9999px');
            Dom.setStyle(CMS.Editor.get('element'), 'position', 'absolute');
            CMS.Editor.get('element_cont').addClass('yui-editor-container');
            Logger('Reset designMode on the Editor');
            CMS.Editor._setDesignMode('on');
            //YAHOO.log('Inject the HTML from the textarea into the editor', 'info', 'example');
            CMS.Editor.setEditorHTML(CMS.Editor.get('textarea').value);
        }
    });


}

CMS.init_admin_links = function() {
    CMS.CreateDialog = new YAHOO.widget.SimpleDialog("create_new_dialog", 
        { width : "400px",
          fixedcenter : true,
          visible : false, 
          constraintoviewport : true,
          postmethod: 'form',
          modal: true,
          buttons : [ { text:"Submit", handler:handleSubmit, isDefault:true } ]
         });
    CMS.RenameDialog = new YAHOO.widget.SimpleDialog("rename_dialog", 
         { width : "400px",
           fixedcenter : true,
           visible : false, 
           constraintoviewport : true,
           postmethod: 'form',
           modal: true,
           buttons : [ { text:"Submit", handler:handleSubmit, isDefault:true } ]
         });

    // Define various event handlers for Dialog
    var handleSubmit = function() {
        this.submit();
    };
    var handleCancel = function() {
        this.cancel();
    };
    
    CMS.CreateDialog.render(document.body);
    CMS.RenameDialog.render(document.body);
    Logger("dialogs rendered");
    
}

CMS.lock_timer = function() {
    
    if (!CMS.LOCK_EXPIRES) {
        Logger('lock expired');
        return;
    }

    //grab current date
    var dateNow = new Date();                               
    //calc milliseconds between dates
    var amount = CMS.LOCK_EXPIRES.getTime() - dateNow.getTime();  
    delete dateNow;

    // time is already past
    if(amount < 0){
        Dom.get('countbox').innerHTML="Lock expired!";
    }
    // date is still good
    else{
        var days, hours, mins, secs, out;
        days=0;hours=0;mins=0;secs=0;out="";

        amount = Math.floor(amount/1000);//kill the "milliseconds" so just secs

        days=Math.floor(amount/86400);//days
        amount=amount%86400;

        hours=Math.floor(amount/3600);//hours
        amount=amount%3600;

        mins=Math.floor(amount/60);//minutes
        amount=amount%60;

        secs=Math.floor(amount);//seconds

        if (days != 0) {
            out += days +" day"+((days!=1)?"s":"")+", ";
        }
        if (days != 0 || hours != 0) {
            out += hours +" hour"+((hours!=1)?"s":"")+", ";
        }
        if (days != 0 || hours != 0 || mins != 0) {
            out += mins +" minute"+((mins!=1)?"s":"")+", ";
        }
        out += secs +" seconds";
        Dom.get('countbox').innerHTML=out;

        setTimeout(CMS.lock_timer, 1000);
    }
}

/* nearly verbatim from
http://developer.yahoo.com/yui/examples/layout/page_layout.html
*/
CMS.init_layout = function() {
    
    var Event = YAHOO.util.Event;
    var layout = new YAHOO.widget.Layout({
            units: [
                
                {   position: 'top', 
                    height: 58, 
                    body: 'top-panel', 
                    header: CMS.HEADER || CMS.THIS_URL, 
                    gutter: '5px', 
                    collapse: true, 
                    resize: true },
                
                {   position: 'right', 
                    header: 'Manage Content', 
                    width: 300, 
                    resize: true, 
                    gutter: '5px', 
                    footer: 'cms', 
                    collapse: true, 
                    scroll: true, 
                    body: 'right-panel', 
                    animate: true },
                
                {   position: 'bottom', 
                    header: '', 
                    height: 60, 
                    resize: true, 
                    body: 'footer', 
                    gutter: '5px', 
                    collapse: true },
                
                /*
                {   position: 'left', 
                    header: 'Left', 
                    width: 200, 
                    resize: true, 
                    body: 'left1', 
                    gutter: '5px', 
                    collapse: true, 
                    close: true, 
                    collapseSize: 50, 
                    scroll: true, 
                    animate: true },
                */
                {   position: 'center', 
                    body: 'content',
                    gutter: '5px' 
                }
            ]
    });

    layout.render();
    
    Logger("layout rendered");

    Event.on('tRight', 'click', function(ev) {
        Event.stopEvent(ev);
        layout.getUnitByPosition('right').toggle();
    });

}

CMS.init_plain_editor = function() {
    CMS.Editor = new YAHOO.util.Resize('editor');
    CMS.Editor.on('resize', function(e) {
        Dom.setStyle('resize', 'height', (e.height - 10) + 'px');
        Dom.setStyle('resize', 'width', (e.width - 10) + 'px');
    }, CMS.Editor, true);
    Logger("plain editor rendered");
}

CMS.init_tree = function() {

    CMS.Tree = new YAHOO.widget.TreeView('wrapper_tree');

    CMS.Tree.render();
    Logger('tree rendered');
}

CMS.setup_page = function() {
    if (CMS.USE_LAYOUT) {
        CMS.init_layout();
    }
    if (CMS.USE_EDITOR) {
        CMS.init_yui_editor();
    }
    else if (Dom.get('editor')) {
        CMS.init_plain_editor();
    }
    CMS.init_admin_links();
    CMS.lock_timer();
    CMS.init_tree();
    
}

YAHOO.util.Event.onDOMReady( CMS.setup_page );

