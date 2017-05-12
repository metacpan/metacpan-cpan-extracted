var context_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var raw_data  = YAHOO.lang.JSON.parse(o.responseText);
			var json_data = new YAHOO.util.LocalDataSource(raw_data);
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "time"},
			{key: "month"},
			{key: "year"},
			]
			};
			var column_defs =
			[
			 {key: "time",  label: ""},
			 {key: "month", label: "Month"},
			 {key: "year",  label: "Year"}
			];
			var data_table = new YAHOO.widget.DataTable("context_result", column_defs, json_data);
			var s = "";
			var start_month = "";
			var i;

			for (i = 0; i < 2; i++)
			{
				s = s + raw_data.results[i].month + " " + raw_data.results[i].year + " ";

				if (start_month == "")
				{
					start_month = raw_data.results[i].month;
				}

				if (i == 0)
				{
					s = s + " to ";
				}
			}

			var e = document.getElementById("payments_tab_result");
			e.innerHTML = "Financial Year: " + s;
			e = document.getElementById("receipts_tab_result");
			e.innerHTML = "Financial Year: " + s;
			e = document.getElementById("reconciliation_tab_result");
			e.innerHTML = "Financial Year: " + s;

			e = document.getElementById("payments_tab_container");
			e.innerHTML = '';
			e = document.getElementById("receipts_tab_container");
			e.innerHTML = '';

			payments_tab_set = new YAHOO.widget.TabView();
			receipts_tab_set = new YAHOO.widget.TabView();

			monthly_tabs(start_month);

			payments_tab_set.appendTo("payments_tab_container");
			receipts_tab_set.appendTo("receipts_tab_container");

			for (i = 0; i <= 11; i++)
			{
				payments_month[i].set("disabled", false);
				receipts_month[i].set("disabled", false);
			}

			e = document.getElementById("reconciliation_tab_container");
			e.innerHTML = initialize_reconciliation_content();

			e = document.getElementById("payments_tab_container");
			e.style.visibility = "visible";
			e = document.getElementById("receipts_tab_container");
			e.style.visibility = "visible";
			e = document.getElementById("reconciliation_tab_container");
			e.style.visibility = "visible";
		}
		else
		{
			var e = document.getElementById("context_result");
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById("context_result");
		e.innerHTML = 'The server failed to respond';
	}
};

function context_onsubmit()
{
	var p = YAHOO.util.Connect.setForm("context_form");
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>', context_callback);

	return false;
}

