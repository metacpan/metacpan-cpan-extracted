// code to execute when the DOM is ready
$(document).ready(function(){

    var pattern = /r(\d+)-t(\d+)-rg(\d+)/;
   	pattern_array = new Array();
    
    //if ( $('form.regional_bracket') ) {
    	$('p').click(function(e){  
         	var span_id = $(this).find('span').attr('id');
         	pattern_array = span_id.match(pattern);
         	var round = parseInt(pattern_array[1]) + 1;
         	var team = pattern_array[2];
    		var region = pattern_array[3];
         	var new_id = 'r' + round + '-t' + team + '-rg' + region;
    		var game = advance_team(team, round, region);
    		var pick_game = 'p' + game;
    		var pick_string = '<span id="' + new_id + '">' + '<input type="hidden" name="' + pick_game + '" value="' + team + '" /></span>';
    		next_game = '#w' + game;
    		$(next_game).html($(this).text() + pick_string);    
    	}); 
  //  }
});

	
function advance_team(team, round, region) {	

	var region_addend = 15*(region - 1);
	var round_addend;
	if (round == 0) {
		round_addend = 0;
	}
	else if (round == 1) {
		round_addend = 0;
	}
	else if (round == 2) {
		round_addend = 8;
	}
	else if (round == 3) {
		round_addend = 12;
	}
	else if (round == 4) {
		round_addend = 14;
	}
	var divisor = Math.pow(2,round);
	var team_addend = parseInt( (team-( 16*(region-1 ))) / divisor);
	var result = team_addend + round_addend + region_addend;
	if (team % divisor != 0) {
		result += 1;
	}	
	//alert('round addend: ' + round_addend + ' team addend: ' + team_addend + ' region addend: ' + region_addend + ' result ' + result + ' divisor: ' + divisor  + ' round: ' + round );
	//alert(result);
	return result;
}