// depends: custom-buttons.js
//          paginator.js
//          choiceList.js
GvaScript.Grid = Class.create();

Object.extend(GvaScript.Grid.prototype, function() {
    var bcss = CSSPREFIX();
    function _compileDTO(dto) {
        switch(typeof dto) {
            case 'object': return $H(dto).update({VUE: 'JSON'});
            case 'string': return $H(dto.toQueryParams()).update({VUE: 'JSON'});
            default: return {VUE: 'JSON'};
        }
    }
    function _compileCss(column) {
        switch (typeof column.css) {
            case 'object': return ' '+column.css.join(' ');
            case 'string': return ' '+column.css;
            default: return '';
        }
    }
    function _compileWidth(column) {
        switch (typeof column.width) {
        case 'number': return ' style="width: '+column.width+'px"';
            case 'string':
                if(isNaN(column.width)) return ' style="width: '+column.width+'"';
                else                    return ' style="width: '+column.width+'px"';
            default: return '';
        }
    }
    function _compileTitle(column) {
        switch (typeof column.title) {
            case 'string': return 'title= '+'"'+column.title+'"';
            default: return '';
        }
    }        
    function _evalCondition(column, grid) {
        if(typeof column.condition == 'undefined') return true;
        else
        if(typeof column.condition == 'function')  return column.condition(grid);
        else
        if(eval(column.condition))                 return true;
        else                                       return false;
    }
    function _getColumnValue(column, elt) {
        switch(typeof column.value) {
            case 'function' : if(val = column.value(elt)) return val; else return (column.default_value || '');
            case 'string'   : if(val = elt[column.value]) return val; else return (column.default_value || '');
            default: return '';
        }
    }

    return {
        destroy: function() {
            // do not destroy if not initialized !
            if(GvaScript.Grids.unregister(this.id)) {
                if(this.choiceList)    this.choiceList.destroy();
                if(this.actionButtons) this.actionButtons.destroy();
            }
        },
        initialize: function(id, datasource, options) {
            var defaults = {
                css            : '',
                dto            : {},
                columns        : [],
                actions        : [],
                grabfocus      : true,
                pagesize       : 'auto',  // fill available grid height
                gridheight     : 'auto',  // available space
                recordheight   : 21,      // default record height in pixels
                requestTimeout : 15,
                method         : 'post',  // default XHR method
                errorMsg       : "Problème de connexion. Réessayer et si le problème persiste, contacter un administrateur.",
                onShow         : Prototype.emptyFunction,
                onPing         : Prototype.emptyFunction,
                onEmpty        : Prototype.emptyFunction,
                onCancel       : Prototype.emptyFunction
            }

            this.options = Object.extend(defaults, options || {});

            this.id                =  id;
            this.grid_container    = $(this.options.grid_container);
            this.toolbar_container = $(this.options.toolbar_container);
            this.columns           = this.options.columns;
            this.datasource        = datasource;
            // determine pagesize to send to paginator
            // size is preset
            if(typeof this.options.pagesize == 'number') {
                this.limit = this.options.pagesize;
            }
            // determine dynamically
            else {
                // set the height of the grid_container
                // height is preset
                if(typeof this.options.gridheight == 'number') {
                    this.grid_container.setStyle({height: this.options.gridheight+'px'});
                }
                // determine dynamically
                else {
                    var parentHeight = this.grid_container.up(0).getHeight();
                    var sibsHeights  = this.grid_container.siblings().collect(function(s) {return s.getHeight()});

                    var sibsHeight   = 0;
                    sibsHeights.each(function(h) {sibsHeight += h});
                    this.grid_container.setStyle({height: parentHeight-sibsHeight+'px'});
                }

                this.limit = Math.floor((this.grid_container.getHeight()-22)/this.options.recordheight);
            }

            this.grid_container.setStyle({width: this.grid_container.up(0).getWidth()+'px'});

            this.toolbar_container.addClassName(bcss+'-grid-toolbar');
            this.toolbar_container.update();

            this.paginatorbar_container = new Element('div', {'class': bcss+'-paginatorbar'});
            this.actionsbar_container   = new Element('div', {'class': bcss+'-grid-actionsbar'});
            this.toolbar_container.insert(this.paginatorbar_container);
            this.toolbar_container.insert(this.actionsbar_container);

            this.dto = _compileDTO(this.options.dto);
            this.paginator = new GvaScript.Paginator(
                this.datasource, {
                    list_container  : this.grid_container,
                    links_container : this.paginatorbar_container,

                    method      : this.options.method,
                    onSuccess   : this.receiveRequest.bind(this),
                    parameters  : this.dto,
                    step        : this.limit,
                    timeoutAjax : this.options.requestTimeout,
                    errorMsg    : this.options.errorMsg,
                    lazy        : true
                }
            );

            if(! (recycled = this.grid_container.choiceList) ) {
                this.choiceList = new GvaScript.ChoiceList([], {
                    paginator         : this.paginator,
                    mouseovernavi     : false,
                    classes           : {'choiceHighlight': "hilite"},
                    choiceItemTagName : "tr",
                    grabfocus         : false,
                    htmlWrapper       : this.gridWrapper.bind(this)

                });
                this.choiceList_initialized = false;
            }
            // recycle the previously created choiceList
            else {
                this.choiceList = recycled;
                this.choiceList.options.htmlWrapper = this.gridWrapper.bind(this);
                this.choiceList.options.paginator = this.paginator;
                this.choiceList_initialized = true;
            }

           this.choiceList.onCancel = this.options.onCancel;
           this.choiceList.onPing   = this.pingWrapper.bind(this);

           this.paginator.loadContent();

           this.grid_container.addClassName(bcss+'-widget');
           this.grid_container.store('widget', this);

           GvaScript.Grids.register(this);
        },

        getId: function() {
            return this.id;
        },

        clearResult: function(msg) {
            this.grid_container.update(msg || '');
        },

        clearToolbar: function() {
            this.toolbar_container.update('');
        },

        clearActionButtons: function() {
            this.actionsbar_container.update('');
        },

        clear: function(msg) {
            this.clearResult(msg);
            this.clearToolbar();
        },

        pingWrapper: function(event) {
            this.options.onPing(this.records[event.index]);
        },

        addActionButtons: function() {
            // first clear the actionbuttons container
            this.clearActionButtons();

            // append the action buttons
            var actions = this.options.actions.each(function(action_props, index) {
                // evaluation button condition in the 'this' context
                prop_condition = action_props.condition;
                switch(typeof prop_condition) {
                    case 'undefined' : action_props.condition = true; break;
                    case 'function'  : action_props.condition = prop_condition(this); break;
                    default          : action_props.condition = eval(prop_condition); break;
                }
                action_props.id = action_props.id || this.getId() + "_btn_" + index;

                // renders a <button> element and appends it to container
                new GvaScript.CustomButtons.Button(this.actionsbar_container, action_props);
            }, this);

            // activate the navigation over the action buttons
            this.actionButtons = new GvaScript.CustomButtons.ButtonNavigation(this.actionsbar_container, {
                selectFirstBtn: false,
                className: bcss+'-btn-container'
            });
        },

        // wrapping the recordset in a table with column headers
        gridWrapper: function(html) {
           return '<table class="'+bcss+'-grid '+this.options.css+'">' +
                    '<thead><tr>' +
                        '<th class="grid-marker">&nbsp;</th>' +
                        (this.columns.collect(function(e) {
                            if(_evalCondition(e, this))
                            return '<th class="grid-header'+_compileCss(e)+'"'+_compileWidth(e)+_compileTitle(e)+'>'+e.label+'</th>'
                            else return '';
                        }, this).join('')) +
                    '</tr></thead>' +
                    '<tbody>'+html+'</tbody>'+
                '</table>';
        },

        // called by the paginator
        receiveRequest: function(response_json) {
            this.records = response_json.liste;
            this.total   = response_json.total;
            this.rights  = response_json.rights || {can_create: 1};

            var list_records = $A(this.records).collect(function(e, index) {
                        return  '<td class="grid-marker">&nbsp;</td>' +
                                this.columns.collect(function(c) {
                                    if(_evalCondition(c, this))
                                    return  '<td class="grid-cell index_'+(index%2)+_compileCss(c)+'" valign="top">' +
                                            _getColumnValue(c, e) +
                                            '</td>';
                                    else return '';
                                }, this).join('');
            }, this);

            // TODO not elegant !
            if(this.choiceList_initialized) {
                this.choiceList.updateContainer(this.grid_container, list_records);
            }
            else {
                this.choiceList.choices = list_records;
                this.choiceList.fillContainer(this.grid_container);
                this.choiceList_initialized = true;
            }

            if(this.options.grabfocus) {
                try {this.grid_container.focus();}
                catch(e) {}
            }

            if(typeof this.actionButtons == 'undefined')
                this.addActionButtons();

            if(!(this.total > 0)) this.options.onEmpty.apply(this);

            (this.options.onShow || Prototype.emptyFunction).call();

            return this.records.length;
        }
    }
}());

// registers all grids
GvaScript.Grids = {
    grids: $A(),

    register: function(grid) {
        this.unregister(grid);
        this.grids.push(grid);
    },

    unregister: function(grid) {
        // nothing to unregister
        if(!grid) return;

        if(typeof grid == 'string') grid = this.get(grid);

        // nothing to unregister
        if(!grid) return false;

        // remove the reference from array
        this.grids = this.grids.reject(function(g) { return g.getId() == grid.getId() });

        return true;
    },

    get: function(id) {
        return this.grids.find(function(g) {return g.getId() == id});
    }
}
