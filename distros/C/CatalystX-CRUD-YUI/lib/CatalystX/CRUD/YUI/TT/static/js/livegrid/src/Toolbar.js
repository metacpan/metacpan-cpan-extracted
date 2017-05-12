/**
 * Ext.ux.grid.livegrid.Toolbar
 * Copyright (c) 2007-2008, http://www.siteartwork.de
 *
 * Ext.ux.grid.livegrid.Toolbar is licensed under the terms of the
 *                  GNU Open Source GPL 3.0
 * license.
 *
 * Commercial use is prohibited. Visit <http://www.siteartwork.de/livegrid>
 * if you need to obtain a commercial license.
 *
 * This program is free software: you can redistribute it and/or modify it under
 * the terms of the GNU General Public License as published by the Free Software
 * Foundation, either version 3 of the License, or any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <http://www.gnu.org/licenses/gpl.html>.
 *
 */

Ext.namespace('Ext.ux.grid.livegrid');

/**
 * toolbar that is bound to a {@link Ext.ux.grid.livegrid.GridView}
 * and provides information about the indexes of the requested data and the buffer
 * state.
 *
 * @class Ext.ux.grid.livegrid.Toolbar
 * @extends Ext.Toolbar
 * @constructor
 * @param {Object} config
 *
 * @author Thorsten Suckow-Homberg <ts@siteartwork.de>
 */
Ext.ux.grid.livegrid.Toolbar = Ext.extend(Ext.Toolbar, {

    /**
     * @cfg {Ext.grid.GridPanel} grid
     * The grid the toolbar is bound to. If ommited, use the cfg property "view"
     */

    /**
     * @cfg {Ext.grid.GridView} view The view the toolbar is bound to
     * The grid the toolbar is bound to. If ommited, use the cfg property "grid"
     */

    /**
     * @cfg {Boolean} displayInfo
     * True to display the displayMsg (defaults to false)
     */

    /**
     * @cfg {String} displayMsg
     * The paging status message to display (defaults to "Displaying {start} - {end} of {total}")
     */
    displayMsg : 'Displaying {0} - {1} of {2}',

    /**
     * @cfg {String} emptyMsg
     * The message to display when no records are found (defaults to "No data to display")
     */
    emptyMsg : 'No data to display',

    /**
     * Value to display as the tooltip text for the refresh button. Defaults to
     * "Refresh"
     * @param {String}
     */
    refreshText : "Refresh",

    initComponent : function()
    {
        Ext.ux.grid.livegrid.Toolbar.superclass.initComponent.call(this);

        if (this.grid) {
            this.view = this.grid.getView();
        }

        var me = this;
        this.view.init = this.view.init.createSequence(function(){
            me.bind(this);
        }, this.view);
    },

    // private
    updateInfo : function(rowIndex, visibleRows, totalCount)
    {
        if(this.displayEl){
            var msg = totalCount == 0 ?
                this.emptyMsg :
                String.format(this.displayMsg, rowIndex+1,
                              rowIndex+visibleRows, totalCount);
            this.displayEl.update(msg);
        }
    },

    /**
     * Unbinds the toolbar.
     *
     * @param {Ext.grid.GridView|Ext.gid.GridPanel} view Either The view to unbind
     * or the grid
     */
    unbind : function(view)
    {
        var st;
        var vw;

        if (view instanceof Ext.grid.GridView) {
            vw = view;
        } else {
            // assuming parameter is of type Ext.grid.GridPanel
            vw = view.getView();
        }

        st = view.ds;

        st.un('loadexception', this.enableLoading,  this);
        st.un('beforeload',    this.disableLoading, this);
        st.un('load',          this.enableLoading,  this);
        vw.un('rowremoved',    this.onRowRemoved,   this);
        vw.un('rowsinserted',  this.onRowsInserted, this);
        vw.un('beforebuffer',  this.beforeBuffer,   this);
        vw.un('cursormove',    this.onCursorMove,   this);
        vw.un('buffer',        this.onBuffer,       this);
        vw.un('bufferfailure', this.enableLoading,  this);

        this.view = undefined;
    },

    /**
     * Binds the toolbar to the specified {@link Ext.ux.grid.Livegrid}
     *
     * @param {Ext.grird.GridView} view The view to bind
     */
    bind : function(view)
    {
        this.view = view;
        var st = view.ds;

        st.on('loadexception',   this.enableLoading,  this);
        st.on('beforeload',      this.disableLoading, this);
        st.on('load',            this.enableLoading,  this);
        view.on('rowremoved',    this.onRowRemoved,   this);
        view.on('rowsinserted',  this.onRowsInserted, this);
        view.on('beforebuffer',  this.beforeBuffer,   this);
        view.on('cursormove',    this.onCursorMove,   this);
        view.on('buffer',        this.onBuffer,       this);
        view.on('bufferfailure', this.enableLoading,  this);
    },

// ----------------------------------- Listeners -------------------------------
    enableLoading : function()
    {
        this.loading.setDisabled(false);
    },

    disableLoading : function()
    {
        this.loading.setDisabled(true);
    },

    onCursorMove : function(view, rowIndex, visibleRows, totalCount)
    {
        this.updateInfo(rowIndex, visibleRows, totalCount);
    },

    // private
    onRowsInserted : function(view, start, end)
    {
        this.updateInfo(view.rowIndex, Math.min(view.ds.totalLength, view.visibleRows-view.rowClipped),
                        view.ds.totalLength);
    },

    // private
    onRowRemoved : function(view, index, record)
    {
        this.updateInfo(view.rowIndex, Math.min(view.ds.totalLength, view.visibleRows-view.rowClipped),
                        view.ds.totalLength);
    },

    // private
    beforeBuffer : function(view, store, rowIndex, visibleRows, totalCount, options)
    {
        this.loading.disable();
        this.updateInfo(rowIndex, visibleRows, totalCount);
    },

    // private
    onBuffer : function(view, store, rowIndex, visibleRows, totalCount)
    {
        this.loading.enable();
        this.updateInfo(rowIndex, visibleRows, totalCount);
    },

    // private
    onClick : function(type)
    {
        switch (type) {
            case 'refresh':
                if (this.view.reset(true)) {
                    this.loading.disable();
                } else {
                    this.loading.enable();
                }
            break;

        }
    },

    // private
    onRender : function(ct, position)
    {
        Ext.PagingToolbar.superclass.onRender.call(this, ct, position);

        this.loading = this.addButton({
            tooltip : this.refreshText,
            iconCls : "x-tbar-loading",
            handler : this.onClick.createDelegate(this, ["refresh"])
        });

        this.addSeparator();

        if(this.displayInfo){
            this.displayEl = Ext.fly(this.el.dom).createChild({cls:'x-paging-info'});
        }
    }
});