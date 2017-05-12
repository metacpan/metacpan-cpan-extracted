function DebugToolbar(cfg) {
    var $toolbar, $window, $toolbarFrame, $windowFrame;
    var displayedScreen, displayedPage;
    
    function init() {
        if (typeof cfg == 'undefined') {
            cfg = parent.__debugtoolbarCfg;
        }
        
        if (typeof cfg == 'string') {
            /* JSON configuration */
            cfg = $.parseJSON(cfg);
        }
        
        $toolbarFrame = $('#debugtoolbar_toolbar_frame', parent.document);
        $windowFrame = $('#debugtoolbar_window_frame', parent.document);
        
        $toolbarFrame.show();
        
        /* Toolbar container element */
        $toolbar = $('#toolbar');
        /* Window container element */
        $window = $('#window', $windowFrame[0].contentDocument);

        if (cfg['screens'])
            for (var name in cfg['screens'])
                if (cfg['screens'][name])
                    addScreen(name, cfg['screens'][name]);
        
        var toolbar = cfg['toolbar'];
        var $buttons = $([]);
        
        /* Add a span element for the logo image */
        if (toolbar['logo'])
            $('<span class="logo" />').appendTo($toolbar);
        
        if (toolbar['buttons']) {
            $buttons = $('<div class="buttons" />').appendTo($toolbar);
            
            for (var name in toolbar['buttons'])
                if (toolbar['buttons'][name])
                    addButton(name, toolbar['buttons'][name]);
            
            if (toolbar['buttons']['close'])
                $('<span class="button close" />').appendTo($toolbar);
        }
        
        /* Standard actions */
        
        /* Expand/collapse toolbar when the logo is clicked */
        $('.logo').click(function () {
            $buttons.toggle();
            resizeToolbar();
            
            if (displayedScreen) {
                $windowFrame.fadeOut(300);
                displayedScreen = false;
            }
        });
        
        /* Alignment */
        $('.button.align').click(function () {
            if ($(this).hasClass('left')) {
                $toolbarFrame.css({ right: '5px', left: 'auto' });
                $(this).attr('title', 'Move the toolbar to the left');
            }
            else {
                $toolbarFrame.css({ left: '5px', right: 'auto' });
                $(this).attr('title', 'Move the toolbar to the right');
            }
            
            $(this).toggleClass('left right');
        });
        
        /* Close */
        $('.button.close').click(function () {
            if (displayedScreen) {
                $windowFrame.fadeOut(300, function () {
                    $windowFrame.remove();
                    $toolbarFrame.remove();
                });
                displayedScreen = false;
            }
            else {
                $windowFrame.remove();
                $toolbarFrame.remove();
            }
        });
        
        /* Buttons are initially hidden */
        $buttons.hide();
        
        resizeToolbar();
        
        /* Adjust info window size when main browser window is resized */
        $(parent).resize(resizeWindow);
    }
       
    function addButton(name, options) {
        var $button;
        
        switch (name) {
        case 'align':
            /* Right/left toolbar alignment button */
            $button = $('<span class="button align" />')
                .addClass('right');
            break;
        case 'close':
            /* Close button gets special treatment -- see init() */
            break;
        default:
            $button = $('<span class="button" />').
                addClass(name);
            $button.data('name', name);
            if (options['text'])
                $button.text(options['text']);
            
            if (cfg['screens'][name])
                $button.click(function () {
                    displayScreen($(this).data('name'));
                });
                
            break;
        }
        
        if ($button)
            $button.appendTo($('.buttons', $toolbar));
    }
    
    function addScreen(name, options) {
        var $screen;
        
        $screen = $('<div class="screen" />')
            .addClass(name);
        
        if (options['title'])
            $screen.append($('<h1>' + options['title'] + '</h1>'));
        
        if (options['pages']) {
            var $pages = $('<div class="pages scrolled" />').appendTo($screen);
            var pageCount = 0;
            
            for (var name in options['pages']) {
                addPage($pages, name, options['pages'][name]);
                pageCount++; 
            }
            
            if (pageCount > 1) {
                /* There's more than one page -- add a menu to switch pages */
                $('<ul class="page-list" />').insertBefore($pages);
                
                for (var name in options['pages'])
                    $('<li />').appendTo($('.page-list', $screen))
                        .data('page', name)
                        .addClass(name)
                        .text(options['pages'][name]['name'] || name)
                        .click(function () {
                            displayPage($(this).data('page'));
                        });
            }
        }
        
        $screen.appendTo($window);
    }
    
    function addPage($parent, name, options) {
        if (pageHandlers[options['type']]) {
            var page = new pageHandlers[options['type']](name, options);
            $parent.append(page.$page.hide());
        }
    }
    
    function resizeWindow() {
        $windowFrame.width($(parent).width() - 10 + 'px');
        $windowFrame.height($(parent).height() * 0.7 + 'px');
        
        $('.screen', $window).each(function () {
            $(this).css('height', $windowFrame.height() - 10 + 'px');

            $('.pages', $(this)).each(function () {
                $(this).css('height', $(this).parent().height() -
                        $(this).position().top + 'px');
            });
        });
        
    }
    
    function displayScreen(screen) {
        if ($windowFrame.is(':visible')) {
            
        }
        else {
            /* Show the information window */
            
            var top = $toolbarFrame.offset().top - 
                $(parent.document).scrollTop() +
                $toolbarFrame.outerHeight() + 5;
            
            $windowFrame.hide();
            $windowFrame.css({ left: '5px', right: '5px',
                top: top + 'px'}).fadeIn(300);
        }
        
        var $screen = $('.screen.' + screen, $window);
        $('.screen:not(.' + screen + ')', $window).hide();
        $screen.show();
        
        displayedScreen = screen;
        
        /* If none of the pages is displayed, display the first one */
        if ($('.pages .page:visible', $screen).length == 0)
            displayPage($('.pages .page', $screen).eq(0).data('name'));
        
        windowDisplayed = true;
        
        resizeWindow();
    }
    
    function displayPage(page, screen) {
        if (!screen)
            screen = displayedScreen;
        
        var $screen = $('.screen.' + screen, $window);
        
        $('.page', $screen).hide();
        $('.page.' + page, $screen).show();

        $('.page-list li', $screen).removeClass('active');
        $('.page-list li.' + page, $screen).addClass('active');
    }
    
    function resizeToolbar() {
        var frame = $('#debugtoolbar_toolbar_frame', parent.document)[0];
        frame.width = $('#toolbar').width();
        frame.height = $('#toolbar').height();
    }
    
    init(cfg);
}

var pageHandlers = {};

var Widget = Class.extend({
    init: function () {
        this.$elem = $('<div class="widget" />');
    },
    
    get: function () {
        return this.$elem;
    }
});

var TextWidget = Widget.extend({
    init: function (content) {
        this._super();
        this.$elem.addClass('text');
        this.$elem.text(content);
    }
});

var DataStructureWidget = Widget.extend({
    init: function (data) {
        this._super();
        this.$elem.addClass('data-structure');
        this.$elem.append(this.htmlize(data));
        
        $('li div.field', this.$elem).each(function () {
            if ($(this).nextAll('div.sub').length > 0) {
                $('<span class="expand"></span>').prependTo($(this))
                    .click(function () {
                        $(this).parent().nextAll('div.sub').toggle();
                        
                        var expanded = $(this).parent().nextAll('div.sub')
                            .is(':visible');
                        
                        $(this).parent().toggleClass('expanded', expanded);
                    });
            }
            else {
                $('<span class="placeholder" />').prependTo($(this));
            }
        });
    },
    
    htmlizeValue: function (item) {
        function htmlizeShort(value) {
            if (typeof value['html'] != 'undefined')
                return $(value['html']);
            else
                return $('<div class="value" />').text(value);
        }
        
        switch (item['type']) {
        case 'list':
            var $ret = $('<div class="sub list" />')
                .hide()
                .append(this.htmlize(item));
            
            if (typeof item['short_value'] != 'undefined')
                $ret = $ret.clone().before(htmlizeShort(item['short_value']));
            
            return $ret;
        case 'map':
            var $ret = $('<div class="sub map" />')
                .hide()
                .append(this.htmlize(item));
            
            if (item['short_value'])
                $ret = $ret.clone().before(htmlizeShort(item['short_value']));
            
            return $ret;
        case 'number':
            return $('<div class="value value-number" />')
                .text(item['value']);
        case 'string':
            return $('<div class="value value-string" />')
                .text(item['value']);
        default:
            return $('<div class="value" />').text(item['value']);
        }
    },
    
    htmlize: function (data) {
        var $ul = $('<ul />');
        
        switch (data['type']) {
        case 'list':
        case 'map':
            /*
             * li
             *   div.field
             *     span.name foo
             *   [... value ...]
             */
            var name;
            
            for (name in data['value']) {
                var $li = $('<li />').appendTo($ul);
                $('<div class="field" />')
                    .append($('<span class="name" />').text(name))
                    .appendTo($li);
                $li.append(this.htmlizeValue(data['value'][name]));
            }
            
            if (!name)
                /* Empty list/map */
                $('<li />').append($('<div class="value value-empty" />')
                        .text('empty')).appendTo($ul);
            
            break;
        }
        
        return $ul;
    }
});

/*
 *  
 */
var Page = Class.extend({
    init: function (name, options) {
        this.name = name;
        this.options = options;
        this.$page = $('<div class="page" />').addClass(name);
        this.$page.data('name', name);
    }
});

var TextPage = Page.extend({
    init: function (name, options) {
        this._super(name, options);
        this.$page.append((new TextWidget(options['content'])).get());
    }
});

/*
 * Page to display complex data structures
 */
var DataStructurePage = Page.extend({
    widgetClass: DataStructureWidget,
    
    init: function (name, options) {
        this._super(name, options);
        this.$page.addClass('data-structure');
        
        this.$page.append((new this.widgetClass(options['data'])).get());
    },
});

/* Perl-specific */
/*
 * Widget to display complex data structures (Perl flavor)
 */
var DataStructurePerlWidget = DataStructureWidget.extend({
    init: function (data) {
        this._super(data);
    },
    
    htmlizeValue: function (item) {
        switch (item['type']) {
        case 'perl/undefined':
            return $('<div class="value value-undefined">undefined</div>');
        case 'perl/cyclic-ref':
            return $('<div class="value value-empty">cyclic reference</div>');
        default:
            return this._super(item);
        }
    }
});

var DataStructurePerlPage = DataStructurePage.extend({
    widgetClass: DataStructurePerlWidget,
    
    init: function (name, options) {
        this._super(name, options);
    }
});

var RoutesPage = Page.extend({
    init: function (name, options) {
        this._super(name, options);
        this.render();
    },

    render: function () {
        for (var type in this.options['routes']) {
            this.$page.append($('<h2 />').text(type));

            var routes = this.options['routes'][type];
            
            for (var i = 0; i < routes.length; i++) {
                var routeData = {
                    'type': 'map',
                    'value': { }
                };
            
                routeData.value[routes[i].pattern] = routes[i].data;
                routeData.value[routes[i].pattern]['short_value'] = '';
            
                var $widget = (new DataStructurePerlWidget(routeData))
                    .get();
                
                $('> ul > li > .field', $widget)
                    .addClass('pattern wide');
                
                if (routes[i].matching)
                    $('> ul > li > .field', $widget).addClass('matching');
                
                this.$page.append($widget);
            }
        }
    }
});

var TemplatesPage = Page.extend({
    init: function (name, options) {
        this._super(name, options);
        this.render();
    },
    
    render: function () {
        for (var i = 0; i < this.options['views'].length; i++) {
            var view = this.options['views'][i];
            
            this.$page.append($('<h2 />').text(view['template'])
                    .append($('<span class="engine" />').text(view['engine'])));
            
            var $widget = (new DataStructurePerlWidget(view['tokens'])).get();
            
            this.$page.append($widget);
        }
    }
});

var DatabaseQueriesPage = Page.extend({
    init: function (name, options) {
        this._super(name, options);
        this.render();
    },

    render: function () {
        var queries = this.options['queries'];
        
        var $ul = $('<ul class="queries" />');
        
        for (var i = 0; i < queries.length; i++) {
            $ul.append($('<li />').append($('<pre />')
                .append($(prettyPrintOne(queries[i].query, 'sql')))));
        }
        
        this.$page.append($ul);
    }
});

/* --- */

pageHandlers['text'] = TextPage;
pageHandlers['data-structure'] = DataStructurePage;

/* Perl and/or Dancer-specific pages */
pageHandlers['data-structure/perl'] = DataStructurePerlPage;
pageHandlers['routes'] = RoutesPage;
pageHandlers['templates'] = TemplatesPage;
pageHandlers['database-queries'] = DatabaseQueriesPage;

/* --- */
