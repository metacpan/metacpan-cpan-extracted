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
