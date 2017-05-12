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
