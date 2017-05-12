'use strict';
var TYPES = {
	"FLAC": "audio/x-flac",
	"Vorbis": "audio/ogg",
	"AAC": "audio/aac",
	"MP3": "audio/mpeg"
};

var audio, details, start, data;
var hash_to_id = {}, inhibit_handle_hash = false;

function load_song (id) {
	audio.style.display = "inline";
	var song = data[id];
	var old_sources = document.getElementsByTagName("source");
	while(old_sources.length)
		old_sources[0].parentNode.removeChild(old_sources[0]);

	for (var i = 0 ; i < song.formats.length ; i++){
		var source = document.createElement("source");
		var type = TYPES[song.formats[i].format];
		source.setAttribute("type", type);
		source.setAttribute("src", song.formats[i].file);
		audio.appendChild(source);
	}

	details.innerHTML = "Now playing: " + song.artist + " - " + song.title;
	inhibit_handle_hash = true;
	location.hash = song.hash;
	inhibit_handle_hash = false;
	audio.load();
}

function play_random () {
	start.innerHTML = "Next";
	var id = Math.floor(Math.random() * data.length);
	load_song(id);
	audio.play();
}

function handle_hash(){
	if(!hash_to_id.hasOwnProperty(location.hash) || inhibit_handle_hash)
		return;
	load_song(hash_to_id[location.hash]);
	start.innerHTML = "Next";
	audio.play();
}

window.onload = function () {
	var container = document.getElementById("player");
	container.innerHTML = '<div id="details"></div> <button id="start_player">Play a random song</button> (or click a song title)<br><audio id="audio" controls></audio>';
	audio = document.getElementById("audio");
	details = document.getElementById("details");
	start = document.getElementById("start_player");

	data = [];
	var trs = document.querySelectorAll("tbody tr");
	for (var i = 0 ; i < trs.length ; i++) {
		var tr = trs[i];
		var song = {
			"artist": tr.getElementsByClassName("artist")[0].textContent,
			"title": tr.getElementsByClassName("title")[0].textContent,
			"hash": tr.getElementsByTagName("a")[0].dataset.hash,
			"formats": []
		};
		var formats = tr.getElementsByClassName("formats")[0].getElementsByTagName("a");
		for (var j = 0 ; j < formats.length ; j++) {
			var format = formats[j];
			song.formats.push({
				"format": format.textContent,
				"file": format.getAttribute("href")
			});
		}
		data.push(song);
		hash_to_id[song.hash] = i;
	}

	audio.style.display = "none";
	audio.addEventListener('ended', play_random);
	audio.addEventListener('error', play_random);
	start.addEventListener('click', play_random);
	window.onhashchange = handle_hash;
	handle_hash();
};
