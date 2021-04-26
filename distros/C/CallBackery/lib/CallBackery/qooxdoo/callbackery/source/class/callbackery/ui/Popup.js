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
        this.base(arguments, this.xtr(cfg.popupTitle));
        this.set({
            layout: new qx.ui.layout.Grow(),
            height: 600,
            width: 800,
            modal: true,
            allowMinimize: false,
            showMinimize: false,
            showStatusbar: false,
            centerOnContainerResize: true,
            centerOnAppear: true
        });
        this.getApplicationRoot().addListener('resize',this.__autoMax,this);
        this.__autoMax();

        if (cfg.set){
            this.set(cfg.set);
        }
        this.add(this._createContent(cfg,getParentFormData));
    },
    members: {
        _screen : null,

        __autoMax: function() {
            let bounds = this.getApplicationRoot().getBounds();
            // make sure the window does not get larger than the screen by default ... 
            if (bounds) {
                this.setMaxWidth(bounds.width-20);
                this.setMaxHeight(bounds.height-20);
            }
        },
        replaceContent : function(cfg,getParentFormData) {
            this.remove(this._screen);
            this.add(this._createContent(cfg,getParentFormData));
        },
        _createContent : function(cfg,getParentFormData) {
            // make sure it gets added to the translation
            this.tr('Cancel');
            var extraAction = {
                label : 'Cancel',
                action : 'cancel'
            };
            if (cfg.cancelLabel) {
                extraAction.label = cfg.cancelLabel;
            }
            cfg.instantiationMode = 'onStartup';
            var screen = this._screen = new callbackery.ui.Screen(cfg,getParentFormData,extraAction);
            screen.addListener('actionResponse',function(e){
                var data = e.getData();
                this.fireDataEvent('actionResponse',data);
                switch (data.action){
                case 'wait':
                case 'dataModified':
                case 'reloadStatus':
                    break;
                case 'showMessage':
                case 'dataSaved':
                case 'cancel':
                    this.close();
                    break;
                default:
                    console.warn('Unknown actionResponse', data.action);
                    break;
                }
            },this);
            this.addListener('keydown',function(e){
                if (e.getKeyIdentifier() == 'Escape'){
                    e.preventDefault();
                    e.stopPropagation();
                    screen.fireDataEvent('actionResponse',{action: 'cancel'});
                }
            },this);
            return screen;
        }
    },
    events: {
        actionResponse: 'qx.event.type.Data'
    }
});
