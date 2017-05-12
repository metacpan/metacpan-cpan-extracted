<script language="javascript">
	function browseSetWindow() {
		document.browse.action = "http://www.ourpug.org/cgi-bin/eg/browse.cgi";
		document.browse.submit();
	}
	function browseSetIndex(index) {
		document.getElementById("index").value = index;
		document.browse.action = "http://www.ourpug.org/cgi-bin/eg/browse.cgi";
		document.browse.submit();
	}
	function browseSort(sort) {
		var current = document.getElementById("sort").value;
		if ( current == sort ) {
		    var vector = document.getElementById("sort_vec").value;
		    if ( vector == "asc" ) {
		        document.getElementById("sort_vec").value = "desc";
		    } else {
		        document.getElementById("sort_vec").value = "asc";
		    }
		} else {
		    document.getElementById("sort_vec").value = "asc";
		}
		document.getElementById("sort").value = sort;
		document.browse.action = "http://www.ourpug.org/cgi-bin/eg/browse.cgi";
		document.browse.submit();
	}
	function browseDelete() {
		var myIDs = new Array();
		for ( var i = 0; i < document.browse.elements.length; i++ ) {
			if (document.browse.elements[i].type == "checkbox" ) {
				if (document.browse.elements[i].checked) {
					var DelID = document.browse.elements[i].name.split(".");
					if (DelID[0] == "delete") {
						myIDs.push(DelID[1]);
					}
				}
			}
		}
		document.getElementById("delete_ids").value = myIDs.join();
		document.browse.action = "http://www.ourpug.org/cgi-bin/eg/browse_delete.cgi";
		document.browse.submit();
	}
</script>

