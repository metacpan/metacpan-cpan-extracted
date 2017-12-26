"use strict";

var temp_limit = -1;
var humidity_limit = -1;
var logged_in;
var graph_event = null; // graph interval timer

$(document).on('pageshow', '#home', function(){

    // authentication

    $.ajax({
        async: false,
        type: 'GET',
        url: '/logged_in',
        success: function(data){
            var json = $.parseJSON(data);
            logged_in = json.status;
        }
    });

    $('div.ui-page-active #auth').addClass('a');

    if (logged_in){
        $('div.ui-page-active #auth').text('Logout');
        $('div.ui-page-active #auth').attr('href', '/logout');
    }
    else {
        $('div.ui-page-active #auth').text('Login');
        $('div.ui-page-active #auth').attr('href', '/login');
    }

    // aux buttons

    for (var i = 1; i < 9; i++){
        var aux = 'aux' + i;

        if (! logged_in){
            $('div.ui-page-active #' + aux).flipswitch("option", "disabled", true);
            $('div.ui-page-active #'+aux+'_widget').prop(
                'title',
                'You must be logged in to make changes.'
            );
        }
        else {
            $('div.ui-page-active #'+ aux).flipswitch();
            $('div.ui-page-active #'+ aux).flipswitch("option", "onText",  "ON");
            $('div.ui-page-active #'+ aux).flipswitch("option", "offText", "OFF");
        }

        // hide all generic auxs if necessary

        $.ajax({
            async: false,
            type: 'GET',
            url: '/get_aux/' + aux,
            success: function(data){
                var json = $.parseJSON(data);
                if (parseInt(json.pin) == '-1'){
                    $('div.ui-page-active #'+aux+'_widget').hide();
                }
            }
        });
    }

    // button event

    $('div.ui-page-active .button').on('change', aux_action);

    // main menu

    $('div.ui-page-active .myMenu ul li').hover(function() {
        $(this).children('ul').stop(true, false, true).slideToggle(300);
    });

    $.get('/get_config/devel', function(devel){
        if (parseInt(devel) == '1'){
            $('#time').css({'background-color': 'red'});
        }
    });

    // draggable widgets

    var s_positions = localStorage.positions || "{}";
    var positions = $.parseJSON(s_positions);

    $.each(positions, function (id, pos){
        $('div.ui-page-active #'+ id).css(pos);
    });

    $('div.ui-page-active .drag').draggable({
        handle: 'p.widget_handle',
        grid: [10, 1],
        scroll: false,
        opacity: 0.5,
        cursor: "move",
        drag: function(){

        },
        stop: function(event, ui){
            positions[this.id] = ui.position;
            localStorage.positions = JSON.stringify(positions)
        }
    });

    // set limits

    $.get('/get_control/temp_limit', function(data){
        temp_limit = data;
    });
    $.get('/get_control/humidity_limit', function(data){
        humidity_limit = data;
    });

    // initialization

    event_interval();
    display_env();
    display_light();
});


$(document).on('pageshow', '#stats', function(){

    $('div.ui-page-active .myMenu ul li').hover(function() {
        $(this).children('ul').stop(true, false, true).slideToggle(300);
    });
    $('div.ui-page-active #auth').addClass('a');

    if (logged_in){
        $('div.ui-page-active #auth').text('Logout');
        $('div.ui-page-active #auth').attr('href', '/logout');
    }
    else {
        $('div.ui-page-active #auth').text('Login');
        $('div.ui-page-active #auth').attr('href', '/login');
    }

    graph_interval();
});

// stop the graph timed event when not in stats page

$(document).on('pagebeforehide', '#stats', function(){
    clearInterval(graph_event);
});

// external functions

// events

function event_interval(){
    $.get('/get_config/event_display_timer', function(interval){
        interval = interval * 1000;
        setInterval(display_env, interval);
    });
}

// core functions

function aux_update(){

    display_time();
    display_light();

    for(var i = 1; i < 9; i++){
        var aux = 'aux'+ i;
        aux_setup(aux);
    }
}

function aux_setup(aux){

    $.ajax({
        async: true,
        type: 'GET',
        url: '/get_aux/' + aux,
        success: function(data){
            var json = $.parseJSON(data);

            if (parseInt(json.pin) == '-1'){
                return;
            }

            var onText;
            var offText;

            if (parseInt(json.override) == 1 && (aux == 'aux1'||'aux2'||'aux3')){
                onText = 'HOLD';
                offText = 'HOLD';
            }
            else {
                onText = 'ON';
                offText = 'OFF';
            }

            var checked = parseInt(json.state);

            $('div.ui-page-active #'+ aux).prop('checked', checked);

            $('div.ui-page-active #'+ aux).off('change');

            $('div.ui-page-active #'+ aux).flipswitch(
                "option",
                "onText",
                onText
            );
            $('div.ui-page-active #'+ aux).flipswitch(
                "option",
                "offText",
                offText
            );

            $('div.ui-page-active #'+ aux).flipswitch('refresh');
            $('div.ui-page-active #'+ aux).on('change', aux_action);
        }
    });
}

function aux_action(e){
    var checked = $(this).prop('checked');
    var aux = $(this).attr('id');

    $.get('/get_aux_override/'+ aux, function(get_override_data){
        var start_override_status = parseInt(get_override_data);

        $.get('/set_aux_override/'+ aux +'/'+ ! start_override_status,
        function(set_override_data){
            var set_override_json = $.parseJSON(set_override_data);

            if (set_override_json.override == -1){
                console.log("aux id " + aux + " toggling is disabled");
                alert(
                    "aux id " + aux + " toggling is disabled in the config file"
                );
                return;
            }
            else {
                // change state only after we know the override operation
                // succeeded

                $.get('/set_aux_state/'+ aux +'/'+ checked, function(set_state){
                    var set_state_json = $.parseJSON(set_state);

                    if (set_state_json.error){
                        console.log(set_state_json.error);
                    }
                });
            }
        });
    });
}

// display functions

function reset_display(){
    localStorage.clear();
    window.location.reload(true);
}

function display_time(){
    var page = $(".ui-page-active").attr("id");
     $.get('/time', function(data){
        $("div.ui-page-active #time").text(data);
    });
}

function display_light(){
    $.get('/light', function(data){
        var light = $.parseJSON(data);
        if (light.enable == "0"){
            $('div.ui-page-active .light').hide();
            return;
        }

        $('div.ui-page-active #light_on_hours').text(light.on_hours);
        $('div.ui-page-active #light_on_at').text(light.on_at);
    });
}

function display_env(){
    $.get('/fetch_env', function(data){
        var json = $.parseJSON(data);
        display_temp(json.temp);
        display_humidity(json.humidity);
    });

    aux_update();
}

function display_temp(temp){
    if (temp > temp_limit && temp_limit != -1){
        $('div.ui-page-active #temp').css('color', 'red');
    }
    else {
        $('div.ui-page-active #temp').css('color', 'green');
    }
    $('div.ui-page-active #temp').text(temp +' F');

    $('div.ui-page-active #temp_limit').text('Limit: ' + temp_limit);
}

function display_humidity(humidity){
    if (humidity < humidity_limit && humidity_limit != -1){
        $('div.ui-page-active #humidity').css('color', 'red');
    }
    else {
        $('div.ui-page-active #humidity').css('color', 'green');
    }
    $('div.ui-page-active #humidity').text(humidity +' %');

    $('div.ui-page-active #humidity_limit').text('Limit: ' + humidity_limit);
}

// statistics page JS

// events

function graph_interval(){
    $.get('/get_config/event_display_timer', function(interval){
        interval = interval * 1000;
        graph_event = setInterval(display_graphs, interval);
    });
}

function display_graphs(){
    $.get('/graph_data', function(data){
        var graph_data = $.parseJSON(data);
        create_graphs(graph_data);
    });
}

function create_graphs(data){
    var info = {
        temp: {
            above_colour: 'red',
            below_colour: 'green',
            name: '#temp_chart',
            limit: temp_limit
        },
        humidity: {
            above_colour: 'green',
            below_colour: 'red',
            name: '#humidity_chart',
            limit: humidity_limit
        }
    };

    var graphs = ['temp', 'humidity'];

    $.each(graphs, function(index, graph){
        $.plot($('div.ui-page-active ' + info[graph].name), [
            {
                data: data[graph],
                threshold: {
                    below: info[graph].limit,
                    color: info[graph].below_colour
                }
            }],
            {
                grid: {
                    hoverable: true,
                    borderWidth: 1
                },
                xaxis: {
                    ticks: []
                },
                    colors: [ info[graph].above_colour ]
                }
            );
        });

    info = null;
    graphs = null;
}
