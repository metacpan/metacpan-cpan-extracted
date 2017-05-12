Ext.namespace("POD");

// Too much regex for my liking.  A JQuery plugin would be cleaner, but this works.
// http://stackoverflow.com/questions/901115/get-querystring-with-jquery/901144#901144
POD.qsVal = function ( name ) {
    name = name.replace(/[\[]/,"\\\[").replace(/[\]]/,"\\\]");
    var regexS = "[\\?&]"+name+"=([^&#]*)";
    var regex = new RegExp( regexS );
    var results = regex.exec( window.location.href );
    if( results == null )
        return "";
    else
        return results[1];
}

POD.addTab = function (title, url, section,module) {
    if(Ext.getCmp("tab-"+title)) {
        Ext.getCmp("tab-"+title).show();
        return Ext.getCmp("tab-"+title);
    }
    POD.clearTOC();
    var tab = POD.tabs.add({
        title: title, 
        id: "tab-" + title,
        closable: true,
        closeAction: "hide",
        autoLoad: {url : url,
        loadScripts: true,
        callback : function() {POD.scrollToSection(tab, section,module);}},
        autoScroll: true
    });
    tab.show();
    return tab;
}

POD.proxyLink = function(link) {
    var re = new RegExp("^" + Ext.escapeRe("[% root %]"));
    if(!re.test(link.href)) return true;
    var module = link.href.replace(new RegExp(Ext.escapeRe("[% root %]/module/")), "");

    var parts = module.split(/#/);
    section = unescape(parts[1]);
    module = parts[0];
    if(re.test(module)) {
        module = POD.tabs.getActiveTab().getId().replace(/tab-/, "");
    }
    var tab = POD.addTab(module, link.href, section, module);
    POD.scrollToSection(tab, section, module);
    return false;
}

POD.scrollToSection = function(tab, section, module){
    var el = document.getElementById("section-"+module+"-"+section);
    if(el){
        var top = (Ext.fly(el).getOffsetsTo(tab.body)[1]) + tab.body.dom.scrollTop;
        tab.body.scrollTo('top', top, {duration:.5});
    }
}

POD.reloadTree = function(e) {
    if(!e.target.value) {
        POD.tree.getLoader().dataUrl = '[% root %]/modules';
        POD.tree.getLoader().load(POD.tree.root);
        return;
    }
    POD.tree.getLoader().dataUrl = '[% root %]/modules/'+e.target.value;
    POD.tree.getLoader().load(POD.tree.root);
}

POD.tree = new Ext.tree.TreePanel({
    title:           "Modules",
    autoScroll:      true,
    animate:         true,
    rootVisible:     false,
    split:           true,
    region:          "center",
    containerScroll: true,
    listeners:  {
        click: function(node) { POD.addTab(node.attributes.name, "[% root %]/module/"+node.attributes.name) }},
        loader: new Ext.tree.TreeLoader({
            dataUrl:   '[% root %]/modules',
            autoLoad:  false,
            listeners: { 
                beforeload: function() { POD.tree.getEl().mask('Modules are being loaded') }, 
                load: function() { 
                    POD.tree.getEl().unmask();
                    if([% expand_module_tree_on_load %]) {
                        var old = POD.tree.animate;
                        POD.tree.animate = false;
                        POD.tree.expandAll();
                        POD.tree.animate = old;
                    }
                }
            }
        }),
    tbar: [
            new Ext.form.TextField({
                width: 130,
                emptyText: 'Find a Class',
                listeners: {
                    render: function(f){
                        f.el.on('keydown', POD.reloadTree, f, {buffer: 350});
                    }
                }
            }), 
            ' ',
            ' ',
            {
                handler: function (){POD.tree.expandAll()},
                tooltip: 'Expand all nodes',
                iconCls:"icon-expand-all"
            },
            {
                handler: function (){POD.tree.collapseAll()},
                tooltip: 'Collapse all nodes',
                iconCls:"icon-collapse-all"}
        ]
});

var root = new Ext.tree.AsyncTreeNode({
    text: 'mods',
    expanded:true,
});

POD.tree.setRootNode(root);
POD.filter = new Ext.tree.TreeFilter(POD.tree, {
    clearBlank: true,
    autoClear: true
});

POD.TOC = new Ext.tree.TreePanel({
    title:       "TOC",
    autoScroll:  true,
    height:      200,
    collapsible: true,
    animate:     true,
    rootVisible: false,
    loader:      new Ext.tree.TreeLoader(),
    split:       true,
    region:      "north",
    listeners: {
        click: function(node) { 
            var module = POD.tabs.getActiveTab().getId().replace(/tab-/,"");
            POD.scrollToSection(POD.tabs.getActiveTab(), node.text, module);
        }
    }
});

POD.TOC.setRootNode(new Ext.tree.AsyncTreeNode({
    text: 'mods',
    expanded:false
}));

POD.populateTOC = function (nodes, root) {
    for(var i = 0; i < nodes.length; i++) {
        var n = POD.TOC.getLoader().createNode(nodes[i]);
        if (n) {
            root.appendChild(n);
        }
    }
}

POD.leftColumn = new Ext.Panel({
    layout: "border",
    region: "west",
    split:  true,
    width:  200,
    items:  [POD.tree, POD.TOC]
});

POD.TOCs = {};

POD.clearTOC = function() {
    while (POD.TOC.root.firstChild) {
        POD.TOC.root.removeChild(POD.TOC.root.firstChild);
    }
}

POD.setTOC = function (nodes) {
    POD.clearTOC();
    POD.TOCs[POD.tabs.getActiveTab().getId()] = nodes;
    POD.populateTOC(nodes, POD.TOC.root);
}


POD.searchStore = new Ext.data.Store( {
    proxy: new Ext.data.HttpProxy( {
        method :'POST',
        url :'[% root %]/search'
    }),
    reader: new Ext.data.JsonReader( {
            root :'module',
            totalProperty :'matches'
            }, [ {
                name :'link',
                mapping :'link'
            }, {
                name :'name',
                mapping :'name'
            }, {
                name :'released',
                mapping :'released'
            }, {
                name :'version',
                mapping :'version'
            }, {
                name :'description',
                mapping :'description'
            }, {
                name :'author',
                mapping :'author'
            }]
    )
});

var resultTpl = new Ext.XTemplate(
    '<tpl for="."><div class="search-item">',
    '<span>{released}',
    '</span><h3>{name}</h3> (Version {version})<br>{description}</div></tpl>');


var Memoria = {};
Memoria.Search = {};
Memoria.Search.InstantAdd = new (function() {

    this.init = function(combo) {
        this.combo = combo;
        var add = new Ext.Layer({cls: "x-combo-list", html: "test1234", zindex: "100"});  
        var lw = combo.listWidth || Math.max(combo.wrap.getWidth(), combo.minListWidth);
        add.setWidth(lw);
        add.alignTo(combo.wrap, combo.listAlign);
        this.content = add.createChild({cls:'search-item'});
        this.add = add;
        new Ext.KeyNav(combo.el, {
            esc: function() { Memoria.Search.InstantAdd.hide() },
            enter: function() {
                Memoria.Search.InstantAdd.hide();
                Memoria.Clients.add(stringToName(Memoria.Search.InstantAdd.combo.getValue()));
            }
        })
        combo.el.on("keydown", this.hide , this);
        this.tpl = new Ext.XTemplate('<h3 style="text-align: center">Sorry. Couldn\'t find anything.</h3>');
    }

    this.show = function () {
        if(!this.combo.getValue()) return;
        this.add.show();
        this.content.dom.innerHTML = this.tpl.apply({name: this.combo.getValue()});
    }

    this.hide = function () {
        this.add.dom.style.visibility=""; // Do not use this.add.hide() BUG?
    }
})();

POD.tabs = new Ext.TabPanel({
    region:         'center',
    activeTab:       0,
    autoScroll:      true,
    margins:         "5 5 5 5",
    enableTabScroll: true,
    listeners: {
        tabchange: function(panel, tab) {
            if(POD.TOCs[tab.getId()])
              POD.setTOC(POD.TOCs[tab.getId()]);
            if(tab.getId() == "search-box")
              POD.clearTOC();
        }
    },
    tools: [
        {
            id: "print", 
            handler: function() {
                window.open("[% root %]/module/"+tabs.getActiveTab().id.replace(/tab-/,"")); }
        }, {
            id: "close",
            handler: function () {
                tabs.items.each(function(el){if(new RegExp("tab-").test(el.id)) tabs.remove(el)})
            }
        }
    ],
});

//
// For some reason the following order matters.
// 

// Display documentation for the permalink
var permalink = POD.qsVal("permalink");
if(permalink) {
    POD.addTab(permalink, "[% root %]/module/" + permalink);
}

// Show the home tab only if we're configured to 
if([% show_home_tab %]) {
    POD.tabs.add({
        layout: 'form',
        title:  "Home",
        id:     "search-box",
        frame:  false,
        border: false,
        autoLoad: {
            url: "[% root %]/home_tab_content",
            callback: function() { POD.configSearchCombo(); },
            loadScripts: true,
        },
    });
}

if("[% initial_module %]") {
    // Display a perldoc tab on startup
    POD.addTab("[% initial_module %]", "[% root %]/module/[% initial_module %]");
}

POD.configSearchCombo = function () {
    var search = new Ext.form.ComboBox( {
        store:      POD.searchStore,
        typeAhead:  false,
        minChars:   3,
        queryParam: 'value',
        emptyText:  "Search the CPAN for modules",
        loadingText:'Searching ...',
        width:       470,
        pageSize:    50,
        hideTrigger: true,
        tpl:         resultTpl,
        applyTo:     Ext.getDom('search'),
        itemSelector:'div.search-item',
        listeners: {
            render: function(combo) {
                Memoria.Search.InstantAdd.init(combo)
            },
            collapse: function() {
                Memoria.Search.InstantAdd.show()
            },
            select: function(combo, record) { 
                POD.addTab(record.get("name"), "[% root %]/module/"+record.get("name"));
                Memoria.Search.InstantAdd.hide();
            },
            blur: function() {
                Memoria.Search.InstantAdd.hide();
            }
        }
    });
    Ext.getDom('search').focus(100, true);
}

Ext.onReady(function(){
    Ext.Updater.defaults.loadScripts = true;
  
    var viewport = new Ext.Viewport({
        layout:'border',
        items:[POD.tabs, POD.leftColumn]
    });
});
