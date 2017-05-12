function(team, round) {
	
	var round_addend;
	if (round == 1) {
		round_addend = 0;
	}
	else if (round == 2) {
		round_addend = 8;
	}
	else if (round == 3) {
		round_addend = 12;
	}
	

	var divisor = 2^round;
	var team_addend = parseInt(team/divisor);
	var result = team_addend + round_addend;
	if (team % divisor != 0) {
		result = 1 + team_addend + round_addend;
	}
	
	alert(result);
}
