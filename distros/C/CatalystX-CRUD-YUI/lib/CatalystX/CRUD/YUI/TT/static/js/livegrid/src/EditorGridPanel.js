/**
 * Ext.ux.grid.livegrid.EditorGridPanel
 * Copyright (c) 2007-2008, http://www.siteartwork.de
 *
 * Ext.ux.grid.livegrid.EditorGridPanel is licensed under the terms of the
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
 * @class Ext.ux.grid.livegrid.EditorGridPanel
 * @extends Ext.grid.EditorGridPanel
 * @constructor
 * @param {Object} config
 *
 * @author Thorsten Suckow-Homberg <ts@siteartwork.de>
 */
Ext.ux.grid.livegrid.EditorGridPanel = Ext.extend(Ext.grid.EditorGridPanel, {

    /**
     * Overriden so the panel listens to the "cursormove" event for
     * cancelling any edit that is in progress.
     *
     * @private
     */
    initEvents : function()
    {
        Ext.ux.grid.livegrid.EditorGridPanel.superclass.initEvents.call(this);

        this.view.on("cursormove", this.stopEditing, this, [true]);
    },

    /**
     * Starts editing the specified for the specified row/column
     * Will be cancelled if the requested row index to edit is not
     * represented by data due to out of range regarding the view's
     * store buffer.
     *
     * @param {Number} rowIndex
     * @param {Number} colIndex
     */
    startEditing : function(row, col)
    {
        this.stopEditing();
        if(this.colModel.isCellEditable(col, row)){
            this.view.ensureVisible(row, col, true);
            if (!this.store.getAt(row)) {
                return;
            }
        }

        return Ext.ux.grid.livegrid.EditorGridPanel.superclass.startEditing.call(this, row, col);
    },

// Since we do not have multiple inheritance, we need to override the
// same methods in this class we have overriden for
// Ext.ux.grid.livegrid.GridPanel
    walkCells : function(row, col, step, fn, scope)
    {
        return Ext.ux.grid.livegrid.GridPanel.prototype.walkCells.call(this, row, col, step, fn, scope);
    },

    onRender : function(ct, position)
    {
        return Ext.ux.grid.livegrid.GridPanel.prototype.onRender.call(this, ct, position);
    }

});