var current;
var last;

window.onhashchange = function(){
  current = getCurrent();
  refreshOverlays();
};

function bindMousetrap(prev, next) {
  Mousetrap.bind(['left', 'up', 'pageup'], function(){
    if (current > 1) {
      current -= 1;
      refreshOverlays()
    } else {
      window.location = prev;
    }
  });
  Mousetrap.bind(['right', 'down', 'pagedown'], function(){
    if (current < last) {
      current += 1;
      refreshOverlays()
    } else {
      window.location = next;
    }
  });
}

function findLastOverlay () {
  var all = $('[ms_overlay]').map(function(){ 
    return $(this).attr('ms_overlay').split('-');
  }).map(function(){
    return this.length ? parseInt(this) : null;
  }).toArray();
  return all.sort(function(a,b){return b-a})[0];
}

function getCurrent () {
  var hash = window.location.hash.slice(1);
  if (! hash) {
    return 1;
  }
  if (hash === 'last') {
    return last;
  }
  return parseInt(hash);
}

function parseOverlaySpec (str) {
  if (str.indexOf('-') == -1) {
    str = str + '-' + str;
  }
  var a = str.split('-');
  if (a.length == 1) {
    a[1] = a[0];
  }
  if (a[0] === '') {
    a[0] = 1;
  }
  if (a[1] === ''){
    a[1] = last;
  }
  a[0] = parseInt(a[0]);
  a[1] = parseInt(a[1]);
  return a;
}

function refreshOverlays () {
  $('[ms_overlay]').each(function(){
    spec = parseOverlaySpec($(this).attr('ms_overlay'));
    if ( current >= spec[0] && current <= spec[1] ) {
      $(this).show();
    } else {
      $(this).hide();
    }
  });
}

$(function(){
  last = findLastOverlay();
  current = getCurrent();
  refreshOverlays();
});

