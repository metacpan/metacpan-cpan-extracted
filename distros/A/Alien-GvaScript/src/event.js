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

