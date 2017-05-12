/*
    The following snippet was taken from Ajax IN ACTION listing 3-1 p. 74.
    I modified it to remove IE support and to simplify it a bit,
    then I added my specific functions update_tree/redraw, etc.
*/
var server_stopped = 0;
var net=new Object();
net.READY_STATE_UNITIALIZED = 0;
net.READY_STATE_LOADING     = 1;
net.READY_STATE_LOADED      = 2;
net.READY_STATE_INTERACTIVE = 3;
net.READY_STATE_COMPLETE    = 4;
net.ContentLoader = function( url, onload, data ) {
    this.url     = url;
    this.onload  = onload;
    this.onerror = this.defaultError;
    this.data    = data;
    this.loadXMLDoc( url );
}
net.ContentLoader.prototype = {
    loadXMLDoc : function( url ) {
        this.req = new XMLHttpRequest();
        try {
            var loader = this;
            this.req.onreadystatechange = function() {
                loader.onReadyState.call( loader );
            }
            this.req.open( 'GET', url, true );
            this.req.send( null );
        }
        catch ( err ) {
            this.onerror.call( this );
        }
    },
    onReadyState : function () {
        var req = this.req;
        var ready = req.readyState;
        if ( ready == net.READY_STATE_COMPLETE ) {
            var httpStatus = req.status;
            if ( httpStatus == 200 || httpStatus == 0 ) {
                this.onload.call( this );
            }
            else {
                this.onerror.call( this );
            }
        }
    },
    defaultError : function () {
        alert( "error getting data " + this.req.getAllResponseHeaders() );
    }
}

/*----------------------------------------------------------------
    BEGIN my code
  ----------------------------------------------------------------*/

/*
    redraw is the net.ContentLoader callback for when the AJAX call to
    the server works.  All it does is dump the result directly into the
    raw_output field.
*/
function redraw() {
    var output_area       = document.getElementById( 'raw_output' );
    output_area.innerHTML = this.req.responseText;

    chat( 'chatter',       '' );
    chat( 'debug_chatter', '' );
}

/*
    redraw_add_div is the net.ContentLoader callback for when you need to
    update both the raw_output div and add to hideable div.

    You must pass the name of the hideable div to which the new div
    will be appended as that third (and final) argument to the
    net.ContentLoader constructor.

    The server needs to return two concatenated pieces:
        the text of the html to add to the app body
        the deparsed tree output
    These are split at the first line beginning 'config {'.
*/
function redraw_add_div() {
    // break response into parts
    var response     = this.req.responseText;
    //chat( 'debug_chatter', response );
    var break_point  = response.indexOf( "config {" );
    var new_div_text = response.substring( 0, break_point - 1 );
    var new_input    = response.substring( break_point );

    // show the new input file as raw output
    var output_area       = document.getElementById( 'raw_output'     );
    output_area.innerHTML = new_input;

    // add the new div to the table body, don't forget the line break
    var div_area = document.getElementById( this.data );

    var new_node       = document.createElement( 'div' );
    var new_br         = document.createElement( 'br' );
    new_node.innerHTML = new_div_text;

    div_area.appendChild( new_node );
    div_area.appendChild( new_br );
}

/*
    redraw_add_field is the net.ContentLoader callback for when you need to
    update both the raw_output div and add a field to a table.

    You must pass 'table_ident' for the new field as the third
    (and final) argument to the net.ContentLoader constructor.

    The server needs to return two concatenated pieces:
        the text of the html to add to the app body
        the deparsed tree output
    These are split at the first line beginning 'config {'.
*/
function redraw_add_field() {
    // break response into parts
    var response      = this.req.responseText;
    var break_point   = response.indexOf( "config {" );
    var new_html_text = response.substring( 0, break_point - 1 );
    var new_input     = response.substring( break_point );

    var new_pieces    = new_html_text.split( /<!-- END DATA TABLE -->/ );
    var new_data_tbl  = new_pieces[0];
    var new_html      = new_pieces[1].split( /<!-- END QUICK TABLE -->/ );
    var new_quick     = new_html[0];
    var new_divs      = new_html[1].split( /<!-- BEGIN DIV -->/ );

    // show the new input file as raw output
    var output_area       = document.getElementById( 'raw_output'     );
    output_area.innerHTML = new_input;

    var pieces            = this.data.split( /::/ );
    var table_ident       = pieces[0];
    var field_names       = pieces[1].split( /\s+/ );

    // add the new divs to the pull down and quick edit box
    var div_area    = document.getElementById( 'fields_for_' + table_ident );
    var select_list = document.getElementById( table_ident + '_fields' );

    for ( var i = 0; i < new_divs.length; i++ ) {

        // create the new node
        var new_node           = document.createElement( 'div' );
        new_node.innerHTML     = new_divs[i];
        new_node.style.display = 'none';

        div_area.appendChild( new_node );

        // put the new field into the pull down Edit Field list
        var children    = new_node.childNodes;
        new_id_text     = children[0].id; // there is only one child
        var new_ident   = new_id_text.replace( /div_/, '' );

        new_node.setAttribute( 'id', 'field_edit_' + new_ident );

        var new_option  = new Option(
                field_names[i], table_ident + '::' + new_ident
        );
        new_option.setAttribute( 'id', 'field_edit_option::' + new_ident );
        select_list.add( new_option, null );
    }

    // replace the quick edit box
    var quick_table = document.getElementById(
            'quick_table::' + table_ident
    );
    quick_table.innerHTML = new_quick;

    // replace the data statement table
    var data_div = document.getElementById( 'hideable_data_' + table_ident );

    data_div.innerHTML = new_data_tbl;
}

/*
    redraw_data is the net.ContentLoader callback for data statement table
    updates.

    You must pass the id of one of the input fields in the data statement
    table as the third (and final) argument to the
    net.ContentLoader constructor.

    The server needs to return two concatenated pieces:
        the text of the html to replace the old data statement table
        the deparsed tree output
    These are split at the first line beginning 'config {'.
*/
function redraw_data() {
    // break response into parts
    var response     = this.req.responseText;
    var break_point  = response.indexOf( "config {" );
    var new_div_text = response.substring( 0, break_point - 1 );
    var new_input    = response.substring( break_point );

    // show the new input file as raw output
    var output_area       = document.getElementById( 'raw_output'     );
    output_area.innerHTML = new_input;

    // replace the old table with the new one
    // data is of this form: data_value::ident_10::ident_5::2
    var pieces      = this.data.split( /::/ );
    var table_ident = pieces[1];

    var data_div = document.getElementById( 'hideable_data_' + table_ident );

    data_div.innerHTML = new_div_text;
}

// Please don't cop out and use this ghostcode.
///*
//    refresh_app_body is the net.ContentLoader callback for when the AJAX
//    call needs to do a hard reload of the app_body tab to reflect multiple
//    changes (like when a field name changes).
//*/
//function refresh_app_body() {
//    var main_div = document.getElementById( 'tabs' );
//    // ask for a hard page reload
//    document.location.replace(
//        '/main/tab-app-body/' +
//        main_div.scrollTop + '/' +
//        document.body.scrollTop
//    );
//}

/*
    redraw_quickall is the net.ContentLoader callback for checkboxes
    in the heading of a field quick edit box.  It sets all the checkboxes
    for individual fields to the value of master checkbox.  It does this
    for both the quick edit box and full edit boxes.
*/
function redraw_quickall() {
    // break response into parts
    var response     = this.req.responseText;
    var break_point  = response.indexOf( "config {" );
    var dom_updates  = response.substring( 0, break_point );
    var new_input    = response.substring( break_point );

    // show the new input file as raw output
    var output_area       = document.getElementById( 'raw_output'     );
    output_area.innerHTML = new_input;

    // Now make the other updates based on what it returned.
    var answers      = dom_updates.split( /;/ );
    var new_value    = answers[0];
    var table_ident  = answers[1];
    var field_idents = answers[2].split( /,/ );

    var keyword      = this.data;

    // First, set the check marks in the quick edit box.
    // Then, set the check marks in the full edit boxes.
    for ( var i = 0; i < field_idents.length; i++ ) {

        var quick_box_id  = 'quick_' + keyword + '_' + field_idents[i];
        var quick_box     = document.getElementById( quick_box_id );

        var full_box_id   = field_idents[i] + '::' + keyword;
        var full_box      = document.getElementById( full_box_id );

        if ( new_value > 0 ) {
            quick_box.checked = 'checked';
            full_box.checked  = 'checked';
        }
        else {
            quick_box.checked = undefined;
            full_box.checked  = undefined;
        }
    }
}

/*
    redraw_quick is the net.ContentLoader callback for fields in a
    quick edit box.  It updates the corresponding input element in the
    full edit for the table.
*/
function redraw_quick() {
    // break response into parts
    var response      = this.req.responseText;
    var break_point   = response.indexOf( "config {" );
    var instructions  = response.substring( 0, break_point - 1 );
    var new_input     = response.substring( break_point );

    // first do the normal thing (like redraw would)
    var output_area       = document.getElementById( 'raw_output' );
    output_area.innerHTML = new_input;

    chat( 'chatter', '' );

    var pieces    = this.data.split( /;/ );
    var input_id  = pieces[0];
    var new_value = pieces[1];
    var type      = pieces[2];

    var input_el = document.getElementById( input_id );

    if ( input_el ) {
        if ( type == 'field_statement_text' ) {
            input_el.value = new_value;
        }
        else if ( new_value == 'true' ) {
            input_el.checked = 'checked';
        }
        else {
            input_el.checked = undefined;
        }
    }
    else {  // it must not have an id => its a multiple
        var input_els = document.getElementsByName( input_id );

        input_els[0].value = new_value;
        for ( var i = 1; i < input_els.length; i++ ) {
            input_els[i].value = '';
        }
    }

    follow_instructions( instructions );
}

/*
    redraw_full_edit is the net.ContentLoader callback for fields in a
    full edit box which have corresponding field in a quick edit box.
    It updates the corresponding input element in that quick edit box for
    the table.
*/
function redraw_full_edit() {
    // first do the normal thing (like redraw would)
    var output_area       = document.getElementById( 'raw_output' );
    output_area.innerHTML = this.req.responseText;

    chat( 'chatter', '' );

    var pieces    = this.data.split( /;/ );
    var input_id  = pieces[0];
    var new_value = pieces[1];
    var type      = pieces[2];

    pieces        = input_id.split( /::/ );
    var ident     = pieces[0];
    var keyword   = pieces[1];

    var quick_id  = 'quick_' + keyword + '_' + ident;

    var input_el = document.getElementById( quick_id );

    if ( input_el ) {
        if ( type == 'field_statement_text' ) {
            input_el.value = new_value;
        }
        else if ( new_value == 'true' ) {
            input_el.checked = 'checked';
        }
        else {
            input_el.checked = undefined;
        }
    }
}

/*
    redraw_name_change is the net.ContentLoader callback for name changes.
    These tend to cause action at a distance updates.  The front end returns
    not only the new bigtop input dump, but a list of input ids to update.
    You can also use this callback any time the AJAX request will return
    instructions, for example when the change might affect the app
    level config table.
*/
function redraw_name_change() {
    // break response into parts
    var response      = this.req.responseText;
    var break_point   = response.indexOf( "config {" );
    var instructions  = response.substring( 0, break_point - 1 );
    var new_input     = response.substring( break_point );

    // first do the normal thing (like redraw would)
    var output_area       = document.getElementById( 'raw_output' );
    output_area.innerHTML = new_input;

    chat( 'chatter', '' );

    follow_instructions( instructions );
}

/*
    follow_instructions updates statements with new values.
    Parameter: instructions - the JSON string representing an array
    of steps to take.  Each entry is a hash with two keys.  One of the
    keys is always keyword which must be the unique id or name of
    the statement you are updating.  The other key is one of these:
        value   the document element should have its value changed to this
        text    the document element should have its text changed to this
        values  the set of elements should have these values
        hashes  the set of paired elements should have these key/value pairs
                each hash has keyword and value keys
*/
function follow_instructions( instructions ) {

    var opener  = instructions.indexOf( '[' );

    if ( instructions.indexOf( '[' ) == -1 ) { /* nothing to do here */
        return;
    }

    //chat( 'debug_chatter', 'about to follow instructions ' + instructions );

    var todo    = eval ( instructions );

    for ( var i = 0; i < todo.length; i++ ) {
        if ( todo[i].values ) {  // multi-valued update
            var multis = document.getElementsByName( todo[i].keyword );

            for ( var j = 0; j < todo[i].values.length; j++ ) {
                multis[j].value = todo[i].values[j];
            }
        }
        else if ( todo[i].value != null ) { // single value update
            var changer   = document.getElementById( todo[i].keyword );
            changer.value = todo[i].value;
        }
        else if ( todo[i].text != null ) {
            var changer  = document.getElementById( todo[i].keyword );
            changer.text = todo[i].text;
        }
        else if ( todo[i].hashes ) {
            for ( var k = 0; k < todo[i].hashes.length; k++ ) {
                var multi_key = document.getElementsByName(
                        todo[i].keyword + '_key'
                );
                var multi_val = document.getElementsByName(
                        todo[i].keyword + '_value'
                );

                multi_key[k].value = todo[i].hashes[k].keyword;
                multi_val[k].value = todo[i].hashes[k].value;

                // make new boxes (always needed)
                hatch_more_rows( todo[i].keyword, multi_key[k], multi_val[k] );
            }
        }
        else if ( todo[i].config_value ) {
            // we know we need a new one, otherwise we wouldn't be here
            insert_app_config( todo[i].keyword, todo[i].config_value, 0 );
        }
//        else {
//            chat( 'debug_chatter', 'do not know what to do ' + todo );
//        }
    }
}

/*
    redraw_chat is a net.ContentLoader callback for when you want to make
    an AJAX call, but want the output to appear in the chat area instead
    of in raw_output.
    The save action uses this to report errors or report confirmation.
*/
function redraw_chat() {
    chat( 'chatter', this.req.responseText );
}

/*
    redraw_stopped is a net.ContentLoader callback for when you want to show
    the user that the server is stopped.  It destroys the underlying page.
*/
function redraw_stopped() {
    var body = document.body();

    body.innerHTML = '<h2>Your tentmaker server has stopped.</h2>';
}

/*
    draw_nothing is a net.ContentLoader callback for when you want to make
    an AJAX call, but don't want to update the screen
*/
function draw_nothing() {}

/*
    Tell chat the name of a div where it can dump debugging output
    and the output to send there.
*/
function chat ( chatter_name, output ) {
    var chatter = document.getElementById( chatter_name );

    chatter.innerHTML = output;
}

function dumper( some_object ) {
    var output = '';
    for ( var prop in some_object ) {
        output += prop + "<br />";
    }

    chat( 'debug_chatter', output );
}

/*
    show_or_hide toggles the visibility of bigtop section divs like
    config, backends, etc.  Pass it the name of the div and it will
    do the rest.
*/
function show_or_hide( elem_name ) {
    var elem               = document.getElementById( elem_name );
    var current_visibility = elem.style.display;

    if ( current_visibility == 'none' ) {
        elem.style.display = 'inline';
    }
    else {
        elem.style.display = 'none';
    }
}

/*
    expose_field changes the available Edit Field to the recently selected
    field name.
    Params: the selection object
*/
function expose_field ( selector ) {
    var selected_index = selector.selectedIndex;

    // loop starts at 1 because the first element is '- Select -', which
    // should hide everything
    for ( var i = 1; i < selector.options.length; i++ ) {

        var option_value  = selector.options[ i ].value;
        var ident_array   = option_value.split( /::/ );
        var table_ident   = ident_array[0];
        var field_ident   = ident_array[1];

        var div_id        = "field_edit_" + field_ident;
        var current_div = document.getElementById( div_id );

        if ( i == selected_index ) {
            current_div.style.display = 'inline';

            // make sure it is open for immediate use
            var edit_id  = "hideable_" + field_ident;
            var edit_div = document.getElementById( edit_id );
            edit_div.style.display = 'inline';
        }
        else {
            current_div.style.display = 'none';
        }
    }

// The following approach opens as many shows a new field, but keeps the
// old ones in the order they were opened.
//    var selected       = selector.options[ selected_index ].value;
//    var selected_div   = document.getElementById( "field_edit_" + selected );
//    var current_visibility = selected_div.style.display;
//
//    if ( current_visibility == 'none' ) {
//        selected_div.style.display = 'inline';
//    }
//    else {
//        selected_div.style.display = 'none';
//    }
}

/*
    walk_selections takes a select form object and returns a ][ delimited
    list of the values currently selected.  This works for single or
    multiple selects.
*/
function walk_selections ( select_element ) {
    var retval     = '';
    var selections = new Array();
    var i;

    for ( i = 0; i < select_element.options.length; i++ ) {
        if ( select_element.options[i].selected ) {
            selections.push( select_element.options[i].value );
        }
    }

    return selections.join( '][' );
}

/*
    create_app_block creates blocks (including literals) at the app
    level.  Note that you don't need this for the config block.
    It autovivifies the first time you try to put something in it.
    The type and name of the block are unloaded from the entry elements.

    See also create_* which make subblocks.
*/
function create_app_block () {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var type_selector = document.getElementById( 'new_app_block_type' );
    var type_namer    = document.getElementById( 'new_app_block_name' );

    var selected_type = type_selector.selectedIndex;
    var block_type    = type_selector.options[ selected_type ].value;
    var block_name    = type_namer.value;

    type_namer.value  = '';

    // Go do it!
    var update_url;
    if ( block_type == 'base_controller' ) {
        update_url    = '/create_app_block/' +
                            'controller::base_controller/base_controller';
    }
    else {
        update_url    = '/create_app_block/' + block_type + '::' + block_name;
    }

    var loader        = new net.ContentLoader(
                            update_url,
                            redraw_add_div,
                            'tab-app-body'
                        );
}

/*
    delete_block deletes blocks (including literals).  These might be
    tables, controllers, literals, fields, etc.
    Note that the config block has its own delete scheme.
*/
function delete_block ( doomed_element ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var trigger_name = doomed_element.name;
    var pieces       = doomed_element.name.split( /::/ );
    var delete_type  = pieces[0];
    var doomed_ident = pieces[1];

    // var doomed_ident = trigger_name.replace( /[^:]*::/, "" );

    if ( ! confirm("Are you sure you want to delete") ) {
        return false; 
    }
    
    // Tell the backend
    var update_url   = '/delete_block/' + doomed_ident;
    var loader;
    
    loader = new net.ContentLoader( update_url, redraw_name_change );

    // Remove it from the display?
    var doomed_div      = document.getElementById( 'div_' + doomed_ident );
    var grieving_parent = doomed_div.parentNode;
    var whitespace      = doomed_div.nextSibling;
    var useless_break;
    var more_whitespace;

    try {
        useless_break   = whitespace.nextSibling;
        try {
            more_whitespace = useless_break.nextSibling;
        }
        catch ( missing_whitespace ) { }

        grieving_parent.removeChild( doomed_div );
        grieving_parent.removeChild( whitespace );
        grieving_parent.removeChild( useless_break );
        grieving_parent.removeChild( more_whitespace );
    }
    catch ( any_exception ) {
    //    chat( 'debug_chatter', "error " + any_exception.message );
    }

    if ( delete_type == 'field_block_delete' ) {
        // take it out of the pull down
        var edit_option = document.getElementById(
                'field_edit_option::' + doomed_ident
        );
        var all_options = edit_option.parentNode;
        all_options.remove( all_options.selectedIndex );

        // take it out of the quick edit box
        var quick_row = document.getElementById(
                'quick_row::' + doomed_ident
        );
        var quick_table = quick_row.parentNode;
        quick_table.removeChild( quick_row );
    }

}

/*
    create_field creates a new field in a table.
*/
function create_field ( table_ident ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var field_namer   = document.getElementById( 'new_field_' + table_ident );
    var new_name      = field_namer.value;

    field_namer.value = '';

    var param         = 'table' + '::' + table_ident + '::' +
                        'field' + '::' + new_name;

    var update_url    = '/create_subblock/' + param;
    var loader        = new net.ContentLoader(
                          update_url,
                          redraw_add_field,
                          table_ident + '::' + new_name
                        );
}

/*
    create_method creates a new method in a controller.
*/
function create_method ( controller_ident ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    // Find the new name.
    var method_namer   = document.getElementById(
                            'new_method_' + controller_ident
                         );
    var new_name       = method_namer.value;
    method_namer.value = '';

    // Find the new type.
    var method_typer   = document.getElementById(
                            'new_method_type_' + controller_ident
                         );
    var new_type       = method_typer.value;

    // Build and send request.
    var param         = 'controller' + '::' + controller_ident + '::' +
                        'method' + '::' + new_name;

    var update_url    = '/create_subblock/' + param + '/' + new_type;
    var loader        = new net.ContentLoader(
                          update_url,
                          redraw_add_div,
                          "hideable_" + controller_ident
                        );
}

/*
    create_controller_config creates a new config block in a controller.
*/
function create_controller_config ( controller_ident ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    // Find the new name.
    var method_namer   = document.getElementById(
                            'new_controller_config_' + controller_ident
                         );
    var new_name       = method_namer.value;
    method_namer.value = '';

    // Build and send request.
    var param         = 'controller' + '::' + controller_ident + '::' +
                        'config' + '::' + new_name;

    var update_url    = '/create_subblock/' + param;
    var loader        = new net.ContentLoader(
                          update_url,
                          redraw_add_div,
                          "hideable_" + controller_ident
                        );
}

/*
    update_tree does an AJAX request which will update the internal
    tree in the server and show the text version of it in the
    raw_output div (output location is goverened by redraw).
    Pass in: suffix of do_update_* method you want
             parameter to change
             new value for it
             optional extra url trailer
             optional refresh flag, make it a positive int to get a page reload
    If a name changes, you always get a page reload, otherwise set the refresh
    flag (and remember to include the extra url trailer even if its blank).
*/
function update_tree (
            update_type,
            parameter,
            new_value,
            extra,
            refresh_type
) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    // chat( 'chatter', 'updating tree with ' + update_type +
    // ' ' + parameter + ' ' + new_value );

    var encoded    = escape( new_value );
    encoded        = encoded.replace( /\//g, "%2F" );
    var update_url = '/update_' + update_type + '/'
                        + parameter + '/' + encoded + '/' + extra;

    // Remember: you can't chat if you ask for a refresh
    // chat( 'debug_chatter', update_url );

    if ( update_type == 'name' || parameter.indexOf( 'paged_conf' ) >= 0 ) {
        var loader = new net.ContentLoader( update_url, redraw_name_change );

        // if its a field name change we want to update the data statement
        // table
        if ( update_type == 'name' && parameter.indexOf( 'field' ) >= 0 ) {
            var th_el = document.getElementById( 'data_for_' + parameter );
            th_el.innerHTML = new_value;
        }
    }
    else if ( refresh_type == 'quick_edit' ) {
        var how_to_update = parameter + ';' + new_value + ';' + update_type;
        var loader = new net.ContentLoader(
                update_url, redraw_quick, how_to_update
        );
    }
    else if ( refresh_type == 'full_edit' ) {
        var how_to_update = parameter + ';' + new_value + ';' + update_type;
        var loader = new net.ContentLoader(
                update_url, redraw_full_edit, how_to_update
        );
    }
    else {
        var loader = new net.ContentLoader( update_url, redraw );
    }
}

/*
    change_data_statement updates values in an existing data statement
    or creates a new data statement.  Pass it:
        the input box from the data statements table
*/
function change_data_statement ( changing_el ) {
    var new_value  = changing_el.value;
    var for_id     = changing_el.id;

    var encoded    = escape( new_value );
    encoded        = encoded.replace( /\//g, "%2F" );

    var update_url = '/update_data_statement/' +
                     for_id + '/' + encoded;

    var loader     = new net.ContentLoader( update_url, redraw_data, for_id );
}

/*
    quick_all handles checkboxes which sit in the heading row of a
    field quick edit box.  It tells the server to set all fields for a
    given table to the checkbox value at once.  It uses its own redraw
    callback (redraw_quickall).
*/
function quick_all (table_ident, keyword, checked) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var update_url = '/table_reset_bool/'  +
                     table_ident   +
                     '/' + keyword +
                     '/' + checked;

    var loader = new net.ContentLoader( update_url, redraw_quickall, keyword );
}

/*
    update_multivalue is like update_tree, but it works for statements
    that allow multiple values.  Use one text input box for each
    value, name them all the same.  Connect them to this passing in:
        suffix of do_update_* method you want
        parameter (a.k.a. statement keyword) to change
        one of the input text elements in the group.
    Not only are all the boxes in the group checked for values, but
    if they are all full, this routine makes a new one.
    None are ever removed.
*/
function update_multivalue (
    update_type,
    parameter,
    one_input,
    refresh_type
) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var sybs          = document.getElementsByName( one_input.name );
    var new_names     = new Array;

    var current_count = sybs.length;
    var new_count     = 0;

    // Walk the text input boxes, storing values and counting them.
    SYBS:
    for ( var i = 0; i < current_count; i++ ) {
        if ( ! sybs[i].value ) { continue SYBS; }
        new_count++;
        new_names.push( sybs[i].value );
    }
    var output     = new_names.join( '][' );
    var encoded    = escape( output );
    var update_url = '/update_' + update_type + '/'
                        + parameter + '/' + encoded;

    // See if we need to add a new box.
    if ( new_count >= current_count - 1 ) { // we're full up
        // make the new box and a separator element
        var br_node = document.createElement( 'br' );
        var clone   = one_input.cloneNode( true );
        clone.value = '';

        // attach them to the parent
        var parent  = one_input.parentNode;
        parent.appendChild( br_node );
        parent.appendChild( clone );
    }
    if ( refresh_type == 'full_edit' ) {
        var how_to_update = parameter + ';' + new_names[0] + ';' + update_type;
        var loader = new net.ContentLoader(
                update_url, redraw_full_edit, how_to_update
        );
    }
    else {
        var loader      = new net.ContentLoader( update_url, redraw );
    }
}

/*
    update_pairs is like update_multivalue, but it works for statements
    that allow multiple pairs of values.  Use two text input boxes for
    each pair (one for the key, the other for the value).  Name them
    all the same.  Pass these parameters to this function:
        suffix of do_update_* method you want
        parameter (a.k.a. statement keyword) to change
        a boolean indicating whether new pair fields should hatch out
        one of the input text elements in the group
    Like update_tree_multivalue, this one makes new boxes if all the
    existing ones are full, but only if the hatch_out boolean is true.
*/
function update_pairs (update_type, parameter, hatch_out, one_input) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    // get names of the key and value fields to be updated
    var base_name  = one_input.name.replace( /_[^_]*$/, '' );
    var key_name   = base_name + "_key";
    var value_name = base_name + "_value";

    // get the sybling elemens
    var key_sybs          = document.getElementsByName( key_name );
    var new_keys          = new Array;
    var current_key_count = key_sybs.length;
    var new_key_count     = 0;

    var value_sybs          = document.getElementsByName( value_name );
    var new_values          = new Array;
    var current_value_count = value_sybs.length;
    var new_value_count     = 0;

    // Find length of longer list.
    var current_count;
    if ( current_key_count < current_value_count ) {
        current_count = current_value_count;
    }
    else {
        current_count = current_key_count;
    }

    // Walk the key boxes, storing values and counting them.
    LABEL_SYBS:
    for ( var i = 0; i < current_key_count; i++ ) {
        if ( ! key_sybs[i].value ) { continue LABEL_SYBS; }
        new_key_count++;
        new_keys.push( key_sybs[i].value );
    }
    var output_keys = new_keys.join( '][' );

    // Walk the value boxes, storing values and counting them.
    VALUE_SYBS:
    for ( var i = 0; i < current_value_count; i++ ) {
        // Note that we skip only if the KEY is blank.  We take blank
        // values just fine.
        if ( ! key_sybs[i].value )   { continue VALUE_SYBS; }
        new_value_count++;
        new_values.push( value_sybs[i].value );
    }
    var output_values = new_values.join( '][' );

    // Make and send query.
    var output_query  = "keys=" + escape( output_keys ) + "&" +
                        "values=" + escape( output_values );

    var update_url    = '/update_' + update_type + '/'
                        + parameter + '?' + output_query;

    //chat( 'debug_chatter', update_url );

    var loader        = new net.ContentLoader( update_url, redraw );

    // See if we need to add new boxes.
    if ( hatch_out > 0
            &&
         ( new_key_count == current_count
              ||
           new_value_count == current_count  ) )
    { // we're full up
        hatch_more_rows( base_name, key_sybs[0], value_sybs[0] );
    }
}

function hatch_more_rows ( base_name, key_syb, value_syb ) {
    // make the new box and a separator element
    var clone_key     = key_syb.cloneNode( true );
    var clone_value   = value_syb.cloneNode( true );
    clone_key.value   = '';
    clone_value.value = '';

    // attach them to the parent
    var parent_table  = document.getElementById(
            base_name + "_input_table"
    );

    var new_row_number  = parent_table.rows.length;
    parent_table.insertRow( new_row_number );
    var inserted_row    = parent_table.rows[ new_row_number ];

    inserted_row.insertCell( 0 );
    inserted_row.insertCell( 1 );

    inserted_row.cells[0].appendChild( clone_key );
    inserted_row.cells[1].appendChild( clone_value );
}

/*
    add_app_config puts an additional row into the app level config table.
    The name of the new config statement is unloaded from the
    app_config_new::ident text input box.
*/
function add_app_config ( ident ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var config_table    = document.getElementById(
            'app_config_table_' + ident
    );
    var last_row_number = config_table.rows.length - 1;
    // We subtract one to account for the row with the button in it.
    var first_row       = config_table.rows[ 0 ];

    var keyword_box     = document.getElementById(
            'app_config_new_' + ident
    );
    var new_keyword     = keyword_box.value;
    keyword_box.value   = '';

    config_table.insertRow( last_row_number );
    var inserted_row    = config_table.rows[ last_row_number ];
    inserted_row.id     = 'app_config::row::' + ident + '::' + new_keyword;

    for ( var i = 0; i < first_row.cells.length; i++ ) {
        inserted_row.insertCell( i );
    }

    // insert the new keyword (once installed, it is imutable)
    inserted_row.cells[0].innerHTML = new_keyword;

    // insert the text box for input
    var value_box_name = 'app_conf_value::' + ident + '::' + new_keyword;
    var value_box = myCreateNodeFromText(
         "<input type='text' name='" + value_box_name + "'" +
         "     value=''                                   " +
         "/>                                              "
    );

    value_box.onblur = config_statement_update;

    inserted_row.cells[1].appendChild( value_box );

    // insert the checkbox for accessor skipping (and check it)
    var accessor_bool_name = 'app_conf_box::' + ident + '::' + new_keyword;
    var accessor_box     = myCreateNodeFromText(
        "<input type='checkbox' value='" + accessor_bool_name + "'" +
        "       name='" + accessor_bool_name                  + "'" +
        "       checked='checked' />"
    );

    accessor_box.onchange = config_statement_accessor_update;

    inserted_row.cells[2].appendChild( accessor_box );

    // insert delete button
    var delete_button = myCreateNodeFromText(
          "<button type='button'                                      " +
          "  name='app_config_delete::" + ident + "::" + new_keyword + "' />" +
          "  Delete                                                   " +
          "</button>                                                  "
    )
    delete_button.onclick = config_statement_delete;

    inserted_row.cells[3].appendChild( delete_button );
}

/*
    add_cont_config puts an additional row into the controller level
    config table.
    The name of the new config statement is unloaded from the
    cont_config_new::ident text input box.
*/
function add_cont_config ( ident ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var config_table    = document.getElementById(
            'app_config_table_' + ident
    );
    var last_row_number = config_table.rows.length - 1;
    // We subtract one to account for the row with the button in it.
    var first_row       = config_table.rows[ 0 ];

    var keyword_box     = document.getElementById(
            'app_config_new_' + ident
    );
    var new_keyword     = keyword_box.value;
    keyword_box.value   = '';

    config_table.insertRow( last_row_number );
    var inserted_row    = config_table.rows[ last_row_number ];
    inserted_row.id     = 'app_config::row::' + ident + '::' + new_keyword;

    for ( var i = 0; i < first_row.cells.length; i++ ) {
        inserted_row.insertCell( i );
    }

    // insert the new keyword (once installed, it is imutable)
    inserted_row.cells[0].innerHTML = new_keyword;

    // insert the text box for input
    var value_box_name = 'cont_conf_value::' + ident + '::' + new_keyword;
    var value_box = myCreateNodeFromText(
         "<input type='text' name='" + value_box_name + "'" +
         "     value=''                                   " +
         "/>                                              "
    );

    value_box.onblur = config_statement_update;

    inserted_row.cells[1].appendChild( value_box );

    // insert delete button
    var delete_button = myCreateNodeFromText(
          "<button type='button'                                      " +
          "  name='app_config_delete::" + ident + "::" + new_keyword + "' />" +
          "  Delete                                                   " +
          "</button>                                                  "
    )
    delete_button.onclick = config_statement_delete;

    inserted_row.cells[2].appendChild( delete_button );
}

/*
    insert_app_config puts a new config statement into the app config table.
    It is designed to be used while following an instruction to add a
    config statement from the server.  Pass it:
        id          - ident::new_keyword where
            ident is the ident of config block which gets the new_keyword
            new_keyword is the new conf variable to define
        new_value   - value to give the variable
        no_accessor - true if you want the box checked, false otherwise
    this routine is very similar to add_app_config and the two could probably
    share
*/
function insert_app_config ( id, new_value, no_accessor ) {

    var name_pieces = id.split( '::' );
    var ident       = name_pieces[0];
    var new_keyword = name_pieces[1];

    var config_table    = document.getElementById(
            'app_config_table_' + ident
    );
    var last_row_number = config_table.rows.length - 1;
    // We subtract one to account for the row with the button in it.
    var first_row       = config_table.rows[ 0 ];

    config_table.insertRow( last_row_number );
    var inserted_row    = config_table.rows[ last_row_number ];
    inserted_row.id     = 'app_config::row::' + id

    for ( var i = 0; i < first_row.cells.length; i++ ) {
        inserted_row.insertCell( i );
    }

    // insert the new keyword (once installed, it is imutable)
    inserted_row.cells[0].innerHTML = new_keyword;

    // insert the text box for input
    var value_box_name = 'app_conf_value::' + id;
    var value_box = myCreateNodeFromText(
         "<input type='text' name='" + value_box_name + "'" +
         "     value='" + new_value + "'" +
         "/>"
    );

    value_box.onblur = config_statement_update;

    inserted_row.cells[1].appendChild( value_box );

    // insert the checkbox for accessor skipping (and check it)
    var accessor_bool_name = 'app_conf_box::' + id;
    var accessor_text      =
        "<input type='checkbox' value='" + accessor_bool_name + "'" +
        "       name='" + accessor_bool_name                  + "'";

    if ( no_accessor ) {
        accessor_text = accessor_text + "       checked='checked' />";
    }
    else {
        accessor_text = accessor_text + "/>";
    }

    var accessor_box      = myCreateNodeFromText( accessor_text );

    accessor_box.onchange = config_statement_accessor_update;

    inserted_row.cells[2].appendChild( accessor_box );

    // insert delete button
    var delete_button = myCreateNodeFromText(
          "<button type='button'                             " +
          "           name='app_config_delete::" + id + "' />" +
          "  Delete                                          " +
          "</button>                                         "
    )
    delete_button.onclick = config_statement_delete;

    inserted_row.cells[3].appendChild( delete_button );
}

/*
    delete_app_config is the button handler for all the delete buttons
    in the App Config Block table.  It tells the server to remove the
    config statement and deletes the corresponding table row in the
    browser view.
*/
function delete_app_config ( delete_button ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var name_pieces = delete_button.name.split( '::' );
    var ident       = name_pieces[1];
    var keyword     = name_pieces[2];

    // tell the backend to do the delete
    var update_url = '/delete_app_config/' + ident + '/' + keyword;
    var loader     = new net.ContentLoader( update_url, redraw );

    // update the table
    var config_row = document.getElementById(
            'app_config::row::' + ident + '::' + keyword
    );
    var config_row_number = config_row.rowIndex;
    var parent_table      = config_row.parentNode;

    parent_table.deleteRow( config_row_number );
}

/*
    The following three event handlers are attached to newly minted
    config table elements so they have the same behavior as the ones
    delivered during initial page load.
*/
function config_statement_update( event ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var source   = event.currentTarget;
    var id       = source.name;
    id           = id.replace( 'app_conf_value::', '' );
    id           = id.replace( 'cont_conf_value::', '' );

    accessor_box = document.getElementsByName( 'app_conf_box::' + id )[0];

    var accessor;
    if ( accessor_box ) {
        accessor = accessor_box.checked;
    }

    update_tree(
        'app_conf_statement',
        id,
        source.value,
        accessor
    );
}

function config_statement_accessor_update( event ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var source  = event.currentTarget;
    var id      = source.name;
    id          = id.replace( 'app_conf_box::', '' );

    update_tree(
        'app_conf_accessor',
        id,
        source.checked
    );
}

function config_statement_delete( event ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var source  = event.currentTarget;

    delete_app_config( source );
}

/*
    type_change is like update_tree, but it only affects changes in
    controller or method types.  Pass it:
        block_type - choose from controller or method
        ident      - the grammar assigned ident of the block to change
        new_type   - what to make the type
*/
function type_change ( ident, new_type ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var update_url = '/type_change/' + ident + '/' + new_type;

    var loader     = new net.ContentLoader( update_url, redraw );
}

/*
    saver puts the file back on the server's disk.
*/
function saver () {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var file_namer = document.getElementById( 'save_file_name' );
    var file_name  = file_namer.value; // don't even think about clearing this

    var encoded    = escape( file_name );
    encoded        = encoded.replace( /\//g, "%2F" );

    var url        = '/save/' + encoded;
    var loader     = new net.ContentLoader( url, redraw_chat );
}

/*
    server_stop sends an AJAX message to the server, telling it to shut
    down.  It also sets the server_stopped flag here, so future activity
    tells you that the server is down.
*/
function server_stop () {

    if ( server_stopped == 1 ) {
        alert( 'Your server is already stopped.' );
        return;
    }

    if ( ! confirm(
                "Are you sure you want to stop the server (did you save)?"
           )
    ) {
        return false; 
    }
    
    server_stopped = 1;

    var loader = new net.ContentLoader( '/server_stop', redraw_stopped );
}

/*
    myCreateNodeFromText is stolen from dojo's html.js, but cleaned
    to remove all dojo dependencies and to make only one node instead
    of an array of them.
*/
function myCreateNodeFromText ( txt ) {
    var new_div = document.createElement( 'div' );
    new_div.style.visibility = 'hidden';

    document.body.appendChild( new_div );

    new_div.innerHTML = txt;

    var node = new_div.childNodes[0].cloneNode( true );

    document.body.removeChild( new_div );

    return node;
}

/*
    changetab sets the display attribute to all tabs to none, then sets
    it to block for the selected tab.  It also puts the link for the
    tab into the active class so its link tab will highlight.  This
    idea is stolen from the sunflowerbroadband.com home page, but the
    implementation is different.
*/
function changetabs( activate_id ) {

    if ( server_stopped == 1 ) {
        alert( 'Your server is stopped.' );
        return;
    }

    var tab_holder = document.getElementById( 'tabs' );
    var tabs       = tab_holder.getElementsByTagName( 'div' );

    TABS:
    for ( var i = 0; i < tabs.length; i++ ) {
        if ( ! tabs[i].id ) { continue TABS; }

        var link_tab_id       = tabs[i].id + '-link';
        var link_tab          = document.getElementById( link_tab_id );

        // Skip descendent divs.  Ours have ids starting with tab-.
        // There are link elements with corresponding ids ending in -link.
        if ( ! link_tab ) { continue TABS; }

        if ( tabs[i].id == activate_id ) {
            tabs[i].style.display = 'block';
            link_tab.className    = 'active';
        }
        else {
            tabs[i].style.display = 'none';
            link_tab.className    = '';
        }
    }
}
