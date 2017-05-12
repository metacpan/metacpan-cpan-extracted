/**
 * Ext.ux.grid.livegrid.RowSelectionModel
 * Copyright (c) 2007-2008, http://www.siteartwork.de
 *
 * Ext.ux.grid.livegrid.RowSelectionModel is licensed under the terms of the
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
 * @class Ext.ux.grid.livegrid.RowSelectionModel
 * @extends Ext.grid.RowSelectionModel
 * @constructor
 * @param {Object} config
 *
 * @author Thorsten Suckow-Homberg <ts@siteartwork.de>
 */
Ext.ux.grid.livegrid.RowSelectionModel = function(config) {


    this.addEvents({
        /**
         * The selection dirty event will be triggered in case records were
         * inserted/ removed at view indexes that may affect the current
         * selection ranges which are only represented by view indexes, but not
         * current record-ids
         */
        'selectiondirty' : true
    });

    Ext.apply(this, config);

    this.pendingSelections = {};

    Ext.ux.grid.livegrid.RowSelectionModel.superclass.constructor.call(this);

};

Ext.extend(Ext.ux.grid.livegrid.RowSelectionModel, Ext.grid.RowSelectionModel, {


 // private
    initEvents : function()
    {
        Ext.ux.grid.livegrid.RowSelectionModel.superclass.initEvents.call(this);

        this.grid.view.on('rowsinserted',    this.onAdd,            this);
        this.grid.store.on('selectionsload', this.onSelectionsLoad, this);
    },

    /**
     * Callback is called when a row gets removed in the view. The process to
     * invoke this method is as follows:
     *
     * <ul>
     *  <li>1. store.remove(record);</li>
     *  <li>2. view.onRemove(store, record, indexInStore, isUpdate)<br />
     *   [view triggers rowremoved event]</li>
     *  <li>3. this.onRemove(view, indexInStore, record)</li>
     * </ul>
     *
     * If r defaults to <tt>null</tt> and index is within the pending selections
     * range, the selectionchange event will be called, too.
     * Additionally, the method will shift all selections and trigger the
     * selectiondirty event if any selections are pending.
     *
     */
    onRemove : function(v, index, r)
    {
        var ranges           = this.getPendingSelections();
        var rangesLength     = ranges.length;
        var selectionChanged = false;

        // if index equals to Number.MIN_VALUE or Number.MAX_VALUE, mark current
        // pending selections as dirty
        if (index == Number.MIN_VALUE || index == Number.MAX_VALUE) {

            if (r) {
                // if the record is part of the current selection, shift the selection down by 1
                // if the index equals to Number.MIN_VALUE
                if (this.isIdSelected(r.id) && index == Number.MIN_VALUE) {
                    // bufferRange already counted down when this method gets
                    // called
                    this.shiftSelections(this.grid.store.bufferRange[1], -1);
                }
                this.selections.remove(r);
                selectionChanged = true;
            }

            // clear all pending selections that are behind the first
            // bufferrange, and shift all pending Selections that lay in front
            // front of the second bufferRange down by 1!
            if (index == Number.MIN_VALUE) {
                this.clearPendingSelections(0, this.grid.store.bufferRange[0]);
            } else {
                // clear pending selections that are in front of bufferRange[1]
                this.clearPendingSelections(this.grid.store.bufferRange[1]);
            }

            // only fire the selectiondirty event if there were pendning ranges
            if (rangesLength != 0) {
                this.fireEvent('selectiondirty', this, index, 1);
            }

        } else {

            selectionChanged = this.isIdSelected(r.id);

            // if the record was not part of the selection, return
            if (!selectionChanged) {
                return;
            }

            this.selections.remove(r);
            //this.last = false;
            // if there are currently pending selections, look up the interval
            // to tell whether removing the record would mark the selection dirty
            if (rangesLength != 0) {

                var startRange = ranges[0];
                var endRange   = ranges[rangesLength-1];
                if (index <= endRange || index <= startRange) {
                    this.shiftSelections(index, -1);
                    this.fireEvent('selectiondirty', this, index, 1);
                }
             }

        }

        if (selectionChanged) {
            this.fireEvent('selectionchange', this);
        }
    },


    /**
     * If records where added to the store, this method will work as a callback,
     * called by the views' rowsinserted event.
     * Selections will be shifted down if, and only if, the listeners for the
     * selectiondirty event will return <tt>true</tt>.
     *
     */
    onAdd : function(store, index, endIndex, recordLength)
    {
        var ranges       = this.getPendingSelections();
        var rangesLength = ranges.length;

        // if index equals to Number.MIN_VALUE or Number.MAX_VALUE, mark current
        // pending selections as dirty
        if ((index == Number.MIN_VALUE || index == Number.MAX_VALUE)) {

            if (index == Number.MIN_VALUE) {
                // bufferRange already counted down when this method gets
                // called
                this.clearPendingSelections(0, this.grid.store.bufferRange[0]);
                this.shiftSelections(this.grid.store.bufferRange[1], recordLength);
            } else {
                this.clearPendingSelections(this.grid.store.bufferRange[1]);
            }

            // only fire the selectiondirty event if there were pendning ranges
            if (rangesLength != 0) {
                this.fireEvent('selectiondirty', this, index, r);
            }

            return;
        }

        // it is safe to say that the selection is dirty when the inserted index
        // is less or equal to the first selection range index or less or equal
        // to the last selection range index
        var startRange = ranges[0];
        var endRange   = ranges[rangesLength-1];
        var viewIndex  = index;
        if (viewIndex <= endRange || viewIndex <= startRange) {
            this.fireEvent('selectiondirty', this, viewIndex, recordLength);
            this.shiftSelections(viewIndex, recordLength);
        }
    },



    /**
     * Shifts current/pending selections. This method can be used when rows where
     * inserted/removed and the selection model has to synchronize itself.
     */
    shiftSelections : function(startRow, length)
    {
        var index         = 0;
        var newIndex      = 0;
        var newRequests   = {};

        var ds            = this.grid.store;
        var storeIndex    = startRow-ds.bufferRange[0];
        var newStoreIndex = 0;
        var totalLength   = this.grid.store.totalLength;
        var rec           = null;

        //this.last = false;

        var ranges       = this.getPendingSelections();
        var rangesLength = ranges.length;

        if (rangesLength == 0) {
            return;
        }

        for (var i = 0; i < rangesLength; i++) {
            index = ranges[i];

            if (index < startRow) {
                continue;
            }

            newIndex      = index+length;
            newStoreIndex = storeIndex+length;
            if (newIndex >= totalLength) {
                break;
            }

            rec = ds.getAt(newStoreIndex);
            if (rec) {
                this.selections.add(rec);
            } else {
                newRequests[newIndex] = true;
            }
        }

        this.pendingSelections = newRequests;
    },

    /**
     *
     * @param {Array} records The records that have been loaded
     * @param {Array} ranges  An array representing the model index ranges the
     *                        reords have been loaded for.
     */
    onSelectionsLoad : function(store, records, ranges)
    {
        this.replaceSelections(records);
    },

    /**
     * Returns true if there is a next record to select
     * @return {Boolean}
     */
    hasNext : function()
    {
        return this.last !== false && (this.last+1) < this.grid.store.getTotalCount();
    },

    /**
     * Gets the number of selected rows.
     * @return {Number}
     */
    getCount : function()
    {
        return this.selections.length + this.getPendingSelections().length;
    },

    /**
     * Returns True if the specified row is selected.
     *
     * @param {Number/Record} record The record or index of the record to check
     * @return {Boolean}
     */
    isSelected : function(index)
    {
        if (typeof index == "number") {
            var orgInd = index;
            index = this.grid.store.getAt(orgInd);
            if (!index) {
                var ind = this.getPendingSelections().indexOf(orgInd);
                if (ind != -1) {
                    return true;
                }

                return false;
            }
        }

        var r = index;
        return (r && this.selections.key(r.id) ? true : false);
    },


    /**
     * Deselects a record.
     * The emthod assumes that the record is physically available, i.e.
     * pendingSelections will not be taken into account
     */
    deselectRecord : function(record, preventViewNotify)
    {
        if(this.locked) {
            return;
        }

        var isSelected = this.selections.key(record.id);

        if (!isSelected) {
            return;
        }

        var store = this.grid.store;
        var index = store.indexOfId(record.id);

        if (index == -1) {
            index = store.findInsertIndex(record);
            if (index != Number.MIN_VALUE && index != Number.MAX_VALUE) {
                index += store.bufferRange[0];
            }
        } else {
            // just to make sure, though this should not be
            // set if the record was availablein the selections
            delete this.pendingSelections[index];
        }

        if (this.last == index) {
            this.last = false;
        }

        if (this.lastActive == index) {
            this.lastActive = false;
        }

        this.selections.remove(record);

        if(!preventViewNotify){
            this.grid.getView().onRowDeselect(index);
        }

        this.fireEvent("rowdeselect", this, index, record);
        this.fireEvent("selectionchange", this);
    },

    /**
     * Deselects a row.
     * @param {Number} row The index of the row to deselect
     */
    deselectRow : function(index, preventViewNotify)
    {
        if(this.locked) return;
        if(this.last == index){
            this.last = false;
        }

        if(this.lastActive == index){
            this.lastActive = false;
        }
        var r = this.grid.store.getAt(index);

        delete this.pendingSelections[index];

        if (r) {
            this.selections.remove(r);
        }
        if(!preventViewNotify){
            this.grid.getView().onRowDeselect(index);
        }
        this.fireEvent("rowdeselect", this, index, r);
        this.fireEvent("selectionchange", this);
    },


    /**
     * Selects a row.
     * @param {Number} row The index of the row to select
     * @param {Boolean} keepExisting (optional) True to keep existing selections
     */
    selectRow : function(index, keepExisting, preventViewNotify)
    {
        if(//this.last === index
           //||
           this.locked
           || index < 0
           || index >= this.grid.store.getTotalCount()) {
            return;
        }

        var r = this.grid.store.getAt(index);

        if(this.fireEvent("beforerowselect", this, index, keepExisting, r) !== false){
            if(!keepExisting || this.singleSelect){
                this.clearSelections();
            }

            if (r) {
                this.selections.add(r);
                delete this.pendingSelections[index];
            } else {
                this.pendingSelections[index] = true;
            }

            this.last = this.lastActive = index;

            if(!preventViewNotify){
                this.grid.getView().onRowSelect(index);
            }

            this.fireEvent("rowselect", this, index, r);
            this.fireEvent("selectionchange", this);
        }
    },

    clearPendingSelections : function(startIndex, endIndex)
    {
        if (endIndex == undefined) {
            endIndex = Number.MAX_VALUE;
        }

        var newSelections = {};

        var ranges       = this.getPendingSelections();
        var rangesLength = ranges.length;

        var index = 0;

        for (var i = 0; i < rangesLength; i++) {
            index = ranges[i];
            if (index <= endIndex && index >= startIndex) {
                continue;
            }

            newSelections[index] = true;
        }

        this.pendingSelections = newSelections;
    },

    /**
     * Replaces already set data with new data from the store if those
     * records can be found within this.selections or this.pendingSelections
     *
     * @param {Array} An array with records buffered by the store
     */
    replaceSelections : function(records)
    {
        if (!records || records.length == 0) {
            return;
        }

        var ds  = this.grid.store;
        var rec = null;

        var assigned     = [];
        var ranges       = this.getPendingSelections();
        var rangesLength = ranges.length

        var selections = this.selections;
        var index      = 0;

        for (var i = 0; i < rangesLength; i++) {
            index = ranges[i];
            rec   = ds.getAt(index);
            if (rec) {
                selections.add(rec);
                assigned.push(rec.id);
                delete this.pendingSelections[index];
            }
        }

        var id  = null;
        for (i = 0, len = records.length; i < len; i++) {
            rec = records[i];
            id  = rec.id;
            if (assigned.indexOf(id) == -1 && selections.containsKey(id)) {
                selections.add(rec);
            }
        }

    },

    getPendingSelections : function(asRange)
    {
        var index         = 1;
        var ranges        = [];
        var currentRange  = 0;
        var tmpArray      = [];

        for (var i in this.pendingSelections) {
            tmpArray.push(parseInt(i));
        }

        tmpArray.sort(function(o1,o2){
            if (o1 > o2) {
                return 1;
            } else if (o1 < o2) {
                return -1;
            } else {
                return 0;
            }
        });

        if (!asRange) {
            return tmpArray;
        }

        var max_i = tmpArray.length;

        if (max_i == 0) {
            return [];
        }

        ranges[currentRange] = [tmpArray[0], tmpArray[0]];
        for (var i = 0, max_i = max_i-1; i < max_i; i++) {
            if (tmpArray[i+1] - tmpArray[i] == 1) {
                ranges[currentRange][1] = tmpArray[i+1];
            } else {
                currentRange++;
                ranges[currentRange] = [tmpArray[i+1], tmpArray[i+1]];
            }
        }

        return ranges;
    },

    /**
     * Clears all selections.
     */
    clearSelections : function(fast)
    {
        if(this.locked) return;
        if(fast !== true){
            var ds  = this.grid.store;
            var s   = this.selections;
            var ind = -1;
            s.each(function(r){
                ind = ds.indexOfId(r.id);
                if (ind != -1) {
                    this.deselectRow(ind+ds.bufferRange[0]);
                }
            }, this);
            s.clear();

            this.pendingSelections = {};

        }else{
            this.selections.clear();
            this.pendingSelections    = {};
        }
        this.last = false;
    },


    /**
     * Selects a range of rows. All rows in between startRow and endRow are also
     * selected.
     *
     * @param {Number} startRow The index of the first row in the range
     * @param {Number} endRow The index of the last row in the range
     * @param {Boolean} keepExisting (optional) True to retain existing selections
     */
    selectRange : function(startRow, endRow, keepExisting)
    {
        if(this.locked) {
            return;
        }

        if(!keepExisting) {
            this.clearSelections();
        }

        if (startRow <= endRow) {
            for(var i = startRow; i <= endRow; i++) {
                this.selectRow(i, true);
            }
        } else {
            for(var i = startRow; i >= endRow; i--) {
                this.selectRow(i, true);
            }
        }

    }

});


