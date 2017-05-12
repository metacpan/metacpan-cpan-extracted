
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
