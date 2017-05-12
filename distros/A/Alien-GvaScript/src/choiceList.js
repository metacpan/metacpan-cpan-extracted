
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

