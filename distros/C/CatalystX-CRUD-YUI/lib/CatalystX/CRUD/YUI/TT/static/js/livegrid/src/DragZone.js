/**
 * Ext.ux.grid.livegrid.DragZone
 * Copyright (c) 2007-2008, http://www.siteartwork.de
 *
 * Ext.ux.grid.livegrid.DragZone is licensed under the terms of the
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
 * @class Ext.ux.grid.livegrid.DragZone
 * @extends Ext.dd.DragZone
 * @author Thorsten Suckow-Homberg <ts@siteartwork.de>
 */
Ext.ux.grid.livegrid.DragZone = function(grid, config){

    Ext.ux.grid.livegrid.DragZone.superclass.constructor.call(this, grid, config);

    this.view.ds.on('beforeselectionsload', this._onBeforeSelectionsLoad, this);
    this.view.ds.on('selectionsload',       this._onSelectionsLoad,       this);
};

Ext.extend(Ext.ux.grid.livegrid.DragZone, Ext.grid.GridDragZone, {

    /**
     * Tells whether a drop is valid. Used inetrnally to determine if pending
     * selections need to be loaded/ have been loaded.
     * @type {Boolean}
     */
    isDropValid : true,

    /**
     * Overriden for loading pending selections if needed.
     */
    onInitDrag : function(e)
    {
        this.view.ds.loadSelections(this.grid.selModel.getPendingSelections(true));

        Ext.ux.grid.livegrid.DragZone.superclass.onInitDrag.call(this, e);
    },

    /**
     * Gets called before pending selections are loaded. Any drop
     * operations are invalid/get paused if the component needs to
     * wait for selections to load from the server.
     *
     */
    _onBeforeSelectionsLoad : function()
    {
        this.isDropValid = false;
        Ext.fly(this.proxy.el.dom.firstChild).addClass('ext-ux-livegrid-drop-waiting');
    },

    /**
     * Gets called after pending selections have been loaded.
     * Any paused drop operation will be resumed.
     *
     */
    _onSelectionsLoad : function()
    {
        this.isDropValid = true;
        this.ddel.innerHTML = this.grid.getDragDropText();
        Ext.fly(this.proxy.el.dom.firstChild).removeClass('ext-ux-livegrid-drop-waiting');
    }
});