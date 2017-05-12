$(document).ready(function() {
    var $dlg = $('<div></div>')
         .html('Hello world')
         .dialog({
               autoOpen: false,
               title: 'Basic dialog',
               closeOnEscape: true,
		modal: true,
               resizable: true,
         });

     $("#dialog").dialog({
					autoOpen: false,
    buttons: {
        'button 1': function() {
                alert(1);
                // handle if button 1 is clicked
        },
        'button 2': function() {
                alert(2);
                // handle if button 2 is clicked
        },
        'button 3': function() {
                alert(3);
                // handle if button 3 is clicked
        }
    }
    });

    $('#tryme').click(function(){
            alert("xxx");
    });
    
    $('#dialog_link').click(function(){
	$('#dialog').dialog('open');
	return false;
    });

     $('.keyword').click(function() {
        //alert('Show popup with explanation about ' + this.firstChild.innerHTML);
        $dlg.dialog("option", "title", this.firstChild.innerHTML);
        $dlg.dialog('open');
	return false;
     });

//     $('#dig').click(function() {
//            send_query();
//            return false;
//     });
//
//     $('#query').bind('keypress', function(e) {
//        if(e.keyCode==13){
//           send_query();
//           return false;
//        }
//     });
});

function send_query() {
            var query = $('#query').val();
            //alert($('#what').val());
            var what = $('#what').val();
            $('#result').html('Searching ...');
            $.get('/q/' + query + '/' + what, function(resp) {
                    $('#content').hide();
                    if (resp["error"]) {
                       alert(resp["error"]);
                    } else {
//alert(resp);
//                     $('#result').html('ok');
                       var html = '';
                       var data = resp["data"];
                       for (var i=0; i<data.length; i++) {
                           // distribution
                           if (data[i]["distribution"] == '1') {
                                html += '<div class="author"><a href="/id/' + data[i]["author"]   + '">' + data[i]["author"] + '</a></div>';
                                html += '<div class="name"><a href="/dist/' + data[i]["name"] + '">' + data[i]["name"]   + '</a></div>';
                                html += '<div class="version">' + data[i]["version"] + '</div>';
                           }
                           // author
                           if (data[i]["author"] == '1') {
                                var name = data[i]["asciiname"];
                                if (data[i]["name"]) {
                                        name = data[i]["name"];
                                }
                                html += '<div class="name"><a href="/id/' + data[i]["pauseid"] + '">' + data[i]["pauseid"] + '(' + name + ')' + '</a></div>';
                                if (data[i]["homepage"]) {
                                        html += '<div class="name"><a href="' + data[i]["homepage"] + '">' + data[i]["homepage"]   + '</a></div>';
                                }
                           }
                          
                           html += '<br>';
                       }
                       $('#result').html(html);
                    }
                    if (resp["ellapsed_time"]) {
                        $('#ellapsed_time').html("Ellapsed time: " + resp.ellapsed_time);
                    }
            }, 'json');
            return false;
};

