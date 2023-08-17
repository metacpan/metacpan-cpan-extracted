/*
    Beekeeper dashboard

    Copyright 2023 José Micó

    This software uses the following libraries:

    - Semantic UI - https://semantic-ui.com/
      Released under the terms of the MIT license

    - jQuery - https://jquery.com/
      Released under the terms of the MIT license

    - MQTT.js - https://github.com/mqttjs/MQTT.js
      Released under the terms of the MIT license

    - D3.js - https://d3js.org/
      Released under the terms of the ISC license

    - DataTables - https://datatables.net/
      Released under the terms of the MIT license
*/

function Dashboard () {

    $(".ui.toggle.button").click(function() {
        $(".mobile.only.grid .ui.vertical.menu").toggle(100);
    });

    $('#sidebar a').click(function(e) {
        let click = $(e.target).index();
        ['#overview','#services','#logs'].forEach(function(id,idx) {
            if (click == idx && !$(id).is(":visible")) {
                $(id+'_btn').addClass('active');
                $(id).trigger('show');
                $(id).show();
            }
            else if (click != idx && $(id).is(":visible")) {
                $(id+'_btn').removeClass('active');
                $(id).hide();
                $(id).trigger('hide');
            }
        });
    });

    let ui = {
        backend:  null,
        overview: null,
        services: null,
        logs:     null,
        auth:     null
    };

    ui.backend = new Backend (ui);
    ui.auth = new AuthUi (ui);
    ui.auth.init();

    ui.backend.connect( function() {

        ui.overview = new OverviewUi (ui);
        ui.services = new ServicesUi (ui);
        ui.logs     = new LogsUi (ui);
    });

    return ui;
}

function Backend (ui) { return {

    bkpr: null,

    connect: function(cb) {

        this.bkpr = new BeekeeperClient;

        this.bkpr.connect({
            url:        CONFIG.url,
            username:   CONFIG.username,
            password:   CONFIG.password,
            debug:      CONFIG.debug,
            on_connect: cb
        });
    },

    is_connected: function() {

        return this.bkpr.mqtt.connected;
    },

    login: function(params,cb) {

        this.bkpr.call_remote_method({
            method: 'bkpr.dashboard.login', 
            params: params,
            on_success: function(result) {
                cb(true);
            },
            on_error: function(error) {
                cb(false);
            }
        });
    },

    get_services: function(params,cb) {

        this.bkpr.call_remote_method({
            method: 'bkpr.dashboard.services', 
            params: params,
            on_success: function(result) {
                cb(result);
            },
            on_error: function(error) {
                console.log(error);
            }
        });
    },

    get_logs: function(params,cb) {

        this.bkpr.call_remote_method({
            method: 'bkpr.dashboard.logs', 
            params: params,
            on_success: function(result) {
                cb(result);
            },
            on_error: function(error) {
                console.log(error);
            }
        });
    }
}}

function AuthUi (ui) { return {

    init: function() {

        $("#auth .form").form({
            inline: true,
            on: "blur",

            fields: {
                email: {
                    identifier: "username",
                    rules: [{ type: "empty", prompt: "Please enter your username" }]
                },
                password: {
                    identifier: "password",
                    rules: [{ type: "empty", prompt: "Please enter your password" }]
                }
            },

            onSuccess: function(e) {
                e.preventDefault();
                let params = $("#auth .form").form('get values');
                $("#auth .form").form('clear');
                if (!ui.backend.is_connected()) return;
                ui.backend.login( params, function(success) {
                    if (success) {

                        ui.overview.init();
                        ui.services.init();
                        ui.logs.init();

                        $('#overview_btn').click();

                        setTimeout(function() {
                            $('#auth').hide();
                        }, 100);
                    }
                    else {
                        $('#auth .login_error').removeClass('hidden');
                    }
                });
            }
        });
    },
}}

function OverviewUi (ui) { return {

    svc_table:  null,
    chart_req:  null,
    chart_load: null,
    chart_tmr:  null,
    table_tmr:  null,
    last_data:  null,

    init: function() {

        this.svc_table = $('#bkservices').DataTable({
            order:     [[0, 'asc']],
            info:      false,
            searching: false,
            paging:    false
        });

        $('#bkservices').on('click', 'tbody td:first-child', function(e) {
            let service = this.svc_table.cell(e.target).data();
            ui.services.service = service;
            $('#svc_class').dropdown('set selected', service);
            $('#services_btn').click();
        }.bind(this));

        $('#bkservices').on('click', 'tbody td:nth-child(5)', function(e) {
            let service = this.svc_table.row(e.target).data()[0];
            service = service.replace(/::Worker$/,'');
            $('#log_service').dropdown('set selected', service);
            service = service.toLowerCase().replace(/::/g,'-');
            ui.logs.service = service;
            $('#logs_btn').click();
        }.bind(this));

        $(window).resize(function() {
            if (!$('#overview').is(":visible")) return;
            this.on_hide();
            this.on_show();
        }.bind(this));

        $('#overview').on('show', this.on_show.bind(this));
        $('#overview').on('hide', this.on_hide.bind(this));
    },

    on_show: function() {

        this.draw_charts();
        this.update_services();

        this.chart_tmr = setInterval( this.update_charts.bind(this), 1000);
        this.table_tmr = setInterval( this.update_services.bind(this), 1000);
    },

    on_hide: function() {

        clearInterval(this.chart_tmr);
        clearInterval(this.table_tmr);

        this.chart_req.clear();
        this.chart_load.clear();
    },

    draw_charts: function() {

        this.last_data = null;
        let params = { class: "_global", resolution: '1s', count: 300 };
        ui.backend.get_services( params, function(result) {

            let req  = [];
            let load = [];
            let peak = 1;

            result.forEach(function(dpoint) {
                let tstamp = dpoint[0] * 1000;
                let stats  = dpoint[1];
                req.push(  [ tstamp, +stats.nps[peak] + +stats.cps[peak] ] );
                load.push( [ tstamp, +stats.load[peak] ] );
            });

            this.chart_req  = new realTimeLineChart('chart_ovw_req', req, 300);
            this.chart_load = new realTimeLineChart('chart_ovw_load', load, 300);

            this.chart_req.draw();
            this.chart_load.draw();

            this.last_data = result[result.length - 1][0];

        }.bind(this));
    },

    update_charts: function() {

        if (!this.last_data) return;
        let params = { class: "_global", resolution: '1s', after: this.last_data, count: 300 };
        ui.backend.get_services( params, function(result) {

            if (!result.length) return;
            let peak = 1; // 0: average, 1: peak

            result.forEach(function(dpoint) {
                let tstamp = dpoint[0] * 1000;
                let stats  = dpoint[1];
                this.chart_req.add_data(  [ tstamp, +stats.nps[peak] + +stats.cps[peak] ] );
                this.chart_load.add_data( [ tstamp, +stats.load[peak] ] );
            }.bind(this));

            this.last_data = result[result.length - 1][0];

        }.bind(this));
    },

    update_services: function() {

        let params = { resolution: '1s', count: 1 };
        ui.backend.get_services( params, function(result) {

            let stats = result[0][1];
            let _global = stats._global;
            let peak = 1; // 0: average, 1: peak

            $('#ovw_req').text((+_global.cps[peak] + +_global.nps[peak]).toFixed(1));
            $('#ovw_err').text((+_global.err[peak]).toFixed(1));
            $('#ovw_mem').text((+_global.mem[peak] / 1000000).toFixed(2));
            $('#ovw_cpu').text((+_global.cpu[peak] / 100).toFixed(2));

            let load = (+_global.load[peak]).toFixed(1);
            $('#ovw_load').text(load + " %");
            $('#ovw_load').css('color', load < 50 ? 'limegreen' : load < 66 ? 'orange' : 'red');

            delete stats._global;

            let rows = Object.keys(stats).map(function(svc) {
                let s = stats[svc];
                return [
                    svc,
                    (+s.count[peak]).toFixed(),
                    (+s.mem[peak] / 1000).toFixed(1),
                    (+s.cpu[peak] / 100).toFixed(2),
                    (+s.err[peak]).toFixed(1),
                    (+s.cps[peak] + +s.nps[peak]).toFixed(1),
                    (+s.load[peak]).toFixed(1)
                ];
            });

            this.svc_table.clear().rows.add(rows).draw();

        }.bind(this));
    }
}}

function ServicesUi (ui) { return {

    service:    null,
    peak:       null,
    resolution: null,
    chart_load: null,
    chart_req:  null,
    chart_err:  null,
    chart_cpu:  null,
    chart_mem:  null,
    chart_tmr:  null,
    stats_tmr:  null,
    last_data:  null,

    init: function() {

        $('#svc_peak').dropdown({
            values: [
                { name: "Peak",    value: 1, selected: true },
                { name: "Average", value: 0  }
            ],
            onChange: function(val) {
                if (this.peak == val || !$('#services').is(":visible")) return;
                this.peak = val;
                this.draw_charts();
            }.bind(this)
        });

        this.peak = 1; // 0: average, 1: peak values

        $('#svc_resolution').dropdown({
            values: [
                { name: "10 minutes", value: "1s"  },
                { name: "1 hour",     value: "5s"  },
                { name: "1 day",      value: "2m", selected: true },
                { name: "1 week",     value: "15m" },
                { name: "1 month",    value: "1h"  }
            ],
            onChange: function(val) {
                if (this.resolution == val || !$('#services').is(":visible")) return;
                this.resolution = val;
                this.draw_charts();
            }.bind(this)
        });

        this.init_services_dropdown('#svc_class', function(val) {
            if (this.service == val || !$('#services').is(":visible")) return;
            this.service = val;
            this.draw_charts();
            this.update_stats();
        }.bind(this));

        $(window).resize(function() {
            if (!$('#services').is(":visible")) return;
            this.on_hide();
            this.on_show();
        }.bind(this));

        $('#services').on('show', this.on_show.bind(this));
        $('#services').on('hide', this.on_hide.bind(this));
    },

    on_show: function() {

        this.draw_charts();
        this.update_stats();

        this.chart_tmr = setInterval( this.update_charts.bind(this), 1000);
        this.stats_tmr = setInterval( this.update_stats.bind(this), 1000);
    },

    on_hide: function() {

        clearInterval(this.chart_tmr);
        clearInterval(this.stats_tmr);

        this.chart_load.clear();
        this.chart_req.clear();
        this.chart_err.clear();
        this.chart_cpu.clear();
        this.chart_mem.clear();
    },

    init_services_dropdown: function(dropdown_id,cb) {

        let params = { resolution: '1s', count: 1 };
        ui.backend.get_services( params, function(result) {

            let stats = result[0][1];
            delete stats._global;

            let dropdown = [{ name: "All services", value: "" }];

            Object.keys(stats).sort().forEach(function(svc,idx) {
                let lbl = svc.replace(/::Worker$/,'');
                dropdown.push({ name: lbl, value: svc });
            });

            $(dropdown_id).dropdown({
                values: dropdown,
                onChange: cb
            });
        });
    },

    draw_charts: function() {

        this.last_data = null;
        let service = this.service || '_global';
        let resolution = this.resolution || '2m';
        let count = { '1s':600, '5s':720, '2m':720, '15m':672, '1h':744 }[resolution];
        let params = { class: service, resolution: resolution, count: count };

        ui.backend.get_services( params, function(result) {

            let load = [];
            let req  = [];
            let err  = [];
            let cpu  = [];
            let mem  = [];

            let peak = this.peak;

            result.forEach(function(dpoint) {
                let tstamp = dpoint[0] * 1000;
                let stats  = dpoint[1];
                load.push( [ tstamp, +stats.load[peak] ] );
                req.push(  [ tstamp, +stats.nps[peak] + +stats.cps[peak] ] );
                err.push(  [ tstamp, +stats.err[peak] ] );
                cpu.push(  [ tstamp, +stats.cpu[peak] / 100 ] );
                mem.push(  [ tstamp, +stats.mem[peak] / 1000 ] );
            });

            this.chart_load = new realTimeLineChart('chart_svc_load', load, count);
            this.chart_req  = new realTimeLineChart('chart_svc_req',  req,  count);
            this.chart_err  = new realTimeLineChart('chart_svc_err',  err,  count);
            this.chart_cpu  = new realTimeLineChart('chart_svc_cpu',  cpu,  count);
            this.chart_mem  = new realTimeLineChart('chart_svc_mem',  mem,  count);

            this.chart_load.draw();
            this.chart_req.draw();
            this.chart_err.draw();
            this.chart_cpu.draw();
            this.chart_mem.draw();

            this.last_data = result[result.length - 1][0];

        }.bind(this));
    },

    update_charts: function() {

        if (!this.last_data) return;
        let service = this.service || '_global';
        let resolution = this.resolution || '2m';
        let count = { '1s':600, '5s':720, '2m':720, '15m':672, '1h':744 }[resolution];
        let params = { class: service, resolution: resolution, after: this.last_data, count: count };

        ui.backend.get_services( params, function(result) {

            if (!result.length) return;
            let peak = this.peak;

            result.forEach(function(dpoint) {
                let tstamp = dpoint[0] * 1000;
                let stats  = dpoint[1];
                this.chart_load.add_data( [ tstamp, +stats.load[peak] ] );
                this.chart_req.add_data(  [ tstamp, +stats.nps[peak] + +stats.cps[peak] ] );
                this.chart_err.add_data(  [ tstamp, +stats.err[peak] ] );
                this.chart_cpu.add_data(  [ tstamp, +stats.cpu[peak]  / 100 ] );
                this.chart_mem.add_data(  [ tstamp, +stats.mem[peak] / 1000 ] );
            }.bind(this));

            this.last_data = result[result.length - 1][0];

        }.bind(this));
    },

    update_stats: function() {

        let service = this.service || '_global';
        let params = { class: service, resolution: '1s', count: 1 };

        ui.backend.get_services( params, function(result) {

            let stats = result[0][1];
            let peak = 1;

            $('#svc_req').text((+stats.cps[peak] + +stats.nps[peak]).toFixed(1));
            $('#svc_err').text((+stats.err[peak]).toFixed(1));
            $('#svc_mem').text((+stats.mem[peak] / 1000).toFixed(1));
            $('#svc_cpu').text((+stats.cpu[peak] / 100).toFixed(2));

            let load = (+stats.load[peak]).toFixed(1);
            $('#svc_load').text(load + " %");
            $('#svc_load').css('color', load < 50 ? 'limegreen' : load < 66 ? 'orangered' : 'red');

        }.bind(this));
    }
}}

function LogsUi (ui) { return {

    logs_tmr: null,
    service:  null,
    labels:   null,
    after:    null,
    level:    null,
    entries:  null,

    init: function() {

        this.labels = {
            1: 'Fatal',
            2: 'Alert',
            3: 'Critical',
            4: 'Error',
            5: 'Warning',
            6: 'Notice',
            7: 'Info',
            8: 'Debug',
            9: 'Trace'
        };

        let lvl_labels = this.labels;
        let options = Object.keys(lvl_labels).sort().map(function(lvl) {
            return { name: lvl_labels[lvl], value: lvl };
        });
 
        options.unshift( { name: "All", value: "" } );

        $('#log_level').dropdown({
            values: options,
            onChange: function(val) {
                if (this.level == val || !$('#logs').is(":visible")) return;
                this.level = val;
                this.get_logs();
            }.bind(this)
        });

        ui.services.init_services_dropdown('#log_service', function(val) {
            let new_val = val.toLowerCase().replace(/::worker$/,'').replace(/::/g,'-');
            if (this.service == new_val || !$('#logs').is(":visible")) return;
            this.service = new_val;
            this.get_logs();
        }.bind(this));

        $('#logs').on('show', this.on_show.bind(this));
        $('#logs').on('hide', this.on_hide.bind(this));
    },

    on_show: function() {

        this.get_logs();
        this.logs_tmr = setInterval( this.update_logs.bind(this), 1000);
    },

    on_hide: function() {

        $('#log_entries').empty();
        clearInterval(this.logs_tmr);
    },

    get_logs: function(update) {

        let autoscroll = $(window).scrollTop() > ($('#logs').innerHeight() - $(window).innerHeight());

        if (!update) {
            this.after = null;
            autoscroll = true;
        }

        if (update && this.after === null) return;

        let params = {
            service: this.service,
            level:   this.level,
            after:   this.after,
            count:   200
        };

        ui.backend.get_logs( params, function(result) {

            let log_entries = $('#log_entries');

            if (!result.length) {
                if (!update) log_entries.empty();
                if (!this.after) this.after = 0;
                return;
            }

            let labels = this.labels;
            let html = '';

            result.forEach(function(entry) {
                let type = labels[entry.level];
                let tstamp = new Date(entry.tstamp*1000).toISOString().replace('T',' &nbsp; ').replace('Z','');
                html += `<div class="entry"><div class="level l${entry.level}">${type}</div><div class="tstamp">${tstamp}<br/>${entry.service}</div><div class="msg">${entry.message}</div></div>`;
            });

            if (update) {
                log_entries.append(html);
                this.entries += result.length;
                let remove = this.entries - 1000;
                if (remove > 0) {
                    this.entries -= remove;
                    log_entries.children().slice(0,remove).remove();
                }
            }
            else {
                log_entries.html(html);
                this.entries = result.length;
            }

            if (autoscroll) $(window).scrollTop( $('#logs').innerHeight() );

            this.after = result[result.length - 1].tstamp;

        }.bind(this));
    },

    update_logs: function() {

        this.get_logs('update');
    }
}}

function realTimeLineChart(id, data, points) { return {

    id:     id,
    data:   data,
    points: points,
    margin: { top: 20, right: 20, bottom: 20, left: 50 },
    width:  null,
    height: null,
    timer:  null,

    draw: function() {

        let target_element = document.getElementById(this.id);
        let cs = getComputedStyle(target_element);

        if (!this.width)  this.width  = cs.width.replace(/px/,"")  || 800;  
        if (!this.height) this.height = cs.height.replace(/px/,"") || 150; 

        let margin = this.margin; 
        let width  = this.width;  
        let height = this.height; 
        let data   = this.data;

        let chartWidth  = width - margin.left - margin.right;
        let chartHeight = height - margin.top - margin.bottom;

        let xMin = new Date( d3.min(data, function(d) { return d[0] }) );
        let xMax = new Date( d3.max(data, function(d) { return d[0] }) );

        let yMin = d3.min(data, function(d) { return d[1] });
        let yMax = d3.max(data, function(d) { return d[1] });

        yMin -= yMax * .05; if (yMin < 0) yMin = 0;
        yMax += yMax * .05; if (yMax < 1) yMax = 1;

        let xScale = d3.scaleTime().rangeRound([ 0, chartWidth ]).domain([xMin, xMax]);
        let yScale = d3.scaleLinear().rangeRound([ chartHeight, 0 ]).domain([yMin, yMax]);

        // Create svg
        let div = d3.select("#"+this.id);
        let svg = div.html("")
            .append("svg")
            .attr("width", width)
            .attr("height", height);

        // Main group
        let main = svg.append("g")
            .attr("class", "rtchart")
            .attr("transform", "translate (" + margin.left + "," + margin.top + ")");

        // Draw background
        main.append("rect")
            .attr("class", "canvas")
            .attr("x", 0)
            .attr("y", 0)
            .attr("width", chartWidth )
            .attr("height", chartHeight );

        let xAxis = d3.axisBottom(xScale).ticks(width > 600 ? 10 : 5);
        let yAxis = d3.axisLeft(yScale).ticks(5);

        // Draw x axis
        main.append("g")
            .attr("class", "axis x")
            .attr("transform", "translate(0," + chartHeight + ")")
            .call(xAxis);

        // Draw y axis
        main.append("g")
            .attr("class", "axis y")
            .call(yAxis);

        // Clip path
        main.append("defs")
            .append("clipPath")
                .attr("id", "clip" + this.id )
            .append("rect")
                .attr("width", chartWidth - 1)
                .attr("height", chartHeight )
                .attr("transform", "translate(1,0)");

        // Line path
        let path = main.append("g")
            .append("path")
                .attr("class", "data")
                .attr("clip-path", "url(#clip" + this.id + ")")
                .style("fill", "none");

        // Line function
        let line = d3.line()
            .curve(d3.curveBasis)
            .x(function(d) { return xScale(d[0]); })
            .y(function(d) { return yScale(d[1]); });

        // Draw line
        path.attr("d", line(data) );

        this.refresh = function() {

            let xMin = d3.min(data, function(d) { return d[0] });
            let xMax = new Date( d3.max(data, function(d) { return d[0] }) );

            let yMin = d3.min(data, function(d) { return d[1] });
            let yMax = d3.max(data, function(d) { return d[1] });

            yMin -= yMax * .05; if (yMin < 0) yMin = 0;
            yMax += yMax * .05; if (yMax < 1) yMax = 1;

            // Update ranges
            xScale.domain([xMin, xMax]);
            yScale.domain([yMin, yMax]);

            // Refresh axis
            main.select(".x").call(xAxis);
            main.select(".y").call(yAxis);

            // Refresh line
            path.attr("d", line(data) );
        };

        if (this.timer) clearInterval(this.timer);
        this.timer = setInterval( this.refresh, 1000 );
    },

    clear: function() {
        clearInterval(this.timer);
    },

    set_data: function(data) {
        this.data.length = 0;
        this.data.push(data);
        this.refresh();
    },

    add_data: function(data) {
        this.data.push(data);
        if (this.data.length > this.points) {
            this.data.splice(0, this.data.length - this.points);
        }
        this.refresh();
    }
}}

function BeekeeperClient () { return {

    mqtt: null,
    host: null,
    client_id: null,
    response_topic: null,
    request_seq: 1,
    subscr_seq: 1,
    pending_req: {},
    subscr_cb: {},
    subscr_re: {},

    connect: function(args) {

        const This = this;

        if (!this.client_id) this._generate_client_id();

        if ('debug' in args) this.debug(args.debug);

        this._debug(`Connecting to MQTT broker at ${args.url}`);

        // It is possible to iterate over a list of servers specifying:
        // url: [{ host: 'localhost', port: 1883 }, ... ]

        // Connect to MQTT broker using websockets
        this.mqtt = mqtt.connect( args.url, {
            username: args.username || 'guest',
            password: args.password || 'guest',
            clientId: this.client_id,
            protocolVersion: 5,
            clean: true,
            keepalive: 60,
            reconnectPeriod: 1000,
            connectTimeout: 30 * 1000
        });

        this.mqtt.on('connect', function (connack) {
            This.host = This.mqtt.options.host;
            This._debug("Connected to MQTT broker at " + This.host);
            This._create_response_topic();
            if (args.on_connect) args.on_connect(connack.properties);
        });

        this.mqtt.on('reconnect', function () {
            // Emitted when a reconnect starts
            This._debug("Reconnecting...");
        });

        this.mqtt.on('close', function () {
            // Emitted after a disconnection
            This._debug("Disconnected");
        });

        this.mqtt.on('disconnect', function (packet) {
            // Emitted after receiving disconnect packet from broker
            This._debug("Disconnected by broker");
        });

        this.mqtt.on('offline', function () {
            // Emitted when the client goes offline
            This._debug("Client offline");
        });

        this.mqtt.on('error', function (error) {
            // Emitted when the client cannot connect
            This._debug(error);
        });

        this.mqtt.on('message', function (topic, message, packet) {

            let jsonrpc;
            try {
                if (message[0] == 0x78) {
                    // Deflated JSON
                    let json = pako.inflate(message, {to:'string'});
                    jsonrpc = JSON.parse(json);
                }
                else {
                    jsonrpc = JSON.parse(message.toString());
                }
            } catch (e) { throw `Received invalid JSON: ${e}` }
            This._debug(`Got  << ${message}`);

            const subscr_id = packet.properties.subscriptionIdentifier;
            const subscr_cb = This.subscr_cb[subscr_id];

            subscr_cb(jsonrpc, packet.properties);
        });
    },

    _generate_client_id: function() {
        // Generate a random client id (128+ bits)
        this.client_id = '';
        const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
        const random = new Uint32Array(22);
        window.crypto.getRandomValues(random);
        for (let i = 0; i < random.length; i++) {
            this.client_id += chars.charAt(random[i] % 62);
        }
    },

   _debug: function () {},
    debug: function(enabled) {
        if (enabled) {
            this._debug = function (msg) { console.log(`Beekeeper: ${msg}`) };
        }
        else {
            this._debug = function () {};
        }
    },

    on_error: null,
   _on_error: function (error) {
        if (!this.on_error) return;
        try { this.on_error(error) }
        catch(e) { this._debug(`Uncaught exception into on_error handler: ${e}`) }
    },

    accept_notifications: function (args) {

        if (!this.mqtt.connected) throw "Not connected to MQTT broker";

        const subscr_id = this.subscr_seq++;
        const on_receive = args.on_receive;
        const This = this;

        this.subscr_cb[subscr_id] = function(jsonrpc, packet_prop) {

            // Incoming notification

            try { on_receive( jsonrpc.params, packet_prop ) }
            catch(e) { This._debug(`Uncaught exception into on_receive callback of ${jsonrpc.method}: ${e}`) }
        };

        this.subscr_re[subscr_id] = new RegExp('^' + args.method.replace(/\./g,'\\.').replace(/\*/g,'.+') + '$');

        // Private notifications are received on response_topic subscription
        if (args.private) return;

        const topic = 'msg/frontend/' + args.method.replace(/\./g,'/').replace(/\*/g,'#');

        this.mqtt.subscribe(
            topic,
            { properties: { subscriptionIdentifier: subscr_id }},
            function (err, granted) {
                if (err) throw `Failed to subscribe to ${topic}: ${err}`;
            }
        );
    },

    call_remote_method: function(args) {

        if (!this.mqtt.connected) throw "Not connected to MQTT broker";

        const req_id = this.request_seq++;

        const json = JSON.stringify({
            jsonrpc: "2.0",
            method: args.method,
            params: args.params,
            id:     req_id
        });

        const QUEUE_LANES = 2;
        const topic  = 'req/backend-' + Math.floor( Math.random() * QUEUE_LANES + 1 );
        const fwd_to = 'req/backend/' + args.method.replace(/\.[\w-]+$/,'').replace(/\./g,'/');

        this.mqtt.publish(
            topic,
            json,
            { properties: {
                responseTopic: this.response_topic,
                userProperties: { fwd_to: fwd_to }
            }}
        );

        this._debug("Sent >> " + json);

        this.pending_req[req_id] = {
            method:     args.method,
            on_success: args.on_success,
            on_error:   args.on_error,
            timeout:    null
        };

        const This = this;

        this.pending_req[req_id].timeout = setTimeout( function() {
            delete This.pending_req[req_id];
            This._debug(`Call to ${args.method} timed out`);
            const err_resp = { code: -32603, message: "Request timeout" };
            if (args.on_error) {
                try { args.on_error(err_resp) }
                catch(e) { This._debug(`Uncaught exception into on_error callback of ${args.method}: ${e}`) }
            }
            else {
                This._on_error(err_resp);
            }
        }, (args.timeout || 30) * 1000);
    },

    _create_response_topic: function() {

        const response_topic = 'priv/' + this.client_id;
        this.response_topic = response_topic;

        const subscr_id = this.subscr_seq++;
        const This = this;

        this.subscr_cb[subscr_id] = function(jsonrpc, packet_prop) {

            if (!jsonrpc.id) {

                // Incoming private notification

                let on_receive;
                for (let subscr_id in This.subscr_re) {
                    if (jsonrpc.method.match( This.subscr_re[subscr_id] )) {
                        on_receive = This.subscr_cb[subscr_id];
                        break;
                    }
                }

                if (on_receive) {
                    try { on_receive( jsonrpc, packet_prop ) }
                    catch(e) { This._debug(`Uncaught exception into on_receive callback of ${jsonrpc.method}: ${e}`) }
                }
                else {
                    This._debug(`Received unhandled private notification ${jsonrpc.method}`);
                }

                return;
            }

            // Incoming remote call response

            const resp = jsonrpc;
            const req = This.pending_req[resp.id];
            delete This.pending_req[resp.id];
            if (!req) return;

            clearTimeout(req.timeout);

            if ('result' in resp) {
                if (req.on_success) {
                    try { req.on_success( resp.result, packet_prop ) }
                    catch(e) { This._debug(`Uncaught exception into on_success callback of ${req.method}: ${e}`) }
                }
            }
            else {
                This._debug(`Error response from ${req.method} call: ${resp.error.message}`);
                if (req.on_error) {
                    try { req.on_error( resp.error, packet_prop ) }
                    catch(e) { This._debug(`Uncaught exception into on_error callback of ${req.method}: ${e}`) }
                }
                else {
                    This._on_error(resp.error);
                }
            }
        };

        this.mqtt.subscribe(
            response_topic,
            { properties: { subscriptionIdentifier: subscr_id }},
            function (err, granted) {
                if (err) throw `Failed to subscribe to ${response_topic}: ${err}`;
            }
        );
    }
}}
