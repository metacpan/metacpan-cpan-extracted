/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPLV3
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */

/**
 * An {@link qx.ui.table.model.Remote} implementation for accessing
 * accessing Messreihen on the server.
 */
qx.Class.define('callbackery.data.RemoteTableModel', {
    extend: qx.ui.table.model.Remote,
    include: [callbackery.locale.MTranslation],
    /**
     * Create an instance of Rpc.
     */
    construct: function(cfg, getParentFormData) {
        this.base(arguments);
        this._getParentFormData = getParentFormData;
        var that = this;
        var ids = [];
        var labels = [];
        var types = {};
        cfg.table.forEach(function(col) {
            ids.push(col.key);
            labels.push(that.xtr(col.label));
            types[col.key] = col.type;
        });
        this.setColumns(labels, ids);
        cfg.table.forEach(function(col, i) {
            this.setColumnSortable(i, col.sortable);
        }, this);
        this.__instanceName = cfg.name;
        this.__types = types;
        this.__ids = ids;
    },

    properties: {
        formData: {
            init: {}
        }
    },

    members: {
        _getParentFormData: null,
        __instanceName: null,
        __types: null,
        __ids: null,
        /**
         * Provid our implementation to make remote table work
         */
        _loadRowCount: function() {
            var that = this;
            var rpc = callbackery.data.Server.getInstance();
            var rpcArgs = {
                formData: this.getFormData()
            };

            if (this._getParentFormData) {
                rpcArgs.parentFormData = this._getParentFormData();
            }

            rpc.callAsyncSmart(function(ret) {
                that._onRowCountLoaded(ret);
            }, 'getPluginData', this.__instanceName, 'tableRowCount', rpcArgs);
        },

        /**
         * Provide our own implementation of the row data loader.
         *
         * @param firstRow {Integer} first row to load
         * @param lastRow {Integer} last row to load
         */
        _loadRowData: function(firstRow, lastRow) {
            var rpcArgs = {
                firstRow: firstRow,
                lastRow: lastRow,
                formData: this.getFormData()
            };

            if (!this.isSortAscending()) {
                rpcArgs.sortDesc = true;
            }

            var sc = this.getSortColumnIndex();

            if (sc >= 0) {
                rpcArgs.sortColumn = this.getColumnId(sc);
            }

            if (this._getParentFormData) {
                rpcArgs.parentFormData = this._getParentFormData();
            }

            var rpc = callbackery.data.Server.getInstance();
            var that = this;

            rpc.callAsyncSmart(function(data) {
                data.forEach(function(col) {
                    for (var id in col) {
                        switch (that.__types[id]){
                            case 'date':
                                col[id] = new Date(col[id]);
                                break;
                            case 'string':
                            case 'str':
                                col[id] = col[id] ? String(col[id]) : '';
                                break;
                            case 'number':
                            case 'num':
                                col[id] = parseFloat(col[id]);
                                break;
                        }
                    }
                });
                that._onRowDataLoaded(data);
            },
            'getPluginData', this.__instanceName, 'tableData', rpcArgs);
        }
    }
});
