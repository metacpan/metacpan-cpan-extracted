var initialize_payments_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var raw_data  = YAHOO.lang.JSON.parse(o.responseText);
			var s = "";
			var msg;

			for (var i = 0; i < raw_data.results[0].error.length; i++)
			{
				msg = raw_data.results[0].error[i];

				if (msg !== null)
				{
					s = s + "<br />" + msg;
				}
			}

			var e = document.getElementById("payments_tab_result");
			var f = e.innerHTML.split('<');
			e.innerHTML = f[0] + s;

			var json_data = new YAHOO.util.LocalDataSource(raw_data);
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "amount"},
			{key: "category"},
			{key: "day"},
			{key: "error"},
			{key: "gst_amount"},
			{key: "gst_category"},
			{key: "payment_method"},
			{key: "petty_cash_in"},
			{key: "petty_cash_out"},
			{key: "private_use_amount"},
			{key: "private_use_percent"},
			{key: "reference"},
			{key: "submit"},
			{key: "tx_detail"}
			]
			};
			var column_defs =
			[
			 {key: "day", label: "Day"},
			 {key: "category",  label: "Category"},
			 {key: "tx_detail",  label: "Detail"},
			 {key: "payment_method",  label: "Pay via"},
			 {key: "reference",  label: "Reference"},
			 {key: "amount",  label: "$"},
			 {key: "gst_category", label: "GST category"},
			 {key: "gst_amount",  label: "GST $"},
			 //{key: "private_use_percent",  label: "Priv. %"},
			 //{key: "private_use_amount",  label: "Priv. $"},
			 //{key: "petty_cash_in",  label: "Petty $ in"},
			 //{key: "petty_cash_out",  label: "Petty $ out"},
			 {key: "submit",  label: ""}
			];
			var data_table = new YAHOO.widget.DataTable(div_name, column_defs, json_data);
		}
		else
		{
			var e = document.getElementById(div_name);
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById(div_name);
		e.innerHTML = 'The server failed to respond';
	}
};

var initialize_receipts_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var raw_data  = YAHOO.lang.JSON.parse(o.responseText);
			var s = "";
			var msg;

			for (var i = 0; i < raw_data.results[0].error.length; i++)
			{
				msg = raw_data.results[0].error[i];

				if (msg !== null)
				{
					s = s + "<br />" + msg;
				}
			}

			var e = document.getElementById("receipts_tab_result");
			var f = e.innerHTML.split('<');
			e.innerHTML = f[0] + s;

			var json_data = new YAHOO.util.LocalDataSource(raw_data);
			json_data.responseSchema =
			{
			resultsList: "results",
			fields:
			[
			{key: "amount"},
			{key: "bank_amount"},
			{key: "category"},
			{key: "comment"},
			{key: "day"},
			{key: "error"},
			{key: "gst_amount"},
			{key: "gst_category"},
			{key: "reference"},
			{key: "submit"},
			{key: "tx_detail"}
			]
			};
			var column_defs =
			[
			 {key: "day", label: "Day"},
			 {key: "category",  label: "Category"},
			 {key: "tx_detail",  label: "Detail"},
			 {key: "reference",  label: "Reference"},
			 {key: "amount",  label: "$"},
			 {key: "gst_category", label: "GST category"},
			 {key: "gst_amount",  label: "GST $"},
			 {key: "bank_amount", label: "Bank $"},
			 {key: "comment", label: "Comment"},
			 {key: "submit",  label: ""}
			];
			var data_table = new YAHOO.widget.DataTable(div_name, column_defs, json_data);
		}
		else
		{
			var e = document.getElementById(div_name);
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById(div_name);
		e.innerHTML = 'The server failed to respond';
	}
};

function initialize_payments_onsubmit(f)
{
	var i = f.name.split('_');
	var month = i[0];
	div_name = month + "_payments_content";
	form_name = month + "_payments_form";
	var p = YAHOO.util.Connect.setForm(form_name);
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>', initialize_payments_callback);
	f.rm.value = "submit_payment";

	return false;
}

function initialize_receipts_onsubmit(f)
{
	var i = f.name.split('_');
	var month = i[0];
	div_name = month + "_receipts_content";
	form_name = month + "_receipts_form";
	var p = YAHOO.util.Connect.setForm(form_name);
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>', initialize_receipts_callback);
	f.rm.value = "submit_receipt";

	return false;
}

function initialize_payments_content(month)
{
	return '<form name="' + month + '_payments_form" id="' + month + '_payments_form" action="" method="post" onSubmit="return initialize_payments_onsubmit(this)"><div id="' + month + '_payments_content"><input type="submit" name="initialize" value="Initialize ' + month + '" /></div><input type="hidden" name="month" value="' + month + '" /><input type="hidden" name="rm" value="initialize_payments" /><input type="hidden" name="sid" value="<tmpl_var name=sid>" /></form><div id="payments_error_report"></div>';
}

function initialize_receipts_content(month)
{
	return '<form name="' + month + '_receipts_form" id="' + month + '_receipts_form" action="" method="post" onSubmit="return initialize_receipts_onsubmit(this)"><div id="' + month + '_receipts_content"><input type="submit" name="initialize" value="Initialize ' + month + '" /></div><input type="hidden" name="month" value="' + month + '" /><input type="hidden" name="rm" value="initialize_receipts" /><input type="hidden" name="sid" value="<tmpl_var name=sid>" /></form><div id="receipts_error_report"></div>';
}

function monthly_tabs(start_month)
{
	var month_name = new Array("January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December");
	var month = new Array("Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec");
	var i;
	var j = - 1;

	for (i = 0; i <= 11; i++)
	{
		if (start_month == month_name[i])
		{
			j = i;
		}
	}

	if (j < 0)
	{
		return;
	}

	var k;
	var s;

	for (i = 0; i <= 11; i++)
	{
		k = i + j;

		if (k > 11)
		{
			k = k - 12;
		}

		s = initialize_payments_content(month_name[k]);

		payments_month[i] = new YAHOO.widget.Tab
		({
			label: month[k],
			content: s,
			disabled: true
		});
		payments_tab_set.addTab(payments_month[i]);

		s = initialize_receipts_content(month_name[k]);

		receipts_month[i] = new YAHOO.widget.Tab
		({
			label: month[k],
			content: s,
			disabled: true
		});
		receipts_tab_set.addTab(receipts_month[i]);
	}

	payments_tab_set.appendTo("payments_tab_container");
	receipts_tab_set.appendTo("receipts_tab_container");
}
