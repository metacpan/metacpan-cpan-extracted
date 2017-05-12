var initialize_reconciliation_callback =
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
			{key: "balance"},
			{key: "difference"},
			{key: "month"},
			{key: "receipts"}
			]
			};
			var column_defs =
			[
			 {key: "month", label: "Month"},
			 {key: "balance",  label: "Balance", editor: new YAHOO.widget.TextboxCellEditor({validator: YAHOO.widget.DataTable.validateNumber})},
			 {key: "receipts",  label: "Receipts"},
			 {key: "difference",  label: "Difference"}
			];
			var data_table = new YAHOO.widget.DataTable("reconciliation_tab_container", column_defs, json_data);
			var highlightEditableCell = function(oArgs)
			{
				var elCell = oArgs.target;

				if (YAHOO.util.Dom.hasClass(elCell, "yui-dt-editable") )
				{
					this.highlightCell(elCell);
				}
			};
			data_table.subscribe("cellMouseoverEvent", highlightEditableCell);
			data_table.subscribe("cellMouseoutEvent", data_table.onEventUnhighlightCell);
			data_table.subscribe("cellClickEvent", data_table.onEventShowCellEditor);

		}
		else
		{
			var e = document.getElementById("reconciliation_tab_container");
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e = document.getElementById(div_name);
		e.innerHTML = 'The server failed to respond';
	}
};

function initialize_reconciliation_onsubmit(f)
{
	var p = YAHOO.util.Connect.setForm("reconciliation_form");
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>', initialize_reconciliation_callback);

	return false;
}

function initialize_reconciliation_content()
{
	return '<form name="reconciliation_form" id="reconciliation_form" action="" method="post" onSubmit="return initialize_reconciliation_onsubmit()"><div id="reconciliation_content"><input type="submit" name="initialize" value="Initialize" /></div><input type="hidden" name="rm" value="initialize_reconciliation" /><input type="hidden" name="sid" value="<tmpl_var name=sid>" /></form>';
}

