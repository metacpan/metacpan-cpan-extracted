var donation_amount_report_cb =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var column_defs =
			[
			 {key: "number", label: "#"},
			 //{key: "type",   label: "Type"},
			 {key: "name",   label: "Name"},
			 {key: "amount", label: "Amount"},
			];
			var json_data = new YAHOO.util.LocalDataSource(YAHOO.lang.JSON.parse(o.responseText) );
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "amount"},
			{key: "name"},
			{key: "number"},
			{key: "type"},
			]
			};
			var data_table = new YAHOO.widget.DataTable("report_result", column_defs, json_data);
		}
		else
		{
			var e = document.getElementById("report_result");
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("report_result");
		e.innerHTML = 'The server failed to respond';
	}
};

var donation_date_report_cb =
{
	success: function(o)
	{
		var e = document.getElementById("report_result");

		if (o.responseText !== undefined)
		{
			var column_defs =
			[
			 {key: "timestamp", label: "Timestamp"},
			 {key: "name", label: "Name"},
			 {key: "amount", label: "Amount"},
			];
			var json_data = new YAHOO.util.LocalDataSource(YAHOO.lang.JSON.parse(o.responseText) );
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "amount"},
			{key: "name"},
			{key: "timestamp"},
			]
			};
			var data_table = new YAHOO.widget.DataTable("report_result", column_defs, json_data);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("report_result");
		e.innerHTML = 'The server failed to respond';
	}
};

var record_report_cb =
{
	success: function(o)
	{
		var e = document.getElementById("report_result");

		if (o.responseText !== undefined)
		{
			var column_defs =
			[
			 {key: "number", label: "#"},
			 {key: "name",   label: "Name"},
			 {key: "type",   label: "Type"},
			];
			var json_data = new YAHOO.util.LocalDataSource(YAHOO.lang.JSON.parse(o.responseText) );
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "name"},
			{key: "number"},
			{key: "type"},
			]
			};
			var data_table = new YAHOO.widget.DataTable("report_result", column_defs, json_data);
		}
		else
		{
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("report_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function report_onsubmit()
{
	var date = from_calendar.getSelectedDates();
	var from = '';

	for (var i = 0; i < date.length; i++)
	{
		var d = date[i];
		from  = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();
	}

	date   = to_calendar.getSelectedDates();
	var to = '';

	for (var i = 0; i < date.length; i++)
	{
		var d = date[i];
		to    = d.getFullYear() + '-' + (d.getMonth() + 1) + '-' + d.getDate();
	}

	document.report_form.date_range.value = from + '.' + to;

	var report = document.report_form.report_id.value;

	var i;
	var option;

	for (i = 0; i < document.report_form.report_id.options.length; i++)
	{
		if (document.report_form.report_id.options[i].value == report)
		{
			option = document.report_form.report_id.options[i].text;
		}
	}

	option = option.replace(/\s/g, "_"); // To make a nice path info.

	var cb;

	if (option == "Records")
	{
		cb = record_report_cb;
	}
	else if (option == "Donations_by_amount")
	{
		cb = donation_amount_report_cb;
	}
	else if (option == "Donations_by_date")
	{
		cb = donation_date_report_cb;
	}
	else // Sticky labels. Not implemented.
	{
		return true;
	}

	var p = YAHOO.util.Connect.setForm("report_form");
	var r = YAHOO.util.Connect.asyncRequest("POST", "<tmpl_var name=form_action>/report/display/" + option, cb);

	return false;
}
