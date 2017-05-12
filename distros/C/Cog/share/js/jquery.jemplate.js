/*
 * jQuery Jemplate adapter, version 0.1 (2011-04-01)
 *
 * http://jemplate.net
 *
 * Copyright(c) 2011 Ingy döt Net
 *
 * Dual licensed under the MIT and GPL licenses:
 * http://www.opensource.org/licenses/mit-license.php
 * http://www.gnu.org/licenses/gpl.html
 */
(function($) {
    $.jemplate = function(template, data) {
        return Jemplate.process(template, data);
    };
    $.fn.jemplate = function(template, data, method) {
        return this[method || 'html']($.jemplate(template, data));
    };
})(jQuery);
