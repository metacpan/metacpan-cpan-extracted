"use strict";

// Javascript library for timeline list view.

bb.UnackedCountsRenderer = (function() {
    var selfclass = function(args) {
        // @param args.domTotal, args.domLevels, args.levelNum = 5
        this.dom_total = args.domTotal;
        this.dom_levels = args.domLevels;
        this.level_num = defined(args.levelNum) ? args.levelNum : 5;
    };
    selfclass.prototype = {
        _renderLevel: function(level, sum_count, this_count) {
            var $pair = $('<li class="bb-unacked-counts-pair"></li>');
            var $level = $('<span class="bb-unacked-counts-level"></span>');
            var $sum_count = $('<span class="bb-unacked-counts-sum-count label label-primary"></span>').text(sum_count);
            if(level === 'total') {
                $level.text("Other");
            }else {
                $pair.append("Lv. ");
                $level.text(level);
            }
            $pair.append($level).append(" ").append($sum_count);
            if(defined(this_count)) {
                $pair.append(" ").append($('<span class="bb-unacked-counts-this-count label label-default"></span>').text("+" + this_count));
            }
            return $pair;
        },
        _showTotal : function(total_count) {
            var self = this;
            var $container_total = $(self.dom_total);
            $container_total.empty();
            $container_total.append(
                $('<span class="bb-unacked-counts-total label label-primary"></span>').text(total_count)
            );
        },
        show: function(unacked_counts) {
            // @returns: nothing
            var self = this;
            var leveled_counts = [];
            var $container_levels = $(self.dom_levels);
            var sum_count = null;
            var count_elements = [];
            var total = unacked_counts.total;
            self._showTotal(total);
            $.each(unacked_counts, function(level, count) {
                if(level === "total") return;
                leveled_counts.push({level: parseInt("" + level, 10), count: count});
            });
            leveled_counts.sort(function(a, b) {
                return b.level - a.level;
            });
            $.each(leveled_counts, function(i, count_entry) {
                if(i >= self.level_num) {
                    return false;
                }
                if(defined(sum_count)) {
                    sum_count += count_entry.count;
                    count_elements.push(self._renderLevel(count_entry.level, sum_count, count_entry.count));
                }else {
                    sum_count = count_entry.count;
                    count_elements.push(self._renderLevel(count_entry.level, sum_count));
                }
            });
            if(leveled_counts.length > self.level_num) {
                count_elements.push(self._renderLevel("total", total, total - sum_count));
            }
            $container_levels.empty();
            $.each(count_elements, function(i, elem) {
                $container_levels.append(elem);
            });
        }
    };
    return selfclass;
})();

bb.UnackedCountsPoller = (function() {
    var selfclass = function(args) {
        // @params: args.apiBase = ""
        var self = this;
        self.api_base = args.apiBase || "";
        self.level = "total"; // ** for now, it's constant
        self.polled_timelines = {};
        self.poller = null;
    };
    selfclass.prototype = {
        addTimeline: function(args) {
            // @params: args.timelineName, args.callback(unacked_counts), args.initialUnackedCounts = {total: 0}
            if(!defined(args.timelineName)) {
                throw "timelineName param is mandatory";
            }
            if(!defined(args.callback)) {
                throw "callback param is mandatory";
            }
            this.polled_timelines[args.timelineName] = {
                callback: args.callback,
                unacked_counts: args.initialUnackedCounts || {"total": 0}
            };
        },
        _makeQuery: function() {
            var self = this;
            var query_obj = { "level": self.level };
            var timeline_count = 0;
            $.each(self.polled_timelines, function(name, polled_timeline) {
                timeline_count++;
                query_obj["tl_" + name] = polled_timeline.unacked_counts[self.level] || 0;
            });
            if(timeline_count === 0) {
                throw "Cannot create valid query because there is no timeline added for polling.";
            }
            return query_obj;
        },
        start: function() {
            var self = this;
            self.poller = new bb.EventPoller({
                url: self.api_base + "/updates/unacked_counts.json",
                initialQuery: self._makeQuery(),
                onResponse: function(response_data) {
                    if(defined(response_data.error)) {
                        return Q.reject("API error: " + response_data.error);
                    }
                    $.each(response_data.unacked_counts, function(timeline_name, got_counts) {
                        var polled_timeline = self.polled_timelines[timeline_name];
                        polled_timeline.unacked_counts = got_counts;
                        polled_timeline.callback($.extend({}, got_counts));
                    });
                    return self._makeQuery();
                }
            });
            self.poller.start();
        }
    };
    return selfclass;
})();
