
$(function() {
  $('.dialog').each(function(i) {
    var name = $(this).attr('title').toLowerCase();
    name = name.replace(/\s+/g, '_');
    name = name.replace(/-/g, '_');
    $(this).dialog({
      height: $.cookie('window_' + name + '_height') || 300,
      width: $.cookie('window_' + name + '_width') || 800,
      position: [
        parseInt($.cookie('window_' + name + '_left') || 10),
        parseInt($.cookie('window_' + name + '_top') || 310*i+10) + 0 ],
      resizeStop: function(e, ui) {
        $.cookie('window_' + name + '_width', ui.size.width);
        $.cookie('window_' + name + '_height', ui.size.height);
      },
      dragStop: function(e, ui) {
        $.cookie('window_' + name + '_left', ui.position.left);
        $.cookie('window_' + name + '_top', ui.position.top);
      }
    });
    $(this).css('overflow', 'auto');
  });
  $('ul').treeview({
    collapsed: true,
    persist: "cookie"
  });
  if($('#repl')) {
    $('#repl').get(0).scrollTop = $('#repl').get(0).scrollHeight;
  }
});

$(function() {  
  $('body').children().wrapAll("<form method=post action='/'></form>");
  $('#repl input[type=text]').focus();
});


