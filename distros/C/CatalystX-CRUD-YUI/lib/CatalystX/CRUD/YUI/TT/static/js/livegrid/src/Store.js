/**
 * Ext.ux.grid.livegrid.Store
 * Copyright (c) 2007-2008, http://www.siteartwork.de
 *
 * Ext.ux.grid.livegrid.Store is licensed under the terms of the
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
 * @class Ext.ux.grid.livegrid.Store
 * @extends Ext.data.Store
 *
 * The BufferedGridSore is a special implementation of a Ext.data.Store. It is used
 * for loading chunks of data from the underlying data repository as requested
 * by the Ext.ux.BufferedGridView. It's size is limited to the config parameter
 * bufferSize and is thereby guaranteed to never hold more than this amount
 * of records in the store.
 *
 * Requesting selection ranges:
 * ----------------------------
 * This store implementation has 2 Http-proxies: A data proxy for requesting data
 * from the server for displaying and another proxy to request pending selections:
 * Pending selections are represented by row indexes which have been selected but
 * which records have not yet been available in the store. The loadSelections method
 * will initiate a request to the data repository (same url as specified in the
 * url config parameter for the store) to fetch the pending selections. The additional
 * parameter send to the server is the "ranges" parameter, which will hold a json
 * encoded string representing ranges of row indexes to load from the data repository.
 * As an example, pending selections with the indexes 1,2,3,4,5,9,10,11,16 would
 * have to be translated to [1,5],[9,11],[16].
 * Please note, that by indexes we do not understand (primary) keys of the data,
 * but indexes as represented by the view. To get the ranges of pending selections,
 * you can use the getPendingSelections method of the BufferedRowSelectionModel, which
 * should be used as the default selection model of the grid.
 *
 * Version-property:
 * -----------------
 * This implementation does also introduce a new member called "version". The version
 * property will help you in determining if any pending selections indexes are still
 * valid or may have changed. This is needed to reduce the danger of data inconsitence
 * when you are requesting data from the server: As an example, a range of indexes must
 * be read from the server but may have been become invalid when the row represented
 * by the index is no longer available in teh underlying data store, caused by a
 * delete or insert operation. Thus, you have to take care of the version property
 * by yourself (server side) and change this value whenever a row was deleted or
 * inserted. You can specify the path to the version property in the BufferedJsonReader,
 * which should be used as the default reader for this store. If the store recognizes
 * a version change, it will fire the versionchange event. It is up to the user
 * to remove all selections which are pending, or use them anyway.
 *
 * Inserting data:
 * ---------------
 * Another thing to notice is the way a user inserts records into the data store.
 * A user should always provide a sortInfo for the grid, so the findInsertIndex
 * method can return a value that comes close to the value as it would have been
 * computed by the underlying store's sort algorithm. Whenever a record should be
 * added to the store, the insert index should be calculated and the used as the
 * parameter for the insert method. The findInsertIndex method will return a value
 * that equals to Number.MIN_VALUE or Number.MAX_VALUE if the added record would not
 * change the current state of the store. If that happens, this data is not available
 * in the store, and may be requested later on when a new request for new data is made.
 *
 * Sorting:
 * --------
 * remoteSort will always be set to true, no matter what value the user provides
 * using the config object.
 *
 * @constructor
 * Creates a new Store.
 * @param {Object} config A config object containing the objects needed for the Store to access data,
 * and read the data into Records.
 *
 * @author Thorsten Suckow-Homberg <ts@siteartwork.de>
 */
Ext.ux.grid.livegrid.Store = function(config) {

    config = config || {};

    // remoteSort will always be set to true.
    config.remoteSort = true;

    // we will intercept the autoLoad property and set it to false so we do not
    // load any contents of the store before the View has not fully initialized
    // itself. if autoLoad was set to true, the Ext.ux.grid.livegrid.GridPanel
    // will take care of loading the store once it has been rendered
    this._autoLoad  = config.autoLoad ? true : false;
    config.autoLoad = false;

    this.addEvents(
         /**
          * @event bulkremove
          * Fires when a bulk remove operation was finished.
          * @param {Ext.ux.BufferedGridStore} this
          * @param {Array} An array with the records that have been removed.
          * The values for each array index are
          * record - the record that was removed
          * index - the index of the removed record in the store
          */
        'bulkremove',
         /**
          * @event versionchange
          * Fires when the version property has changed.
          * @param {Ext.ux.BufferedGridStore} this
          * @param {String} oldValue
          * @param {String} newValue
          */
        'versionchange',
         /**
          * @event beforeselectionsload
          * Fires before the store sends a request for ranges of records to
          * the server.
          * @param {Ext.ux.BufferedGridStore} this
          * @param {Array} ranges
          */
        'beforeselectionsload',
         /**
          * @event selectionsload
          * Fires when selections have been loaded.
          * @param {Ext.ux.BufferedGridStore} this
          * @param {Array} records An array containing the loaded records from
          * the server.
          * @param {Array} ranges An array containing the ranges of indexes this
          * records may represent.
          */
        'selectionsload'
    );

    Ext.ux.grid.livegrid.Store.superclass.constructor.call(this, config);

    this.totalLength = 0;


    /**
     * The array represents the range of rows available in the buffer absolute to
     * the indexes of the data model. Initialized with  [-1, -1] which tells that no
     * records are currrently buffered
     * @param {Array}
     */
    this.bufferRange = [-1, -1];

    this.on('clear', function (){
        this.bufferRange = [-1, -1];
    }, this);

    if(this.url && !this.selectionsProxy){
        this.selectionsProxy = new Ext.data.HttpProxy({url: this.url});
    }

};

Ext.extend(Ext.ux.grid.livegrid.Store, Ext.data.Store, {

    /**
     * The version of the data in the store. This value is represented by the
     * versionProperty-property of the BufferedJsonReader.
     * @property
     */
    version : null,

    /**
     * Inserts a record at the position as specified in index.
     * If the index equals to Number.MIN_VALUE or Number.MAX_VALUE, the record will
     * not be added to the store, but still fire the add-event to indicate that
     * the set of data in the underlying store has been changed.
     * If the index equals to 0 and the length of data in the store equals to
     * bufferSize, the add-event will be triggered with Number.MIN_VALUE to
     * indicate that a record has been prepended. If the index equals to
     * bufferSize, the method will assume that the record has been appended and
     * trigger the add event with index set to Number.MAX_VALUE.
     *
     * Note:
     * -----
     * The index parameter is not a view index, but a value in the range of
     * [0, this.bufferSize].
     *
     * You are strongly advised to not use this method directly. Instead, call
     * findInsertIndex wirst and use the return-value as the first parameter for
     * for this method.
     */
    insert : function(index, records)
    {
        // hooray for haskell!
        records = [].concat(records);

        index = index >= this.bufferSize ? Number.MAX_VALUE : index;

        if (index == Number.MIN_VALUE || index == Number.MAX_VALUE) {
            var l = records.length;
            if (index == Number.MIN_VALUE) {
                this.bufferRange[0] += l;
                this.bufferRange[1] += l;
            }

            this.totalLength += l;
            this.fireEvent("add", this, records, index);
            return;
        }

        var split = false;
        var insertRecords = records;
        if (records.length + index >= this.bufferSize) {
            split = true;
            insertRecords = records.splice(0, this.bufferSize-index)
        }
        this.totalLength += insertRecords.length;

        // if the store was loaded without data and the bufferRange
        // has to be filled first
        if (this.bufferRange[0] <= -1) {
            this.bufferRange[0] = 0;
        }
        if (this.bufferRange[1] < (this.bufferSize-1)) {
            this.bufferRange[1] = Math.min(this.bufferRange[1] + insertRecords.length, this.bufferSize-1);
        }

        for (var i = 0, len = insertRecords.length; i < len; i++) {
            this.data.insert(index, insertRecords[i]);
            insertRecords[i].join(this);
        }

        while (this.getCount() > this.bufferSize) {
            this.data.remove(this.data.last());
        }

        this.fireEvent("add", this, insertRecords, index);

        if (split == true) {
            this.fireEvent("add", this, records, Number.MAX_VALUE);
        }
    },

    /**
     * Remove a Record from the Store and fires the remove event.
     *
     * This implementation will check for the appearance of the record id
     * in the store. The record to be removed does not neccesarily be bound
     * to the instance of this store.
     * If the record is not within the store, the method will try to guess it's
     * index by calling findInsertIndex.
     *
     * Please note that this method assumes that the records that's about to
     * be removed from the store does belong to the data within the store or the
     * underlying data store, thus the remove event will always be fired.
     * This may lead to inconsitency if you have to stores up at once. Let A
     * be the store that reads from the data repository C, and B the other store
     * that only represents a subset of data of the data repository C. If you
     * now remove a record X from A, which has not been in the store, but is assumed
     * to be available in the data repository, and would like to sync the available
     * data of B, then you have to check first if X may have apperead in the subset
     * of data C represented by B before calling remove from the B store (because
     * the remove operation will always trigger the "remove" event, no matter what).
     * (Common use case: you have selected a range of records which are then stored in
     * the row selection model. User scrolls through the data and the store's buffer
     * gets refreshed with new data for displaying. Now you want to remove all records
     * which are within the rowselection model, but not anymore within the store.)
     * One possible workaround is to only remove the record X from B if, and only
     * if the return value of a call to [object instance of store B].data.indexOf(X)
     * does not return a value less than 0. Though not removing the record from
     * B may not update the view of an attached BufferedGridView immediately.
     *
     * @param {Ext.data.Record} record
     * @param {Boolean} suspendEvent true to suspend the "remove"-event
     *
     * @return Number the index of the record removed.
     */
    remove : function(record, suspendEvent)
    {
        // check wether the record.id can be found in this store
        var index = this._getIndex(record);

        if (index < 0) {
            this.totalLength -= 1;
            if(this.pruneModifiedRecords){
                this.modified.remove(record);
            }
            // adjust the buffer range if a record was removed
            // in the range that is actually behind the bufferRange
            this.bufferRange[0] = Math.max(-1, this.bufferRange[0]-1);
            this.bufferRange[1] = Math.max(-1, this.bufferRange[1]-1);

            if (suspendEvent !== true) {
                this.fireEvent("remove", this, record, index);
            }
            return index;
        }

        this.bufferRange[1] = Math.max(-1, this.bufferRange[1]-1);
        this.data.removeAt(index);

        if(this.pruneModifiedRecords){
            this.modified.remove(record);
        }

        this.totalLength -= 1;
        if (suspendEvent !== true) {
            this.fireEvent("remove", this, record, index);
        }

        return index;
    },

    _getIndex : function(record)
    {
        var index = this.indexOfId(record.id);

        if (index < 0) {
            index = this.findInsertIndex(record);
        }

        return index;
    },

    /**
     * Removes a larger amount of records from the store and fires the "bulkremove"
     * event.
     * This helps listeners to determine whether the remove operation of multiple
     * records is still pending.
     *
     * @param {Array} records
     */
    bulkRemove : function(records)
    {
        var rec  = null;
        var recs = [];
        var ind  = 0;
        var len  = records.length;

        var orgIndexes = [];
        for (var i = 0; i < len; i++) {
            rec = records[i];

            orgIndexes[rec.id] = this._getIndex(rec);
        }

        for (var i = 0; i < len; i++) {
            rec = records[i];
            this.remove(rec, true);
            recs.push([rec, orgIndexes[rec.id]]);
        }

        this.fireEvent("bulkremove", this, recs);
    },

    /**
     * Remove all Records from the Store and fires the clear event.
     * The method assumes that there will be no data available anymore in the
     * underlying data store.
     */
    removeAll : function()
    {
        this.totalLength = 0;
        this.bufferRange = [-1, -1];
        this.data.clear();

        if(this.pruneModifiedRecords){
            this.modified = [];
        }
        this.fireEvent("clear", this);
    },

    /**
     * Requests a range of data from the underlying data store. Similiar to the
     * start and limit parameter usually send to the server, the method needs
     * an array of ranges of indexes.
     * Example: To load all records at the positions 1,2,3,4,9,12,13,14, the supplied
     * parameter should equal to [[1,4],[9],[12,14]].
     * The request will only be done if the beforeselectionsloaded events return
     * value does not equal to false.
     */
    loadRanges : function(ranges)
    {
        var max_i = ranges.length;

        if(max_i > 0 && !this.selectionsProxy.activeRequest
           && this.fireEvent("beforeselectionsload", this, ranges) !== false){

            var lParams = this.lastOptions.params;

            var params = {};
            params.ranges = Ext.encode(ranges);

            if (lParams) {
                if (lParams.sort) {
                    params.sort = lParams.sort;
                }
                if (lParams.dir) {
                    params.dir = lParams.dir;
                }
            }

            var options = {};
            for (var i in this.lastOptions) {
                options.i = this.lastOptions.i;
            }

            options.ranges = params.ranges;

            this.selectionsProxy.load(params, this.reader,
                            this.selectionsLoaded, this,
                            options);
        }
    },

    /**
     * Alias for loadRanges.
     */
    loadSelections : function(ranges)
    {
        if (ranges.length == 0) {
            return;
        }
        this.loadRanges(ranges);
    },

    /**
     * Called as a callback by the proxy which loads pending selections.
     * Will fire the selectionsload event with the loaded records if, and only
     * if the return value of the checkVersionChange event does not equal to
     * false.
     */
    selectionsLoaded : function(o, options, success)
    {
        if (this.checkVersionChange(o, options, success) !== false) {

            var r = o.records;
            for(var i = 0, len = r.length; i < len; i++){
                r[i].join(this);
            }

            this.fireEvent("selectionsload", this, o.records, Ext.decode(options.ranges));
        } else {
            this.fireEvent("selectionsload", this, [], Ext.decode(options.ranges));
        }
    },

    /**
     * Checks if the version supplied in <tt>o</tt> differs from the version
     * property of the current instance of this object and fires the versionchange
     * event if it does.
     */
    // private
    checkVersionChange : function(o, options, success)
    {
        if(o && success !== false){
            if (o.version !== undefined) {
                var old      = this.version;
                this.version = o.version;
                if (this.version !== old) {
                    return this.fireEvent('versionchange', this, old, this.version);
                }
            }
        }
    },

    /**
     * The sort procedure tries to respect the current data in the buffer. If the
     * found index would not be within the bufferRange, Number.MIN_VALUE is returned to
     * indicate that the record would be sorted below the first record in the buffer
     * range, while Number.MAX_VALUE would indicate that the record would be added after
     * the last record in the buffer range.
     *
     * The method is not guaranteed to return the relative index of the record
     * in the data model as returned by the underlying domain model.
     */
    findInsertIndex : function(record)
    {
        this.remoteSort = false;
        var index = Ext.ux.grid.livegrid.Store.superclass.findInsertIndex.call(this, record);
        this.remoteSort = true;

        // special case... index is 0 and we are at the very first record
        // buffered
        if (this.bufferRange[0] <= 0 && index == 0) {
            return index;
        } else if (this.bufferRange[0] > 0 && index == 0) {
            return Number.MIN_VALUE;
        } else if (index >= this.bufferSize) {
            return Number.MAX_VALUE;
        }

        return index;
    },

    /**
     * Removed snapshot check
     */
    // private
    sortData : function(f, direction)
    {
        direction = direction || 'ASC';
        var st = this.fields.get(f).sortType;
        var fn = function(r1, r2){
            var v1 = st(r1.data[f]), v2 = st(r2.data[f]);
            return v1 > v2 ? 1 : (v1 < v2 ? -1 : 0);
        };
        this.data.sort(direction, fn);
    },



    /**
     * @cfg {Number} bufferSize The number of records that will at least always
     * be available in the store for rendering. This value will be send to the
     * server as the <tt>limit</tt> parameter and should not change during the
     * lifetime of a grid component. Note: In a paging grid, this number would
     * indicate the page size.
     * The value should be set high enough to make a userfirendly scrolling
     * possible and should be greater than the sum of {nearLimit} and
     * {visibleRows}. Usually, a value in between 150 and 200 is good enough.
     * A lesser value will more often make the store re-request new data, while
     * a larger number will make loading times higher.
     */


    // private
    onMetaChange : function(meta, rtype, o)
    {
        this.version = null;
        Ext.ux.grid.livegrid.Store.superclass.onMetaChange.call(this, meta, rtype, o);
    },


    /**
     * Will fire the versionchange event if the version of incoming data has changed.
     */
    // private
    loadRecords : function(o, options, success)
    {
        this.checkVersionChange(o, options, success);

        // we have to stay in sync with rows that may have been skipped while
        // the request was loading.
        // if the response didn't make it through, set buffer range to -1,-1
        if (!o) {
            this.bufferRange = [-1,-1];
        } else {
            this.bufferRange = [
                options.params.start,
                Math.max(0, Math.min((options.params.start+options.params.limit)-1, o.totalRecords-1))
            ];
        }

        Ext.ux.grid.livegrid.Store.superclass.loadRecords.call(this, o, options, success);
    },

    /**
     * Get the Record at the specified index.
     * The function will take the bufferRange into account and translate the passed argument
     * to the index of the record in the current buffer.
     *
     * @param {Number} index The index of the Record to find.
     * @return {Ext.data.Record} The Record at the passed index. Returns undefined if not found.
     */
    getAt : function(index)
    {
        //anything buffered yet?
        if (this.bufferRange[0] == -1) {
            return undefined;
        }

        var modelIndex = index - this.bufferRange[0];
        return this.data.itemAt(modelIndex);
    },

//--------------------------------------EMPTY-----------------------------------
    // no interface concept, so simply overwrite and leave them empty as for now
    clearFilter : function(){},
    isFiltered : function(){},
    collect : function(){},
    createFilterFn : function(){},
    sum : function(){},
    filter : function(){},
    filterBy : function(){},
    query : function(){},
    queryBy : function(){},
    find : function(){},
    findBy : function(){}

});