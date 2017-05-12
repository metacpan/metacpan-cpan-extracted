



function writeAll(e) {
    var msgids = jQuery(e).parents("form").find( "*[name=msgid[]]" )
        .map( function(i,n) {
            return jQuery(n).val();
         }).get();

    var msgstrs = jQuery(e).parents("form").find( "textarea[name=msgstr[]]" )
        .map( function(i,n) {
            return jQuery(n).val();
         }).get();

    var pofile = jQuery(e).parents("form").find( "input[name=pofile]" ).val();
    //console.log( pofile , msgids , msgstrs );
    jQuery.ajax({
        url: '/',
        type: 'post',
        data: {
            'msgid[]': msgids,
            'msgstr[]': msgstrs,
            'pofile': pofile
         },
        success: function( ) { 
            jQuery.jGrowl( "Updated" );
         }
     });
    return false;
}


var EntryList = {
	UI: { },
	list: [  ],
	i: null,
	next: function() {
		if( this.i + 1 < this.list.length ) 
			return this.list[++this.i];
	},
	prev: function() {
		if( this.i > 0 )
			return this.list[ --this.i ];
	},
	current: function() {
		return this.list[this.i];
	},
	fetch: function(lang,callback) {
		var that = this;
		if( ! lang ) lang = "";
		$.getJSON( '/api/entry/list/' + lang , function(data){
			that.list = data.entrylist;
			that.i    = 0;
			callback(data);
		});
	},
	save: function(cb) {
		var that = this;
        var record = this.current().id;
        var msgstr = this.current().msgstr;

		$.ajax({
			url: '/api/entry/set',
			type: 'post',
			data: { 
				id: record,
				msgstr: msgstr
			},
			dataType: 'json',
			success: function(resp) {
				if(resp) {
					$.jGrowl( "Entry Saved: " + msgstr );
					cb( resp );
				}
			}
		});
	}
};

EntryList.UI.EditPanel = {
	init: function(lg) {
		this.lg = lg;
		this.current_lang = lg.code;

		var that = this;
		$.get( '/entry_edit' , function(html) {
			$('#panel').html( html );

			// init entry
			var entry = EntryList.current();
			that.update(entry);
			$('.prev-message').click(function(){
				var entry = EntryList.prev();
				that.update(entry);
			});
			$('.skip-message').click(function() {
				var entry = EntryList.next();
				that.update(entry);
			});
			$('.next-message').click(function() {
				EntryList.current().msgstr = $('#current-msgstr').val();
				EntryList.save( function(resp) {
					var entry = EntryList.next();
					that.update(entry);
				});
			});


		});
	},
	update: function(entry) { 
		var lang = this.current_lang;
		if(!entry)
			return;

		$('#current-lang').html( "Current Language: " + this.lg.name );
		$('#current-msgid').html( entry.msgid );
		$('#current-msgstr').val( entry.msgstr );
		$('#current-id').val( entry.id );

		var g_el = $('#google-translation');
		var g_el_text = g_el.find('div.text');
		if( g_el.get(0) ) {
			g_el.show();
			g_el_text.html( "Translating..." );
		}
		else {
			g_el = $('<div/>').attr('id','google-translation').append( $('<div/>').addClass('text') );
			$('#current-msgstr').after( g_el );
			g_el = $('#google-translation');
			g_el_text = g_el.find('div.text');
		}

        if( typeof google != "undefined" ) {
            google.language.translate( entry.msgid  , "", lang , function(result) {
                if( result.error ) {
                    g_el_text.html( "Error:" + result.error.message );
                    $.jGrowl( result.error.message , { header: 'Google Translation' , theme: 'error' , sticky: 1 } );
                } else {
                    g_el_text.html( result.translation );
                    var apply = $('<a/>').attr( { href: '#', tabindex: 5 } ).html( 'Apply' ).addClass('apply').click( function(e) {
                        $('#current-msgstr').val( result.translation );
                        g_el.fadeOut('slow');
                    });
                    g_el_text.append( apply );
                }
            });
        }

		$('#current-msgstr').focus( );

	}
};

$(document.body).ready( function() {

		jQuery.getJSON( '/api/podata' , function(langdata) {
				// console.log( data );
		
			var langlistel = jQuery( '#langlist' );
			for ( var lang in langdata ) {
				(function(lang) {
					var lg = langdata[lang];

					var link = jQuery( '<li/>' ).html( jQuery( '<a/>' ).html( lg.name ).click(function(e) {
						EntryList.fetch( lang , function(data) {
							EntryList.UI.EditPanel.init( lg );
						});
					} ));
					langlistel.append( link );
				})( lang );
			}
		});
});
