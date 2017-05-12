window.onload=montre;
function montre(id) {
	var d = document.getElementById(id);
	for (var i = 1; i<=10; i++) {
		if (document.getElementById('smenu'+i)) {
			if (document.getElementById('smenu'+i) != d){
				document.getElementById('smenu'+i).style.display='none';
			}
		}
	}
	if (d.style.display == 'none') {
		d.style.display='block';
	} else if (d.style.display == 'block') {
		d.style.display='none';
	}
}