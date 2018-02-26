/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * Abstract Visualization widget.
 */
qx.Class.define('callbackery.ui.plugin.Table', {
    extend : callbackery.ui.plugin.Form,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embedd
     */
    properties: {
        selection: {
            init: {}
        }
    },
    members: {
        _populate: function(){
            this.setLayout(new qx.ui.layout.VBox(0));
            this.add(this._createToolbar());
            this.add(this._createTable(), {flex: 1});
        },
        _createToolbar: function(){
            var that = this;
            var cfg = this._cfg;
            var toolbar = new qx.ui.toolbar.ToolBar();
            var action = this._action = new callbackery.ui.plugin.Action(
                cfg,qx.ui.toolbar.Button,
                new qx.ui.layout.HBox(0),
                function(){
                    if (that._form.validate()){
                        var rpcData = that._form.getData();
                        rpcData['selection'] = that.getSelection();
                        return rpcData;
                    }
                    else {
                        return false;
                    }
                }
            );
            action.set({
                paddingLeft: -10
            });
            toolbar.add(action);
            toolbar.addSpacer();
            var form = this._form = new callbackery.ui.form.Auto(cfg.form,null,callbackery.ui.form.renderer.HBox);
            toolbar.add(form);
	    return toolbar;
        },
        _createTable: function(){
            var cfg = this._cfg;
            var model = this._model = new callbackery.data.RemoteTableModel(cfg,this._getParentFormData);
            var table = this._table = new qx.ui.table.Table(model,{
                tableColumnModel : function(obj) {
                    return new qx.ui.table.columnmodel.Resize(obj);
                }
            }).set({
                showCellFocusIndicator: false
            });
            var ctxMenu = this._action.getTableContextMenu();
            if (ctxMenu){
                table.setContextMenu(ctxMenu);
            }
            var defaultAction = this._action.getDefaultAction();
            if (defaultAction){
                table.addListener('cellDbltap',defaultAction,this._action);
            }
            var resizeBehavior = table.getTableColumnModel().getBehavior();
            cfg.table.forEach(function(col,i){
                var tcm = table.getTableColumnModel();
                var cr;
                switch (col.type) {
                    case 'date':
                        cr =  new qx.ui.table.cellrenderer.Date;
                        if (col.format != null) {
                            cr.setDateFormat(new qx.util.format.DateFormat(col.format));
                        }
                        break;
                    case 'str':
                    case 'string':
                        cr =  new qx.ui.table.cellrenderer.String(
                            col.align,col.color,col.style,col.weight
                        );
                        break;
                    case 'num':
                    case 'number':
                        cr =  new qx.ui.table.cellrenderer.Number(
                            col.align,col.color,col.style,col.weight
                        );
                        if (col.format != null) {
                            cr.setNumberFormat(
                                new qx.util.format.NumberFormat(col.locale)
                                    .set(col.format)
                            );
                        }
                        break;
                }
                if (cr){
                    tcm.setDataCellRenderer(i, cr);
                }
                if (col.width != null){
                    resizeBehavior.setWidth(i, String(col.width));
                }
            });

            var selectionModel = table.getSelectionModel();
            var currentRow = null;
            selectionModel.setSelectionMode(qx.ui.table.selection.Model.SINGLE_SELECTION);
            selectionModel.addListener('changeSelection',function(){
                selectionModel.iterateSelection(function(index) {
                    if (model.getRowData(index) != null) {
                        this.setSelection(model.getRowData(index));
                        currentRow = index;
                    }
                },this);
            },this);
            var processing = false;
            model.addListener('dataChanged',function(e){
                if (processing){
                    return;
                }
                processing = true;
                var lastData = this.getSelection();
                new qx.util.DeferredCall(function(){
                    if (currentRow !== null && qx.lang.Type.isObject(lastData) ){
                        for (var offset=-1;offset<=1;offset++){
                            if (currentRow + offset < 0){
                                continue;
                            }
                            var currentData = model.getRowData(currentRow+offset);
                            var gotPrimary = false;
                            var equal = true;
                            cfg.table.forEach(function(col,i){
                                if (col.primary){
                                    gotPrimary = true;
                                    if (!qx.lang.Type.isObject(currentData)
                                        || !qx.lang.Type.isObject(lastData)
                                        || currentData[col.key] != lastData[col.key]){
                                        equal = false;
                                    }
                                }
                            });
                            if (gotPrimary && equal){
                                if (offset != 0){
                                    table.clearFocusedRowHighlight();
                                    table.setFocusedCell(0,currentRow+offset,false);
                                    selectionModel.setSelectionInterval(currentRow+offset,currentRow+offset);
                                }
                                this.setSelection(currentData);
                                processing = false;
                                return;
                            }
                        }
                    }
                    table.resetSelection();
                    table.clearFocusedRowHighlight();
                    this.setSelection({});
                    processing = false;
                },this).schedule();
            },this);

            this.addListener('appear',function(e){
                model.reloadData();
            });
            this._form.addListener('changeData',function(e){
                model.setFormData(e.getData());
                if (this._loading == 0){ // only reload when data has been changed by human
                    model.reloadData();
                }
            },this);

            this._action.addListener('actionResponse',function(e){
                var data = e.getData();
                switch (data.action){
                    case 'reload':
                    case 'dataModified':
                        model.reloadData();
                        break;
                }
            });
            return table;
        }
    }
});
