//-----------------------------------------------------
// Some extensions to the prototype javascript framework
//-----------------------------------------------------

// fire value:change event when setValue method
// is used to change the value of a Form Element
Form.Element.Methods.setValue = Form.Element.Methods.setValue.wrap(
    function($p, element, value) {
        var oldvalue = $F(element);
        var _return = $p(element, value);
        element.fire('value:change', {oldvalue: oldvalue, newvalue: value});
        return _return;
    }
);
Element.addMethods();

// adds the method flash to SPAN, DIV, INPUT, BUTTON elements
// flashes an element by adding a classname for a brief moment of time
// options: {classname: // classname to add (default: flash)
//           duration:  // duration in ms to keep the classname (default: 100ms)}
var _element_list = ['DIV', 'INPUT',
                    'BUTTON', 'TEXTAREA', 'A',
                    'H1', 'H2', 'H3', 'H4', 'H5'];
// for the moment, SPAN not supported on WebKit (see prototype.js bug  in
// https://prototype.lighthouseapp.com/projects/8886/tickets/976-elementaddmethodsspan-fails-on-webkit)
if (!Prototype.Browser.WebKit) _element_list.push('SPAN');
Element.addMethods(_element_list, {
    flash: function(element, options) {
        if (element._IS_FLASHING) return;
        element = $(element);

        options = options || {};
        var duration  = options.duration  || 100;
        var classname = options.classname || 'flash';

        element._IS_FLASHING = true;

        var endFlash  = function() {
            this.removeClassName(classname);
            this._IS_FLASHING = false;
        };

        element.addClassName(classname);
        setTimeout(endFlash.bind(element), duration);
    }
});

// utilities for hash

// expands flat hash into a multi-level deep hash
// javascript version of Perl  CGI::Expand::expand_hash
Hash.expand = function(flat_hash) {
  var tree = {};

  // iterate on keys in the flat hash
  for (var k in flat_hash) {
    var parts = k.split(/\./);
    var loop = {tree: tree, key: "root"};

    // iterate on path parts within the key
    for (var i = 0 ; i < parts.length; i++) {
      var part = parts[i];

      // if no subtree yet, build it (Array or Object)
      if (!loop.tree[loop.key])
      loop.tree[loop.key] = part.match(/^\d+$/) ? [] : {};

      // walk down to subtree
      loop = {tree: loop.tree[loop.key], key:part};
    }
    // store value in leaf
    loop.tree[loop.key] = flat_hash[k];
  }

  return tree.root;
}

// collapses deep hash into a one level hash
Hash.flatten = function(deep_hash, prefix, tree) {
  tree = tree   || {};

  for (var i in deep_hash) {
    var v = deep_hash[i];
    var new_prefix = prefix? prefix + '.' + i : i;
    switch (typeof(v)) {
        case "function": continue; break;
        case "object"  : Hash.flatten(v, new_prefix, tree); break;
        case "string"  :
        case "number"  : tree["" + new_prefix + ""] = v; break;
        default        : break;
    }
  }
  return tree;
}

// utilities for string

Object.extend(String.prototype, {
  chomp: function() {
    return this.replace(/(\n|\r)+$/, '');
  }
});

Object.extend(Element, {

  classRegExp : function(wanted_classes) {
    if (typeof wanted_classes != "string" &&
        wanted_classes instanceof Array)
       wanted_classes = wanted_classes.join("|");
    return new RegExp("\\b(" + wanted_classes + ")\\b");
  },

  hasAnyClass: function (elem, wanted_classes) {
    return Element.classRegExp(wanted_classes).test(elem.className);
  },

  getElementsByClassNames: function(parent, wanted_classes) {
    var regexp = Element.classRegExp(wanted_classes);
    var children = ($(parent) || document.body).getElementsByTagName('*');
    var result = [];
    for (var i = 0; i < children.length; i++) {
      var child = children[i];
      if (regexp.test(child.className)) result.push(child);
    }
    return result;
  },

  // start at elem, walk nav_property until find any of wanted_classes
  navigateDom: function (elem, navigation_property,
                         wanted_classes, stop_condition) {
    while (elem){
       if (stop_condition && stop_condition(elem)) break;
       if (elem.nodeType == 1 &&
           Element.hasAnyClass(elem, wanted_classes))
         return $(elem);
       // else walk to next element
       elem = elem[navigation_property];
     }
     return null;
  },


  autoScroll: function(elem, container, percentage) {
    percentage = percentage || 20; // default
    container  = container  || elem.offsetParent;

    var offset = elem.offsetTop;
    var firstElementChild = container.firstElementChild
                          || $(container).firstDescendant();

    if (firstElementChild) {
      var first_child_offset = firstElementChild.offsetTop;
      if (first_child_offset == container.offsetTop)
        offset -= first_child_offset;
    }

    var min = offset - (container.clientHeight * (100-percentage)/100);
    var max = offset - (container.clientHeight * percentage/100);

    if      (container.scrollTop < min) container.scrollTop = min;
    else if (container.scrollTop > max) container.scrollTop = max;
  },

  outerHTML: function(elem) {
    var tag = elem.tagName;
    if (!tag)
      return elem;           // not an element node
    if (elem.outerHTML)
      return elem.outerHTML; // has builtin implementation
    else {
      var attrs = elem.attributes;
      var str = "<" + tag;
      for (var i = 0; i < attrs.length; i++) {
        var val = attrs[i].value;
        var delim = val.indexOf('"') > -1 ? "'" : '"';
        str += " " + attrs[i].name + "=" + delim + val + delim;
      }
      return str + ">" + elem.innerHTML + "</" + tag + ">";
    }
  }

});

Class.checkOptions = function(defaultOptions, ctorOptions) {
  ctorOptions = ctorOptions || {}; // options passed to the class constructor
  for (var property in ctorOptions) {
    if (defaultOptions[property] === undefined)
      throw new Error("unexpected option: " + property);
  }
  return Object.extend(Object.clone(defaultOptions), ctorOptions);
};


Object.extend(Event, {

  detailedStop: function(event, toStop) {
    if (toStop.preventDefault) {
      if (event.preventDefault) event.preventDefault();
      else                      event.returnValue = false;
    }
    if (toStop.stopPropagation) {
      if (event.stopPropagation) event.stopPropagation();
      else                       event.cancelBubble = true;
    }
  },

  stopAll:  {stopPropagation: true, preventDefault: true},
  stopNone: {stopPropagation: false, preventDefault: false}

});

function ASSERT (cond, msg) {
  if (!cond)
    throw new Error("Violated assertion: " + msg);
}

// detects if a global CSS_PREFIX has been set
// if yes, use it to prefix the css classes
// default to gva
function CSSPREFIX () {
    if(typeof CSS_PREFIX != 'undefined') {
        return (CSS_PREFIX)? CSS_PREFIX : 'gva';
    }
    return 'gva';
}

/**
 *
 * Cross-Browser Split 1.0.1 
 * (c) Steven Levithan <stevenlevithan.com>; MIT License
 * in order to fix a bug with String.prototype.split(RegExp) and Internet Explorer
 * [http://blog.stevenlevithan.com/archives/cross-browser-split]
 * An ECMA-compliant, uniform cross-browser split method
 *
 * */

var cbSplit;

// avoid running twice, which would break `cbSplit._nativeSplit`'s reference to the native `split`
if (!cbSplit) {

cbSplit = function (str, separator, limit) {
    // if `separator` is not a regex, use the native `split`
    if (Object.prototype.toString.call(separator) !== "[object RegExp]") {
        return cbSplit._nativeSplit.call(str, separator, limit);
    }

    var output = [],
        lastLastIndex = 0,
        flags = (separator.ignoreCase ? "i" : "") +
                (separator.multiline  ? "m" : "") +
                (separator.sticky     ? "y" : ""),
        separator = RegExp(separator.source, flags + "g"), // make `global` and avoid `lastIndex` issues by working with a copy
        separator2, match, lastIndex, lastLength;

    str = str + ""; // type conversion
    if (!cbSplit._compliantExecNpcg) {
        separator2 = RegExp("^" + separator.source + "$(?!\\s)", flags); // doesn't need /g or /y, but they don't hurt
    }

    /* behavior for `limit`: if it's...
    - `undefined`: no limit.
    - `NaN` or zero: return an empty array.
    - a positive number: use `Math.floor(limit)`.
    - a negative number: no limit.
    - other: type-convert, then use the above rules. */
    if (limit === undefined || +limit < 0) {
        limit = Infinity;
    } else {
        limit = Math.floor(+limit);
        if (!limit) {
            return [];
        }
    }

    while (match = separator.exec(str)) {
        lastIndex = match.index + match[0].length; // `separator.lastIndex` is not reliable cross-browser

        if (lastIndex > lastLastIndex) {
            output.push(str.slice(lastLastIndex, match.index));

            // fix browsers whose `exec` methods don't consistently return `undefined` for nonparticipating capturing groups
            if (!cbSplit._compliantExecNpcg && match.length > 1) {
                match[0].replace(separator2, function () {
                    for (var i = 1; i < arguments.length - 2; i++) {
                        if (arguments[i] === undefined) {
                            match[i] = undefined;
                        }
                    }
                });
            }

            if (match.length > 1 && match.index < str.length) {
                Array.prototype.push.apply(output, match.slice(1));
            }

            lastLength = match[0].length;
            lastLastIndex = lastIndex;

            if (output.length >= limit) {
                break;
            }
        }

        if (separator.lastIndex === match.index) {
            separator.lastIndex++; // avoid an infinite loop
        }
    }

    if (lastLastIndex === str.length) {
        if (lastLength || !separator.test("")) {
            output.push("");
        }
    } else {
        output.push(str.slice(lastLastIndex));
    }

    return output.length > limit ? output.slice(0, limit) : output;
};

cbSplit._compliantExecNpcg = /()??/.exec("")[1] === undefined; // NPCG: nonparticipating capturing group
cbSplit._nativeSplit = String.prototype.split;

} // end `if (!cbSplit)`

// for convenience...
String.prototype.split = function (separator, limit) {
    return cbSplit(this, separator, limit);
};


/**
 * Event Delegation
 * Based on http://code.google.com/p/protolicious/source/browse/trunk/src/event.register.js
 * modified to support focus/blur event capturing
 * [http://www.quirksmode.org/blog/archives/2008/04/delegating_the.html]
 *
 * Prototype core is supposed to have this in v 1.7 !
 * Naming might differ, Event.register -> Event.delegate but at least
 * will have the same syntax
 */
// wrap in an anonymous function to avoid any variable conflict
(function() {
  var rules = { };
  var exprSplit = function(expression) {
    var expressions = [];
    expression.scan(/(([\w#:.~>+()\s-]+|\*|\[.*?\])+)\s*(,|$)/, function(m) {
      expressions.push(m[1].strip());
    });
    return expressions;
  }
  var eventManager = function(o_id, event) {
    // IE sometimes fires some events
    // while reloading (after unregister)
    if(! rules[o_id]) return;

    var element = event.target;
    var eventType = (event.memo)? event.eventName : event.type;
    do {
      if (element.nodeType == 1) {
        element = Element.extend(element);
        for (var selector in rules[o_id][eventType]) {
          if (_match = matches(rules[o_id][eventType][selector]._selector, element)) {
            for (var i=0, handlers=rules[o_id][eventType][selector], l=handlers.length; i<l; ++i) {
              handlers[i].call(element, Object.extend(event, { _target: element, _match: _match }));
            }
          }
        }
      }
    } while (element = element.parentNode)
  }
  var matches = function(selectors, element) {
    for (var i=0, l=selectors.length; i<l; ++i) {
      if (Prototype.Selector.match(element, selectors[i])) return selectors[i];
    }
    return undefined;
  }

  Event.register = function(observer, selector, eventName, handler) {
    var use_capture = (eventName == 'focus' || eventName == 'blur');
    if(use_capture && Prototype.Browser.IE) {
        eventName = (eventName == 'focus')? 'focusin' : 'focusout';
    }
    var observer_id = observer.identify ? observer.identify() : 'document';

    // create entry in cache for rules per observer
    if(! rules[observer_id]) {
        rules[observer_id] = { };
    }

    // observe event only once on the same observer
    if(! rules[observer_id][eventName]) {
      rules[observer_id][eventName] = { };

      if(use_capture) {
        if(Prototype.Browser.IE)
        Event.observe(observer, eventName, eventManager.curry(observer_id));
        else
        observer.addEventListener(eventName, eventManager.curry(observer_id), true);
      }
      else
      Event.observe(observer, eventName, eventManager.curry(observer_id));
    }

    var _selector = [ ], expr = selector.strip();
    // instantiate Selector's
    exprSplit(selector).each(function(s) { _selector.push(s) })

    // store instantiated Selector for faster matching
    if (!rules[observer_id][eventName][expr]) {
      rules[observer_id][eventName][expr] = Object.extend([ ], { _selector: _selector });
    }

    // associate handler with expression
    rules[observer_id][eventName][expr].push(handler);
  }

  // unregistering an event on an elemment
  Event.unregister = function(elt, selector, eventName) {
    var _id = (typeof elt == 'string')? elt :
              (elt.identify)? elt.identify() : 'document';
    // unregister event identified by name and selector
    if (eventName) {
      rules[_id][eventName][selector] = null;
      delete rules[_id][eventName][selector];
    }
    else {
      for (var eventName in rules[_id]) {
        // unregister all events identified by selector
        if(selector) {
          rules[_id][eventName][selector] = null;
          delete rules[_id][eventName][selector];
        }
        // unregister all events
        else {
          rules[_id][eventName] = null;
          delete rules[_id][eventName];
        }
      }
    }
  },

  // unregister *all* events registered using
  // the Event.register method
  Event.unregisterAll = function() {
    for(var _id in rules) {
        Event.unregister(_id);
        delete rules[_id];
    }
  }

  Event.observe(window, 'unload', Event.unregisterAll);
  document.register = Event.register.curry(document);
  Element.addMethods({register: Event.register, unregister: Event.unregister});
})();

// based on:
// getJSON function by Juriy Zaytsev
// http://github.com/kangax/protolicious/tree/master/get_json.js
(function(){
  var id = 0, head = $$('head')[0];
  Prototype.getJSON = function(url, callback) {
    var script = document.createElement('script'), token = '__jsonp' + id;

    // callback should be a global function
    window[token] = callback;

    // url should have "?2" parameter which is to be replaced with a global callback name
    script.src = url.replace(/\?(&|$)/, '__jsonp' + id + '$1');

    // clean up on load: remove script tag, null script variable and delete global callback function
    script.onload = function() {
      script.remove();
      script = null;
      delete window[token];
    };
    head.appendChild(script);

    // callback name should be unique
    id++;
  }
})();
