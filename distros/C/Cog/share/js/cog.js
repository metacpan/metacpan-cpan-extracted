// TODO:
// - Add a url decoder/encoder

// $Cog is the Cog prototype object. You can use it anywhere to extend Cog.

$Cog = (Cog = function() {this.init()}).prototype = {
    url_map: {},
    setup_functions: [],
    busy: false
};

$Cog.init = function() {
    var funcs = this.setup_functions;
    for (var i = 0, l = funcs.length; i < l; i++) {
        funcs[i].apply(this);
    }
};

$Cog.setup_functions.push(function() {
    $('.site-navigation a._navigate')
        .unbind('click')
        .bind('click', this.bind('navigate'));
});

$Cog.navigate = function(elem) {
    var f = $(elem).attr('href').replace(/^#/, '');
    this.bind(f)();
    return false;
};

$Cog.dispatch = function(path) {
    var map = this.url_map;
    for (var i = 0, il = map.length; i < il; i++) {
        var re = map[i][0];
        var regex = new RegExp('^' + re + '$');
        var method = map[i][1];
        var args = map[i].splice(2);
        var m = path.match(regex);
        if (m) {
            for (var j = 0, jl = args.length; j < jl; j++) {
                args[j] = args[j].replace(/^\$(\d)$/, function(x, d) { return m[Number(d)] });
            }
            if (typeof this[method] == 'undefined')
                throw "'" + method + "' method not found";
            this[method].apply(this, args);
            if (path.length > 1) {
                $.cookie("last_url", path, {path:'/'});
            }
            return;
        }
    }
    $('div.content').jemplate('404.html');
    return;
};

$Cog.redirect = function(url) {
    location = url;
};

$Cog.home_page = function() {
    this.redirect('/page/' + this.config.home_page_id);
};

$Cog.page_display = function(id) {
    var self = this;
    $.getJSON('/view/' + id + '.json', function(data) {
        $('div.content').jemplate('page-display.html', data);
        $.get('/view/' + id + '.html', function(data) {
            $('div.page').html(data);
        });
        setTimeout(function() {
            self.setup_links();
        }, 500);
    });
};

$Cog.page_list = function(title) {
    $.getJSON('/view/page-list.json', function(data) {
        data = {
            'pages': data,
            'title': title
        };
        $('div.content').jemplate('page-list.html', data);
    });
};

$Cog.tag_list = function() {
    $.getJSON('/view/tag-list.json', function(data) {
        data = {tags: data};
        $('div.content').jemplate('tag-list.html', data);
    });
};

$Cog.tag_page_list = function(tag) {
    $.getJSON('/view/tag/' + tag + '.json', function(data) {
        data = {pages: data};
        data.title = 'Tag: ' + tag.replace(/%20/g, ' ');
        $('div.content').jemplate('page-list.html', data);
    });
};

$Cog.page_by_name = function(name) {
    var self = this;
    var name = name
        .toLowerCase()
        .replace(/%[0-9a-fA-F]{2}/g, '_')
        .replace(/[^\w]+/g, '_')
        .replace(/_+/g, '_')
        .replace(/^_*(.*?)_*$/, '$1');
    $.get('/view/name/' + name + '.txt', function(id) {
        self.page_display(id);
    });
};

$Cog.setup_links = function() {
    var $links = $('.content .sectionbody a')
        .each(function() {
            var $link = $(this);
            if ($link.attr('href') == 'page') {
                $link.attr('href', '/page/name/' + $link.text());
            }
        });
};

$Cog.post_data = function(post_url, post_data, post_callback) {
    $.ajax({
        type: 'POST',
        url: post_url,
        data: post_data,
        dataType: "html",
        complete: this.bind(post_callback, post_data),
    });
};

$Cog.post_json = function(post_url, post_data, post_callback) {
    $.ajax({
        type: 'POST',
        url: post_url,
        data: $.toJSON(post_data),
        processData: false,
        contentType: "application/json; charset=utf-8",
        complete: this.bind(post_callback),
    });
};

$Cog.bind = function(method) {
    var cog = this;
    var args = Array.prototype.slice.call(arguments, 1);
    return function() {
        var func =
            (typeof method == 'string') ? cog[method] :
            (typeof method == 'undefined') ? function() {} :
            method;
        return func.apply(
            cog, args.concat(this, Array.prototype.slice.call(arguments))
        );
    };
};
