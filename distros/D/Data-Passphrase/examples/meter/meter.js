var DATA_PASSPHRASE_LOCATION = "https://itso.iu.edu/validate/http";

var E_BAR                = "passphrase_bar";
var E_HINT               = "passphrase_hint";
var E_MESSAGE            = "passphrase_message";
var E_PASSPHRASE         = "passphrase";
var REQ_FREQ_MAX         = 400;

var Last_keypress = 0;
var Last_request  = 0;
var Request = new XMLHttpRequest();

function log(message) {
    if (!log.window_ || log.window_.closed) {
        var win = window.open("", null, "width=400,height=200," +
                              "scrollbars=yes,resizable=yes,status=no," +
                              "location=no,menubar=no,toolbar=no");
        if (!win) return;
        var doc = win.document;
        doc.write("<html><head><title>Debug Log</title></head>" +
                  "<body></body></html>");
        doc.close();
        log.window_ = win;
    }
    var logLine = log.window_.document.createElement("div");
    logLine.appendChild(log.window_.document.createTextNode(message));
    log.window_.document.body.appendChild(logLine);
}

function update_meter()
{
    // only handle requests that have completed
    if (Request.readyState != 4)
        return;

    // parse response
    var result  = eval("(" + Request.responseText + ")");
    var score   = result.score;
    var message = result.message;
    var code    = result.code;

    // get current passphrase, text, and bar objects
    var bar  = document.getElementById(E_BAR    );
    var text = document.getElementById(E_MESSAGE);

    // update bar width
    bar.style.width = score + "%";

    // update bar color
    var bar_color;
    if (score >= 80)
        bar_color = "green";
    else if (score >= 60)
        bar_color = "orange";
    else
        bar_color = "red";
    bar.style.backgroundColor = bar_color;

    // update text with numeric score
    text.innerHTML = "<span style=\"color: " + bar_color + "\">Passphrase "
        + message + "</span>";

    // handle any subsequent keypresses
    if (Last_keypress > Last_request)
        send_request();
}

function run_special_command(passphrase)
{
    var command = passphrase.substring(3);
}

function _send_request()
{
    // only maintain one request at a time
    if (Request.readyState && Request.readyState != 4)
        return;

    // build the query string
    var passphrase = document.getElementById(E_PASSPHRASE).value;
    var query_string = "passphrase=" + encodeURIComponent(passphrase);

    // hint about spaces
    var hint_element = document.getElementById(E_HINT);
    if (passphrase.length > 14 && !passphrase.match(/[^a-z]/i))
        hint_element.innerHTML = "Try using spaces between words";
    else
        hint_element.innerHTML = "";

    // update the timestamp
    var date_object = new Date();
    Last_request = date_object.getTime();

    // send the request
    Request.open("POST", DATA_PASSPHRASE_LOCATION, true);
    Request.onreadystatechange = update_meter;
    Request.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
    Request.setRequestHeader("Content-length", query_string.length);
    Request.setRequestHeader("Connection", "close");
    Request.send(query_string);
}

// space out requests to avoid overloading server
function send_request()
{
    var date_object = new Date();
    var current_time = date_object.getTime();
    var delay = REQ_FREQ_MAX - (current_time - Last_request);
    if (delay)
        setTimeout("_send_request()", delay);
    else
        _send_request();
}

function handle_keypress(field_id)
{
    // timestamp this keypress and try to send a request
    var date_object = new Date();
    Last_keypress = date_object.getTime();
    send_request();
}

function disable_return_key(event)
{
    var keycode = event ? event.which : window.event.keyCode;
    return keycode != 13;
}

function focus_input_field()
{
    document.passphrase_form.passphrase.focus();
}
