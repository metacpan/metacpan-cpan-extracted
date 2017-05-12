GvaScript.Paginator = Class.create();

Object.extend(GvaScript.Paginator.prototype, function() {
    var bcss = CSSPREFIX();
    var paginator_css = bcss + '-paginatorbar';
    var pagination_buttons = "<div class='last' title='Dernière page'></div>"
             + "<div class='forward' title='Page suivante'></div>"
             + "<div class='text'></div>"
             + "<div class='back' title='Page précédente'></div>"
             + "<div class='first' title='Première page'></div>";


    function _toggleNavigatorsVisibility() {
        if(this.hasPrevious()) {
            this.back.removeClassName('inactive');
            this.first.removeClassName('inactive');
        }
        else {
            this.back.addClassName('inactive');
            this.first.addClassName('inactive');
        }
        if(this.hasNext()) {
            this.forward.removeClassName('inactive');
            this.last.removeClassName('inactive');
        }
        else {
            this.forward.addClassName('inactive');
            this.last.addClassName('inactive');
        }
        this.links_container.show();
    }
    /* Create pagination controls and append them to the placeholder 'PG:frame' */
    function _addPaginationElts() {
        // append the pagination buttons
        this.links_container.insert(pagination_buttons);

        this.first    = this.links_container.down('.first');
        this.last     = this.links_container.down('.last');
        this.forward  = this.links_container.down('.forward');
        this.back     = this.links_container.down('.back');
        this.textElem = this.links_container.down('.text');

        this.first.observe  ('click', this.getFirstPage.bind(this));
        this.last.observe   ('click', this.getLastPage.bind(this));
        this.back.observe   ('click', this.getPrevPage.bind(this));
        this.forward.observe('click', this.getNextPage.bind(this));
    }

    return {
        destroy: function() {
            this.first.stopObserving();
            this.last.stopObserving();
            this.back.stopObserving();
            this.forward.stopObserving();
        },
        initialize: function(url, options) {

            var defaults = {
                reset                : 'no',    // if yes, first call sends RESET=yes,
                                                // subsequent calls don't (useful for
                                                // resetting cache upon first request)
                step                 : 20,

                method               : 'post',  // POST so we get dispatched to *_PROCESS_FORM
                parameters           : $H({}),
                onSuccess            : Prototype.emptyFunction,

                lazy                 : false,   // false: load first page with Paginator initialization
                                                // true: donot load automatically, loadContent would
                                                // have to be called explicity
                timeoutAjax          : 15,
                errorMsg             : "Problème de connexion. Réessayer et si le problème persiste, contacter un administrateur."
            };
            this.options = Object.extend(defaults, options || {});
            this.options.errorMsg = "<h3 style='color: #183E6C'>" + this.options.errorMsg + "</h3>";

            this.links_container = $(this.options.links_container);
            this.list_container  = $(this.options.list_container);
            this.url             = url;

            // initialization of flags
            this.index         = 1;
            this.end_index     = 0;
            this.total         = 0;

            this._executing    = false; // loadContent one at a time

            // set the css for the paginator container
            this.links_container.addClassName(paginator_css);
            // and hide it
            this.links_container.hide();
            // add the pagination elements (next/prev links + text)
            _addPaginationElts.apply(this);

            this.links_container.addClassName(bcss+'-widget');
            this.links_container.store('widget', this);

            // load content by XHR
            if(!this.options.lazy) this.loadContent();
        },

        hasPrevious: function() {
            return this.index != 1;
        },

        hasNext: function() {
            return this.end_index != this.total;
        },

        /* Get the next set of index to 1records from the current url */
        getNextPage: function(btn) {
            if(this._executing == false && this.hasNext()) {
                this.index += this.options.step;
                this.loadContent();
                return true;
            }
            else
            return false;
        },

        /* Get the prev set of records from the current url */
        getPrevPage: function() {
            if(this._executing == false && this.hasPrevious()) {
                this.index -= this.options.step;
                this.loadContent();
                return true;
            }
            else
            return false;
        },

        getLastPage: function() {
            if(this._executing == false && this.hasNext()) {
                this.index = Math.floor(this.total/this.options.step)*this.options.step+1;
                this.loadContent();
                return true;
            }
            else
            return false;
        },

        getFirstPage: function() {
            if(this._executing == false && this.hasPrevious()) {
                this.index = 1;
                this.loadContent();
                return true;
            }
            else
            return false;
        },

        // Core function of the pagination object.
        // Get records from url that are in the specified range
        loadContent: function() {
            if(this._executing == true) return; // still handling a previous request
            else this._executing = true;

            // Add STEP and INDEX as url parameters
            var url = this.url;
            this.options.parameters.update({
                STEP: this.options.step,
                INDEX: this.index,
                RESET: this.options.reset
            });

            this.links_container.hide(); // hide 'em. (one click at a time)
            this.list_container.update(new Element('div', {'class': bcss+'-loading'}));

            new Ajax.Request(url, {
                evalJSON: 'force',  // force evaluation of response into responseJSON
                method: this.options.method,
                parameters: this.options.parameters,
                requestTimeout: this.options.timeoutAjax * 1000,
                onTimeout: function(req) {
                    this._executing = false;
                    this.list_container.update(this.options.errorMsg);
                }.bind(this),
                // on s'attend à avoir du JSON en retour
                onFailure: function(req) {
                    this._executing = false;
                    var answer = req.responseJSON;
                    var msg = answer.error.message || this.options.errorMsg;
                    this.list_container.update(msg);
                }.bind(this),
                onSuccess: function(req) {
                    this._executing = false;

                    var answer = req.responseJSON;
                    if(answer) {
                        var nb_displayed_records = this.options.onSuccess(answer);
                        this.total     = answer.total; // total number of records

                        this.end_index = Math.min(this.total, this.index+nb_displayed_records-1); // end index of records on current page

                        this.textElem.innerHTML = (this.total > 0)?
                            this.index + " &agrave; " + this.end_index + " de " + this.total: '0';
                        _toggleNavigatorsVisibility.apply(this);
                    }
                 }.bind(this)
            });
        }
    }
}());
