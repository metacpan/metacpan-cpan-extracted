"use strict";

//// BusyBird main library
//// Copyright (c) 2013 Toshio ITO


function defined(val){
    // ** simulate Perl's defined() function.
    return !(val === null || typeof(val) === 'undefined');
}

var bb = {};

bb.ajaxRetry = (function() {
    var backoff_init_ms = 500;
    var backoff_factor = 2;
    var backoff_max_ms = 120000;
    return function (ajax_param) {
        var ajax_xhr = null;
        var ajax_retry_ok = true;
        var ajax_retry_backoff = backoff_init_ms;
        var deferred = Q.defer();
        var try_max = 0;
        var try_count = 0;
        var ajax_done_handler, ajax_fail_handler;
        if('tryMax' in ajax_param) {
            try_max = ajax_param.tryMax;
            delete ajax_param.tryMax;
        }
        ajax_done_handler = function(data, textStatus, jqXHR) {
            // deferred.call(data, textStatus, jqXHR);
            deferred.resolve(data);
        };
        ajax_fail_handler = function(jqXHR, textStatus, errorThrown) {
            ajax_xhr = null;
            try_count++;
            if(try_max > 0 && try_count >= try_max) {
                // deferred.fail(jqXHR, textStatus, errorThrown);
                deferred.reject("Network error");
                return;
            }
            ajax_retry_backoff *= backoff_factor;
            if(ajax_retry_backoff > backoff_max_ms) {
                ajax_retry_backoff = backoff_max_ms;
            }
            setTimeout(function() {
                if(ajax_retry_ok) {
                    ajax_xhr =  $.ajax(ajax_param);
                    ajax_xhr.then(ajax_done_handler, ajax_fail_handler);
                };
            }, ajax_retry_backoff);
        };
        ajax_xhr = $.ajax(ajax_param);
        ajax_xhr.then(ajax_done_handler, ajax_fail_handler);
        return {
            promise: deferred.promise,
            cancel: function() {
                ajax_retry_ok = false;
                deferred.reject("Ajax cancelled.");
                console.log("ajaxRetry: canceller called");
                if(defined(ajax_xhr)) {
                    console.log("ajaxRetry: xhr aborted.");
                    ajax_xhr.abort();
                }
            }
        };
    };
})();

bb.blockEach = function(orig_array, block_size, each_func) {
    var block_num = Math.ceil(orig_array.length / block_size);
    var i;
    var start_defer = Q.defer();
    var end_promise = start_defer.promise;
    var generate_callback_for = function(block_index) {
        return function() {
            var start_global_index = block_size * block_index;
            return each_func(orig_array.slice(start_global_index, start_global_index + block_size), start_global_index);
        };
    };
    start_defer.resolve();
    for(i = 0 ; i < block_num ; i++) {
        end_promise = end_promise.then(generate_callback_for(i));
    }
    return end_promise;
};

bb.distanceRanges = function (a_top, a_range, b_top, b_range) {
    var a_btm = a_top + a_range;
    var b_btm = b_top + b_range;
    var dist_top = a_top  - b_top;
    var dist_btm = b_btm - a_btm;
    var signed_dist = (dist_top > dist_btm ? dist_top : dist_btm);
    return (signed_dist > 0 ? signed_dist : 0);
};

bb.slideToggleElements = function($elements, duration, step_func) {
    var deferred = Q.defer();
    if(!step_func) {
        step_func = function(now, fx) {};
    }
    $elements.animate(
        { "height": "toggle",
          "marginTop": "toggle",
          "marginBottom": "toggle",
          "paddingTop": "toggle",
          "paddingBottom": "toggle"
        },
        {
            duration: duration,
            step: step_func
        }
    ).promise().done(function() {
        deferred.resolve();
    }).fail(function() {
        deferred.reject("Animation somehow failed.");
    });
    return deferred.promise;
};

bb.Spinner = function(sel_target) {
    this.sel_target = sel_target;
    this.spin_count = 0;
    this.spinner = new Spinner({
        lines: 10,
        length: 5,
        width: 2,
        radius: 3,
        corners: 1,
        rotate: 0,
        trail: 60,
        speed: 1.0,
        color: "#CCC",
        className: 'bb-spinner',
        left: 0
    });
};
bb.Spinner.prototype = {
    set: function(val) {
        var old = this.spin_count;
        if(val < 0) val = 0;
        this.spin_count = val;
        if(old > 0 && this.spin_count <= 0) {
            this.spinner.stop();
        }else if(old <= 0 && this.spin_count > 0) {
            this.spinner.spin($(this.sel_target).get(0));
        }
    },
    begin: function() {
        this.set(this.spin_count + 1);
    },
    end: function() {
        this.set(this.spin_count - 1);
    }
};

bb.MessageBanner = function(sel_target) {
    this.sel_target = sel_target;
    this.timeout_obj = null;
};
bb.MessageBanner.prototype = {
    show: function(msg, type, timeout) {
        var $msg = $(this.sel_target);
        var self = this;
        if(!defined(type)) type = "normal";
        msg = '<span class="bb-msg-'+type+'">'+msg+'</span>';
        $msg.html(msg).show();
        if(!defined(timeout) || timeout <= 0) timeout = 5000;
        if(defined(self.timeout_obj)) {
            clearTimeout(self.timeout_obj);
            self.timeout_obj = null;
        }
        self.timeout_obj = setTimeout(function() {
            self.timeout_obj = null;
            $msg.fadeOut('fast');
        }, timeout);
    },
};

bb.EventPoller = function(args) {
    // @params: args.url, args.initialQuery,
    //          args.onResponse (function(response_data) returning next_query or promise(next_query))
    this.url = args.url;
    this.initial_query = args.initialQuery;
    this.on_response = args.onResponse;
};
bb.EventPoller.prototype = {
    start: function() {
        // @returns: nothing
        var self = this;
        var query_object = self.initial_query;
        var makeRequest = function() {
            return bb.ajaxRetry({
                type: "GET", url: self.url, data: query_object, contentType: "application/json; charset=utf8",
                dataType: "json", cache: false, timeout: 0
            }).promise.then(function(response_data) {
                return self.on_response(response_data);
            }).then(function(next_query) {
                query_object = next_query;
                return makeRequest();
            }).fail(function(reason) {
                console.error("EventPoller fatal error:");
                console.error(reason);
            });
        };
        makeRequest();
    },
};

bb.Notification = function(args) {
    // @params: args.titleBase (default: current value of <title>)
    //          args.scriptName (default: "")
    if(!defined(args)) args = {};
    this.init_web_notifications_done = false;
    this.title_base = defined(args.titleBase) ? args.titleBase : document.title;
    this.script_name = defined(args.scriptName) ? args.scriptName : "";
};
bb.Notification.prototype = {
    _isWebNotificationEnabled: function() {
        return this.init_web_notifications_done && window.Notification && window.Notification.permission === 'granted';
    },
    initWebNotification: function() {
        // @returns a promise resolved when initialization is done. If
        // Web Notification is permitted, the promise
        // fulfills. Otherwise it rejects.
        var self = this;
        var init_defer = Q.defer();
        var resolve_init = function(permission) {
            if(permission === 'granted') {
                init_defer.resolve();
            }else {
                init_defer.reject("Web Notification is denied (perhaps by the user)");
            }
            self.init_web_notifications_done = true;
        };
        if(window.Notification) {
            if(window.Notification.permission === 'default') {
                window.Notification.requestPermission(resolve_init);
            }else {
                resolve_init(window.Notification.permission);
            }
        }else {
            init_defer.reject("Web Notification is not supported in this environment.");
        }
        return init_defer.promise;
    },
    _getFaviconPath: function(type) {
        // @param type either "normal" or "alert".
        return this.script_name + "/static/favicon_" + type + ".ico";
    },
    setFaviconAlert: function(is_alert) {
        var self = this;
        var favicon_type = is_alert ? "alert" : "normal";
        $("link[rel='shortcut icon']").remove();
        
        $("head").append( $('<link rel="shortcut icon"></link>').attr('href', self._getFaviconPath(favicon_type)) );
    },
    showWebNotification: function(args) {
        // @params: args.message, args.tag, subtitle,
        //          args.onClick (optional) (function (message) returning nothing)
        var self = this;
        if(!self._isWebNotificationEnabled()) return;
        var message = args.message;
        var onclick = args.onClick;
        var title = defined(args.subtitle) ? args.subtitle + ' - BusyBird' : 'BusyBird';
        var notification = new Notification(title, {
            body: message, tag: args.tag, icon: self._getFaviconPath("alert")
        });
        notification.onclick = function() {
            this.close();
            if(defined(onclick)) onclick(message);
        };
    },
    setTitleNotification: function(message) {
        if(defined(message) && message !== "") {
            document.title = message + " " + this.title_base;
        }else {
            document.title = this.title_base;
        }
        
    },
};

