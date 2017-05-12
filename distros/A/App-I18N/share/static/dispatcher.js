
var CQDispatcher = function( listenURL , clientId ) {
    var that = this;
	this.clientId = clientId;


    if( window.console )
        console.log( 'listening .. ' + listenURL );

    function onNewEvent(events) {
		for ( var i=0; i < events.length ; i ++ ) {
			var e = events[i];
			that.call( e.type , e );
		}
    }

    // XXX: should register auth code ?
    // dispatch handlers
    if( typeof DUI != 'undefined' )
    {
        var s = new DUI.Stream();
        s.listen('application/json', function(e) {
            var event = eval('(' + e + ')');
            onNewEvent(event);
        });
        // s.load('/chat/<%= $channel %>/mxhrpoll');
        s.load( listenURL );
    } 
    else 
    {
        // $.ev.handlers.message = onNewEvent;
        // $.ev.loop('/chat/<%= $channel %>/poll?client_id=' + Math.random());
        $.ev.loop( listenURL , onNewEvent );
    }
    this.init();
    return this;
};

CQDispatcher.prototype = {

    init: function() { 
        this._handlers = {};
    },

    add:  function(name,handler) { 
        if( ! this._handlers[ name ] ) {
            this._handlers[ name ] = new Array();
        }
        this._handlers[ name ].push( handler );
        return this;
    },

    remove: function(name,handler) { 
        if( ! this._handlers || ! this._handlers[ name ] ) {
            return null;
        }

        var hlist = this._handlers[ name ];
        for ( i in hlist ) {
            var h = hlist[i];
            if( h == handler ) {
                return delete( hlist[i] );
            }
        }
        return null;
    },

    get: function(name) { 
        return this._handlers[ name ];
    },

    call: function(name,e) {
        var hlist = this._handlers[ name ];
		if( hlist )
        for (var i=0; i < hlist.length ; i++ ) {
            var handler = hlist[i];
            handler( e );
        }

    }

};

