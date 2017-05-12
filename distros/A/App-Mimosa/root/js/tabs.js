Ext.onReady(function(){
    // basic tabs 1, built from existing content
    var tabs = new Ext.TabPanel({
        renderTo: 'tabs1',
        width:    "80%",
        activeTab: 0,
        frame:     true,
        defaults:  {autoHeight: true},
        items:[
            {contentEl:'t1_content', title: 'Align'},
            {contentEl:'t2_content', title: 'Preferences'},
            {contentEl:'t3_content', title: 'About'},
        ]
    });

});
