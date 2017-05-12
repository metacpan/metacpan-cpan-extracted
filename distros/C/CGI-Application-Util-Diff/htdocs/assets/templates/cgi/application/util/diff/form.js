function cell_click(arg)
{
	// Q 1) How do I get the /value/ in the cell which was clicked?
	// Q 2) How do I get all the values in the row which was clicked?

	// var target = arg.target;
	// var column = this.getColumn(target);
	// var record = this.getRecord(target);
	// var valueThisCell = record.getData(column.key); // this answers #1
	// var valuesThisRow = record.getData(); // this answers #2

	var row = this.getRecord(arg.target).getData();

	// Wipe out any previous menu.

	var e       = document.getElementById("menu.button");
	e.innerHTML = "";

	// Declare the event handler for when menu items are clicked.

	var onMenuItemClick = function(p_sType, p_aArgs, p_oItem)
	{
		// Set form field action's value for the submit.

		var e    = document.getElementById("action");
		e.value  = p_oItem.value;
		e        = document.getElementById("target");
		e.value  = row.name;
		var sure = false;

		if ( (<tmpl_var name=confirm_action> == 0) || confirm("Action: " + p_oItem.value) )
		{
			sure = true;
		}

		if (sure)
		{
			util_diff_onsubmit();
		}
	};

	// Build menu items. We do it this way so we only ever have 1 menu in existance.

	var item_list;

	if (row.type == "Dir")
	{
		item_list =
		[
<tmpl_loop name=dir_loop>		<tmpl_var name=item>
</tmpl_loop>		];
	}
	else
	{
		item_list =
		[
<tmpl_loop name=file_loop>		<tmpl_var name=item>
</tmpl_loop>		];
	}

	// Instantiate the menu.
	// When the uses selects an item, the above function, onMenuItemClick, will be executed.

	var oMenuButton = new YAHOO.widget.Button
		({
			type: "menu",
			label: row.name,
			menu: item_list,
			container: "menu.button"
		});
}

var util_diff_callback =
{
	success: function(o)
	{
		if (o.responseText !== undefined)
		{
			var data    = YAHOO.lang.JSON.parse(o.responseText);
			var e       = document.getElementById("left");
			e.value     = data.response.left;
			e           = document.getElementById("right");
			e.value     = data.response.right;
			e           = document.getElementById("message");
			e.innerHTML = data.response.message;
			var table_1 = new YAHOO.util.LocalDataSource(data);

			table_1.responseSchema =
			{
			resultsList: "response.output",
			fields:
			[
			{key: "line"}
			],
			};

			var column_defs_1 =
			[
			 {key: "line", label: "Output"},
			];

			var output_table = new YAHOO.widget.DataTable("output", column_defs_1, table_1);
			var table_2      = new YAHOO.util.LocalDataSource(data);

			table_2.responseSchema =
			{
			resultsList: "response.table",
			fields:
			[
			{key: "name"},
			{key: "type"},
			{key: "match"},
			{key: "left_size"},
			{key: "left_mtime"},
			{key: "right_size"},
			{key: "right_mtime"}
			],
			};

			var column_defs_2 =
			[
			 {key: "name",        label: "Name"},
			 {key: "type",        label: "Type"},
			 {key: "match",       label: "Match"},
			 {key: "left_size",   label: "Left size"},
			 {key: "left_mtime",  label: "Left modification time"},
			 {key: "right_size",  label: "Right size"},
			 {key: "right_mtime", label: "Right modification time"}
			];

			var diff_table = new YAHOO.widget.DataTable("result", column_defs_2, table_2);

			diff_table.subscribe("cellClickEvent", cell_click);
		}
		else
		{
			var e       = document.getElementById("result");
			e.innerHTML = "The server's response is incomprehensible";
		};
	},
	failure: function(o)
	{
		var e       = document.getElementById("result");
		e.innerHTML = 'The server failed to respond';
	}
};

function util_diff_onsubmit()
{
	var left   = document.getElementById("left");
	var right  = document.getElementById("right");
	var action = document.getElementById("action");
	var target = document.getElementById("target");

	// Note: The &rm=diff is only in the next line for cgi-bin/util.diff.cgi.
	// local/ajax does not need it, due to the /diff in the next line plus 1,
	// which is converted into a run mode by CGI::Application::Dispatch.

	var s = "left=" + left.value + "&right=" + right.value + "&action=" + action.value + "&target=" + target.value + "&rm=diff";
	var r = YAHOO.util.Connect.asyncRequest('POST', '<tmpl_var name=form_action>/diff', util_diff_callback, s);

	left.focus();

	return false;
}
