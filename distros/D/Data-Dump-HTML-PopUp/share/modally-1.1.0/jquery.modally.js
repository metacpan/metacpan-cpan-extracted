(function ($) {
  function getScrollWidth() {
    var $tester = $('<div></div>');
    var $inner = $('<div></div>');

    $tester.css({
        width:  '100px',
        height: '100px',
        'z-index': 0,
        position: 'fixed',
        left: '-9999px',
        top: 0,
        'overflow-x': 'hidden',
        'overflow-y': 'scroll'
    });

    $inner.css({
      'min-height': '10px'
    });

    $tester.append($inner);
    $('html').append($tester);

    var scroll_width = $inner.width();
    $inner.remove();
    $tester.remove();

    return 100 - scroll_width;
  }

  window.scroll_width = getScrollWidth();

  function storePaddingRight($elem) {
    var padding_right = parseInt($elem.css('padding-right'), 10);
    $elem.data('padding-right', padding_right);
    return padding_right;
  }

  function restorePaddingRight($elem) {
    var padding_right = $elem.data('padding-right');
    $elem.css('padding-right', padding_right);
    $elem.data('padding-right', null);
    return padding_right;
  }

  $.fn.paddingFill = function() {
    var $this = $(this);

    if (window.scroll_width) {
      $this.each(function() {
        var $elem = $(this);
        var data = $elem.data('padding-right');
        if (data === null || data === undefined) {
          $elem.css('padding-right', storePaddingRight($elem) + scroll_width );
        }
      });
    }
  };

  $.fn.disableScroll = function() {
    var $this = $(this);
    var $html = $('html');

    if (!$html.data('scroll-blocked')) {
      $html.css({
        overflow: 'hidden',
        height: '100%'
      });
      $html.data('scroll-blocked', true);
    }

    $this.paddingFill();
  };

  $.fn.undoPaddingFill = function() {
    var $this = $(this);

    if (window.scroll_width) {
      $this.each(function() {
        var $elem = $(this);
        var data = $elem.data('padding-right');
        if (data !== null) {
          $elem.css('padding-right', restorePaddingRight($elem));
        }
      });
    }
  };

  $.fn.enableScroll = function() {
    var $this = $(this);
    $this.undoPaddingFill();
    var $html = $('html');

    if ($html.data('scroll-blocked')) {
      $html.css({
        overflow: 'auto',
        height: 'auto'
      });
      $html.data('scroll-blocked', false);
    }
  };

  // https://www.youtube.com/watch?v=gJ-WmYn_9GE
    window._modally_video_re = {};
    window._modally_video_re.YOUTUBE = /(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/ ]{11})/i;
    window._modally_video_re.VIMEO = /(?:www\.|player\.)?vimeo.com\/(?:channels\/(?:\w+\/)?|groups\/(?:[^\/]*)\/videos\/|album\/(?:\d+)\/video\/|video\/|)(\d+)(?:[a-zA-Z0-9_\-]+)?/i;
    window._modally_video_re.VIDEO = /(.*\/[^\/]+\.mp4|ogg|ogv|ogm|webm|avi)\s?$/i;
  //TODO: add support for brightcove and cloudfront
  //TODO: automatic video modal detection

  window._modally_index = {};

    var Modally = function(id, elem, params) {
        var self = this;
        this.id = id;
        this.$element = $(elem);
        this.params = params;
        this.initial_z_index = null;

        if (this.params === undefined || this.params === null) {
            this.params = {};
        }


        var defaults = {
            'landing': 'body',
            'max-width': 'none',
      'classes': '',
            'vertical-align': 'middle',
            'close-parent': false,
            'close-other': false,
            'image': false,
            'video': false,
            'autoplay': true,
            'template': '<div class="modally-wrap"><div class="modally-table"><div class="modally-cell"><div class="modally-underlay modally-close"></div><div class="modally" role="dialog" aria-modal="true"><button tabindex="1" class="modally-close modally-close-button">&times;</button><div class="modally-content"></div></div></div></div></div>',
            'in-duration': 'normal',
            'in-easing': 'swing',
            'out-duration': 'normal',
            'out-easing': 'swing',
            'in-css': null, //TODO: css animation
            'out-css': null //TODO: css animation
        };

        // TODO: maybe image lightbox - you have the old code you did for a mexican guy in 2012
        // TODO: responsive triggers (needs deep extend)
        // TODO: make a modal manager class, should solve the bulky code on open and close - will also enable to reopen the closed parent
        // TODO: iframe modal

        function __init__() {
            for (var k in defaults) {
                //load in defaults
          if (!self.params.hasOwnProperty(k)) {
            self.params[k] = defaults[k];
          }

                //check for inline properties - not deep
                if (self.$element.length) {
                    var attr = self.$element.attr('modally-'+k)

                    if (attr) {
                        if (k === 'max-width' && attr !== 'none') {
                            attr = parseInt(attr, 10);
                        }

                        if (k === 'close-parent' && attr === 'false') {
                            attr = false;
                        }

                        self.params[k] = attr;
                    }
                }
        }
            self.$template = $(self.params.template);

            //setup
            self.$template.find('.modally').css({
                'max-width': self.params['max-width']
            });

            self.$template.find('.modally-cell').css({
                'vertical-align': self.params['vertical-align']
            });

            if (self.$element.length) {
                self.$element.data('modally', self);

                if (self.$element.hasClass('modally-init')) {
                  self.$element.removeClass('modally-init');
                }
                self.$element.show();
            }
            self.$template.data('modally', self);
            self.$template.addClass(self.params['classes']);

            if (self.params.video) {
                self.$spacer = $('<svg aria-hidden="true" width="1920" height="1080"></svg>');
                var ymod = '';
                var vmod = '';
                var vidmod = '';
                if (self.params.autoplay) {
                    ymod = 'autoplay=1&amp;';
                    vmod = 'autoplay=1';
                    vidmod = ' autoplay';
                }
                self.$embeds = $('<iframe class="youtube embed-template template" data-src="https://www.youtube.com/embed/{ID}?'+ymod+'autohide=1&amp;fs=1&amp;rel=0&amp;hd=1&amp;wmode=opaque&amp;enablejsapi=1" type="text/html" width="1920" height="1080" allow="autoplay" frameborder="0" vspace="0" hspace="0" webkitallowfullscreen="" mozallowfullscreen="" allowfullscreen="" scrolling="auto"></iframe><iframe class="vimeo embed-template template" title="vimeo-player" data-src="https://player.vimeo.com/video/{ID}?'+vmod+'" type="text/html" width="1920" height="1080" allow="autoplay; allowfullscreen" rameborder="0" allowfullscreen=""></iframe><video height="1920" width="1080" class="video embed-template template" data-src="{ID}" controls playsinline'+vidmod+'></video>');
                self.$template.find('.modally-content').append('<div class="iframe-landing"></div>');
                self.$template.find('.iframe-landing').append(self.$spacer);
                self.$spacer.css({'width': '100%', 'display': 'block', 'height': 'auto'});
                self.$template.append(self.$embeds);
                self.$embeds.hide();
                self.$template.addClass('video-embed');
            } else if (self.params.image) {
              self.$template.find('.modally-content').append('<div class="image-landing"><img style="width: 100%; height: auto;" decoding="async" loading="lazy" alt="" /></div>');
              self.$template.addClass('image-embed');
            } else {
                if (self.$element.length) {
                    var ghost = self.$element.detach();
                    self.$template.find('.modally-content').append(ghost);
                }
            }

            self.$template.addClass(self.id);
            self.$template.find('.modally-close').on('click', function(){
                self.close();
            });

            $(self.params.landing).append(self.$template);

            if (self.initial_z_index === null) {
                self.initial_z_index = self.$template.css('z-index');
            }

            var event_elem = self.$element.length ? self.$element : $(document);
            event_elem.trigger('modally:init', [self]);
            $(document).trigger('modally:init:'+self.id, [self]);
      window._modally_index[id] = self;
        }
        __init__();
    };

    //XXX: This code sucks - REFACTOR
    Modally.prototype.open = function(e, callback) {
        var $parent_modally = null;

    if (e && !e.hasOwnProperty('currentTarget')) {
      e  = $(e);
    }

    if (e && e.hasOwnProperty('currentTarget')) {
      $parent_modally = $(e.currentTarget).closest('.modally-wrap');
    } else {
      $parent_modally = $(e).closest('.modally-wrap'); //XXX: ???
    }

        var self = this;
        $('body').addClass('modally-open modally-'+this.id);

        $('.modally-wrap.open').removeClass('last');
        this.$template.addClass('open last');

        function run_open(e, self) {
            if (self.params.video) {
                var link = null;

        if (e && e.hasOwnProperty('currentTarget')) {
          link = $(e.currentTarget).data('video');
        } else {
          var url_pts = /video=([^&]+)/gi.exec(window.location.hash);
          if (url_pts && url_pts.length && url_pts[1] !== '') {
            link = url_pts[1];
          }
        }

                var pts = [];
                var link_type = null;

          for (var k in window._modally_video_re) {
            var reg = window._modally_video_re[k];

            var pts_tmp = reg.exec(link);

            if (pts_tmp && pts_tmp.length && pts_tmp[1] !== '') {
               pts = pts_tmp;
              link_type = k;
              break;
            }

          reg.lastIndex = 0;
          }

                if (pts && pts.length) {
                    var id = pts[1];
                    var $temp = self.$template.find('.embed-template.template.'+link_type.toLowerCase()).clone();
                    $temp.removeClass('template');
                    $temp.show();
                    var srctemp = $temp.data('src');
                    var src = srctemp.replace('{ID}', id);
                    $temp.attr('src', src);
                    self.$template.find('.iframe-landing').append($temp);
                }
            }

            if (self.params.image) {
              link = $(e.currentTarget).data('image');
              self.$template.find('.image-landing img').attr('src', link);
            }

            $('html, .modally-wrap').disableScroll();

            if (window.hasOwnProperty('iNoBounce')) {
                iNoBounce.enable();
            }

            if (self.$element.length) {
                self.$element.trigger('modally:opening', e, self);
            }
            self.$template.trigger('modally:opening', e, self);
            $(document).trigger('modally:opening:'+self.id, [e, self]);

            self.$template.stop(true).fadeIn(self.params['in-duration'], self.params['in-easing'], function(){
                if (self.$element.length) {
                    self.$element.trigger('modally:opened', e, self);
                }
                self.$template.trigger('modally:opened', e, self);
                $(document).trigger('modally:opened:'+self.id, [e, self]);

                if (callback && typeof callback === 'function') {
                    callback();
                }
            });
        }

        if ($parent_modally.length) {
            var data = $parent_modally.data('modally');

            if (this.params.close_parent) {
                data.close(e, function() {
                    run_open(e, self);
                });
                return this;
            }

            this.temp_parent = data;
            this.$template.css('z-index', data.initial_z_index + 1);
        }

        run_open(e, this);

        return this;
    };

    Modally.prototype.close = function(e, callback) {
        var self = this;

        if (this.$element.length) {
            this.$element.trigger('modally:closing', e, this);
        }
        this.$template.trigger('modally:closing', e, this);
        $(document).trigger('modally:closing:'+this.id, [e, this]);

        this.$template.stop(true).fadeOut(self.params['out-duration'], self.params['out-easing'], function() {
            if (self.$element.length) {
                self.$element.trigger('modally:closed', e, self);
            }
            self.$template.trigger('modally:closed', e, self);
            $(document).trigger('modally:closed:'+self.id, [e, self]);

            if (callback && typeof callback === 'function') {
                callback();
            }
        });

        $('html, .modally-wrap').enableScroll();

        if (window.hasOwnProperty('iNoBounce')) {
            iNoBounce.disable();
        }
        this.$template.removeClass('open');

        if (this.$template.hasClass('last') && this.temp_parent) {
            this.temp_parent.$template.addClass('last');
            this.$template.removeClass('last');
            delete this.temp_parent;
        }

        if (!$('.modally-wrap.open').length) {
            $('.modally-wrap').removeClass('last');
            $('body').removeClass('modally-open');
        }

        if (this.params.video) {
            this.$template.find('.iframe-landing iframe, .iframe-landing video').remove();
        }

        /*
        if (this.params.image) {
            this.$template.find('.image-landing img').removeAttr('src');
        }
        */

        if (this.initial_z_index !== this.$template.css('z-index')) {
            this.$template.css('z-index', this.initial_z_index);
        }


        $('body').removeClass('modally-'+this.id);

        return this;
    };

    $.fn.modally = function(id, params) {

        if (!window.hasOwnProperty('_modally_storage')) {
            window._modally_storage = {};
        }

        var $this = null;

        if (!(this instanceof Window)) {
            $this = $(this);

            if (id === undefined || id === null) {
                id = $this.attr('id');
            }
        }

        if (id === undefined || id === null || id === '') {
            console.error('jquery.modally >> in order to use this plugin you need to provide a unique ID for each modal manually or automatically throughout target element\'s ID attribute.');
            return $this;
        }

        if (window._modally_storage.hasOwnProperty(id)) {
            console.warn('jquery.modally >> modal with the provided ID: "' + id +'" already exists. Rewriting.');
        }
        window._modally_storage[id] = new Modally(id, $this, params);

    return $this;
    };

    window.modally = $.fn.modally;

    //close last modal on escape
    $(document).on('keyup', function(e) {
    if (e.which === 27) {
      var $last_modally = $('.modally-wrap.open.last');
      if ($last_modally.length) {
         $last_modally.data('modally').close();
      }
    }
    });

    function _modallyTrigger(e, elem, action) {
    var href = null;

    if (typeof elem === 'string') {
      href = elem;
    } else {
      href = $(elem).attr('href');
    }

        if (href === undefined
            || href === null
            || href.length < 2
            || href === '#') {

            if (action === 'close') {
        if (e) {
          var $parent = $(e.currentTarget).closest('.modally-wrap');
                  if ($parent.length) {
                      var data = $parent.data('modally');
                      data.close();
                      return;
                  }
        }
            }

            console.error('jquery.modally >> href attribute needs to contain the existing modal ID');
            return;
        }

        if (/^#/ig.test(href) && href.length > 1) {
            href = href.replace('#', '');
        }

        if (window.hasOwnProperty('_modally_storage')
      && window._modally_storage.hasOwnProperty(href)) {

            window._modally_storage[href][action](e);
        } else {
            console.error('jquery.modally >> no modal registered by provided ID: ' + href);
        }
    }

    function _modallyTriggerOpen(e) {
        e.preventDefault();
        _modallyTrigger(e, this, 'open');
    }

    function _modallyTriggerClose(e) {
        e.preventDefault();
        _modallyTrigger(e, this, 'close');
    }

    $(document).on('click', '[target="_modal"]:not([disabled])', _modallyTriggerOpen);
    $(document).on('click', '[target="_modal:open"]:not([disabled])', _modallyTriggerOpen);
    $(document).on('click', '[target="_modal:close"]:not([disabled])', _modallyTriggerClose);

  function modallyHashCheck() {
    if (window.location.hash !== ''
      && window.location.hash !== '#') {
      var href = window.location.hash;

      var url_pts = /^#([a-z\_\-]+[a-z0-9\_\-]*)/gi.exec(window.location.hash);
      if (url_pts && url_pts.length && url_pts[1].length) {
        href = url_pts[1];
      }

      if (window._modally_index.hasOwnProperty(href)) {
        _modallyTrigger(null, href, 'open');
      }
    }
  }

  $(document).ready(function() {
    $('.modally-init').each(function(){
      $(this).modally();
    });

    modallyHashCheck();
  });

  $(window).on('hashchange', function() {
    modallyHashCheck();
  });
})(jQuery);
