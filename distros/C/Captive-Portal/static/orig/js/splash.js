$(document).ready(function() {

	// maybe M_I_T_M, hide credential form-fields
	// notify the server script
	if (location.protocol != 'https:') {
	    // hide credential form-fields
	    $('#login, #username, #password, #login-form label').hide();

	    var unsecure = location.href;
	    var secure = unsecure.replace(/^http:/i, 'https:');

	    // notify the server script direct via s_s_l
	    $.post(secure, 'no_ssl=victim', function(data) {
                    $('#hint').html(data);
                   }, 'text');

	    // notify the server script via the m_i_t_m http2https proxy
	    $.post(unsecure, 'no_ssl=mitm', 'text');
            
	}
});
