/*
	HTTunnelClient
*/
function HTTunnelClient(_url) {
	this.url = _url ;
	this.fhid = null ;
	this.proto = null ;
	this.peer_info = null ;


	this.connect = function(_proto, host, port, timeout){
		this.proto = _proto ;
		if ((this.proto == null)||(this.proto == "")){
			this.proto = "tcp" ;
		}
		if ((host == null)||(host == "")){
			host = "localhost" ;
		}
		if (timeout <= 0){
			timeout = 15 ;
		}

		this.fhid = this.execute("connect", new Array(this.proto, host, port, timeout), null, null) ;
		if (this.proto == "tcp"){
			var parts = this.fhid.split(":", 3) ;
			var addr = parts[0] ; 
			var port = parts[1] ;
			this.fhid = parts[2] ;
			this.peer_info = addr + ":" + port ;
		}

		return 1 ;
	}


	this.read = function(len, timeout, callback){
		if (timeout <= 0){
			timeout = 15 ;
		}

		if (this.fhid == null){
			throw("HTTunnelClient object is not connected") ;
		}

		if (callback){
			var htc = this ;
			this.execute("read", new Array(this.fhid, this.proto, len, timeout), null, function(data, exception){
				// alert("data:" + data + ", exception:" + exception) ;
				if (exception == "timeout"){
					htc.read(len, timeout, callback) ;
				}
				else if (exception != null){
					callback(null, exception) ;
				}
				else {
		            callback(htc._post_read(data), null) ;
				}
			}) ;

			return 1 ;
        }
		else {
			// return this._post_read(data) ;
		}
	}


	this._post_read = function(data){
		if (this.proto == "udp"){
			var parts = data.split(":", 3) ;
			var addr = parts[0] ; 
			var port = parts[1] ;
			data = parts[2] ;
			this.peer_info = addr + ":" + port ;
		}

		return data ;
	}


	this.get_peer_info = function(){
		return this.peer_info ;
	}


	this.print = function(data, callback){
		if (this.fhid == null){
			throw("HTTunnel.Client object is not connected") ;
		}

		this.execute("write", new Array(this.fhid, this.proto), data, (! callback ? null : function(exception){
			callback(exception) ;
		})) ;

		return 1 ;
	}


	this.close = function(){
		if (this.fhid != null){
			this.execute("close", new Array(this.fhid), null, null) ;
			this.fhid = null ;

			return 1 ;
		}
	
		return 0 ;
	}


	this.execute = function(cmd, args, data, callback){
		var furl = this.url + "/" + cmd ;
		for (var i = 0 ; i < args.length ; i++){
			furl += ("/" + args[i]) ;
		}

		var htc = this ;
		var c = this._xmlhttprequest(furl, data, (! callback ? null : function(content){
			var exception = null ;
			try {
				content = htc._post_execute(content) ;
			}
			catch (e){
				content = null ;
				exception = e ;
			}
			callback(content, exception) ;
		})) ;
		if (! callback){
			return this._post_execute(c) ;
		}
		else {
			return 1 ;
		}
	}


	this._post_execute = function(content){
		var code = content.substring(0, 3) ;
		if (code == "err"){
			throw("Apache::HTTunnel error:" + content.substring(3)) ;
		}
		else if (code == "okn"){
			return null ;
		}
		else if (code == "okd"){
			return content.substring(3) ;
		}
		else if (code == "okt"){
			throw("timeout") ;
		}
		else {
			throw("Invalid Apache::HTTunnel response code '" + code + "'") ;
		}
	}


	// This code is isolated since it is less portable.
	this._xmlhttprequest = function(url, data, callback){
		var req = (window.XMLHttpRequest ? new XMLHttpRequest() : new ActiveXObject("Microsoft.XMLHTTP")) ;
		req.open("POST", url, (callback ? true : false)) ;
		this.request_callback(req) ;
		if (callback){
			var htc = this ;
			req.onreadystatechange = function(){
				if (req.readyState == 4){
					if (req.status == 200){
						htc.response_callback(req) ;
						var content = req.responseText ;
						// alert(content) ;
						callback(content) ;
					}
					else {
						throw("HTTP error: " + req.status + " (" + req.statusText + ")") ;
					}
				}
			} ;
			req.send(data) ;
			return 1 ;
		}
		else {
			req.send(data) ;
			this.response_callback(req) ;
			var content = req.responseText ;
			// alert(content) ;
			return content ;
		}
	}


	this.request_callback = function(xmlhttp){
	}


	this.response_callback = function(xmlhttp){
	}
}
