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
