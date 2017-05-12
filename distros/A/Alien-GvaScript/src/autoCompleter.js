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


