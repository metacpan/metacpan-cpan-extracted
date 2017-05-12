function play_all() {
    location = "playlist.m3u?Play+Selected=1;playlist=1;" + _get_files("mp3",false);
}

function shuffle_all() {
    location = "playlist.m3u?Shuffle+Selected=1;" + _get_files("mp3",false);
}

function shuffle_selected() {
    location = "playlist.m3u?Shuffle+Selected=1;" + _get_files("mp3",true);
}

function play_selected() {
    location = "playlist.m3u?Play+Selected=1;playlist=1;" + _get_files("mp3",true);
}

function add_selected() {
    location = "playlist.m3u?Add+to+Playlist=1;" + _get_files("mp3",true); 
}

function add_all(){
    location = "playlist.m3u?Add+to+Playlist=1;" + _get_files("mp3",false); 
}


function clear_selected_playlist() {
    location = "playlist.m3u?Clear+Selected=1;" + _get_files("pl",true);
	
}


function play_selected_playlist() {    
    location = "playlist.m3u?Play+Selected=1;playlist=1;" + _get_files("pl",true);
}

function _get_files(name, selected_only) {
    var out = "";
    var f=document.apache_mp3_skin;
    for (var x=0; x<f.elements.length; x++) { 
      if ((f.elements[x].name == name) && ((!selected_only) || (f.elements[x].checked))) {
           out += "file="+escape(f.elements[x].value)+";";
        }
    }
    return out;

}


function select_all_playlist () {
	_select("pl",true);
    
}

function unselect_all_playlist () {
	_select("pl",false);
    
}

function select_all_mp3s () {
	_select("mp3",true);
}

function unselect_all_mp3s (state) {
	_select("mp3",false);
}

function _select(name, state) {
  var f=document.apache_mp3_skin;
  for (var x=0; x<f.elements.length; x++) { 
      if (f.elements[x].name == name) { f.elements[x].checked = state; }
  }  
}


