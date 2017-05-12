
/* Sample client javascript function that queries the server for progress "name" 
 * and returns a json data structure. This could be extended to do whatever 
 * you want */
function checkProgress(name, displayCallback) {
    $.getJSON('/_progress_status/' + name, function(data) {
        console.log(data);
        displayCallback(data);
        if ( !data.in_progress ) {
            return;
        }
        setTimeout(function() { checkProgress(name, displayCallback) }, 1000);
    })
}
