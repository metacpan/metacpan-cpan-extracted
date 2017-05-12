"use strict";

var temp_limit = -1;
var humidity_limit = -1;

$(document).ready(function(){

    // authentication

    var logged_in;

    $.ajax({
        async: false,
        type: 'GET',
        url: '/logged_in',
        success: function(data){
            var json = $.parseJSON(data);
            logged_in = json.status;
        }
    });

    $('#auth').addClass('a');

    if (logged_in){
        $('#auth').text('Logout');
        $('#auth').attr('href', '/logout');
    }
    else {
        $('#auth').text('Login');
        $('#auth').attr('href', '/login');
    }

    // aux buttons

    for (var i = 1; i < 9; i++){
        var aux = 'aux' + i;

        if (! logged_in){
            $('#'+aux).flipswitch("option", "disabled", true);
        }
        else {
            $('#'+ aux).flipswitch();
            $('#'+ aux).flipswitch("option", "onText",  "ON");
            $('#'+ aux).flipswitch("option", "offText", "OFF");
        }

        // hide all generic auxs if necessary

        $.ajax({
            async: false,
            type: 'GET',
            url: '/get_aux/' + aux,
            success: function(data){
                var json = $.parseJSON(data);
                if (parseInt(json.pin) == '-1'){
                    // $('#'+aux+'_widget').hide();
                }
            }
        });
    }

    $('.button').on('change', flip_change);

    // main menu

    $('.myMenu ul li').hover(function() {
        $(this).children('ul').stop(true, false, true).slideToggle(300);
    });

    // draggable widgets

    var s_positions = localStorage.positions || "{}";
    var positions = $.parseJSON(s_positions);

    $.each(positions, function (id, pos){
        $('#'+ id).css(pos);
    })

    $('.drag').draggable({
        handle: 'p.widget_handle',
        grid: [10, 1],
        scroll: false,
        opacity: 0.5,
        cursor: "move",
        drag: function(){

        },
        stop: function(event, ui){
            positions[this.id] = ui.position;
            console.log(positions);
            localStorage.positions = JSON.stringify(positions)
        }
    });

    // set variables

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
        aux_state(aux);
    }
}

function aux_state(aux){

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
                onText = 'OVERRIDE';
                offText = 'OVERRIDE';
            }
            else {
                onText = 'ON';
                offText = 'OFF';
            }

            var checked = parseInt(json.state);

            $('#'+ aux).prop('checked', checked);

            $('#'+ aux).off('change');

            $('#'+ aux).flipswitch("option", "onText",  onText);
            $('#'+ aux).flipswitch("option", "offText", offText);

            $('#'+ aux).flipswitch('refresh');

            $('#'+ aux).on('change', flip_change);

        }
    });
}

function flip_change(e){
    // use this to ensure aux_state() doesn't call this event handler
    // console.log(this);

    var checked = $(this).prop('checked');
    var aux = $(this).attr('id');

    $.get('/set_aux_override/'+ aux +'/'+ checked, function(data){
        var json = $.parseJSON(data);
        if (json.error){
            console.log(json.error);
        }
    });

    $.get('/set_aux_state/'+ aux +'/'+ checked, function(data){
        var json = $.parseJSON(data);
        if (json.error){
            console.log(json.error);
        }
    });
}

// display functions

function reset_display(){
    localStorage.clear();
    window.location.reload(true);
}

function display_time(){
     $.get('/time', function(data){
        $('#time').text(data);
    });
}

function display_light(){
    $.get('/light', function(data){
        var light = $.parseJSON(data);
        if (light.enable == "0"){
            $('.light').hide();
            return;
        }
        if (light.toggle == 'disabled'){
            $('#aux3').flipswitch('option', 'disable', true);
        }
        else {
            $('#aux3').flipswitch();
        }
        $('#light_on_hours').text(light.on_hours);
        $('#light_on_at').text(light.on_at);
    });
}

function display_graphs(){
    $.get('/graph_data', function(data){
        var graph_data = $.parseJSON(data);
        create_graphs(graph_data);
    });
}

function display_env(){
    $.get('/fetch_env', function(data){
        var json = $.parseJSON(data);
        display_temp(json.temp);
        display_humidity(json.humidity);
    });

    // display_graphs();
    aux_update();
}

function display_temp(temp){
    if (temp > temp_limit && temp_limit != -1){
        $('#temp').css('color', 'red');
    }
    else {
        $('#temp').css('color', 'green');
    }
    $('#temp').text(temp +' F');
}

function display_humidity(humidity){
    if (humidity < humidity_limit && humidity_limit != -1){
        $('#humidity').css('color', 'red');
    }
    else {
        $('#humidity').css('color', 'green');
    }
    $('#humidity').text(humidity +' %');
}

//graphs

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
        $.plot($(info[graph].name), [
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
