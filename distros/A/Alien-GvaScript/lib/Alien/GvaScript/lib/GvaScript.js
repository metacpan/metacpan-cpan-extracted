/*-------------------------------------------------------------------------*
 * GvaScript - Javascript framework born in Geneva.
 *
 *  Authors: Laurent Dami            <laurent.d...@etat.ge.ch>
 *           Mona Remlawi
 *           Jean-Christophe Durand
 *           Sebastien Cuendet

 *  LICENSE
 *  This library is free software, you can redistribute it and/or modify
 *  it under the same terms as Perl's artistic license.
 *
 *--------------------------------------------------------------------------*/

var GvaScript = {
  Version: '1.44',
  REQUIRED_PROTOTYPE: '1.7',
  load: function() {
    function convertVersionString(versionString) {
      var v = versionString.replace(/_.*|\./g, '');
      v = parseInt(v + '0'.times(4-v.length));
      return versionString.indexOf('_') > -1 ? v-1 : v;
    }
    if((typeof Prototype=='undefined') ||
       (typeof Element == 'undefined') ||
       (typeof Element.Methods=='undefined') ||
       (convertVersionString(Prototype.Version) <
        convertVersionString(GvaScript.REQUIRED_PROTOTYPE)))
       throw("GvaScript requires the Prototype JavaScript framework >= " +
        GvaScript.REQUIRED_PROTOTYPE);
  }
};

GvaScript.load();

//----------protoExtensions.js
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

//----------event.js
// array holding fired events that are pending to be executed
// useful for avoiding accidental double firing of events
// events in queue are unique per eventType&eventTarget
GvaScript.eventsQueue = Class.create();
Object.extend(GvaScript.eventsQueue, {
    _queue: $A([]),
    hasEvent: function(target, name) {
        return (typeof this._queue.find(function(e) {
            return (e.target == target && e.name == name);
        }) == 'object');
    },
    pushEvent: function(target, name) {
        this._queue.push({target: target, name: name});
    },
    popEvent: function(target, name) {
        this._queue = this._queue.reject(function(e) {
            return (e.target == target && e.name == name);
        });
    }
});

// fireEvent : should be COPIED into controller objects, so that
// 'this' is properly bound to the controller

GvaScript.fireEvent = function(/* type, elem1, elem2, ... */) {

  var event;

  switch (typeof arguments[0]) {
  case "string" :
    event = {type: arguments[0]};
    break;
  case "object" :
    event = arguments[0];
    break;
  default:
    throw new Error("invalid first argument to fireEvent()");
  }

  var propName = "on" + event.type;
  var handler;
  var target   = arguments[1]; // first element where the event is triggered
  var currentTarget;           // where the handler is found

  // event already fired and executing
  if(GvaScript.eventsQueue.hasEvent(target, event.type)) return;

  // try to find the handler, first in the HTML elements, then in "this"
  for (var i = 1, len = arguments.length; i < len; i++) {
    var elem = arguments[i];
    if (handler = elem.getAttribute(propName)) {
      currentTarget = elem;
      break;
    }
  }
  if (currentTarget === undefined)
    if (handler = this[propName])
      currentTarget = this;

  if (handler) {
    // build context and copy into event structure
    var controller = this;
    if (!event.target)        event.target        = target;
    if (!event.srcElement)    event.srcElement    = target;
    if (!event.currentTarget) event.currentTarget = currentTarget;
    if (!event.controller)    event.controller    = controller;

    // add the event to the queue, it's about to be fired
    GvaScript.eventsQueue.pushEvent(target, event.type);

    var event_return = null; // return value of event execution
    if (typeof(handler) == "string") {
      // string will be eval-ed in a closure context where 'this', 'event',
      // 'target' and 'controller' are defined.
      var eval_handler = function(){return eval( handler ) };
      handler = eval_handler.call(currentTarget); // target bound to 'this'
    }

    if (handler instanceof Function) {
      // now call the eval-ed or pre-bound handler
      event_return = handler(event);
    }
    else {
      // whatever was returned by the string evaluation
      event_return = handler;
    }

    // event executed, pop from the queue
    // keep a safety margin of 1sec before allowing
    // the same event on the same element to be refired
    // TODO: is 1sec reasonable
    window.setTimeout(function() {
        GvaScript.eventsQueue.popEvent(target, event.type)
    }, 1000);

    return event_return;
  }
  else
    return null; // no handler found
};


//----------keyMap.js

//constructor
GvaScript.KeyMap = function (rules) {
    if (!(rules instanceof Object)) throw "KeyMap: invalid argument";
    this.rules = [rules];
    return this;
};


GvaScript.KeyMap.prototype = {
  destroy: function() {
    Event.stopObserving(this.elem, this.eventType, this.eventHandler);
  },

  eventHandler: function(event) {
    var keymap = this;

    // translate key code into key name
    event.keyName = GvaScript.KeyMap.KEYS.BUILTIN_NAMES[event.keyCode]
                 || String.fromCharCode(event.keyCode);

    // add Control|Shift|Alt modifiers
    event.keyModifiers = "";
    if (event.ctrlKey  && !this.options.ignoreCtrl)  event.keyModifiers += "C_";
    if (event.shiftKey && !this.options.ignoreShift) event.keyModifiers += "S_";
    if (event.altKey   && !this.options.ignoreAlt)   event.keyModifiers += "A_";

    // but cancel all modifiers if main key is Control|Shift|Alt
    if (event.keyName.search(/^(CTRL|SHIFT|ALT)$/) == 0)
      event.keyModifiers = "";

    // try to get the corresponding handler, and call it if found
    var handler = keymap._findInStack(event, keymap.rules);
    if (handler) {
      var toStop = handler.call(keymap, event);
      Event.detailedStop(event, toStop || this.options);
    }
  },

  observe: function(eventType, elem, options) {
    this.eventType = eventType || 'keydown';
    this.elem      = elem      || document;

    // "Shift" modifier usually does not make sense for keypress events
    if (eventType == 'keypress' && !options)
      options = {ignoreShift: true};

    this.options = Class.checkOptions(Event.stopNone, this.options || {});

    this.eventHandler = this.eventHandler.bindAsEventListener(this);
    Event.observe(this.elem, this.eventType, this.eventHandler);
  },

  _findInStack: function(event, stack) {
    for (var i = stack.length - 1; i >= 0; i--) {
      var rules = stack[i];

      // trick to differentiate between C_9 (digit) and C_09 (TAB)
      var keyCode = event.keyCode>9 ? event.keyCode : ("0"+event.keyCode);

      var handler = rules[event.keyModifiers + event.keyName]
                 || rules[event.keyModifiers + keyCode]
                 || this._regex_handler(event, rules.REGEX, true)
                 || this._regex_handler(event, rules.ANTIREGEX, false);
      if (handler)
        return handler;
    }
    return null;
  },

  _regex_handler: function(event, regex_rules, want_match) {
    if (!regex_rules) return null;
    for (var j = 0; j < regex_rules.length; j++) {
      var rule      = regex_rules[j];
      var modifiers = rule[0];
      var regex     = rule[1];
      var handler   = rule[2];

      var same_modifiers = modifiers == null
                        || modifiers == event.keyModifiers;

      // build regex if it was passed as a string
      if (typeof(regex) == "string")
        regex = new RegExp("^(" + regex + ")$");

      var match = same_modifiers && regex.test(event.keyName);
      if ((match && want_match) || (!match && !want_match))
        return handler;
    }
    return null;
  }
};

GvaScript.KeyMap.MapAllKeys = function(handler) {
    return {REGEX:[[null, /.*/, handler]]}
};


GvaScript.KeyMap.Prefix = function(rules) {

    // create a specific handler for the next character ...
    var one_time_handler = function (event) {
        this.rules.pop(); // cancel prefix
        var handler = this._findInStack(event, [rules]);
        if (handler) handler.call(this, event);
    }

    // ... and push that handler on top of the current rules
    return function(event) {
        this.rules.push(GvaScript.KeyMap.MapAllKeys(one_time_handler));
    }
};

// helpers for identifying keys
GvaScript.KeyMap.KEYS = {
    BUILTIN_NAMES : {
        8: "BACKSPACE",
        9: "TAB",
        10: "LINEFEED",
        13: "RETURN",
        16: "SHIFT",
        17: "CTRL",
        18: "ALT",
        19: "PAUSE",
        20: "CAPS_LOCK",
        27: "ESCAPE",
        32: "SPACE",
        33: "PAGE_UP",
        34: "PAGE_DOWN",
        35: "END",
        36: "HOME",
        37: "LEFT",
        38: "UP",
        39: "RIGHT",
        40: "DOWN",
        44: "PRINT_SCREEN", // MSIE6.0: will only fire on keyup!
        45: "INSERT",
        46: "DELETE",
        91: "WINDOWS",
        96: "KP_0",
        97: "KP_1",
        98: "KP_2",
        99: "KP_3",
        100: "KP_4",
        101: "KP_5",
        102: "KP_6",
        103: "KP_7",
        104: "KP_8",
        105: "KP_9",
        106: "KP_STAR",
        107: "KP_PLUS",
        109: "KP_MINUS",
        110: "KP_DOT",
        111: "KP_SLASH",
        112: "F1",
        113: "F2",
        114: "F3",
        115: "F4",
        116: "F5",
        117: "F6",
        118: "F7",
        119: "F8",
        120: "F9",
        121: "F10",
        122: "F11",
        123: "F12",
        144: "NUM_LOCK",
        145: "SCROLL_LOCK",
        190: "DOT"
    },
    META_KEYS: {
        8   : 'KEY_BACKSPACE',
        9   : 'KEY_TAB',
        13  : 'KEY_RETURN',
        27  : 'KEY_ESC',
        37  : 'KEY_LEFT',
        38  : 'KEY_UP',
        39  : 'KEY_RIGHT',
        40  : 'KEY_DOWN',
        46  : 'KEY_DELETE',
        36  : 'KEY_HOME',
        35  : 'KEY_END',
        33  : 'KEY_PAGEUP',
        34  : 'KEY_PAGEDOWN',
        45  : 'KEY_INSERT',
        112 : "F1",
        113 : "F2",
        114 : "F3",
        115 : "F4",
        116 : "F5",
        117 : "F6",
        118 : "F7",
        119 : "F8",
        120 : "F9",
        121 : "F10",
        122 : "F11",
        123 : "F12"
    }
}

//----------treeNavigator.js
//-----------------------------------------------------
// Constructor
//-----------------------------------------------------

GvaScript.TreeNavigator = function(elem, options) {

  // fix bug of background images on dynamic divs in MSIE 6.0, see URLs
  // http://www.bazon.net/mishoo/articles.epl?art_id=958
  // http://misterpixel.blogspot.com/2006/09/forensic-analysis-of-ie6.html
  try { document.execCommand("BackgroundImageCache",false,true); }
  catch(e) {};

  elem = $(elem); // in case we got an id instead of an element
  options = options || {};

  // default options
  var defaultOptions = {
    tabIndex            : -1,
    treeTabIndex        :  0,
    flashDuration       : 200,     // milliseconds
    flashColor          : "red",
    selectDelay         : 100,     // milliseconds
    selectOnButtonClick : true,
    noPingOnFirstClick  : false,
    selectFirstNode     : true,
    createButtons       : true,
    scrollingContainer  : elem.ownerDocument.documentElement,
    autoScrollPercentage: 20,
    classes             : {},
    keymap              : null
  };

  this.options = Class.checkOptions(defaultOptions, options);

  // values can be single class names or arrays of class names
  var defaultClasses = {
    node     : "TN_node",
    leaf     : "TN_leaf",
    label    : "TN_label",
    closed   : "TN_closed",
    content  : "TN_content",
    selected : "TN_selected",
    mouse    : "TN_mouse",
    button   : "TN_button",
    showall  : "TN_showall"
  };
  this.classes = Class.checkOptions(defaultClasses, this.options.classes);
  this.classes.nodeOrLeaf = [this.classes.node, this.classes.leaf].flatten();

  // connect to the root element
  this.rootElement = elem;

  // add buttons and tabIndex to labels
  this.initSubTree(elem);

  // tree-wide navigation handlers
  this._addHandlers();
  // tree-wide tabbing handlers
  this._addTabbingBehaviour();

  // initializing the keymap
  var keyHandlers = {
    DOWN:       this._downHandler   .bindAsEventListener(this),
    UP:         this._upHandler     .bindAsEventListener(this),
    LEFT:       this._leftHandler   .bindAsEventListener(this),
    RIGHT:      this._rightHandler  .bindAsEventListener(this),
    KP_PLUS:    this._kpPlusHandler .bindAsEventListener(this),
    KP_MINUS:   this._kpMinusHandler.bindAsEventListener(this),
    KP_STAR:    this._kpStarHandler .bindAsEventListener(this),
    KP_SLASH:   this._kpSlashHandler.bindAsEventListener(this),
    C_R:        this._ctrl_R_handler.bindAsEventListener(this),
    RETURN:     this._ReturnHandler .bindAsEventListener(this),
    C_KP_STAR:  this._showAll       .bindAsEventListener(this, true),
    C_KP_SLASH: this._showAll       .bindAsEventListener(this, false),
    HOME:       this._homeHandler   .bindAsEventListener(this),
    END:        this._endHandler    .bindAsEventListener(this),

    C_PAGE_UP  : this._ctrlPgUpHandler  .bindAsEventListener(this),
    C_PAGE_DOWN: this._ctrlPgDownHandler.bindAsEventListener(this),

    REGEX      : [[ "", /^\w$/, this._charHandler.bindAsEventListener(this) ]]
  };

  if (this.options.tabIndex >= 0)
    keyHandlers["TAB"] = this._tabHandler.bindAsEventListener(this);

  // handlers for ctrl_1, ctrl_2, etc. to open the tree at that level
  var numHandler = this._chooseLevel.bindAsEventListener(this);
  $R(1, 9).each(function(num){keyHandlers["C_" + num] = numHandler});

  // tabIndex for the tree element
  elem.tabIndex = Math.max(elem.tabIndex, this.options.treeTabIndex);

  this._clear_quick_navi();

  if (options.keymap) {
    this.keymap = options.keymap;
    this.keymap.rules.push(keyHandlers);
  }
  else {
    this.keymap = new GvaScript.KeyMap(keyHandlers);

    // observe keyboard events on tree (preferred) or on document
    var target = (elem.tabIndex  < 0) ? document : elem;
    this.keymap.observe("keydown", target, Event.stopNone);
  }

  this.rootElement.store('widget', this);
  this.rootElement.addClassName(CSSPREFIX() + '-widget');

  // selecting the first node
  if (this.options.selectFirstNode) {
    this.select(this.firstSubNode());

    // if labels do not take focus but tree does, then set focus on the tree
    if (this.options.tabIndex < 0 && elem.tabIndex >= 0)
      elem.focus();
  }
}


GvaScript.TreeNavigator.prototype = {

//-----------------------------------------------------
// Public methods
//-----------------------------------------------------
  destroy: function() {
    this._removeHandlers();
  },

  initSubTree: function (tree_root) {
    tree_root = $(tree_root);
    // get the labels of the sub tree
    var labels = tree_root.select('.'+this.classes.label);

    // add tabIndex per label
    if (this.options.tabIndex >= 0) {
      _idx = this.options.tabIndex;
      labels.each(function(label) {
        label.tabIndex = _idx;
      });
    }

    // add tree navigation buttons per label
    if (this.options.createButtons) {
      var button = document.createElement("span");
      button.className = this.classes.button;

      labels.each(function(label) {
        label.parentNode.insertBefore(button.cloneNode(true), label);
      });
    }
  },

  isClosed: function (node) {
    return Element.hasAnyClass(node, this.classes.closed);
  },

  isVisible: function(elem) { // true if elem is not display:none
    return !(elem.offsetWidth == 0 && elem.offsetHeight == 0);
  },

  isLeaf: function(node) {
    return Element.hasAnyClass(node, this.classes.leaf);
  },

  isRootElement: function(elem) {
    return (elem === this.rootElement);
  },

  isLabel: function(elem) {
    if(elem.hasClassName(this.classes.label))
      return elem;
    else
      return Element.navigateDom(elem, 'parentNode', this.classes.label);
  },

  close: function (node) {
    if (this.isLeaf(node))
      return;
    Element.addClassName(node, this.classes.closed);
    this.fireEvent("Close", node, this.rootElement);
  },

  open: function (node) {
    if (this.isLeaf(node))
      return;

    Element.removeClassName(node, this.classes.closed);

    var node_content = this.content(node);
    // if inline content, adjust scrollbar to make visible (if necessary)
    // FIXME: only works for default scrollingContainer
    if (node_content) {
       this.scrollTo(node, true);
    }
    // ajax content -> go get it
    else {
      this.loadContent(node);
    }

    this.fireEvent("Open", node, this.rootElement);
  },

  toggle: function(node) {
    if (this.isClosed(node))
        this.open(node);
    else
        this.close(node);
  },

  openEnclosingNodes: function (elem) {
    var node = this.enclosingNode(elem);
    while (node) {
      if (this.isClosed(node))
        this.open(node);
      node = this.parentNode(node);
    }
  },

  openAtLevel: function(elem, level) {
    var method = this[(level > 1) ? "open" : "close"];
    var node = this.firstSubNode(elem);
    while (node) {
      method.call(this, node); // open or close
      this.openAtLevel(node, level-1);
      node = this.nextSibling(node);
    }
  },

  loadContent: function (node) {
    var url = node.getAttribute('tn:contenturl');
    // TODO : default URL generator at the tree level

    if (url) {
      var content = this.content(node);
      if (!content) {
        content = document.createElement('div');
        content.className = this.classes.content;
        var content_type = node.getAttribute('content_type');
        if (content_type) content.className += " " + content_type;
        content.innerHTML = "loading " + url;
        node.insertBefore(content, null); // null ==> insert at end of node
      }
      this.fireEvent("BeforeLoadContent", node, this.rootElement);

      var treeNavigator = this; // needed for closure below
      var callback = function() {
        treeNavigator.initSubTree(content);
        treeNavigator.fireEvent("AfterLoadContent", node, this.rootElement);
      };
      new Ajax.Updater(content, url, {onComplete: callback});
      return true;
    }
  },

  select: function (node) {
    var previousNode = this.selectedNode;

    // re-selecting the current node is a no-op
    if (node == previousNode) return;

    // deselect the previously selected node
    if (previousNode) {
        var label = this.label(previousNode);
        if (label) {
          Element.removeClassName(label, this.classes.selected);
        }
    }

    // select the new node
    this.selectedNode = node;
    if (node) {
      this._assertNodeOrLeaf(node, 'select node');
      var label = this.label(node);
      if (!label) {
        throw new Error("selected node has no label");
      }
      else {
        Element.addClassName(label, this.classes.selected);

        if (this.isVisible(label)) {
          // focus has not yet been given to label
          if(! label.hasAttribute('hasFocus'))
            label.focus();
        }
      }
    }

    // cancel if there was any select execution pending
    if (this._selectionTimeoutId) clearTimeout(this._selectionTimeoutId);

    // register code to call the selection handlers after some delay
    var callback = this._selectionTimeoutHandler.bind(this, previousNode);
    this._selectionTimeoutId =
      setTimeout(callback, this.options.selectDelay);
  },

  scrollTo: function(node, with_content) {
    if(!node) return;

    var container = this.options.scrollingContainer;
    if(typeof container == 'string') {
      container = $(container);
    }
    if(!container) return;

    // donot invoke scroll if scrolling is disabled
    // first test if scrolling is enabled on the scrolling container
    if(container.tagName.toLowerCase() == 'html') {
      // on document body
      if(document.body.style.overflow == 'hidden'
        || document.body.style.overflowY == 'hidden'
        || document.body.scroll == 'no') // IE
      return;
    }
    else {
      // on element
      if(container.style.overflow == 'hidden'
        || container.style.overflowY == 'hidden')
      return;
    }

    // test if the node in 'in view'
    _container_y_start = container.scrollTop;
    _container_y_end   = _container_y_start + container.clientHeight;
    _node_y  = Element.cumulativeOffset(node).top + (with_content? node.offsetHeight: 0);

    // calculate padding space between the selected node and
    // the edge of the scrollable container
    _perc = this.options.autoScrollPercentage || 0;
    _padding = container.clientHeight * _perc / 100;

    // calculate delta scroll to affect on scrollingContainer
    _delta = 0;

    // node is beneath scrolling area
    if(_node_y > _container_y_end - _padding) {
      _delta = _node_y - _container_y_end + _padding;
    }

    // node is above scrolling area
    if(_node_y < _container_y_start + _padding) {
      _delta = _container_y_start - _node_y - _padding;
    }

    if(_delta != 0) {
      // amount required to scroll to greater than available document height
      if(_delta > container.clientHeight - _padding) {
        // make label top
        var lbl_pos = Element.cumulativeOffset(this.label(node)).top;
        container.scrollTop = lbl_pos - _padding;
      }
      else
      container.scrollTop += parseInt(_delta)
    }
    return;
  },

  label: function(node) {
    this._assertNodeOrLeaf(node, 'label: arg type');
    return Element.navigateDom(node.firstChild, 'nextSibling',
                               this.classes.label);
  },

  content: function(node) {
    if (this.isLeaf(node)) return null;
    this._assertNode(node, 'content: arg type');
    return Element.navigateDom(node.lastChild, 'previousSibling',
                               this.classes.content);
  },

  parentNode: function (node) {
    this._assertNodeOrLeaf(node, 'parentNode: arg type');
    return Element.navigateDom(
      node.parentNode, 'parentNode', this.classes.node,
      this.isRootElement.bind(this));
  },

  nextSibling: function (node) {
    this._assertNodeOrLeaf(node, 'nextSibling: arg type');
    return Element.navigateDom(node.nextSibling, 'nextSibling',
                               this.classes.nodeOrLeaf);

  },

  previousSibling: function (node) {
    this._assertNodeOrLeaf(node, 'previousSibling: arg type');
    return Element.navigateDom(node.previousSibling, 'previousSibling',
                               this.classes.nodeOrLeaf);

  },

  firstSubNode: function (node) {
    node = node || this.rootElement;
    var parent = (node == this.rootElement) ? node
               : this.isLeaf(node)          ? null
               :                              this.content(node);
    return parent ? Element.navigateDom(parent.firstChild, 'nextSibling',
                                        this.classes.nodeOrLeaf)
                  : null;
  },

  lastSubNode: function (node) {
    node = node || this.rootElement;
    var parent = (node == this.rootElement) ? node
               : this.isLeaf(node)          ? null
               :                              this.content(node);
    return parent ? Element.navigateDom(parent.lastChild, 'previousSibling',
                                        this.classes.nodeOrLeaf)
                  : null;
  },

  lastVisibleSubnode: function(node) {
    node = node || this.rootElement;
    while(!this.isClosed(node)) {
      var lastSubNode = this.lastSubNode(node);
      if (!lastSubNode) break;
      node = lastSubNode;
    }
    return node;
  },

  // find next displayed node (i.e. skipping hidden nodes).
  nextDisplayedNode: function (node) {
    this._assertNodeOrLeaf(node, 'nextDisplayedNode: arg type');

    // case 1: node is opened and has a subtree : then return first subchild
    if (!this.isClosed(node)) {
      var firstSubNode = this.firstSubNode(node);
      if (firstSubNode) return firstSubNode;
    }

    // case 2: current node or one of its parents has a sibling
    while (node) {
      var sibling = this.nextSibling(node);

      if (sibling) {
        if (this.isVisible(sibling))
          return sibling;
        else
          node = sibling;
      }
      else
        node = this.parentNode(node);
    }

    // case 3: no next Node
    return null;
  },

  // find previous displayed node (i.e. skipping hidden nodes).
  previousDisplayedNode: function (node) {
    this._assertNodeOrLeaf(node, 'previousDisplayedNode: arg type');
    var node_init = node;

    while (node) {
      node = this.previousSibling(node);
      if (node && this.isVisible(node))
        return this.lastVisibleSubnode(node);
    }

    // if no previous sibling
    return this.parentNode(node_init);
  },

  enclosingNode:  function (elem) {
    return Element.navigateDom(
      $(elem), 'parentNode', this.classes.nodeOrLeaf,
      this.isRootElement.bind(this));
  },

  // flash the node
  flash: function (node) {
    var label = this.label(node);

    ASSERT(label, "node has no label");

    label.flash({duration: 200});
  },

  fireEvent: function(eventName, elem) {
    var args = [eventName];
    while (elem) {
      args.push(elem);
      elem = this.parentNode(elem);
    }
    args.push(this.rootElement);
    return GvaScript.fireEvent.apply(this, args);
  },

//-----------------------------------------------------
// Private methods
//-----------------------------------------------------
  // quick navigation initialization:
  // - exit navi_mode
  // - clear navi_word
  // - clear match result
  _clear_quick_navi: function() {
    if(this._quick_navi_mode !== false)
      window.clearTimeout(this._quick_navi_mode);

    this._quick_navi_mode  = false;  // quick_navi mode active (navi timer)
    this._quick_navi_word  = "";     // word to navigate to
    this.labels_array      = null;   // tree labels array
  },

  _assertNode: function(elem, msg) {
    ASSERT(elem && Element.hasAnyClass(elem, this.classes.node), msg);
  },

  _assertNodeOrLeaf: function(elem, msg) {
    ASSERT(elem && Element.hasAnyClass(elem, this.classes.nodeOrLeaf), msg);
  },

  _addHandlers: function() {
    Event.observe(
      this.rootElement,  "mouseover",
      this._treeMouseOverHandler.bindAsEventListener(this));

    Event.observe(
      this.rootElement,  "mouseout",
      this._treeMouseOutHandler.bindAsEventListener(this));

    Event.observe(
      // observing "mouseup" instead of "click", because "click"
      // on MSIE8 only fires when there is a tabindex
      this.rootElement,  "mouseup",
      this._treeClickHandler.bindAsEventListener(this));

    Event.observe(
      this.rootElement,  "dblclick",
      this._treeDblClickHandler.bindAsEventListener(this));
  },

  _removeHandlers: function() {
    this.rootElement.stopObserving();
    this.rootElement.unregister();
  },

//-----------------------------------------------------
// mouse handlers
//-----------------------------------------------------
  _treeClickHandler : function(event) {
    var target = Event.element(event);
    // IE: click on disabled input will fire the event
    // with event.srcElement null
    if(target.nodeType != 1) return;

    // ignore right mousedown
    if(!Event.isLeftClick(event)) return;

    // button clicked
    if(target.hasClassName(this.classes.button)) {
        // as not to fire blur_handler
        // on treeNode
        Event.stop(event);
        return this._buttonClicked(target.parentNode);
    }

    // label (or one of its childElements) clicked
    if(label = this.isLabel(target)) {
        return this._labelClicked(label.parentNode, event);
    }
  },

  _treeDblClickHandler : function(event) {
    var target = Event.element(event);
    if(target.nodeType != 1) return;

    // only consider doubleclicks on labels
    if(!(label = this.isLabel(target))) return;

    var event_stop_mode;

    // should_ping_on_dblclick was just set within _labelClicked
    if (this.should_ping_on_dblclick) {
      event_stop_mode = this.fireEvent("Ping", label.parentNode, this.rootElement);
    }

    // stop the event unless the ping_handler decided otherwise
    Event.detailedStop(event, event_stop_mode || Event.stopAll);
  },

  _treeMouseOverHandler: function(event) {
    var target = Event.element(event);
    if(target.nodeType != 1) return;

    if(label = this.isLabel(target)) {
      Element.addClassName(label, this.classes.mouse);
      Event.stop(event);
    }
  },

  _treeMouseOutHandler: function(event) {
    var target = Event.element(event);
    if(target.nodeType != 1) return;

    if(label = this.isLabel(target)) {
      Element.removeClassName(label, this.classes.mouse);
      Event.stop(event);
    }
  },

  _buttonClicked : function(node) {
    var method = this.isClosed(node) ? this.open : this.close;
    method.call(this, node);
    if (this.options.selectOnButtonClick) {
        window.setTimeout(function() {
            this.select(node);
        }.bind(this), 0);
    }
  },

  _labelClicked : function(node, event) {
    // situation before the mousedown
    var is_selected    = (this.selectedNode == node);
    var is_first_click = !is_selected;

    // select node if it wasn't
    if (!is_selected) this.select(node);

    // should ping : depends on options.noPingOnFirstClick
    var should_ping = (!is_first_click) || !this.options.noPingOnFirstClick;

    // do the ping if necessary
    var event_stop_mode;
    if (should_ping)
    event_stop_mode = this.fireEvent("Ping", node, this.rootElement);

    // avoid a second ping from the dblclick handler
    this.should_ping_on_dblclick = !should_ping;

    // stop the event unless the ping_handler decided otherwise
    Event.detailedStop(event, event_stop_mode || Event.stopAll);
  },

//-----------------------------------------------------
// Keyboard handlers
//-----------------------------------------------------
  _addTabbingBehaviour: function() {
    if (this.options.tabIndex < 0) return; // no tabbing

    var treeNavigator = this; // handlers will be closures on this

    // focus handler
    var focus_handler = function(e) {
      var label = e._target;
      label.writeAttribute('hasFocus', 'hasFocus');

      var node  = Element.navigateDom(label, 'parentNode',
                                      treeNavigator.classes.nodeOrLeaf);

      // not yet been selected
      if(node && !label.hasClassName(treeNavigator.classes.selected)) {
        treeNavigator.select  (node);
      }
    };

    // blur handler
    var blur_handler = function(e) {
      var label = e._target;
      label.removeAttribute('hasFocus');

      // deselect the previously selected node
      treeNavigator.select(null);
    };

    // focus and blur do not bubble
    // workaround per browser
    focus_handler = focus_handler.bindAsEventListener(this);
    blur_handler  = blur_handler.bindAsEventListener(this);

    this.rootElement.register('.'+this.classes.label, 'focus', focus_handler);
    this.rootElement.register('.'+this.classes.label, 'blur',  blur_handler );
  },


//-----------------------------------------------------
// timeout handler for firing Select/Deselect events
//-----------------------------------------------------

  _selectionTimeoutHandler: function(previousNode) {
      this._selectionTimeoutId = null;

      var newNode = this.selectedNode;

      // fire events
      if (previousNode != newNode) {
        if (previousNode) {
          this.fireEvent("Deselect", previousNode, this.rootElement);
        }
        if (newNode) {
          this.fireEvent("Select", newNode, this.rootElement);
        }
      }
  },


//-----------------------------------------------------
// Key handlers
//-----------------------------------------------------
  _charHandler: function (event) {
    var selectedNode = this.selectedNode;
    if(! selectedNode) return;

    // stop firefox quick search if enabled
    // via "accessibility.typeaheadfind" => 'true'
    Event.stop(event);

    this._quick_navi_word += event.keyName; // always uppercase
    var is_quick_navi_mode = (this._quick_navi_mode !== false);

    // drop the previous timer
    if(is_quick_navi_mode) {
      window.clearTimeout(this._quick_navi_mode);
    }
    // initialize labels_array on start of quick-search
    // (mandate of dynamic trees)
    else {
        this.labels_array = this.rootElement.select('.'+this.classes.label);
    }

    // activate a new timer
    this._quick_navi_mode = window.setTimeout(function() {
      this._clear_quick_navi();
    }.bind(this), 800);

    var selectedLabel = this.label(selectedNode);
    var selectedIndex = this.labels_array.indexOf(selectedLabel);
    // partitions the labels array into 2 arrays
    // 1: preceeding labels & selectedNode if not in quick_navi_mode
    // 2: following labels  & selectedNode if in quick_navi_mode
    var labels = this.labels_array.partition(function(l, index) {
        // quick-navi mode
        if(is_quick_navi_mode) return index < selectedIndex;
        else                   return index <= selectedIndex;
    });

    // returns first label found to start with word.
    var find_match = function(labels, word) {
        var match = labels.find(function(label) {
            return label.innerHTML.stripTags()          // in case label contains HTML elements
                    .replace(/\r?\n/g, '')              // clear line breaks
                    .replace(/\ \ /g, '')               // clear white-spaces
                    .toUpperCase().startsWith(word);
        });
        return match;
    }

    // first look ahead then look back
    var matching_label  =  find_match(labels[1], this._quick_navi_word)
                        || find_match(labels[0], this._quick_navi_word);

    // found a match -> make it visible and select it
    if(matching_label) {
      this.openEnclosingNodes(matching_label);

      var znode = this.enclosingNode(matching_label);
      this.scrollTo(znode);
      this.select  (znode);
    }
    // no match -> flash the selected label
    else {
      this.label(this.selectedNode).flash();
    }
  },

  _downHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode) {
      var nextNode = this.nextDisplayedNode(selectedNode);
      if (nextNode) {
        this.scrollTo(nextNode);
        this.select  (nextNode);
      }
      else this.flash(selectedNode);

      Event.stop(event);
    }
    // otherwise: do nothing and let default behaviour happen
  },

  _upHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode) {
      var prevNode = this.previousDisplayedNode(selectedNode);
      if (prevNode) {
        this.scrollTo(prevNode);
        this.select  (prevNode);
      }
      else this.flash(selectedNode);

      Event.stop(event);
    }
    // otherwise: do nothing and let default behaviour happen
  },

  _leftHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode) {
      if (!this.isLeaf(selectedNode) && !this.isClosed(selectedNode)) {
        this.close(selectedNode);
      }
      else {
        var zparent = this.parentNode(selectedNode);
        if (zparent) {
          this.scrollTo(zparent);
          this.select  (zparent);
        }
        else
          this.flash(selectedNode);
      }
      Event.stop(event);
    }
  },

  _rightHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode) {
      if (this.isLeaf(selectedNode)) return;
      if (this.isClosed(selectedNode))
        this.open(selectedNode);
      else {
        var subNode = this.firstSubNode(selectedNode);
        if (subNode) {
          this.scrollTo(subNode);
          this.select  (subNode);
        }
        else
          this.flash(selectedNode);
      }
      Event.stop(event);
    }
  },

  _tabHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode && this.isClosed(selectedNode)) {
      this.open(selectedNode);
      var label = this.label(selectedNode);
      Event.stop(event);
    }
  },

  _kpPlusHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode && this.isClosed(selectedNode)) {
      this.open(selectedNode);
      Event.stop(event);
    }
  },

  _kpMinusHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode && !this.isClosed(selectedNode)) {
      this.close(selectedNode);
      Event.stop(event);
    }
  },

  _kpStarHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode) {
      var nodes = Element.getElementsByClassNames(
        selectedNode,
        this.classes.node
      );
      nodes.unshift(selectedNode);
      nodes.each(function(node) {this.open(node)}, this);
      Event.stop(event);
    }
  },

  _kpSlashHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode) {
      var nodes = Element.getElementsByClassNames(
        selectedNode,
        this.classes.node
      );
      nodes.unshift(selectedNode);
      nodes.each(function(node) {this.close(node)}, this);
      Event.stop(event);
    }
  },

  _ctrl_R_handler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode) {
      if (this.loadContent(selectedNode))
        Event.stop(event);
    }
  },

  _ReturnHandler: function (event) {
    var selectedNode = this.selectedNode;
    if (selectedNode) {
      var toStop = this.fireEvent("Ping", selectedNode, this.rootElement);
      Event.detailedStop(event, toStop || Event.stopAll);
    }
  },

  _homeHandler: function (event) {
    if (this.selectedNode) {
      var znode = this.firstSubNode();
      this.scrollTo(znode);
      this.select  (znode);
      Event.stop(event);
    }
  },

  _endHandler: function (event) {
    if (this.selectedNode) {
      var znode = this.lastVisibleSubnode();
      this.scrollTo(znode);
      this.select  (znode);
      Event.stop(event);
    }
  },

  _ctrlPgUpHandler: function (event) {
    var node = this.enclosingNode(Event.element(event));
    if (node) {
      this.scrollTo(node);
      this.select  (node);
      Event.stop(event);
    }
  },

  _ctrlPgDownHandler: function (event) {
    var node = this.enclosingNode(Event.element(event));
    if (node) {
      node = this.nextDisplayedNode(node);
      if (node) {
        this.scrollTo(node);
        this.select  (node);
        Event.stop(event);
      }
    }
  },

  _chooseLevel: function(event) {
    var level = event.keyCode - "0".charCodeAt(0);
    this.openAtLevel(this.rootElement, level);

    // stop the default Ctrl-num event
    // FF: jump to tab#num
    // IE: Ctrl-5 Select-All
    Event.stop(event);
  },

  _showAll: function(event, toggle) {
    var method = toggle ? Element.addClassName : Element.removeClassName;
    method(this.rootElement, this.classes.showall);
  }

};

//----------choiceList.js

//----------------------------------------------------------------------
// CONSTRUCTOR
//----------------------------------------------------------------------

GvaScript.ChoiceList = function(choices, options) {
  if (! (choices instanceof Array) )
    throw new Error("invalid choices argument : " + choices);
  this.choices = choices;

  var defaultOptions = {
    labelField       : "label",
    classes          : {},        // see below for default classes
    idForChoices     : "CL_choice",
    keymap           : null,
    grabfocus        : false,
    mouseovernavi    : true,
    scrollCount      : 5,
    choiceItemTagName: "div",
    htmlWrapper      : function(html) {return html;},
    paginator        : null
  };


  this.options = Class.checkOptions(defaultOptions, options);

  var defaultClasses = {
    choiceItem      : "CL_choiceItem",
    choiceHighlight : "CL_highlight"
  };
  this.classes = Class.checkOptions(defaultClasses, this.options.classes);

  // handy vars
  this.hasPaginator = this.options.paginator != null;
  this.pageSize = (
                    // the step size of the paginator if any
                    (this.hasPaginator && this.options.paginator.options.step)
                    ||
                    // scroll count
                    this.options.scrollCount
                  );

  // prepare some stuff to be reused when binding to inputElements
  this.reuse = {
    onmouseover : this._listOverHandler.bindAsEventListener(this),
    onclick     : this._clickHandler.bindAsEventListener(this),
    ondblclick  : this._dblclickHandler.bindAsEventListener(this),
    navigationRules: {
      DOWN:      this._highlightDelta.bindAsEventListener(this, 1),
      UP:        this._highlightDelta.bindAsEventListener(this, -1),

      PAGE_DOWN: this._highlightDelta.bindAsEventListener(this, this.pageSize),
      PAGE_UP:   this._highlightDelta.bindAsEventListener(this, -this.pageSize),

      HOME:      this._jumpToIndex.bindAsEventListener(this, 0),
      END:       this._jumpToIndex.bindAsEventListener(this, 99999),

      RETURN:    this._returnHandler .bindAsEventListener(this),
      ESCAPE:    this._escapeHandler .bindAsEventListener(this)
    }
  };

  if(this.hasPaginator) {
    // next/prev page
    this.reuse.navigationRules.RIGHT
        = this._highlightDelta.bindAsEventListener(this, this.pageSize)
    this.reuse.navigationRules.LEFT
        = this._highlightDelta.bindAsEventListener(this, -this.pageSize);

    // first/last page
    this.reuse.navigationRules.C_HOME
        = this._jumpToPage.bindAsEventListener(this, 0);
    this.reuse.navigationRules.C_END
        = this._jumpToPage.bindAsEventListener(this, 99999);
  }
};


GvaScript.ChoiceList.prototype = {

//----------------------------------------------------------------------
// PUBLIC METHODS
//----------------------------------------------------------------------
  destroy: function() {
    // test that element still in DOM
    if(this.container) Event.stopObserving(this.container);
  },

  fillContainer: function(containerElem) {

    this.container = containerElem;
    this.container.choiceList = this;

    Element.update(this.container, this.htmlForChoices());

    // mouse events on choice items will bubble up to the container
    if(this.options.mouseovernavi) {
        Event.observe(this.container, "mouseover", this.reuse.onmouseover);
    }
    Event.observe(this.container, "click"    , this.reuse.onclick);
    Event.observe(this.container, "dblclick" , this.reuse.ondblclick);

    if (this.options.keymap) {
      this.keymap = this.options.keymap;
      this.keymap.rules.push(this.reuse.navigationRules);
    }
    else {
      this.keymap = new GvaScript.KeyMap(this.reuse.navigationRules);
      var target = this.container.tabIndex == undefined
                     ? document
                     : this.container;
      this.keymap.observe("keydown", target);
    }
    // POTENTIAL PROBLEM HERE : the keymap may stay active
    // even after the choiceList is deleted (may yield memory leaks and
    // inconsistent behaviour). But we have no "destructor", so how
    // can we unregister the keymap ?


    // highlight the initial value or the first choice
    this._highlightChoiceNum(this.currentHighlightedIndex || 0, true);
  },

  updateContainer: function(container, list) {
    this.choices = list;
    Element.update(this.container, this.htmlForChoices());
    this._highlightChoiceNum(0, true);
  },

  htmlForChoices: function(){ // creates the innerHTML
    var html = "";
    for (var i = 0; i < this.choices.length; i++) {
      var choice = this.choices[i];
      var label  =
        typeof choice == "string" ? choice : choice[this.options.labelField];

      var id = this.container.id ? this.container.id + "." : '';
      id += this.options.idForChoices + "." + i;
      html += this.choiceElementHTML(label, id);
    }
    return this.options.htmlWrapper(html);
  },

  choiceElementHTML: function(label, id) {
    return "<" + this.options.choiceItemTagName + " class='" 
               + this.classes.choiceItem +  "' id='" + id + "'>"
               + label + "</" + this.options.choiceItemTagName + ">";
  },

  fireEvent: GvaScript.fireEvent, // must be copied here for binding "this"


//----------------------------------------------------------------------
// PRIVATE METHODS
//----------------------------------------------------------------------


  //----------------------------------------------------------------------
  // conversion index <=> HTMLElement
  //----------------------------------------------------------------------

  _choiceElem: function(index) { // find DOM element from choice index
    var prefix = this.container.id ? this.container.id + "." : '';
    return $(prefix + this.options.idForChoices + "." + index);
  },

  _choiceIndex: function(elem) {
    return parseInt(elem.id.match(/\.(\d+)$/)[1], 10);
  },


  //----------------------------------------------------------------------
  // highlighting
  //----------------------------------------------------------------------

  _highlightChoiceNum: function(newIndex, autoScroll) {

    // do nothing if newIndex is invalid
    if (newIndex > this.choices.length - 1) return;

    Element.removeClassName(this._choiceElem(this.currentHighlightedIndex),
                            this.classes.choiceHighlight);
    this.currentHighlightedIndex = newIndex;
    var elem = this._choiceElem(newIndex);
    // not to throw an arrow when user is holding an UP/DN keys while
    // paginating
    if(! $(elem)) return;

    Element.addClassName(elem, this.classes.choiceHighlight);

    if (autoScroll)
      Element.autoScroll(elem, this.container, 30); // 30%

    this.fireEvent({type: "Highlight", index: newIndex}, elem, this.container);
  },

  // this method restricts navigation to the current page
  _jumpToIndex: function(event, nextIndex) {
    var autoScroll = event && event.keyName; // autoScroll only for key events

    this._highlightChoiceNum(
        Math.max(0, Math.min(this.choices.length-1, nextIndex)),
        autoScroll
    );

    if (event) Event.stop(event);
  },


  // TODO: jump to page numbers would be a nice addition
  _jumpToPage: function(event, pageIndex) {
    if(pageIndex <=1) return this.options.paginator.getFirstPage();
    if(pageIndex == 99999) return this.options.paginator.getLastPage();

    if (event) Event.stop(event);
  },

  // would navigate through pages if index goes out of bound
  _highlightDelta: function(event, deltax, deltay) {
    var currentIndex = this.currentHighlightedIndex;
    var nextIndex    = currentIndex + deltax;

    // first try to flip a page
    // if first page -> go top of list
    if (nextIndex < 0) {
        if(this.hasPaginator) {
            if(this.options.paginator.getPrevPage()) return;
        }
        nextIndex = 0;
    }

    if (nextIndex >= this.choices.length) {
        if(this.hasPaginator) {
            if(this.options.paginator.getNextPage()) return;
        }
        nextIndex = this.choices.length -1;
    }

    // we're still on the same page
    this._jumpToIndex(event, nextIndex);
  },

  //----------------------------------------------------------------------
  // navigation
  //----------------------------------------------------------------------

  _findChoiceItem: function(event) { // walk up DOM to find mouse target
    var stop_condition = function(elem){return elem === this.container};
    return Element.navigateDom(Event.element(event), "parentNode",
                               this.classes.choiceItem,
                               stop_condition);
  },

  _listOverHandler: function(event) {
    var elem = this._findChoiceItem(event);
    if (elem) {
      this._highlightChoiceNum(this._choiceIndex(elem), false);
      if (this.options.grabfocus)
        this.container.focus();
      Event.stop(event);
    }
  },

  // no _listOutHandler needed

  _dblclickHandler: function(event) {
    var elem = this._findChoiceItem(event);
    if (elem) {
      var newIndex = this._choiceIndex(elem);
      this._highlightChoiceNum(newIndex, false);
      this._clickHandler(event);
    }
  },

  _clickHandler: function(event) {
    var elem = this._findChoiceItem(event);
    if (elem) {
      var newIndex = this._choiceIndex(elem);
      // check if choice is selected
      if (this.currentHighlightedIndex == newIndex) {
        // selected -> fire ping event
        var toStop = this.fireEvent({type : "Ping",
                                    index: this._choiceIndex(elem)},
                                    elem,
                                    this.container);
        Event.detailedStop(event, toStop || Event.stopAll);
      }
      else {
        // not selected -> select
        this._highlightChoiceNum(newIndex, false);
      }
    }
  },

  _returnHandler: function(event) {
    var index = this.currentHighlightedIndex;
    if (index != undefined) {
      var elem = this._choiceElem(index);
      var toStop = this.fireEvent({type : "Ping",
                                   index: index}, elem, this.container);
      Event.detailedStop(event, toStop || Event.stopAll);
    }
  },

  _escapeHandler: function(event) {
    var toStop = this.fireEvent("Cancel", this.container);
    Event.detailedStop(event, toStop || Event.stopAll);
  }

};


//----------autoCompleter.js
/**

TODO:
  - messages : choose language

  - multivalue :
     - inconsistent variable names
     - missing doc

  - rajouter option "hierarchicalValues : true/false" (si true, pas besoin de
    refaire un appel serveur quand l'utilisateur rajoute des lettres).

  - sometimes arrowDown should force Ajax call even if < minChars

  - choiceElementHTML

  - cache choices. Modes are NOCACHE / CACHE_ON_BIND / CACHE_ON_SETUP

  - dependentFields should also work with non-strict autocompleters

**/

//----------------------------------------------------------------------
// CONSTRUCTOR
//----------------------------------------------------------------------

GvaScript.AutoCompleter = function(datasource, options) {

  var defaultOptions = {
    minimumChars     : 1,
    labelField       : "label",
    valueField       : "value",
    autoSuggest      : true,      // will dropDown automatically on keypress
    autoSuggestDelay : 100,       // milliseconds, (OBSOLETE)
    checkNewValDelay : 100,       // milliseconds
    typeAhead        : true,      // will fill the inputElement on highlight
    classes          : {},        // see below for default classes
    maxHeight        : 200,       // pixels
    minWidth         : 200,       // pixels
    offsetX          : 0,         // pixels
    strict           : false,     // will complain on illegal values
    blankOK          : true,      // if strict, will also accept blanks
    colorIllegal     : "red",     // background color when illegal values
    scrollCount      : 5,
    multivalued      : false,
    multivalue_separator :  /[;,\s]\s*/,
    choiceItemTagName: "div",
    htmlWrapper      : function(html) {return html;},
    observed_scroll  : null,      // observe the scroll of a given element and
                                  // move the dropdown accordingly (useful in
                                  // case of scrolling windows)
    additional_params: null,      // additional parameters with optional default
                                  // values (only in the case where the
                                  // datasource is a URL)
    http_method      : 'get',     // method for Ajax requests
    dependentFields  : {},
    deltaTime_tolerance : 50,      // added msec. for imprecisions in setTimeout
    ignorePrefix : false,
    caseSensitive: false

  };

  // more options for array datasources
  if (typeof datasource == "object" && datasource instanceof Array) {
    defaultOptions.ignorePrefix  = false;  // if true, will always display
                                           // the full list
    defaultOptions.caseSensitive = true;
  }

  this.options = Class.checkOptions(defaultOptions, options);

  // autoSuggestDelay cannot be smaller than checkNewValueDelay
  this.options.autoSuggestDelay = Math.max(this.options.autoSuggestDelay,
                                           this.options.checkNewValDelay);

  var defaultClasses = {
    loading         : "AC_loading",
    dropdown        : "AC_dropdown",
    message         : "AC_message"
  };
  this.classes = Class.checkOptions(defaultClasses, this.options.classes);

  if (this.options.multivalued && this.options.strict) {
    throw new Error("options 'strict' and 'multivalue' are incompatible");
  }

  this.dropdownDiv = null;
  // array to store running ajax requests
  // of same autocompleter but for different input element
  this._runningAjax = [];

  this.setdatasource(datasource);

  // prepare an initial keymap; will be registered at first
  // focus() event; then a second set of keymap rules is pushed/popped
  // whenever the choice list is visible
  var basicHandler = this._keyDownHandler.bindAsEventListener(this);
  var detectedKeys = /^(BACKSPACE|DELETE|KP_.*|.)$/;
                   // catch any single char, plus some editing keys
  var basicMap     = { DOWN: this._ArrowDownHandler.bindAsEventListener(this),
                       REGEX: [[null, detectedKeys, basicHandler]] };
  this.keymap = new GvaScript.KeyMap(basicMap);

  // prepare some stuff to be reused when binding to inputElements
  this.reuse = {
    onblur  : this._blurHandler.bindAsEventListener(this),
    onclick : this._clickHandler.bindAsEventListener(this)
  };
}


GvaScript.AutoCompleter.prototype = {

//----------------------------------------------------------------------
// PUBLIC METHODS
//----------------------------------------------------------------------

  // autocomplete : called when the input element gets focus; binds
  // the autocompleter to the input element
  autocomplete: function(elem) {
    elem = $(elem);// in case we got an id instead of an element

    if (!elem) throw new Error("attempt to autocomplete a null element");

    // elem is readonly => no action
    if (elem.getAttribute('readonly') || elem.readOnly) return;

    // if already bound, no more work to do
    if (elem === this.inputElement) return;

    // bind to the element; if first time, also register the event handlers
    this.inputElement = elem;
    if (!elem._autocompleter) {
      elem._autocompleter = this;
      this.keymap.observe("keydown", elem, Event.stopNone);
      Element.observe(elem, "blur", this.reuse.onblur);
      Element.observe(elem, "click", this.reuse.onclick);

      // prevent browser builtin autocomplete behaviour
      elem.writeAttribute("autocomplete", "off");
    }

    // initialize time stamps
    this._timeLastCheck = this._timeLastKeyDown = 0;

    // more initialization, but only if we did not just come back from a
    // click on the dropdownDiv
    if (!this.dropdownDiv) {
      this.lastTypedValue = this.lastValue = "";
      this.choices = null;
      this.fireEvent("Bind", elem);
    }

    this._checkNewValue();
  },

  detach: function(elem) {
    elem._autocompleter = null;
    Element.stopObserving(elem, "blur", this.reuse.onblur);
    Element.stopObserving(elem, "click", this.reuse.onclick);
    Element.stopObserving(elem, "keydown", elem.onkeydown);
  },

  displayMessage : function(message) {
    this._removeDropdownDiv();
    if(_div = this._mkDropdownDiv()) {
      _div.innerHTML = message;
      Element.addClassName(_div, this.classes.message);
    }
  },

  // set additional params for autocompleters that have more than 1 param;
  // second param is the HTTP method (post or get)
  // DALNOTE 10.01.09 : pas de raison de faire le choix de la  méthode HTTP
  // dans  setAdditionalParams()! TOFIX. Apparemment, utilisé une seule fois
  // dans DMWeb (root\src\tab_composition\form.tt2:43)
  setAdditionalParams : function(params, method) {
    this.additional_params = params;
    if (method) this.options.http_method = method;
  },

  addAdditionalParam : function(param, value) {
    if (!this.additional_params)
      this.additional_params = {};
    this.additional_params[param] = value;
  },

  setdatasource : function(datasource) {

    // remember datasource in private property
    this._datasource = datasource;

    // register proper "updateChoices" function according to type of datasource
    var ds_type = typeof datasource;
    this._updateChoicesHandler
      = (ds_type == "string")   ? this._updateChoicesFromAjax
      : (ds_type == "function") ? this._updateChoicesFromCallback
      : (ds_type == "object" && datasource instanceof Array)
                                ? this._updateChoicesFromArray
      : (ds_type == "object" && datasource instanceof Object)
                                ? this._updateChoicesFromJSONP
      : undefined;
     if (!this._updateChoicesHandler)
      throw new Error("unexpected datasource type");
  },

  // 'fireEvent' function is copied from GvaScript.fireEvent, so that "this"
  // in that code gets properly bound to the current object
  fireEvent: GvaScript.fireEvent,

  // Set the element for the AC to look at to adapt its position. If elem is
  // null, stop observing the scroll.
  // DALNOTE 10.01.09 : pas certain de l'utilité de "set_observed_scroll"; si
  // l'élément est positionné correctement dans le DOM par rapport à son parent,
  // il devrait suivre le scroll automatiquement. N'est utilisé dans DMWeb que
  // par "avocat.js".
  set_observed_scroll : function(elem) {
    if (!elem) {
        Event.stopObserving(this.observed_scroll, 'scroll',
                            correct_dropdown_position);
        return;
    }

    this.observed_scroll = elem;
    this.currentScrollTop = elem.scrollTop;
    this.currentScrollLeft = elem.scrollLeft;
    var correct_dropdown_position = function() {
      if (this.dropdownDiv) {
        var dim = Element.getDimensions(this.inputElement);
        var pos = this.dropdownDiv.positionedOffset();
        pos.top  -= this.observed_scroll.scrollTop - this.currentScrollTop;
        pos.left -= this.observed_scroll.scrollLeft;
        this.dropdownDiv.style.top  = pos.top   + "px";
        this.dropdownDiv.style.left = pos.left  + "px";
      }
      this.currentScrollTop = this.observed_scroll.scrollTop;
      this.currentScrollLeft = this.observed_scroll.scrollLeft;
    }

    Event.observe(elem, 'scroll',
                  correct_dropdown_position.bindAsEventListener(this));
  },


//----------------------------------------------------------------------
// PRIVATE METHODS
//----------------------------------------------------------------------

  _updateChoicesFromAjax: function (val_to_complete, continuation) {

    // copies into local variables, needed for closures below (can't rely on
    // 'this' because 'this' may have changed when the ajax call comes back)
    var autocompleter = this;
    var inputElement  = this.inputElement;

    inputElement.style.backgroundColor = ""; // remove colorIllegal

    // abort prev ajax request on this input element
    if (this._runningAjax[inputElement.name])
      this._runningAjax[inputElement.name].transport.abort();

    Element.addClassName(inputElement, this.classes.loading);

    // encode value to complete 
    val_to_complete = val_to_complete.split("").map(function (c) {
      if (c.match(/[@\+\/]/)) {
        return encodeURIComponent(c);
      }
      else {
        return escape(c);
      }
    }).join("");
    
    var complete_url = this._datasource + val_to_complete;

    this._runningAjax[inputElement.name] = new Ajax.Request(
      complete_url,
      {asynchronous: true,
       method: this.options.http_method,
       parameters: this.additional_params, // for example {C_ETAT_AVOC : 'AC'}

       // DALNOTE 10.01.09: forcer du JSON dans le body du POST est spécifique
       // DMWeb; pour le cas général il faut pouvoir envoyer du
       // x-www-form-urlencoded ordinaire
       postBody: this.options.http_method == 'post'
                     ? Object.toJSON(this.additional_params)
                     : null,

       contentType: "text/javascript",
       evalJSON: 'force', // will evaluate even if header != 'application/json'
       onSuccess: function(xhr) {
          // aborted by the onblur handler
          if (xhr.transport.status == 0) return;

          autocompleter._runningAjax[inputElement.name] = null;

          if (xhr.responseJSON) continuation(xhr.responseJSON);

          // autocompleter input already blurred without _blurHandler being
          // called (autocompleter is strict and needs its choices to
          // be able to fire its final status
          if (xhr['blurAfterSuccess']) autocompleter._blurHandler();
       },
       onFailure: function(xhr) {
          autocompleter._runningAjax[inputElement.name] = null;
          autocompleter.displayMessage("pas de réponse du serveur");
       },
       onComplete: function(xhr) {
          Element.removeClassName(inputElement,
                                  autocompleter.classes.loading);
       }
      });
  },

  _updateChoicesFromCallback : function(val_to_complete, continuation) {
     continuation(this._datasource(val_to_complete));
  },

  _updateChoicesFromJSONP : function(val_to_complete, continuation) {
      if(val_to_complete) {
        var _url = this._datasource.json_url.replace(/\?1/, val_to_complete).replace(/\?2/, '?');
        var that = this;

        Element.addClassName(that.inputElement, that.classes.loading);
        Prototype.getJSON(_url, function(data) {
          var _data_list = data;

          if(that._datasource.json_list)
          that._datasource.json_list.split('/').each(function(p) {
            _data_list = _data_list[p];
          });
          Element.removeClassName(that.inputElement, that.classes.loading);

          continuation(_data_list);
        });
      }
  },

  _updateChoicesFromArray : function(val_to_complete, continuation) {
    if (this.options.ignorePrefix) {
      // store the index of the initial value
      if (val_to_complete) {
        this._idx_to_hilite = (val_to_complete == ''? 0 : -1);
        $A(this._datasource).each(function(choice, index) {
          switch(typeof choice) {
            case "object" : value = choice[this.options.valueField]; break;
            case "number" : value = choice.toString(10); break;
            case "string" : value = choice; break;
            default: throw new Error("unexpected type of value");
          }
          if(value.toLowerCase().startsWith(val_to_complete.toLowerCase())) {
            this._idx_to_hilite = index;
            throw $break;
          }
        }, this);
      }
      continuation(this._datasource);
    }
    else {
      var regex = new RegExp("^" + RegExp.escape(val_to_complete),
                             this.options.caseSensitive ? "" : "i");
      var matchPrefix = function(choice) {
        var value;
        switch(typeof choice) {
          case "object" : value = choice[this.options.valueField]; break;
          case "number" : value = choice.toString(10); break;
          case "string" : value = choice; break;
          default: throw new Error("unexpected type of value");
        }
        return value.search(regex) > -1;
      };
      continuation(this._datasource.select(matchPrefix.bind(this)));
    }
  },


  _updateChoices : function (continuation) {
    var value = this._getValueToComplete();

//     if (window.console) console.log('updateChoices', value);

    this._updateChoicesHandler(value, continuation);
  },


  // does the reverse of "autocomplete()"
  // doesnot fire if input blurred from click on choice list
  _blurHandler: function(event) {

    // remove choice list
    if (this.dropdownDiv)  this._removeDropdownDiv();

    // xhr is still active: waiting for response from server
    if (_xhr = this._runningAjax[this.inputElement.name]) {

      // if autocompleter is strict, need to wait for xhr to
      // finish before calling the _blurHandler to fire the
      // autocompleter's finalState
      if (this.options.strict) {
        _xhr['blurAfterSuccess'] = true;
        return;
      }

      _xhr.transport.abort();
      _xhr = null;
      Element.removeClassName(this.inputElement, this.classes.loading);
    }

    // if strict mode, inform client about the final status
    if (this.options.strict) {
      var value = this._getValueToComplete();

      // if value has changed, invalidate previous list of choices
      if (value != this.lastValue) {
        this.choices = null;
      }

      // if blank and blankOK, this is a legal value
      if (!value && this.options.blankOK) {
        this._updateDependentFields(this.inputElement, "");
        this.fireEvent({ type       : "LegalValue",
                         value      : "",
                         choice     : null,
                         controller : null  }, this.inputElement);
      }

      // if choices are known, just inspect status
      else if (this.choices) {
        this._fireFinalStatus(this.inputElement, this.choices);
      }

      // if not enough chars to get valid choices, this is illegal
      else if (value.length < this.options.minimumChars) {
        var return_value = this.fireEvent({
          type: "IllegalValue", value: value
        }, this.inputElement);

        if(! return_value) {
          this.inputElement.style.backgroundColor = this.options.colorIllegal;
          this._updateDependentFields(this.inputElement, null);
        }
      }

      // otherwise get choices and then inspect status (maybe asynchronously)
      else  {
        this._updateChoices(this._fireFinalStatus.bind(this,
                                                       this.inputElement));
      }
    }

    this.fireEvent("Leave", this.inputElement);
    this.inputElement = null;
  },

  _fireFinalStatus: function (inputElement, choices) {
  // NOTE: takes inputElement and choices as arguments, because it might be
  // called asynchronously, after "this" has been detached from the input
  // element and the choices array, so we cannot call the object properties.

    var input_val = this._getValueToComplete(inputElement.value);

    var index = null;

    // inspect the choice list to automatically choose the appropriate candidate
    for (var i=0; i < choices.length; i++) {
        var val = this._valueFromChoiceItem(choices[i]);

        if (val == input_val) {
            index = i;
            break; // break the loop because this is the best choice
        }
        else if (val.toUpperCase() == input_val.toUpperCase()) {
            index = i;  // is a candidate, but we may find a better one
        }
    }

    // if automatic choice did not work, but we have only 1 choice, and this is
    // not blank on purpose, then force it into the field
    if (index === null && choices.length == 1
                       && (input_val || !this.options.blankOK ))
        index = 0;

    if (index !== null) {
        var choice = choices[index];
        var val = this._valueFromChoiceItem(choice);

        // put canonical value back into input field
        this._setValue(val, inputElement);

        // for backwards compatibility, we generate a "Complete" event, but
        // with a fake controller (because the real controller might be in a
        // diffent state).
        this.fireEvent({ type      : "Complete",
                         referrer  : "blur",    // input blur fired this event
                         index     : index,
                         choice    : choice,
                         controller: {choices: choices} }, inputElement);

        // update dependent fields
        this._updateDependentFields(inputElement, choice);

        // for new code : generate a "LegalValue" event
        this.fireEvent({ type       : "LegalValue",
                         value      : val,
                         choice     : choice,
                         controller : null  }, inputElement);

    }
    else {
        var return_value = this.fireEvent({
          type       : "IllegalValue",
          value      : input_val,
          controller : null
        }, inputElement);

        if(! return_value) {
          inputElement.style.backgroundColor = this.options.colorIllegal;
          this._updateDependentFields(inputElement, null);
        }
    }
  },

  _updateDependentFields: function(inputElement, choice) {
        // "choice" might be
        //   - an object or nonempty string ==> update dependent fields
        //   - an empty string              ==> clear dependent fields
        //   - null                         ==> put "ILLEGAL_***"
        var attr       = inputElement.getAttribute('ac:dependentFields');
        var dep_fields = attr ? eval("("+attr+")")
                              : this.options.dependentFields;
        if (!dep_fields) return;

        var form       = inputElement.form;
        var name_parts = inputElement.name.split(/\./);

        for (var k in dep_fields) {
            name_parts[name_parts.length - 1] = k;
            var related_name    = name_parts.join('.');
            var related_field   = form[related_name];
            var value_in_choice = dep_fields[k];
            if (related_field) {
                related_field.value
                    = (value_in_choice == "")        ? ""
                    : (choice === null)              ? "!!ILLEGAL_" + k + "!!"
                    : (typeof choice == "object")    ? 
                      (choice[value_in_choice]       ? choice[value_in_choice] : "")
                    : (typeof choice == "string")    ? choice
                    : "!!UNEXPECTED SOURCE FOR RELATED FIELD!!";
            }
        }
    },

  // if clicking in the 20px right border of the input element, will display
  // or hide the drowpdown div (like pressing ARROWDOWN or ESC)
  _clickHandler: function(event) {
    var x = event.offsetX || event.layerX; // MSIE || FIREFOX
    if (x > Element.getDimensions(this.inputElement).width - 20) {
        if ( this.dropdownDiv ) {
            this._removeDropdownDiv();
            Event.stop(event);
        }
        else
            this._ArrowDownHandler(event);
    }
  },

  _ArrowDownHandler: function(event) {
    var value = this._getValueToComplete();
    var valueLength = (value || "").length;
    if (valueLength < this.options.minimumChars)
      this.displayMessage("liste de choix à partir de "
                            + this.options.minimumChars + " caractères");
    else
      this._displayChoices();
    Event.stop(event);
  },



  _keyDownHandler: function(event) {

    // invalidate previous lists of choices because value may have changed
    this.choices = null;
    this._removeDropdownDiv();

    // cancel pending timeouts because we create a new one
    if (this._timeoutId) clearTimeout(this._timeoutId);

    this._timeLastKeyDown = (new Date()).getTime();
//     if (window.console) console.log('keyDown', this._timeLastKeyDown, event.keyCode);
    this._timeoutId = setTimeout(this._checkNewValue.bind(this),
                                 this.options.checkNewValDelay);

    // do NOT stop the event here : give back control so that the standard
    // browser behaviour can update the value; then come back through a
    // timeout to update the Autocompleter
  },



  _checkNewValue: function() {

    // abort if the timeout occurs after a blur (no input element)
    if (!this.inputElement) {
//       if (window.console) console.log('_checkNewValue ... no input elem');
      return;
    }

    // several calls to this function may be queued by setTimeout,
    // so we perform some checks to avoid doing the work twice
    if (this._timeLastCheck > this._timeLastKeyDown) {

//       if (window.console) console.log('_checkNewValue ... done already ',
//                   this._timeLastCheck, this._timeLastKeyDown);

      return; // the work was done already
    }

    var now = (new Date()).getTime();

    var deltaTime = now - this._timeLastKeyDown;
    if (deltaTime + this.options.deltaTime_tolerance
          <  this.options.checkNewValDelay) {

//       if (window.console) console.log('_checkNewValue ... too young ',
//                                       now, this._timeLastKeyDown);

      return; // too young, let olders do the work
    }


    this._timeLastCheck = now;
    var value = this._getValueToComplete();
//     if (window.console)
//         console.log('_checkNewValue ... real work [value = %o]  - [lastValue = %o] ',
//                              value, this.lastValue);
    this.lastValue = this.lastTypedValue = value;

    // create a list of choices if we have enough chars
    if (value.length >= this.options.minimumChars) {

        // first create a "continuation function"
        var continuation = function (choices) {

          // if, meanwhile, another keyDown occurred, then abort
          if (this._timeLastKeyDown > this._timeLastCheck) {
//             if (window.console)
//               console.log('after updateChoices .. abort because of keyDown',
//                           now, this._timeLastKeyDown);
            return;
          }

          this.choices = choices;
          if (choices && choices.length > 0) {
            this.inputElement.style.backgroundColor = ""; // remove colorIllegal
            if (this.options.autoSuggest)
              this._displayChoices();
          }
          else if (this.options.strict && (!this.options.blankOK)) {
            this.inputElement.style.backgroundColor = this.options.colorIllegal;
          }
        };

        // now call updateChoices (which then will call the continuation)
        this._updateChoices(continuation.bind(this));
      }
  },


  // return the value to be completed
  // TODO : for multivalued, should return the value under the cursor,
  // instead returning sytematically the last value
  _getValueToComplete : function(value) {
     // NOTE: the explicit value as argument is only used from
     //_fireFinalStatus(), when we can no longer rely on
     // this.inputElement.value
    value = value || this.inputElement.value;
    if (this.options.multivalued) {
      var vals = value.split(this.options.multivalue_separator);
      value    = vals[vals.length-1];
    }
    return value;
  },

  _setValue : function(value, inputElement) {
        // NOTE: the explicit inputElement as argument is only used from
        // _fireFinalStatus(), when we can no longer rely on this.inputElement

    // default inputElement is the one bound to this autocompleter
    if (!inputElement) inputElement = this.inputElement;

    // if multivalued, the completed value replaces the last one in the list
    if (this.options.multivalued) {
      var _sep = inputElement.value.match(this.options.multivalue_separator);
      if (_sep) {
        var vals = inputElement.value.split(this.options.multivalue_separator);
        vals[vals.length-1] = value;
        value = vals.join(_sep[0]); // join all vals with first separator found
      }
    }

    // setting value in input field
    inputElement.value = this.lastValue = value;
  },



  _typeAhead : function () {
    var curLen     = this.lastTypedValue.length;
    var index      = this.choiceList.currentHighlightedIndex;
    var suggestion = this._valueFromChoice(index);
    var newLen     = suggestion.length;
    this._setValue(suggestion);

    if (this.inputElement.createTextRange){ // MSIE
      var range = this.inputElement.createTextRange();
      range.moveStart("character", curLen); // no need to moveEnd
      range.select(); // will call focus();
    }
    else if (this.inputElement.setSelectionRange){ // Mozilla
      this.inputElement.setSelectionRange(curLen, newLen);
    }
  },



//----------------------------------------------------------------------
// methods for the dropdown list of choices
//----------------------------------------------------------------------

  _mkDropdownDiv : function() {
    this._removeDropdownDiv();

    // the autocompleter has been blurred ->
    // do not display the div
    if(!this.inputElement) return null;

    // if observed element for scroll, reposition
    var movedUpBy   = 0;
    var movedLeftBy = 0;
    if (this.observed_scroll) {
        movedUpBy   = this.observed_scroll.scrollTop;
        movedLeftBy = this.observed_scroll.scrollLeft;
    }

    // create div
    var div = new Element('div');
    div.className = this.classes.dropdown;

    // positioning
    var coords = Position.cumulativeOffset(this.inputElement);
    var dim     = Element.getDimensions(this.inputElement);
    div.style.left      = coords[0] + this.options.offsetX - movedLeftBy + "px";
    div.style.top       = coords[1] + dim.height -movedUpBy + "px";
    div.style.maxHeight = this.options.maxHeight + "px";
    div.style.minWidth  = this.options.minWidth + "px";
    div.style.zIndex    = 32767; //Seems to be the highest valid value

    // insert into DOM
    document.body.appendChild(div);

    // simulate minWidth on old MSIE (must be AFTER appendChild())
    // maxHeight cannot be simulated untill displayChoices
    if (navigator.userAgent.match(/\bMSIE [456]\b/)) {
      div.style.width  = this.options.minWidth + "px";
    }

    // mouseenter and mouseleave events to control
    // whether autocompleter has been blurred
    var elem = this.inputElement;
    div.observe('mouseenter', function(e) {
      Element.stopObserving(elem, "blur", this.reuse.onblur);
    }.bind(this));
    div.observe('mouseleave', function(e) {
      Element.observe(elem, "blur", this.reuse.onblur);
    }.bind(this));

    return this.dropdownDiv = div;
  },



  _displayChoices: function() {

    // if no choices are ready, can't display anything
    if (!this.choices) return;

    var toCompleteVal = this._getValueToComplete();

    if (this.choices.length > 0) {
      var ac = this;

      // create a choiceList
      var cl = this.choiceList = new GvaScript.ChoiceList(this.choices, {
        labelField        : this.options.labelField,
        scrollCount       : this.options.scrollCount,
        choiceItemTagName : this.options.choiceItemTagName,
        htmlWrapper       : this.options.htmlWrapper
      });
      cl.currentHighlightedIndex = ac._idx_to_hilite;

      // TODO: explain and publish method "choiceElementHTML", or redesign
      // and make it a private method
      if ( this.choiceElementHTML ) {
        cl.choiceElementHTML = this.choiceElementHTML;
      }

      cl.onHighlight = function(event) {
        if (ac.options.typeAhead)
          ac._typeAhead();
        ac.fireEvent(event, ac.inputElement);
      };
      cl.onPing = function(event) {
        ac._completeFromChoiceElem(event.target);
      };
      cl.onCancel = function(event) {
        ac._removeDropdownDiv();
      };

      // append div to DOM
      var choices_div = this._mkDropdownDiv();
      // fill div now so that the keymap gets initialized
      cl.fillContainer(choices_div);
      // set height of div for IE6 (no suppport for maxHeight!)
      if (navigator.userAgent.match(/\bMSIE [456]\b/)) {
        choices_div.style.height =
          (choices_div.scrollHeight > this.options.maxHeight)?
            this.options.maxHeight + 'px' :
            'auto';
      }

      // determine if there is a space to dislay
      // the choices list under the input
      // if not, display above.
      // onscreen height needed for displaying the choices list
      var _h_needed = Element.viewportOffset(this.inputElement)[1]
                      + this.inputElement.offsetHeight
                      + choices_div.offsetHeight;
      var _h_avail  = document.viewport.getHeight();
      // move choices list on top of the input element
      if(_h_needed >= _h_avail) {
        var div_top = choices_div.offsetTop
                      - choices_div.offsetHeight
                      - this.inputElement.offsetHeight;
        if (div_top >= 0)
          choices_div.style.top = div_top + 'px';
      }

      // catch keypress on TAB while choiceList has focus
      cl.keymap.rules[0].TAB = cl.keymap.rules[0].S_TAB = function(event) {
        var index = cl.currentHighlightedIndex;
        if (index != undefined) {

          var elem = cl._choiceElem(index);

          // generate a "Ping" on the choiceList, like if user had
          // pressed RETURN to select the current highlighted item
          cl.fireEvent({type : "Ping",
                        index: index}, elem, cl.container);

          // NO Event.stop() here, because the navigator should
          // do the tabbing (pass focus to next/previous element)
        }
      };

      // more key handlers when the suggestion list is displayed
      this.keymap.rules.push(cl.keymap.rules[0]);

    }
    else
      this.displayMessage("pas de suggestion");
  },

  _removeDropdownDiv: function() {
    // remove the dropdownDiv that was added previously by _mkDropdownDiv();
    // that div contained either a menu of choices or a message to the user
    if (this.dropdownDiv) {
      // remove mouseenter and mouseleave observers
      this.dropdownDiv.stopObserving();
      Element.remove(this.dropdownDiv);
      this.dropdownDiv = null;
    }

    // if applicable, also remove rules previously pushed by _displayChoices
    if (this.keymap.rules.length > 1)
      this.keymap.rules.pop();
  },

  _valueFromChoice: function(index) {
    if (!this.choices) return null;
    var choice = this.choices[index];
    return (choice !== null) ? this._valueFromChoiceItem(choice) : null;
  },

  _valueFromChoiceItem: function(choice) {
    return (typeof choice == "string") ? choice
                                       : choice[this.options.valueField];
  },



  //triggered by the onPing event on the choicelist, i.e. when the user selects
  //one of the choices in the list
  _completeFromChoiceElem: function(elem) {
    // identify the selected line and handle it
    var num = parseInt(elem.id.match(/\.(\d+)$/)[1], 10);

    // add the value to the input element
    var value = this._valueFromChoice(num);
    if (value !== null) {
      this._setValue(value)
      this._removeDropdownDiv();
      
      // ADDED LEMOINEJ 26.09.13
      this._timeLastCheck = this._timeLastKeyDown = 0;      
      this._checkNewValue();

      if (!this.options.multivalued) {
        this.inputElement.select();
      }

      this._updateDependentFields(this.inputElement, this.choices[num]);

      // fire events: "Complete" for backwards compatibility, "LegalValue"
      // for regular use
      var eventNames =  ["Complete", "LegalValue"];
      // for loop : can't use .each() from prototype.js because it alters "this"
      for (var i = 0; i < eventNames.length; i++) {
        this.fireEvent({
          type      : eventNames[i],
          referrer  : "select",    // choice selection fired this event
          index     : num,
          choice    : this.choices[num],
          controller: {choices: this.choices}
          }, elem, this.inputElement);
      }
    }
  }
}



//----------customButtons.js
// depends: keyMap.js

GvaScript.CustomButtons = {};

GvaScript.CustomButtons.Button = Class.create();
// Renders Buttons in the following HTML structure
// <span class="gva-btn-container">
//         <span class="left"/>
//         <span class="center">
//                 <button class="btn" style="width: auto;" id="btn_1227001526005">
//                         Créer
//                 </button>
//         </span>
//         <span class="right"/>
// </span>
Object.extend(GvaScript.CustomButtons.Button.prototype, function() {
    var bcss = CSSPREFIX();

    function _extendCss(button_options) {
        // basic class
        var button_css = bcss+'-btn-container';

        // extended classes
        switch (typeof button_options.css) {
            case 'object': button_css += (' ' + button_options.css.join(' ')); break;
            case 'string': button_css += (' ' + button_options.css); break;
            default: break;
        }
        button_options.button_css = button_css;
    }
    var _button_template = new Template(
          '<span class="#{button_css}" id="#{id}">'
        + '<span class="left"></span>'
        + '<span class="center">'
            + '<button type="#{type}" style="width:#{width}" '
            + ' class="btn">#{label}'
            + '</button>'
        + '</span>'
        + '<span class="right"></span>'
        + '</span>'
    );
    function _render(button_options) {
        _extendCss(button_options);
        return _button_template.evaluate(button_options);
    }
    function _evalCondition(button_condition) {
        if(typeof button_condition == 'function') return button_condition();
        else
        if(eval(button_condition)) return true;
        else                       return false;
    }
    return {
        destroy: function() {
            // test that element still in DOM
            if(this.btnElt) this.btnElt.stopObserving('click');
        },
        initialize: function(container, options) {
            var defaults = {
                id: 'btn_' + (new Date()).getTime(),
                callback: Prototype.emptyFunction,
                condition: true,
                width: 'auto',
                type: 'button',
                label: 'GVA_SCRIPT_BUTTON'
            };
            this.options = Object.extend(defaults, options || {});

            if(_evalCondition(this.options.condition)) {
                try {
                    this.container = $(container);
                    this.container.insert(_render(this.options));
                    this.btnContainer = $(this.options.id); // the outer <span/>

                    this.btnElt = this.btnContainer.down('.btn'); // the <button/>

                    // setting inline style on the button container
                    if(typeof this.options.style != 'undefined') {
                        this.btnContainer.setStyle(this.options.style);
                    }

                    // setting tabindex on button if any
                    if(typeof this.options.tabindex != 'undefined') {
                        this.btnElt.writeAttribute('tabindex', this.options.tabindex);
                    }

                    this.btnElt.observe('click', this.options.callback.bind(this.btnElt));
                } catch (e) {}
            }
        }
    }
}());

GvaScript.CustomButtons.ButtonNavigation = Class.create();
Object.extend(GvaScript.CustomButtons.ButtonNavigation.prototype, function() {
        // private members
        var bcss = CSSPREFIX();

        function _leftHandler(event) {
            var selectedBtn = this.selectedBtn;
            if (selectedBtn) {
                var nextBtn = this.previousBtn(selectedBtn);

                if (nextBtn) this.select(nextBtn);
                else         selectedBtn.flash();

                Event.stop(event);
            }
        }
        function _rightHandler(event) {
            var selectedBtn = this.selectedBtn;
            if (selectedBtn) {
                var prevBtn = this.nextBtn(selectedBtn);

                if (prevBtn) this.select(prevBtn);
                else         selectedBtn.flash();

                Event.stop(event);
            }
        }
        function _tabHandler(event) {
            if (this.options.preventListBlur)
                if (this.isLast(this.selectedBtn))
                    Event.stop(event);
        }
        function _shiftTabHandler(event) {
            if (this.options.preventListBlur)
                if (this.isFirst(this.selectedBtn))
                    Event.stop(event);
        }
        function _homeHandler(event) {
            if (this.selectedBtn) {
                this.select(this.firstBtn());
                Event.stop(event);
            }
        }
        function _endHandler(event) {
            if (this.selectedBtn) {
                this.select(this.lastBtn());
                Event.stop(event);
            }
        }
        function _addHandlers() {
            this.buttons.each(function(btnContainer) {
                var btn;
                // if the button is a GvaScript.CustomButtons.BUTTON, then the actual <button> element
                // will be embedded and selectable via .btn classname:
                // <span class="gva-btn-container">
                //         <span class="left"/>
                //         <span class="center">
                //                 <button accesskey="r" class="btn" style="width: auto;" id="btn_1226916357164">
                //                         Rechercher dans Calvin
                //                 </button>
                //         </span>
                //         <span class="right"/>
                // </span>
                // this will be cleaner when all application buttons are transformed into
                // GvaScript.CustomButtons.Button instances
                if(btnContainer.tagName.search(/^(INPUT|BUTTON)$/i) > -1) btn = btnContainer;
                else {
                    btn = btnContainer.down('.btn');
                    btn.visible        = function() {return btnContainer.visible();}
                    // support focus function on span.buttonContainer
                    btnContainer.focus = function() {btn.focus();}
                }

                if(typeof btn == 'undefined') return;

            }, this);

            this.container.register('button.btn', 'focus', function(e) {
                this.select.call(this, e._target.up('.'+bcss+'-btn-container'));
            }.bind(this));
            this.container.register('button.btn', 'blur', function(e) {
                this.select.call(this, null);
            }.bind(this));
        }

        // public members
        return {
            destroy: function() {
                // test that element still in DOM
                if(this.container) this.container.unregister();
                this.keymap.destroy();
            },
            initialize: function(container, options) {
                var defaults = {
                    preventListBlur     : false,
                    flashDuration       : 100,     // milliseconds
                    flashClassName      : 'flash',
                    keymap              : null,
                    selectFirstBtn      : true,
                    className           : bcss+'-button'
                };
                this.options   = Object.extend(defaults, options || {});
                this.container = $(container);

                // initializing the keymap
                var keyHandlers = {
                    LEFT:       _leftHandler     .bindAsEventListener(this),
                    RIGHT:      _rightHandler    .bindAsEventListener(this),
                    TAB:        _tabHandler      .bindAsEventListener(this),
                    S_TAB:      _shiftTabHandler .bindAsEventListener(this),
                    HOME:       _homeHandler     .bindAsEventListener(this),
                    END:        _endHandler      .bindAsEventListener(this)
                };
                this.keymap = new GvaScript.KeyMap(keyHandlers);
                this.keymap.observe("keydown", container, {
                    preventDefault:false,
                    stopPropagation:false
                });

                // get all buttons of designated className regardless of their
                // visibility jump over hidden ones when navigating
                this.buttons = this.container.select('.'+this.options.className);
                _addHandlers.call(this);

                if (this.options.selectFirstBtn) {
                    if(firstButObj = this.firstBtn()) {
                        this.select(firstButObj);
                    }
                    // set the focus on the container anyways so that the focus
                    // gets trasferred successfully to windows with empty
                    // actionsbar
                    else {
                        this.container.writeAttribute('tabindex', 0);
                        this.container.focus();
                    }
                }
            },
            select: function (btn) {
                var previousBtn = this.selectedBtn || null;
                if (previousBtn === btn) return; // selection already handled

                // blur the previously selected button
                if (previousBtn) {
                    previousBtn.removeClassName('btn-focus');
                }
                this.selectedBtn = btn;
                if (btn) {
                    btn.addClassName('btn-focus');
                    try {
                        if(btn.tagName.search(/^(INPUT|BUTTON)$/i) > -1)
                            btn.focus();
                        else
                            btn.down('.btn').focus();
                    } catch (err) {}
                }
            },
            // returns the next visible button
            // null if none exists
            nextBtn: function (btn) {
                var _idx = this.buttons.indexOf(btn);
                var _nextBtn = null;

                do    _nextBtn = this.buttons[++_idx]
                while(_nextBtn && !(_nextBtn.visible()));

                return _nextBtn;
            },
            // returns the previous visible button
            // null if none exists
            previousBtn: function (btn) {
                var _idx = this.buttons.indexOf(btn);
                var _prevBtn = null;

                do    _prevBtn = this.buttons[--_idx]
                while(_prevBtn && !(_prevBtn.visible()));

                return _prevBtn;
            },
            isFirst: function(btn) { return btn == this.firstBtn() },
            isLast:  function(btn) { return btn == this.lastBtn() },
            // return first visible button
            firstBtn: function() {
                return this.buttons.find(function(e) {
                    return e.visible();
                });
            },
            // return last visible button
            lastBtn: function() {
                return this.buttons.reverse(false).find(function(e) {
                    return e.visible();
                });
            }
        }
}());


GvaScript.CustomButtons.ActionsBar = Class.create();
Object.extend(GvaScript.CustomButtons.ActionsBar.prototype, {
    initialize: function(container, options) {
        var bcss = CSSPREFIX();
        var defaults = {
            actions: [],
            selectfirst: false
        }
        this.container = $(container);
        this.container.update('');
        this.options = Object.extend(defaults, options || {});
        this.container.addClassName(bcss+'-actionsbar');

        this.options.actions.each(function(action_props, index) {
            action_props.id = action_props.id || this.container.id + '_btn_' + index;
            // renders a <button> element and appends it to container
            new GvaScript.CustomButtons.Button(this.container, action_props);
        }, this);

        this.buttonNavigation = new GvaScript.CustomButtons.ButtonNavigation(this.container, {
            selectFirstBtn: this.options.selectfirst,
            className: bcss+'-btn-container'
        });

        this.container.store('widget', this);
        this.container.addClassName(bcss+'-widget');
    },
    destroy: function() {
        this.buttonNavigation.destroy();
    }
});

document.register('.'+CSSPREFIX()+'-btn-container', 'mouseover', function(e) {
    e._target.addClassName('btn-hover');
});
document.register('.'+CSSPREFIX()+'-btn-container', 'mouseout', function(e) {
    e._target.removeClassName('btn-hover');
});

//----------paginator.js
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

//----------grid.js
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

//----------repeat.js
/* TODO :
    - invent syntax for IF blocks (first/last, odd/even)
*/

GvaScript.Repeat = {

//-----------------------------------------------------
// Public methods
//-----------------------------------------------------

  init: function(elem) {
    this._init_repeat_elements(elem);
  },

  add: function(repeat_name, count) {
    if (count == undefined) count = 1;

    // get repeat properties
    var placeholder = this._find_placeholder(repeat_name);
    var repeat      = placeholder.repeat;
    var path_ini    = repeat.path;

    // regex substitutions to build html for the new repetition block (can't
    // use Template.replace() because we need structured namespaces)
    var regex       = new RegExp("#{" + repeat.name + "\\.(\\w+)}", "g");
    var replacement = function ($0, $1){var s = repeat[$1];
                                        return s == undefined ? "" : s};

    while (count-- > 0 && repeat.count < repeat.max) {
      // increment the repetition block count and update path
      repeat.ix    = repeat.count++;  // invariant: count == ix + 1
      repeat.path  = path_ini + "." + repeat.ix;

      // compute the HTML
      var html  = repeat.template.replace(regex, replacement);

      // insert into the DOM
      placeholder.insert({before:html});
      var insertion_block = $(repeat.path);

      // repetition block gets an event
      placeholder.fireEvent("Add", insertion_block);

      // deal with nested repeated sections
      this._init_repeat_elements(insertion_block, repeat.path);

      // restore initial path
      repeat.path = path_ini;
    }

    return repeat.count;
  },


  remove: function(repetition_block, live_update) {
    // default behavior to live update all blocks below
    // the removed block
    if(typeof live_update == 'undefined') live_update = true;

    // find element, placeholder and repeat info
    var elem = $(repetition_block);
    elem.id.match(/(.*)\.(\d+)$/);
    var repeat_name = RegExp.$1;
    var remove_ix   = RegExp.$2;
    var placeholder = this._find_placeholder(repeat_name);
    var max         = placeholder.repeat.count;

    // fire onRemove event
    // remove block from DOM
    var block = $(repeat_name + "." + remove_ix);
    placeholder.fireEvent("Remove", block);
    block.remove();

    // if live_update
    if(live_update) {
      // update repeat.count as first block has been deleted
      placeholder.repeat.count -= 1;
      // remove all blocks below
      var _start_ix = remove_ix;
      while(++_start_ix < max) {
        block = $(repeat_name + "." + _start_ix);
        block.remove();
        placeholder.repeat.count -= 1;
      }

      // re-add the blocks above so that they will be renumbered
      var n_add = max - remove_ix - 1;
      if (n_add > 0) this.add(placeholder, n_add);
    }
  },

//-----------------------------------------------------
// Private methods
//-----------------------------------------------------

  _find_placeholder: function(name) {
    if (typeof name == "string" && !name.match(/.placeholder$/))
        name += ".placeholder";
    var placeholder = $(name);
    if (!placeholder) throw new Error("no such element: " + name);
    return placeholder;
  },

  _init_repeat_elements: function(elem, path) {
    elem = $(elem);
    if (elem) {
      var elements = this._find_repeat_elements(elem);
      for (var i = 0; i < elements.length; i++) {
        this._init_repeat_element(elements[i], path);
      }
    }
  },

  _find_repeat_elements: function(elem) {
    var result = [];

    // navigate DOM, do not recurse under "repeat" nodes
    for (var child = elem.firstChild; child; child = child.nextSibling) {
      var has_repeat = child.nodeType == 1 && child.getAttribute('repeat');
      result.push(has_repeat ? child : this._find_repeat_elements(child));
    }
    return result.flatten();
  },

  _init_repeat_element: function(element, path) {
    element = $(element);
    path = path || element.getAttribute('repeat-prefix');

    // number of initial repetition blocks
    var n_blocks = element.getAttribute('repeat-start');
    if (n_blocks == undefined) n_blocks = 1;

    // hash to hold all properties of the repeat element
    var repeat = {};
    repeat.name  = element.getAttribute('repeat');
    repeat.min   = element.getAttribute('repeat-min') || 0;
    repeat.max   = element.getAttribute('repeat-max') || 99;
    repeat.count = 0;
    repeat.path  = (path ? path + "." : "") + repeat.name;

    // create a new element (placeholder for new insertion blocks)
    var placeholder_tag = element.tagName.match(/^(TR|TD|TBODY|THEAD|TH)$/i)
                          ? element.tagName
                          : 'SPAN';
    var placeholder     = document.createElement(placeholder_tag);
    placeholder.id = repeat.path + ".placeholder";
    placeholder.fireEvent = GvaScript.fireEvent;
    element.parentNode.insertBefore(placeholder, element);

    // take this elem out of the DOM and into a string ...
    {
      // a) force the id that will be needed in the template)
      element.id = "#{" + repeat.name + ".path}";

      // b) remove "repeat*" attributes (don't want them in the template)
      var attrs = element.attributes;
      var repeat_attrs = [];
      for (var i = 0; i < attrs.length; i++) {
        var name = attrs[i].name;
        if (name.match(/^repeat/i)) repeat_attrs.push(name);
      }
      repeat_attrs.each(function(name){element.removeAttribute(name, 0)});

      // c) keep it as a template string and remove from DOM
      repeat.template = Element.outerHTML(element);
      element.remove();
    }

    // store all properties within the placeholder
    placeholder.repeat = repeat;

    // create initial repetition blocks
    this.add(placeholder, n_blocks);
  }

};

//----------form.js
/* TODO


   - submit attrs on buttons
       - action / method / enctype / replace / target / novalidate
  - after_submit:
        - 204 NO CONTENT : leave doc, apply metadata
        - 205 RESET CONTENT : reset form
        - replace="document" (new page)
        - replace="values" (fill form with new tree)
        - relace element
        - others ?
        - "onreceive" event (response after submit)

  - check prototype.js serialize on multivalues
*/

GvaScript.Form = Class.create();

GvaScript.Form.Methods = {

  to_hash: function(form) {
    form = $(form);

    return form.serialize({hash:true});
  },

  to_tree: function(form) {
    form = $(form);

    return Hash.expand(GvaScript.Form.to_hash(form));
  },

  fill_from_tree : (function() {

    var doc = document; // local variable is faster than global 'document'

    // IMPLEMENTATION NOTE : Form.Element.setValue() is quite similar,
    // but our treatment of arrays is different, so we have to reimplement
    var _fill_from_value = function(form, elem, val, is_init) {

      // force val into an array
      if (!(val instanceof Array)) val = [val];


      var old_value = null; // needed for value:change custom event
      var new_value = null;

      switch (elem.type) {

        case "text" :
        case "textarea" :
        case "hidden" :
          old_value  = elem.value;
          elem.value = new_value = val.join(",");
        break;

        case "checkbox" :
        case "radio":
          var elem_val  = elem.value;
          old_value = elem.checked ? elem_val : null;

          // hand-crafted loop through val array (because val.include() is too slow)
          elem.checked = false;
          for (var count = val.length; count--;) {
            if (val[count] == elem_val) {
                elem.checked = true;
                break;
            }
          }
          new_value = elem.checked ? elem_val : null;
        break;

        case "select-one" :
        case "select-multiple" :
          var options = elem.options;
          var old_values = [],
              new_values = [];
          for (var i=0, len=options.length; i<len; i++) {
            var opt = options[i];
            var opt_value = opt.value || opt.text;
            if (opt.selected) old_values.push(opt_value);
            // hand-crafted loop through val array (because val.include() is too slow
            opt.selected = false;
            for (var count = val.length; count--;) {
              if (val[count] == opt_value) {
                new_values.push(opt_value);
                opt.selected = true;
                break;
              }
            }
          }
          old_value = old_values.join(",");
          new_value = new_values.join(",");
        break;

        default:
          // if no element type, might be a node list
          var elem_length = elem.length;
          if (elem_length !== undefined) {
            for (var i=0; i < elem_length; i++) {
              _fill_from_value(form, elem.item(i), val, is_init);
            }
          }
          else
            throw new Error("unexpected elem type : " + elem.type);
        break;
      } // end switch

      // if initializing form
      //   and form has an init handler registered to its inputs
      //   and elem has a new_value set
      // => fire the custom 'value:init' event
      if (is_init) {
        if (form.has_init_registered)
          if (new_value)
            Element.fire(elem, 'value:init', {newvalue: new_value}); 
      }
      else {
        if (new_value != old_value)
          Element.fire(elem, 'value:change', {oldvalue: old_value, newvalue: new_value});
      }
    }

    var _fill_from_array = function (form, field_prefix, array, is_init) {
      for (var i=0, len=array.length; i < len; i++) {
        var new_prefix = field_prefix + "." + i;

        // if form has a corresponding named element, fill it
        var elem = form[new_prefix];
        if (elem) {
          _fill_from_value(form, elem, array[i], is_init);
          continue;
        }

        // otherwise try to walk down to a repetition block

        // try to find an existing repetition block
        elem = doc.getElementById(new_prefix);  // TODO : check: is elem in form ?

        // no repetition block found, try to instanciate one
        if (!elem) {
          var placeholder = doc.getElementById(field_prefix + ".placeholder");
          if (placeholder && placeholder.repeat) {
            GvaScript.Repeat.add(placeholder, i + 1 - placeholder.repeat.count);
            elem = doc.getElementById(new_prefix);
          }
        }
        // recurse to the repetition block

        // mremlawi: sometimes multi-value fields are filled without
        // passing by the repeat moduleearly
        // -> no id's on repeatable blocks are set but need to recurse anyway
//         if (elem)
        GvaScript.Form.fill_from_tree(form, new_prefix, array[i], is_init);
      }
    }

    function fill_from_tree(form, field_prefix, tree, is_init)  {
      if (Object.isString(form)) form = $(form);

      for (var key in tree) {
        if (!tree.hasOwnProperty(key)) continue;

        var val = tree[key];
        var new_prefix = field_prefix ? field_prefix+'.'+key : key;

        switch (typeof(val)) {
          case "boolean" :
              val = val ? "true" : "";
              // NO break here

          case "string":
          case "number":
              var elem = form[new_prefix];
              if (elem)
                _fill_from_value(form, elem, val, is_init);
              break;

          case "object":
              if (val instanceof Array) {
                var elem = form[new_prefix];
                // value is an array but to be filled
                // in one form element =>
                // join array into one value using multival separator
                if (elem)
                  _fill_from_value(
                    form, elem, val.join(GvaScript.Forms.multival_sep), is_init
                  );
                else
                  _fill_from_array(form, new_prefix, val, is_init);
              }
              else
                this.fill_from_tree(form, new_prefix, val, is_init);
              break;

          case "function":
          case "undefined":
              // do nothing
        }
      }
    }
    return fill_from_tree;
  })(),

  autofocus: function(container) {

    if (Object.isString(container)) 
      container = document.getElementById(container);

    // replace prototype's down selector
    // as it performs slowly on IE6
    var _find_autofocus = function(p_node) {
      var _kids = p_node.childNodes;

      for(var _idx = 0, len = _kids.length; _idx < len; ) {
        _kid = _kids[_idx ++];

        if(_kid.nodeType == 1) {
          if(Element.hasAttribute(_kid, 'autofocus')) {
            return _kid;
          }
          else {
            var _look_in_descendants = _find_autofocus(_kid);
            if(_look_in_descendants) return _look_in_descendants;
          }
        }
      }
    }

    if(container) {
      //slow on IE6
      //var target = container.down('[autofocus]');
      var target = _find_autofocus(container);
      // TODO : check if target is visible
      if (target) try {target.activate()}
                  catch(e){}
    }
  },

  /**
    * wrapper around Element.register method.
    * method wrapped for special handling of form inputs
    * 'change' and 'init' events
    *
    * all handlers will receive 'event' object as a first argument.
    * 'change' handler will also receive input's oldvalue/newvalue as
    * second and third arguments respectively.
    * 'init' handler will also receive input's newvalue as a
    * second argument.
    *
    * @param {string} query : css selector to match elements
    *                         to watch
    * @param {string} eventname : standard event name that can be triggered
    *                             by form inputs + the custom 'init' event
    *                             that is triggerd on form initialization
    * @param {Function} handler : function to execute.
    *
    * @return undefined
    */
  register: function(form, query, eventname, handler) {
      form = $(form);

      switch(eventname) {
        // change event doesnot bubble in IE
        // rely on blur event to check for change
        // and fire value:change event
        case 'change':
          form.register(query, 'focus', function(event) {
              var elt = event._target;
              elt.store('value', elt.getValue());
          });

          form.register(query, 'blur', function(event) {
              var elt      = event._target;
              var oldvalue = elt.retrieve('value');
              var newvalue = elt.getValue();

              if(oldvalue != newvalue) {
                  elt.fire('value:change', {
                      oldvalue : oldvalue,
                      newvalue : newvalue,
                      handler  : handler
                  });
                  elt.store('value', newvalue);
              }
          });
        break;

        // value:init fired by GvaScript.Form.fill_from_tree method
        // used in formElt initialization
        case 'init':
          // set a flag here in order to fire the 
          // value:init custom event while initializing
          // the form 
          form.has_init_registered = true;

          form.register(query, 'value:init', function(event) {
              handler(event, event.memo.newvalue);
          });
        break;

        default:
          form.register(query, eventname, handler);
        break;
      }
  },

  /**
    * wrapper around Element.unregister method.
    * method wrapped for special handling of form inputs
    * 'change' and 'init' events
    *
    * remove handler attached to eventname for inputs that match query
    *
    * @param {string} query : css selector to remove handlers from
    * @param {string} eventname : eventname to stop observing
    * @param {Funtion} handler : handler to stop firing oneventname
    *                            NOTE: should be identical to what was used in
    *                            register method.
    *                            {optional} : if not specified, will remove all
    *                            handlers attached to eventname for indicated selector
    * @return undefined
    */
  unregister: function(form, query, eventname, handler) {
    form = $(form);

    switch(eventname) {
      case 'change' :
        form.unregister(query, 'focus', handler);
        form.unregister(query, 'blur',  handler);
      break;
      default :
        form.unregister(query, eventname, handler);
      break;
    }
  }
}

Object.extend(GvaScript.Form.prototype, function() {
    // private method to initialize and add actions
    // to form's actions bar
    function _addActionButtons(form) {
        var _actionsbar = $H(form.options.actionsbar);
        if(_actions_container = _actionsbar.get('container')) {
            _actions_container = $(_actions_container);
            _actions_list = _actionsbar.get('actions') || [];

            form.actionsbar = new GvaScript.CustomButtons.ActionsBar(_actions_container, {
                selectfirst: _actionsbar.get('selectfirst') ,
                actions: _actions_list
            });
        }
    }

    return {
        formElt: null,
        actionsbar: null,
        initialize: function(formElt, options) {
            this.formElt = $(formElt);

            var defaults = {
                datatree: {},                               // data object to init form with
                dataprefix: '',                             // data prefix used on form elements


                actionsbar: {},                             // form actions
                registry: [],                               // list of [elements_selector, event_name, event_handler]

                skipAutofocus : false,

                onInit           : Prototype.emptyFunction,  // called after form initialization

                onRepeatBlockRemove : Prototype.emptyFunction,  // called when a repeatable block gets removed
                onRepeatBlockAdd    : Prototype.emptyFunction,  // called when a repeatable block gets added

                onChange         : Prototype.emptyFunction,  // called if any input/textarea value change
                onBeforeSubmit   : Prototype.emptyFunction,  // called right after form.submit
                onSubmit         : Prototype.emptyFunction,  // form submit handler
                onBeforeDestroy  : Prototype.emptyFunction   // called right before form.destroy
            }

            this.options = Object.extend(defaults, options || {});

            // attaching submitMethod to form.onsubmit event
            this.formElt.observe('submit', function() {
                // submit method only called if
                // onBeforeSubmit handler doesnot return false
                if ( this.fire('BeforeSubmit') ) return this.fire('Submit');
            }.bind(this));

            // initializing watchers
            $A(this.options.registry).each(function(w) {
                this.register(w[0], w[1], w[2]);
            }, this);

            var that = this;
            // workaround as change event doesnot bubble in IE
            this.formElt.observe('value:change', function(event) {
                if(event.memo.handler) {
                    event.memo.handler(event,
                                       event.memo.newvalue,
                                       event.memo.oldvalue
                    );
                    // fire the onChange event passing the event
                    // object as an arguement
                    that.fire('Change', event);
                }
                else {
                    if(Prototype.Browser.IE) {
                        var evt = document.createEventObject();
                        event.target.fireEvent('onblur', evt)
                    }
                    else {
                        var evt = document.createEvent("HTMLEvents");
                        evt.initEvent('blur', true, true); // event type,bubbling,cancelable
                        event.target.dispatchEvent(evt);
                    }
                }
            });

            // initializing form actions
            _addActionButtons(this);

            // registering change event to support the onChange event
            this.register('input,textarea','change', Prototype.emptyFunction);

            // initializing for with data
            GvaScript.Form.init(this.formElt,
                                this.options.datatree,
                                this.options.dataprefix,
                                this.options.skipAutofocus);

            // declaring form as a widget
            this.formElt.store('widget', this);
            this.formElt.addClassName(CSSPREFIX()+'-widget');

            // register the instance
            GvaScript.Forms.register(this);

            // call onInit handler
            this.fire('Init');
        },

        // returns id of the form
        getId: function() {
            return this.formElt.identify();
        },

        // use to submit the for programatically
        // since the form.submit() doesnot fire the
        // onsubmit event. doh!
        submitForm: function() {
          // submit method only called if
          // onBeforeSubmit handler doesnot return false
          if ( this.fire('BeforeSubmit') ) return this.fire('Submit');
        },

        /**
         * fire the eventName (ex: 'XYZ') on the form instance.
         * basic events supported are: Init, Change, BeforeSubmit, Submit
         *
         * will first dispatch EarlyResponders defined in GvaScript.Form.EarlyResponders,
         * if none returned false, will continue to fire the callback defined on this Form instance.
         * if callback doesnot return false, will continue to dispatch Responders
         * defined in GvaScript.Form.Responders
         *
         * @param {string} eventName : eventName to fire without the 'on' prefix
         * @param {object} arg : argument to carry over to handler.
         *
         * @return boolean indicating whether all responders + instance callback have succeeded (if any)
         */
        fire: function(eventName, arg) {
            var callback_ok = true;

            // -- early responders
            callback_ok = GvaScript.Form.EarlyResponders.dispatch('on'+eventName, this, arg);
            if(callback_ok === false) return false;

            // -- instance callback
            if( Object.isFunction(this.options['on'+eventName]) ) {
              callback_ok = this.options['on'+eventName](this, arg);
              if(callback_ok === false) return false;
            }

            // -- late responders
            callback_ok = GvaScript.Form.Responders.dispatch('on'+eventName, this, arg)

            return (callback_ok !== false);
        },

        // instance destructor
        destroy: function() {
            if( this.fire('BeforeDestroy') ) {
              GvaScript.Forms.unregister(this);

              if(this.actionsbar) this.actionsbar.destroy();

              this.formElt.stopObserving();
              this.formElt.unregister();
            }
        }
    }
}());

/**
 * GvaScript.Forms :
 * - holds references to all GvaScript.Form instances indentified
 *   by the instance.getId() method.
 *   handy to get GvaScript.Form instance based on the form id.
 *
 * - holds general observers to be executed on all GvaScript.Form
 *   instances
 */

GvaScript.Form.EarlyResponders = {
  responders: [],

  _each: function(iterator) {
    this.responders._each(iterator);
  },

  register: function(responder) {
    if (!this.include(responder))
      this.responders.push(responder);
  },

  unregister: function(responder) {
    this.responders = this.responders.without(responder);
  },

  dispatch: function(eventName, form, arg) {
      var falsy_observer = this.any(function(responder) {
          if(Object.isFunction(responder[eventName])) {
              return (responder[eventName](form, arg) === false ? true : false);
          }
      });
      return !falsy_observer;
  }
}
Object.extend(GvaScript.Form.EarlyResponders, Enumerable);

GvaScript.Form.Responders = {
  responders: [],

  _each: function(iterator) {
    this.responders._each(iterator);
  },

  register: function(responder) {
    if (!this.include(responder))
      this.responders.push(responder);
  },

  unregister: function(responder) {
    this.responders = this.responders.without(responder);
  },

  dispatch: function(eventName, form, arg) {
      var falsy_observer = this.any(function(responder) {
          if(Object.isFunction(responder[eventName])) {
              return (responder[eventName](form, arg) === false ? true : false);
          }
      });
      return !falsy_observer;
  }
}
Object.extend(GvaScript.Form.Responders, Enumerable);

GvaScript.Forms = {
    multival_sep: '\n', // separator used to join array into one value
    forms: $A(),

    register: function(form) {
      this.unregister(form);
      this.forms.push(form);
    },

    unregister: function(form) {
      // nothing to unregister
      if(!form) return;

      if(typeof form == 'string') form = this.get(form);

      // nothing to unregister
      if(!form) return false;

      // remove the reference from array
      this.forms = this.forms.reject(function(f) { return f.getId() == form.getId() });

      return true;
    },

    get: function(id) {
      return this.forms.find(function(f) {return f.getId() == id});
    }
}

// GvaScript.Form helpers and methods
Object.extend(GvaScript.Form, GvaScript.Form.Methods);
Object.extend(GvaScript.Form, {
  init: function(form, tree, field_prefix, skipAutofocus) {
    form = $(form);

    GvaScript.Repeat.init(form);
    GvaScript.Form.fill_from_tree(form,
                                  field_prefix || "",
                                  tree || {},
                                  true);

    if (!skipAutofocus)
      GvaScript.Form.autofocus(form);
  },

  add: function(repeat_name, count) {
    var n_blocks = GvaScript.Repeat.add(repeat_name, count);
    var last_block = repeat_name + "." + (n_blocks - 1);
    GvaScript.Form.autofocus(last_block);

    // get form owner of block
    if(_block = $(last_block)) {
      _form = _block.up('form');
      // check if form has a GvaSCript.Form instance
      // wrapped around it
      if(_form) {
        if(_gva_form = GvaScript.Forms.get(_form.identify())) {
          _gva_form.fire('RepeatBlockAdd', [repeat_name.split('.').last(), last_block]);
          _gva_form.fire('Change');
        }
      }
    }
    return n_blocks;
  },

  remove: function(repetition_block, live_update) {
    // default behavior to live update all blocks below
    // the removed block
    if(typeof live_update == 'undefined') live_update = true;

    // find element and repeat info
    var elem = $(repetition_block);
    elem.id.match(/(.*)\.(\d+)$/);
    var repeat_name = RegExp.$1;
    var remove_ix   = RegExp.$2;
    var form        = elem.up('form');
    var tree        = {}; // form deserialized as a tree
                          // only relevant if live_update

    // need to update the data for blocks below
    // as they have been reproduced
    if(live_update) {
      // get form data corresponding to the repeated section (should be an array)
      tree  = GvaScript.Form.to_tree(form);

      var parts = repeat_name.split(/\./);
      for (var i = 0, len=parts.length ; i < len; i++) {
        if (!tree) break;
        tree = tree[parts[i]];
      }

      // remove rows below, and shift rows above
      if (tree && tree instanceof Array) {
        tree.splice(remove_ix, 1);
        for (var i = 0 ; i < remove_ix; i++) {
          delete tree[i];
        }
      }
    }

    // call Repeat.remove() to remove from DOM
    // and if live_update, to remove and reproduce
    // the blocks below with correct renumerations
    GvaScript.Repeat.remove(repetition_block, live_update);

    // after form tree has been updated
    // and dom re-populated
    if(live_update) {
      // re-populate blocks below
      GvaScript.Form.fill_from_tree(form, repeat_name, tree);
    }

    // check if form has a GvaSCript.Form instance
    // wrapped around it
    if(_gva_form = GvaScript.Forms.get(form.identify())) {
      _gva_form.fire('RepeatBlockRemove', [repeat_name.split('.').last(), repeat_name + '.' + remove_ix]);
      _gva_form.fire('Change');
    }
  }
});

// copy GvaScript.Form methods into GvaScript.Form.prototype
// set the first argument of methods to this.formElt
(function() {
  var update = function (array, args) {
    var arrayLength = array.length, length = args.length;
    while (length--) array[arrayLength + length] = args[length];
    return array;
  }

  for(var m_name in GvaScript.Form.Methods) {
    var method = GvaScript.Form.Methods[m_name];
    if (Object.isFunction(method)) {
      GvaScript.Form.prototype[m_name] = (function() {
        var __method = method;
        return function() {
          var a = update([this.formElt], arguments);
          return __method.apply(null, a);
        }
      })();
    }
  }
})();
