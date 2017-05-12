/*
 * RFID support for Koha
 *
 * Writtern by Dobrica Pavlinusic <dpavlin@rot13.org> under GPL v2 or later
 *
 * This provides example how to intergrate JSONP interface from
 *
 * scripts/RFID-JSONP-server.pl
 *
 * to provide overlay for tags in range and emulate form fill for Koha Library System
 * which allows check-in and checkout-operations without touching html interface
 *
 * You will have to inject remote javascript in Koha intranetuserjs using:


<!-- this is basically remote script injection, doesn't work in Chrome with SSL -->
//]]></script>

<!-- invoke local RFID javascript -->
<script type="text/javascript"
src="http://localhost:9000/examples/koha-rfid.js" 
>

<script type="text/javascript">
//<![CDATA[

 */

function barcode_on_screen(barcode) {
	var found = 0;
	$('table tr td a:contains(130)').each( function(i,o) {
		var possible = $(o).text();
console.debug(i,o,possible, barcode);
		if ( possible == barcode ) found++;
	})
	return found;
}

function rfid_secure(barcode,sid,val) {
	console.debug('rfid_secure', barcode, sid, val);
	if ( barcode_on_screen(barcode) ) 
		$.getJSON( 'http://localhost:9000/secure.js?' + sid + '=' + val + ';callback=?' )
}

var rfid_reset_field = false;

function rfid_scan(data,textStatus) {
//	console.debug( 'rfid_scan', data, textStatus );

	var span = $('span#rfid');
	if ( span.size() == 0 ) {
		$('ul#i18nMenu').append('<li><span id=rfid>RFID reader found<span>');
		span = $('span#rfid');
	}

	if ( data.tags ) {
		if ( data.tags.length === 1 ) {
			var t = data.tags[0];
//			if ( span.text() != t.content ) {
			if ( 1 ) { // force update of security

				var url = document.location.toString();
				var circulation = url.substr(-14,14) == 'circulation.pl';
				var returns = url.substr(-10,10) == 'returns.pl';

				if ( t.content.substr(0,3) == '130' ) {

					if ( circulation )
						 rfid_secure( t.content, t.sid, 'D7' );
					if ( returns )
						 rfid_secure( t.content, t.sid, 'DA' );

					var color = 'blue';
					if ( t.security.toUpperCase() == 'DA' ) color = 'red';
					if ( t.security.toUpperCase() == 'D7' ) color = 'green';
					span.text( t.content ).css('color', color);

					if ( ! barcode_on_screen( t.content ) ) {
						rfid_reset_field = 'barcode';
						var i = $('input[name=barcode]:last');
						if ( i.val() != t.content ) 
							i.val( t.content )
							.closest('form').submit();
					}

				} else {
					span.text( t.content ).css('color', 'blue' );

					if ( url.substr(-14,14) != 'circulation.pl' || $('form[name=mainform]').size() == 0 ) {
						rfid_reset_field = 'findborrower';
						$('input[name=findborrower]').val( t.content )
							.parent().submit();
					}
				}
			}
		} else {
			var error = data.tags.length + ' tags near reader: ';
			$.each( data.tags, function(i,tag) { error += tag.content + ' '; } );
			span.text( error ).css( 'color', 'red' );
		}

	} else {
		span.text( 'no tags in range' ).css('color','gray');
		if ( rfid_reset_field ) {
			$('input[name='+rfid_reset_field+']').val( '' );
			rfid_reset_field = false;
		}
	}

	window.setTimeout( function() {
		$.getJSON("http://localhost:9000/scan?callback=?", rfid_scan);
	}, 1000 ); // 1000ms
}

$(document).ready( function() {
	$.getJSON("http://localhost:9000/scan?callback=?", rfid_scan);
});
