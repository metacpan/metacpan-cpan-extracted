var entries = []; // list of news items

// event complete: stop propagation of the event
function stopPropagation(event) {
  if (event.preventDefault) {
    event.preventDefault();
    event.stopPropagation();
  } else {
   event.returnValue = false;
  }
}

// scroll back to the previous article
function prevArticle(event) {
  for (var i=entries.length; --i>=0;) {
    if (entries[i].offsetTop < document.documentElement.scrollTop) {
      window.location.hash=entries[i].id;
      stopPropagation(event);
      break;
    }
  }
}

// advance to the next article
function nextArticle(event) {
  for (var i=1; i<entries.length; i++) {
    if (entries[i].offsetTop-20 > document.documentElement.scrollTop) {
      window.location.hash=entries[i].id;
      stopPropagation(event);
      break;
    }
  }
}

// process keypresses
function navkey(event) {
  if (!event) event=window.event;
  key=event.keyCode;
  if (!document.documentElement) return;
  if (key == 'J'.charCodeAt(0)) nextArticle(event);
  if (key == 'K'.charCodeAt(0)) prevArticle(event);
}

function personalize() {
  var h = document.getElementsByTagName('h3');
  for (var i=0; i<h.length; i++) {
    var a = h[i].getElementsByTagName('a');
    if (a.length > 1) {
      var link = a[1];
      link.id = "news-" + i;
      entries[entries.length] = link;
    }
  }

  document.onkeydown = navkey;
}

// hook event
window.onload = personalize;
if (document.addEventListener) {
    onDOMLoad = function() {
      window.onload = undefined;
      personalize();
    };
    document.addEventListener("DOMContentLoaded", onDOMLoad, false);
}
