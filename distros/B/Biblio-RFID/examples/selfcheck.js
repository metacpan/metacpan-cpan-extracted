
// configure timeouts
var end_timeout   = 3000; // ms from end page to start page
var error_timeout = 5000; // ms from error page to start page
var tag_rescan    = 200;  // ms rescan tags every 0.2s

// mock console
if(!window.console) {
	window.console = new function() {
		this.info = function(str) {};
		this.error = function(str) {};
		this.debug = function(str) {};
	};
}

var state;
var scan_timeout;
var pending_jsonp = 0;
var only_reader = '';

// timeout warning dialog
var tick_timeout = 25; // s
var tick_warning = 10; // s
var tick = 0;

function beep( message ) {
	pending_jsonp++;
	$.getJSON("/beep/" + message)
	.done( function(data) {
		pending_jsonp--;
	})
	.fail( function(data) {
		pending_jsonp--;
	});
}

function start_timeout() {
	$('#timeout').hide();
	tick = Math.round( tick_timeout * ( 1000 / tag_rescan ) );
}

function change_page(new_state) {
	if ( state != new_state ) {

		if ( new_state == 'checkin' ) {
			new_state = 'circulation'; // page has different name
			$('.checkout').hide();
			$('.checkin').show();
			circulation_type = 'checkin';
			borrower_cardnumber = 0; // fake
			only_reader = '/only/3M';
		} else if ( new_state == 'checkout' ) {
			new_state = 'circulation'; // page has different name
			$('.checkout').show();
			$('.checkin').hide();
			circulation_type = 'checkout';
			only_reader = '/only/3M';
		}

		state = new_state;

		$('.page').each( function(i,el) {
			if ( el.id != new_state ) {
				$(el).hide();
			} else {
				$(el).show();
			}
		});
		console.info('change_page', state);

		if ( state == 'start' ) {
			circulation_type = 'checkout';
			book_barcodes = {};
			$('ul#books').html(''); // clear book list
			$('#books_count').html( 0 );
			only_reader = '/only/librfid';
			scan_tags();
		}

		if ( state == 'end' ) {
			window.setTimeout(function(){
				//change_page('start');
				location.reload(); // force js VM to GC?
			},end_timeout);
		}

		if ( state == 'error' ) {
			beep( 'error page' );
			window.setTimeout(function(){
				//change_page('start');
				location.reload();
			},error_timeout);
		}

		if ( state == 'circulation' || state == 'borrower_info' ) {
			start_timeout();
		} else {
			tick = 0; // timeout disabled
		}
	}
}

function got_visible_tags(data,textStatus) {
	var html = 'No tags in range';
	if ( data.tags ) {
		html = '<ul class="tags">';
		$.each(data.tags, function(i,tag) {
			console.debug( i, tag );
			html += '<li><tt class="' + tag.security + '">' + tag.sid;
			var content = tag.content || tag.borrower.cardnumber;

			if ( content ) {
				var link;
				if ( content.length = 10 && content.substr(0,3) == 130 ) { // book
					link = 'catalogue/search.pl?q=';
				} else if ( content.length == 12 && content.substr(0,2) == 20 ) {
					link = 'members/member.pl?member=';
				} else if ( tag.tag_type == 'SmartX' ) {
					link = 'members/member.pl?member=';
				} else {
					html += '<b>UNKNOWN TAG</b> '+content;
				}

				if ( link ) {
					html += ' <a href="http://koha.example.com:8080/cgi-bin/koha/'
						+ link + content
						+ '" title="lookup in Koha" target="koha-lookup">' + content + '</a>';
						+ '</tt>';
				}

				console.debug( 'calling', state, content );
				window[state]( content, tag ); // call function with barcode

			}
		});
		html += '</ul>';

	}

	var arrows = Array( 8592, 8598, 8593, 8599, 8594, 8600, 8595, 8601 );

	html = '<div class=status>'
		+ textStatus
		+ ' &#' + arrows[ data.time % arrows.length ] + ';'
		+ '</div>'
		+ html
		;
	$('#tags').html( html ); // FIXME leaks memory?

	pending_jsonp--;
};

var wait_counter = 0;

function scan_tags() {
	if ( pending_jsonp ) {
		wait_counter++;
		console.debug('scan_tags disabled ', pending_jsonp, ' requests waiting counter', wait_counter);
		if ( wait_counter > 3 ) $('#working').show();
	} else {
		console.info('scan_tags', only_reader);
		pending_jsonp++;
		$.getJSON("/scan"+only_reader+"?callback=?", got_visible_tags).fail( function(data) {
			console.error('scan error pending jsonp', pending_jsonp);
			pending_jsonp--;
		});
		wait_counter = 0;
		$('#working').hide();
	}

	if ( tick > 0 ) {
		if ( tick < tick_warning * ( 1000 / tag_rescan ) ) {
			$('#tick').html( Math.round( tick * tag_rescan / 1000 ) );
			$('#timeout').show();
		}
		tick--;
		if ( tick == 0 ) {
			$('#timeout').hide();
			change_page('end');
		}
	}

	scan_timeout = window.setTimeout(function(){
		scan_tags();
	},tag_rescan);	// re-scan every 200ms
}

$(document).ready(function() {
		$('div#tags').click( function() {
			scan_tags();
		});

		change_page('start');
});

function fill_in( where, value ) {
	$('.'+where).each(function(i, el) {
		$(el).html(value);
	});

}

/* Selfcheck state actions */

var borrower_cardnumber;
var circulation_type;
var book_barcodes = {};

function start( cardnumber, tag ) {

	if ( tag.tag_type != 'SmartX' && ( cardnumber.length != 12 || cardnumber.substr(0,2) != "20" ) ) {
		console.error(cardnumber, 'is not borrower card', tag);
		return;
	}

	borrower_cardnumber = cardnumber; // for circulation

	fill_in( 'borrower_number', cardnumber );

	pending_jsonp++;
	$.getJSON('/sip2/patron_info/'+cardnumber)
	.done( function( data ) {
		console.info('patron', data);
		fill_in( 'borrower_name', data['AE'] );
		fill_in( 'borrower_email', data['BE'] );
		fill_in( 'hold_items',    data['fixed'].substr( 2 + 14 + 3 + 18 + ( 0 * 4 ), 4 ) * 1 );
		//fill_in( 'overdue_items', data['fixed'].substr( 2 + 14 + 3 + 18 + ( 1 * 4 ), 4 ) * 1 );
		var overdue = data['fixed'].substr( 2 + 14 + 3 + 18 + ( 1 * 4 ), 4 ) * 1;
		if ( overdue > 0 ) {
			overdue = '<span style="color:red">'+overdue+'</span>';
			beep( 'overdue: ' + overdue );
		}
		fill_in( 'overdue_items', overdue );
		fill_in( 'charged_items', data['fixed'].substr( 2 + 14 + 3 + 18 + ( 2 * 4 ), 4 ) * 1 );
		fill_in( 'fine_items',    data['fixed'].substr( 2 + 14 + 3 + 18 + ( 3 * 4 ), 4 ) * 1 );


		pending_jsonp--;
		change_page('borrower_info');
	}).fail( function(data) {
		pending_jsonp--;
		change_page('error');
	});
}

function borrower_info() {
	// nop
}

function circulation( barcode, tag ) {
	if ( barcode
			&& barcode.length == 10
			&& barcode.substr(0,3) == 130
			&& book_barcodes[barcode] != 1
			&& tag.reader == '3M810'
	) { // book, not seen yet
		book_barcodes[ barcode ] = 1;
		pending_jsonp++;
		$.getJSON('/sip2/'+circulation_type+'/'+borrower_cardnumber+'/'+barcode+'/'+tag.sid , function( data ) {
			console.info( circulation_type, data );

			var color = 'red';
			var message = 'Transakcija neuspješna. Odnesite knjige na pult!';
			if ( data['fixed'].substr(2,1) == 1 ) {
				color='green';
				message = circulation_type == 'checkout' ? 'Posuđeno' : 'Vraćeno';
			} else {
				beep( circulation_type + ': ' + data['AF'] );
			}

			if ( data['AF'] ) {
				message = data['AF'] + ' ' + message;
			}

			$('ul#books').append('<li>' + ( data['AJ'] || barcode ) + ' <b style="color:'+color+'">' + message + '</b></li>');
			$('#books_count').html( $('ul#books > li').length );
			console.debug( book_barcodes );
			pending_jsonp--;
			start_timeout(); // reset timeout
		}).fail( function() {
			change_page('error');
			pending_jsonp--;
		});
	}
}

function end() {
	// nop
}
