
var socket;

$(function(){

  socket = io.connect();

  socket.on('connect',function(){});

  socket.on('disconnect',function(){});

  var container = $('#main-tile-container');

  $.getJSON('/name', function(name) {
    $('#aqname').text(name);
  });

  $.getJSON('/tiles', function(tiles) {
    var tile_count = tiles.length;
    var tile_loaded = 0;
    var loaded = {};
    $.each(tiles, function(index,value) {
      $.getJSON('/tile/' + value, function(data) {
        tile_loaded += 1;
        loaded[value] = data;
        if (tile_loaded == tile_count) {
          $.each(tiles, function(index,value){
            var data = loaded[value];
            container.append(data.html);
            if (data.js) {
              $.globalEval(data.js);
            }
          });
          container.shapeshift({
            minColumns: 2,
            enableDrag: false,
            enableCrossDrop: false,
            enableResize: false,
            enableTrash: false,
          });
          socket.emit('aqhive',{ cmd: 'data' });
        }
      });
    });
  });

  $('#current-app').hide();
  $('#loading').hide();
  $('#restart').hide();

  $('#backbutton').hide().click(function(){
    $('#current-app').hide('fast');
    $('#backbutton').hide('fast');
    container.show('fast');
  });

  $('#shutdown').click(function(){
    event.preventDefault();
    $('#current-app').hide();
    $('#main-tile-container').hide('fast');
    $('#restart').show('fast');
    reload_loop();
    $.get($(this).attr('href'));
  });

});

function reload_loop() {
  setTimeout(function(){
    $.get(location.href, function(){
      location.reload(1);
    }).fail(function(){
      reload_loop();
    });
  }, 1000);
}

function call_app(url) {

  var tile_container = $('#main-tile-container');
  var app_container = $('#current-app');
  var loading = $('#loading');
  var backbutton = $('#backbutton');

  app_container.hide();
  app_container.empty();
  tile_container.hide('fast');
//  loading.show('fast');

  $.getJSON('/' + url, function(data) {
    app_container.append(data.html);
    $.globalEval(data.js);
//    loading.hide('fast');
    app_container.show('fast');
    backbutton.show('fast');
  });

}
