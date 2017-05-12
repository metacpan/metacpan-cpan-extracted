"use strict";

// Javascript library specific to timeline view


bb.StatusContainer = (function() { var selfclass = $.extend(function(args) {
    // @params: args.selectorContainer, args.timeline, args.apiBase = ""
    var self = this;
    var now_toggling_extension = false;
    if(!defined(args.selectorContainer)) {
        throw "selectorContainer param is mandatory";
    }
    if(!defined(args.timeline)) {
        throw "timeline param is mandatory";
    }
    self.sel_container = args.selectorContainer;
    self.timeline = args.timeline;
    self.api_base = defined(args.apiBase) ? args.apiBase : "";
    self.threshold_level = 0;
    self.$cursor = null;
    self.on_threshold_level_changed_callbacks = [];
    
    $(self.sel_container).on("click", ".bb-status", function() {
        self.setCursor(this);
    });
    $(self.sel_container).on("click", ".bb-status-extension-toggler", function(event) {
        if(!now_toggling_extension && $(event.target).closest("a").size() === 0) {
            now_toggling_extension = true;
            self.toggleExtensionPane(this).fin(function() {
                now_toggling_extension = false;
            });
        }
    });
}, {
    ADD_STATUSES_BLOCK_SIZE: 100,
    ANIMATE_STATUS_MAX_NUM: 15,
    ANIMATE_STATUS_DURATION: 400,
    LOAD_STATUS_TRY_MAX: 3,
    LOAD_UNACKED_STATUSES_COUNT_PER_PAGE: 100,
    LOAD_UNACKED_STATUSES_MAX_PAGE_NUM: 6,
    ACK_TRY_MAX: 3,
    LOAD_MORE_STATUSES_COUNT: 20,
    _getStatusID: function($status) {
        return $status.find(".bb-status-id").text();
    },
    _formatHiddenStatusesHeader : function (invisible_num) {
        var plural = invisible_num > 1 ? "es" : "";
        return '<li class="bb-hidden-statuses-header"><span class="bb-hidden-statuses-num">'+ invisible_num +'</span> status'+plural+' hidden here.</li>';
    },
    _updateHiddenStatusesHeaders: function($statuses, hidden_header_list, window_adjuster) {
        if(!defined(window_adjuster)) window_adjuster = function() {};
        $statuses.filter(".bb-hidden-statuses-header").remove();
        window_adjuster();
        return bb.blockEach(hidden_header_list, 40, function(header_block) {
            $.each(header_block, function(i, header_entry) {
                if(defined(header_entry.$followed_by)) {
                    header_entry.$followed_by.before(selfclass._formatHiddenStatusesHeader(header_entry.entries.length));
                }else {
                    $statuses.filter('.bb-status').last().after(selfclass._formatHiddenStatusesHeader(header_entry.entries.length));
                }
            });
            window_adjuster();
        });
    },
    _createWindowAdjuster: function(anchor_position_func) {
        if(!anchor_position_func) {
            return function() {};
        }
        var relative_position_of_anchor;
        relative_position_of_anchor = anchor_position_func() - $(window).scrollTop();
        return function() {
            $(window).scrollTop(anchor_position_func() - relative_position_of_anchor);
        };
    },
    _scanStatusesForDisplayActions: function($statuses, threshold_level, enable_animation, cursor_index) {
        var ACTION_STAY_VISIBLE = 0;
        var ACTION_STAY_INVISIBLE = 1;
        var ACTION_BECOME_VISIBLE = 2;
        var ACTION_BECOME_INVISIBLE = 3;
        var final_result = { // ** return this struct from the promise
            hiddenHeaderList: [],
            domsAnimateToggle: [],
            domsImmediateToggle: [],
            domAnchorElem: null
        };
        var metrics_list = [];
        var next_seq_invisible_entries = [];
        var prev_pos = 0;
        var win_dim = {"top": $(window).scrollTop(), "range": $(window).height()};
        if(!cursor_index) cursor_index = 0;
        return bb.blockEach($statuses.filter(".bb-status").get(), 150, function(status_block, block_start_index) {
            $.each(status_block, function(index_in_block, cur_entry) {
                var cur_index = block_start_index + index_in_block;
                var $cur_entry = $(cur_entry);
                var entry_level = $cur_entry.data('bb-status-level');
                var cur_is_visible = ($cur_entry.css('display') !== 'none');
                var cur_pos = (cur_is_visible ? $cur_entry.offset().top : prev_pos);
                var metric = {
                    status_entry: cur_entry,
                    action: null,
                    win_dist: 0,
                    cursor_index_dist: 0
                };
                if(entry_level >= threshold_level) {
                    metric.action = (cur_is_visible ? ACTION_STAY_VISIBLE : ACTION_BECOME_VISIBLE);
                    if(next_seq_invisible_entries.length > 0) {
                        final_result.hiddenHeaderList.push({'$followed_by': $cur_entry, 'entries': next_seq_invisible_entries});
                        next_seq_invisible_entries = [];
                    }
                }else {
                    metric.action = (cur_is_visible ? ACTION_BECOME_INVISIBLE : ACTION_STAY_INVISIBLE);
                    next_seq_invisible_entries.push($cur_entry);
                }
                metric.win_dist = bb.distanceRanges(win_dim.top, win_dim.range, cur_pos, cur_is_visible ? $cur_entry.height() : 0);
                metric.cursor_index_dist = Math.abs(cur_index - cursor_index);
                prev_pos = cur_pos;
                metrics_list.push(metric);
            });
        }).then(function() {
            var animate_count_max = enable_animation ? selfclass.ANIMATE_STATUS_MAX_NUM : 0;
            var animate_count = 0;
            if(next_seq_invisible_entries.length > 0) {
                final_result.hiddenHeaderList.push({'$followed_by': null, 'entries': next_seq_invisible_entries});
            }
            metrics_list = metrics_list.sort(function (a, b) {
                if(a.win_dist !== b.win_dist) {
                    return a.win_dist - b.win_dist;
                }
                return a.cursor_index_dist - b.cursor_index_dist;
            });
            $.each(metrics_list, function(metrics_index, metric) {
                var target_container;
                if(final_result.domAnchorElem === null && metric.action === ACTION_STAY_VISIBLE) {
                    final_result.domAnchorElem = metric.status_entry;
                }
                if(metric.action === ACTION_STAY_VISIBLE || metric.action === ACTION_STAY_INVISIBLE) {
                    return true;
                }
                if(animate_count < animate_count_max) {
                    animate_count++;
                    target_container = final_result.domsAnimateToggle;
                }else {
                    target_container = final_result.domsImmediateToggle;
                }
                target_container.push(metric.status_entry);
            });
            return final_result;
        });
    },
    setDisplayByThreshold: function(args) {
        // @params: args.$statuses, args.threshold, args.enableAnimation, args.enableWindowAdjust, args.cursorIndex
        // @returns: promise for completion event.
        var window_adjuster = function(){};
        return Q.fcall(function() {
            if(!defined(args.$statuses)) {
                throw "$statuses param is mandatory";
            }
            if(!defined(args.threshold)) {
                throw "threshold param is mandatory";
            }
            return selfclass._scanStatusesForDisplayActions(args.$statuses, args.threshold, args.enableAnimation, args.cursorIndex);
        }).then(function(action_description) {
            var promise_hidden_statuses, promise_animation, promise_immediate;
            var $anchor_element;
            var anchor_position_function = null;
            if(args.enableWindowAdjust) {
                if(action_description.domAnchorElem) {
                    $anchor_element = $(action_description.domAnchorElem);
                    anchor_position_function = function() {
                        return $anchor_element.offset().top;
                    };
                }
                window_adjuster = selfclass._createWindowAdjuster(anchor_position_function);
            }
            if(action_description.domsAnimateToggle.length > 0) {
                promise_animation = bb.slideToggleElements(
                    $(action_description.domsAnimateToggle), selfclass.ANIMATE_STATUS_DURATION,
                    function(now, fx) {
                        if(fx.prop !== "height") return;
                        window_adjuster();
                    }
                );
            }else {
                promise_animation = Q.fcall(function() { });
            }
            promise_hidden_statuses = selfclass._updateHiddenStatusesHeaders(args.$statuses,
                                                                             action_description.hiddenHeaderList,
                                                                             window_adjuster);
            promise_immediate = bb.blockEach(action_description.domsImmediateToggle, 100, function(status_block) {
                $(status_block).toggle();
                window_adjuster();
            });
            return Q.all([promise_hidden_statuses, promise_animation, promise_immediate]);
        }).then(function() {
            window_adjuster();
        });
    },
    loadStatuses: function(args) {
        // @params: args.apiURL, args.countPerPage, args.maxPageNum (so far, required)
        //          args.ackState = "any",
        //          args.startMaxID = null,
        // @returns: a promise holding the following object in success
        //           { maxReached: (boolean), numRequests: (number of requests sent), statuses: (array of status DOM elements) }
        return Q.fcall(function() {
            if(!defined(args.apiURL)) {
                throw "apiURL param is mandatory";
            }
            if(!defined(args.maxPageNum)) {
                throw "maxPageNum param is mandatory";
            }
            if(!defined(args.countPerPage)) {
                throw "countPerPage param is mandatory";
            }
            var api_url = args.apiURL;
            var max_page_num = args.maxPageNum;
            if(max_page_num <= 0) {
                throw "maxPageNum param must be greater than 0";
            }
            var query_params = {
                "ack_state": defined(args.ackState) ? args.ackState : "any",
                "count": args.countPerPage
            };
            if(query_params.count <= 0) {
                throw "countPerPage param must be greater than 0";
            }
            if(defined(args.startMaxID)) {
                query_params.max_id = args.startMaxID;
            }
            var request_num = 0;
            var loaded_statuses = [];
            var last_status_id = null;
            var fulfill_handler;
            var makeRequest = function() {
                return bb.ajaxRetry({
                    type: "GET", url: api_url, data: query_params, cache: false, timeout: 3000,
                    tryMax: selfclass.LOAD_STATUS_TRY_MAX, dataType: "html",
                }).promise.then(fulfill_handler);
            };
            fulfill_handler = function(statuses_str) {
                var $statuses = $(statuses_str).filter(".bb-status");
                var fully_loaded = ($statuses.size() < query_params.count);
                var is_completed;
                request_num++;
                is_completed = (fully_loaded || request_num >= max_page_num);
                if(defined(last_status_id) && last_status_id === selfclass._getStatusID($statuses.first())) {
                    $statuses = $statuses.slice(1);
                }
                $.merge(loaded_statuses, $statuses.get());
                if(is_completed) {
                    return {
                        maxReached: !fully_loaded,
                        numRequests: request_num,
                        statuses: loaded_statuses
                    };
                }else {
                    if($statuses.size() > 0) {
                        last_status_id = selfclass._getStatusID($statuses.last());
                    }
                    if(defined(last_status_id)) {
                        query_params.max_id = last_status_id;
                    }
                    return makeRequest();
                }
            };
            return makeRequest();
        });
    }
}); selfclass.prototype = {
    _setDisplayImmediately: function($target_statuses) {
        var self = this;
        var args = {
            $statuses: $target_statuses,
            threshold: self.threshold_level,
            cursorIndex: self._getCursorIndex(),
        };
        return selfclass.setDisplayByThreshold(args);
    },
    _getLoadStatusesURL: function() {
        return this.api_base + "/timelines/" + this.timeline + "/statuses.html";
    },
    _getStatuses: function() {
        return $(this.sel_container).children(".bb-status");
    },
    _ackStatuses: function(acked_statuses_dom, set_max_id) {
        var self = this;
        if(acked_statuses_dom.length <= 0) {
            return Q.fcall(function() {});
        }
        var ack_ids = $.map(acked_statuses_dom, function(status_dom) {
            return selfclass._getStatusID($(status_dom));
        });
        var query_object = {"ids": ack_ids};
        if(set_max_id) {
            query_object["max_id"] = selfclass._getStatusID($(acked_statuses_dom[acked_statuses_dom.length-1]));
        }
        return bb.ajaxRetry({
            type: "POST", url: self.api_base + "/timelines/" + self.timeline + "/ack.json",
            data: JSON.stringify(query_object), contentType: "application/json",
            cache: false, timeout: 10000, dataType: "json", tryMax: selfclass.ACK_TRY_MAX
        }).promise;
    },
    _addStatuses: function(added_statuses_dom, is_prepend) {
        var self = this;
        var $container = $(self.sel_container);
        var $next_top = null;
        return bb.blockEach(added_statuses_dom, selfclass.ADD_STATUSES_BLOCK_SIZE, function(statuses_block) {
            var $statuses = $(statuses_block);
            $statuses.css("display", "none");
            if(defined($next_top)) {
                $next_top.after($statuses);
            }else {
                if(is_prepend) {
                    $container.prepend($statuses);
                }else {
                    $container.append($statuses);
                }
            }
            $next_top = $statuses.last();
        }).then(function() {
            return self._setDisplayImmediately($(added_statuses_dom));
        });
    },
    _isValidForCursor: function($elem) {
        var self = this;
        return ($elem.hasClass("bb-status") && $elem.data("bb-status-level") >= self.threshold_level);
    },
    _adjustCursor: function() {
        var self = this;
        var $statuses;
        var $next_candidate, $prev_candidate;
        if(!defined(self.$cursor)) {
            $statuses = self._getStatuses();
            if($statuses.size() === 0) return;
            self.setCursor($statuses.get(0));
        }
        if(self._isValidForCursor(self.$cursor)) {
            return;
        }
        $next_candidate = self.$cursor;
        $prev_candidate = self.$cursor;
        while(true) {
            $next_candidate = $next_candidate.next();
            $prev_candidate = $prev_candidate.prev();
            if($next_candidate.size() === 0 && $prev_candidate.size() === 0) {
                return;
            }
            if($next_candidate.size() === 1 && self._isValidForCursor($next_candidate.eq(0))) {
                self.setCursor($next_candidate.get(0));
                return;
            }
            if($prev_candidate.size() === 1 && self._isValidForCursor($prev_candidate.eq(0))) {
                self.setCursor($prev_candidate.get(0));
                return;
            }
        }
    },
    _getCursorIndex: function() {
        var self = this;
        if(!defined(self.$cursor)) return -1;
        var $statuses = self._getStatuses();
        if($statuses.size() === 0) return -1;
        return $statuses.index(self.$cursor);
    },
    appendStatuses: function(added_statuses_dom) {
        // @returns: promise resolved when done.
        return this._addStatuses(added_statuses_dom, false);
    },
    prependStatuses: function(added_statuses_dom) {
        // @returns: promise resolved when done.
        return this._addStatuses(added_statuses_dom, true);
    },
    setThresholdLevel: function(new_threshold) {
        // @returns: promise resolved when done.
        var self = this;
        var old_threshold = self.threshold_level;
        self.threshold_level = parseInt(new_threshold, 10);
        self._adjustCursor();
        if(old_threshold !== new_threshold) {
            $.each(self.on_threshold_level_changed_callbacks, function(i, callback) {
                callback(new_threshold);
            });
        }
        return selfclass.setDisplayByThreshold({
            $statuses: $(self.sel_container).children(),
            threshold: self.threshold_level,
            enableAnimation: true,
            enableWindowAdjust: true,
            cursorIndex: self._getCursorIndex()
        });
    },
    getThresholdLevel: function() {
        return this.threshold_level;
    },
    getTimelineName: function() { return this.timeline },
    getAPIBase: function() { return this.api_base },
    loadUnackedStatuses: function() {
        // @returns: promise with the following object
        //           { maxReached: (boolean), statuses: (array of status DOM elements loaded) }
        var self = this;
        var load_result;
        var $acked_new_statuses_label = $(self.sel_container).find(".bb-status-new-label");
        return selfclass.loadStatuses({
            apiURL: self._getLoadStatusesURL(), countPerPage: selfclass.LOAD_UNACKED_STATUSES_COUNT_PER_PAGE,
            maxPageNum: selfclass.LOAD_UNACKED_STATUSES_MAX_PAGE_NUM, ackState: "unacked"
        }).then(function(result) {
            load_result = result;
            return self._ackStatuses(load_result.statuses, load_result.maxReached);
        }).then(function() {
            return self.prependStatuses(load_result.statuses);
        }).then(function() {
            if(!defined(self.$cursor)) {
                self._adjustCursor();
            }
            $acked_new_statuses_label.remove();
            return {maxReached: load_result.maxReached, statuses: load_result.statuses};
        });
    },
    loadMoreStatuses: function() {
        // @returns: promise resolved when done
        var self = this;
        var start_id = null;
        return Q.fcall(function() {
            var $statuses = self._getStatuses();
            if($statuses.size() > 0) {
                start_id = selfclass._getStatusID($statuses.last());
            }
            return selfclass.loadStatuses({
                apiURL: self._getLoadStatusesURL(),
                ackState: "acked", countPerPage: selfclass.LOAD_MORE_STATUSES_COUNT,
                startMaxID: start_id, maxPageNum: 1
            });
        }).then(function(result) {
            var added_statuses = result.statuses;
            if(defined(start_id) && added_statuses.length > 0
               && selfclass._getStatusID($(added_statuses[0])) === start_id) {
                added_statuses.shift();
            }
            return self.appendStatuses(result.statuses);
        }).then(function() {
            if(!defined(self.$cursor)) {
                self._adjustCursor();
            }
        });
    },
    loadInit: function() {
        // @returns: promise with the following object
        //           { maxReached: (boolean), statuses: (array of unacked status DOM elements loaded) }
        var self = this;
        var unacked_load_result;
        return self.loadUnackedStatuses().then(function(result) {
            unacked_load_result = result;
            if(!result.maxReached) {
                return self.loadMoreStatuses();
            }
        }).then(function() {
            return unacked_load_result;
        });
    },
    setCursor: function(cursor_dom) {
        var self = this;
        if(defined(self.$cursor)) {
            self.$cursor.removeClass("bb-status-cursor");
        }
        self.$cursor = $(cursor_dom);
        self.$cursor.addClass("bb-status-cursor");
    },
    listenOnThresholdLevelChanged: function(callback) {
        // @params: callback (function(new_threshold) returning anything)
        this.on_threshold_level_changed_callbacks.push(callback);
    },
    _getWindowAdjusterForExtensionPane: function($pane) {
        // @return: a window adjuster function that keeps the closing
        // extension pane near the center of the screen as mush as
        // possible.
        var self = this;
        var pane_init_height = $pane.height();
        if(pane_init_height <= 0) {
            return null;
        }
        var screen_center = $(window).scrollTop() + $(window).height() * 0.4; // a little above the center, actually
        var pos_ratio = (screen_center - $pane.offset().top) / pane_init_height;
        if(pos_ratio <= 0) {
            return null;
        }
        if(pos_ratio > 1) {
            pos_ratio = 1;
        }
        return selfclass._createWindowAdjuster(function() {
            return $pane.offset().top + pos_ratio * $pane.height();
        });
    },
    toggleExtensionPane: function(extension_container_dom) {
        // @returns: promise that resolves when it finishes toggling.
        var self = this;
        var $container = $(extension_container_dom);
        var $pane = $container.find(".bb-status-extension-pane");
        var $icon_expander = $container.find(".bb-status-extension-expander");
        var $icon_collapser = $container.find(".bb-status-extension-collapser");
        var $anchor = null;
        var window_adjuster = null;
        if($pane.size() === 0) {
            return;
        }
        if($pane.css("display") === "none") {
            $icon_expander.hide();
            $icon_collapser.show();
        }else {
            window_adjuster = self._getWindowAdjusterForExtensionPane($pane);
            $icon_expander.show();
            $icon_collapser.hide();
        }
        return bb.slideToggleElements($pane, selfclass.ANIMATE_STATUS_DURATION, window_adjuster);
    },
}; return selfclass;})();

////////////////////////////////////////////////////////

bb.TimelineUnackedCountsPoller = (function() {
    var selfclass = $.extend(function(args) {
        // @params: args.statusContainer
        var scon = args.statusContainer;
        var self = this;
        if(!defined(scon)) {
            throw "statusContainer param is mandatory";
        }
        this.status_container = scon;
        this.on_change_listeners = [];
        this.poller = new bb.EventPoller({
            url: scon.getAPIBase() + "/timelines/" + scon.getTimelineName() + "/updates/unacked_counts.json",
            initialQuery: this._makeQuery({}),
            onResponse: function(response_data) {
                if(defined(response_data.error)) {
                    self._onError(response_data.error);
                    return Q.reject("API error: " + response_data.error);
                }
                $.each(self.on_change_listeners, function(i, listener) {
                    listener(response_data.unacked_counts);
                });
                return self._makeQuery(response_data.unacked_counts);
            }
        });
    }, {
        LEVEL_MARGIN: 2,
    });
    selfclass.prototype = {
        _onError: function(error_message) { console.log(error_message) },
        _setQueryItem: function(target_query_object, current_unacked_counts, key) {
            var cur_value = current_unacked_counts[key];
            target_query_object[key] = defined(cur_value) ? cur_value : 0;
        },
        _makeQuery: function(current_unacked_counts) {
            var self = this;
            var query = {};
            var threshold = self.status_container.getThresholdLevel();
            var level;
            if(!defined(current_unacked_counts)) {
                current_unacked_counts = {};
            }
            self._setQueryItem(query, current_unacked_counts, "total");
            for(level = threshold - selfclass.LEVEL_MARGIN ; level <= threshold + selfclass.LEVEL_MARGIN ; level++) {
                self._setQueryItem(query, current_unacked_counts, level);
            }
            return query;
        },
        listenOnChange: function(callback) {
            // @params: callback (function(unacked_counts))
            this.on_change_listeners.push(callback);
        },
        start: function() { this.poller.start() },
    };
    return selfclass;
})();

//////////////////////////////////////////

bb.StatusesSummary = function(args) {
    // @params: args.selectorContainer
    this.selector_container = args.selectorContainer;
};
bb.StatusesSummary.prototype = {
    _makeSummaryEntries: function($statuses) {
        var summary_for_level = {};
        $statuses.each(function() {
            var $status = $(this);
            var level = $status.data("bb-status-level");
            var username = $status.find(".bb-status-username").text();
            if(!defined(summary_for_level[level])) {
                summary_for_level[level] = {"level": level, "count": 0, "per_user": {}};
            }
            summary_for_level[level].count++;
            if(!defined(summary_for_level[level]["per_user"][username])) {
                summary_for_level[level]["per_user"][username] = 0;
            }
            summary_for_level[level]["per_user"][username]++;
        });
        return $.map(summary_for_level, function(entry) { return entry }).sort(function(a, b) {
            return b.level - a.level;
        });
    },
    _renderPerUserList: function(count_per_user) {
        var peruser_entries = $.map(count_per_user, function(count, username) { return {"username": username, "count": count} })
                               .sort(function(a, b) { return b.count - a.count });
        var $userlist = $('<ul class="list-group"></ul>');
        $.each(peruser_entries, function(i, entry) {
            var $username = $('<span class="bb-summary-count-username"></span>').text(entry.username);
            var $count    = $('<span class="bb-summary-count-per-user label label-default"></span>').text(entry.count);
            var $li_entry = $('<li class="bb-summary-count-per-user-entry list-group-item"></li>')
                             .append($username).append(" ").append($count);
            $userlist.append($li_entry);
        });
        return $userlist;
    },
    _renderSummaryEntry: function(entry, count_above) {
        var self = this;
        var accordion_body_id = "bb-summary-body-level" + entry.level;
        var $heading = $('<div class="panel-heading bb-summary-heading">'
                       + '<a data-toggle="collapse" href="#'+ accordion_body_id +'">'
                       + '<span class="caret"></span> '
                       + 'Lv. <span class="bb-summary-level">' + entry.level + '</span> &nbsp;&nbsp;'
                       + '<span class="bb-summary-count-pair">'
                       + '<span class="label label-primary bb-summary-count-above-level">' + count_above + '</span> '
                       + (entry.count === count_above ? '' : '<span class="label label-default bb-summary-count-this-level">+' + entry.count + '</span>')
                       + '</span>'
                       + '</a></div>');
        var $body = self._renderPerUserList(entry.per_user);
        $body.attr("id", accordion_body_id).addClass("panel-collapse collapse");
        var $entry = $('<div class="panel panel-default bb-summary-level-entry">').append($heading).append($body);
        return $entry;
    },
    showSummaryOf: function($statuses) {
        var self = this;
        var $container = $(self.selector_container);
        $container.empty();
        var summary_entries = self._makeSummaryEntries($statuses);
        var count_sofar = 0;
        $.each(summary_entries, function(i, entry) {
            count_sofar += entry.count;
            $container.append(self._renderSummaryEntry(entry, count_sofar));
        });
    }
};

