/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Abstract Visualization widget.
 */
qx.Class.define("callbackery.ui.Popup", {
    extend : qx.ui.window.Window,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embedd
     */
    construct : function(cfg,getParentFormData) {
        /* using syntax trick to not get a warning for translating
           a variable */
        this.base(arguments, this['tr'](cfg.popupTitle));
        this.set({
            layout: new qx.ui.layout.Grow(),
            minHeight: 600,
            minWidth: 800,
            modal: true,
            allowMinimize: false,
            showMinimize: false,
            showStatusbar: false
        });
        var extraAction = {
            label : 'Cancel',
            action : 'cancel'
        };
        cfg.instantiationMode = 'onStartup';
        var screen = new callbackery.ui.Screen(cfg,getParentFormData,extraAction);
        this.add(screen);
        screen.addListener('actionResponse',function(e){
            var data = e.getData();
            this.fireDataEvent('actionResponse',data);
            switch (data.action){
                case 'dataSaved':
                case 'cancel':
                    this.close();
            }
        },this);
        this.addListener('keydown',function(e){
            if (e.getKeyIdentifier() == 'Escape'){
                e.preventDefault();
                e.stopPropagation();
                screen.fireDataEvent('actionResponse',{action: 'cancel'});
            }
        },this);
        this.addListener('appear',function(){
            this.center()
        },this);
        screen.getApplicationRoot().addListener('resize',function(){
            this.center()
        },this);

    },
    events: {
        actionResponse: 'qx.event.type.Data'
    }
});
