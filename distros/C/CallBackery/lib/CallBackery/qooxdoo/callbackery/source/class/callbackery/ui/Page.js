/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Abstract Visualization widget.
 */
qx.Class.define("callbackery.ui.Page", {
    extend : qx.ui.tabview.Page,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embedd
     */
    construct : function(cfg) {
        /* using syntax trick to not get a warning for translating
           a variable */
        this.base(arguments, this.xtr(cfg.tabName));
        this.setLayout(new qx.ui.layout.Grow());
        this.setPadding([0,0,0,0]);
        var screen = new callbackery.ui.Screen(cfg);
        // track visibility changes in the screen widget
        screen.addListener('changeVisibility',function(){
            var visibility = screen.getVisibility();
            this.setVisibility(visibility);
            this.getChildControl('button').setVisibility(visibility);
        },this);
        this.add(screen);
        screen.addListener('actionResponse',function(e){
            var data = e.getData();
            switch (data.action){
                case 'dataSaved':
                case 'cancel':
                    this.setUnsavedData(false);
                    break;
                case 'dataModified':
                    this.setUnsavedData(true);
                    break;
            }
        },this);
    },
    properties: {
        unsavedData: {
            init: false
        }
    }
});
