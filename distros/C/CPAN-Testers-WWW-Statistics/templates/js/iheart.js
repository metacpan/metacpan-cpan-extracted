var html;
$(document).ready(
  $.getJSON('/sponsors.json', function(data) {
    $('#iheart').empty();
    html = ''; // '<div id="iheart">';
    $.each(data, function(entryIndex, entry) {
      html += '<h2>'+entry.category+'</h2><ul>';
      $.each(entry.links, function(itemIndex, item) {
        if(item.image) {
          html += '<li><a href="' + item.href + '" title="link to ' + item.title + '"><img src="' + item.image + '" alt="' + item.title + '" ';
          if(item.width > 150) { html += 'width="150"' } else { html += 'height="50"' }
          html += ' /></a></li>';
        } else if(item.title) {
          html += '<li><a href="' + item.href + '" title="link to ' + item.title + '">' + item.title + '</a></li>';
        } else {
          html += '<li><a href="' + item.href + '" title="link to ' + item.href + '">' + item.href + '</a></li>';
        }
      });
      html += '</ul>';
    });
    // html += '</div>';
    $('#iheart').append(html);
  })
);
