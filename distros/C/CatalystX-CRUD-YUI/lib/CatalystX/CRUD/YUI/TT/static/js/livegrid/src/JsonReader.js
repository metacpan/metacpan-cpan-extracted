/**
 * Ext.ux.grid.livegrid.JsonReader
 * Copyright (c) 2007-2008, http://www.siteartwork.de
 *
 * Ext.ux.grid.livegrid.JsonReader is licensed under the terms of the
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
 * @class Ext.ux.grid.livegrid.JsonReader
 * @extends Ext.data.JsonReader
 * @constructor
 * @param {Object} config
 *
 * @author Thorsten Suckow-Homberg <ts@siteartwork.de>
 */
Ext.ux.grid.livegrid.JsonReader = function(meta, recordType){

    Ext.ux.grid.livegrid.JsonReader.superclass.constructor.call(this, meta, recordType);
};


Ext.extend(Ext.ux.grid.livegrid.JsonReader, Ext.data.JsonReader, {

    /**
     * @cfg {String} versionProperty Name of the property from which to retrieve the
     *                               version of the data repository this reader parses
     *                               the reponse from
     */



    /**
     * Create a data block containing Ext.data.Records from a JSON object.
     * @param {Object} o An object which contains an Array of row objects in the property specified
     * in the config as 'root, and optionally a property, specified in the config as 'totalProperty'
     * which contains the total size of the dataset.
     * @return {Object} data A data block which is used by an Ext.data.Store object as
     * a cache of Ext.data.Records.
     */
    readRecords : function(o)
    {
        var s = this.meta;

        if(!this.ef && s.versionProperty) {
            this.getVersion = this.getJsonAccessor(s.versionProperty);
        }

        // shorten for future calls
        if (!this.__readRecords) {
            this.__readRecords = Ext.ux.grid.livegrid.JsonReader.superclass.readRecords;
        }

        var intercept = this.__readRecords.call(this, o);


        if (s.versionProperty) {
            var v = this.getVersion(o);
            intercept.version = (v === undefined || v === "") ? null : v;
        }


        return intercept;
    }

});