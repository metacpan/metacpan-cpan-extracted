// code to execute when the DOM is ready
$(document).ready(function(){

    var pattern = /w(\d+)-t(\d+)/;
   	pattern_array = new Array();
    
	$('p').click(function(e){  
     	var span_id = $(this).find('span').attr('id');
     	pattern_array = span_id.match(pattern);
     	var game_number = parseInt(pattern_array[1]);
     	var team = pattern_array[2];
     	var next_game_number;
     	if (game_number == 15 || game_number == 30) { next_game_number = 61 }
     	else if (game_number == 45 || game_number == 60) { next_game_number = 62 }
     	else if (game_number == 61 || game_number == 62) { next_game_number = 63 }
     	var new_id = 'w' + next_game_number + '-t' + team ;
		var game = next_game_number;
		var pick_game = 'p' + game;
		var pick_string = '<span id="' + new_id + '">' + '<input type="hidden" name="' + pick_game + '" value="' + team + '" /></span>';
		next_game = '#w' + game;
		$(next_game).html($(this).text() + pick_string);    
	}); 
});
