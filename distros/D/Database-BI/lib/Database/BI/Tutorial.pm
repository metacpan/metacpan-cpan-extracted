package Database::BI::Tutorial;

use strict;
use warnings;

our $VERSION = '0.020.0';

# ---------------------------------------------------------------------------
# The tutorial that the application shows at GET /tutorial.
#
# This is deliberately data, not a long HTML file.  A chapter is one feature,
# and adding a feature means adding one hash to @CHAPTERS.  The template
# (templates/web/en/tutorial.html.tt) knows how to show every field, so a new
# chapter needs no template change.
#
# To add a chapter:
#   1. Copy the shape of a chapter below.
#   2. Give it a unique id, a part, a title, a one-sentence lead and short
#      numbered steps.
#   3. List the GET page routes that it covers in routes => [ ... ].
#      t/tutorial.t fails when a GET page in lib/Database/BI.pm has no
#      chapter, so this list is a reminder that cannot be forgotten.
#   4. Use short sentences and common words.  The test also fails a lead,
#      step or tip that is longer than 25 words.
#
# A route that is not a page for readers (JSON for a panel, for example) goes
# in %EXEMPT_ROUTES with a reason, instead of getting a chapter.
# ---------------------------------------------------------------------------

my @INTRO = (
	'Database::BI shows data files as tables and charts in your web browser.',
	'It reads your files. It does not change them. Export writes a new file; it does not change the source.',
	'You do not need to know Perl or any other programming language to use this tutorial.',
	'This page uses the same words that you see on the screen.',
	'The data folder contains example files. You can use them to try the steps.',
	'A few chapters have a Walk through box: follow it on screen to learn a hard idea.',
);

my @CHAPTERS = (

	# ---------------------------------------------------------------
	# First steps
	# ---------------------------------------------------------------
	{
		id    => 'open-file',
		part  => 'First steps',
		title => 'Open your first data file',
		lead  => 'The home page shows the data files that the program can read.',
		steps => [
			'Start the program. If you did not start it, ask the person who did. The usual address is http://localhost:3000.',
			'Open that address in your web browser.',
			'Find a file card. The card shows the name of a data file.',
			'Click the card. The file opens as a table.',
			'You can also drop a file onto the page. The program opens it at once.',
		],
		tip   => 'The program reads CSV, TSV, PSV, XLSX, XML, SQLite and Berkeley DB files. Start with a CSV file if you can.',
		try   => { href => '/', label => 'Open the home page' },
		routes => [ '/' ],
	},
	{
		id    => 'find-your-way',
		part  => 'First steps',
		title => 'Find your way around',
		lead  => 'Every page shows where you are and how you got there.',
		steps => [
			'The links at the top of every page are Home, Canvases, Catalog, Open file..., Preferences and Tutorial.',
			'The Help link beside Tutorial opens the chapter for the page that you are on. F1 does the same.',
			'Below the title, the breadcrumb lists each page between Home and this one. Click a step to go back to it.',
			'Each step is named after what it shows, for example Bar chart: amount by region.',
			'A chart, pivot, statistics or insights page shows a Drawn from: strip under the breadcrumb.',
			'The strip lists the filters, the time range and the other changes that the page uses.',
			'Click Change... in the strip to go back to the page that they came from and change them.',
			'If an address is wrong, you see Page not found. Click Go to Home or Open a file.',
		],
		tip   => 'A chart opened from a chart keeps the whole trail, so you can always find the table that you started from.',
		routes => [],
	},
	{
		id    => 'other-files',
		part  => 'First steps',
		title => 'Open a file from another place',
		lead  => 'You are not limited to the files in the data folder.',
		steps => [
			'Open the home page and click Browse your files. Click folders to move down. Click Up to move back.',
			'Click a data file in the list to open it.',
			'To use a full path, type it in the box that shows /path/to/file.csv and click Open.',
			'To open a file from your computer, drop it on the page. The program keeps a copy in a temporary folder.',
			'A database file can hold more than one table. The program shows the table list first. Click one table.',
			'To see a file as soon as the program starts, name it when you start the program: script/database-bi data/store.db.',
			'The home address then shows that file. Click Home in the breadcrumb to see the usual list.',
			'You can name only one file this way. To bring files together, open one and use Merge or Combine.',
		],
		tip   => 'A dropped file is a copy. Changes in the view do not change your original file.',
		routes => [ '/browse', '/open', '/tables' ],
	},
	{
		id    => 'remote-file',
		part  => 'First steps',
		title => 'Open a file on another computer',
		lead  => 'You can open a data file on a remote server without copying it first.',
		steps => [
			'In the path box, type /../hostname/folder/file.csv where hostname is the server name.',
			'To connect as a specific user, type /../user@hostname/folder/file.csv instead.',
			'Click Open. The program downloads the file over SSH and shows it as a table.',
			'The remote path also works in the Merge data panel and the column selector.',
			'Files with unusual extensions such as .log are read and detected automatically.',
		],
		tip   => 'The remote host must run an SSH server. The program connects with SFTP and does not ask for a password here.',
		routes => [ '/open' ],
	},
	{
		id    => 'web-table',
		part  => 'First steps',
		title => 'Import a table from a web page',
		lead  => 'Some web pages contain data tables. You can open one without saving it.',
		steps => [
			'On the home page, find Import from a web page.',
			'Paste the address of the page into the box.',
			'If the page has more than one table, type its number. The first table is 0.',
			'Click Import. The table opens in the program.',
		],
		tip   => 'The import reads the page each time. If the page changes, open it again.',
		routes => [ '/import' ],
	},

	# ---------------------------------------------------------------
	# Work with a table
	# ---------------------------------------------------------------
	{
		id    => 'read-table',
		part  => 'Work with a table',
		title => 'Read and move around a table',
		lead  => 'A table has rows and columns. A row is one record. A column is one kind of value.',
		steps => [
			'Click a column heading to sort by that column. Click it again to reverse the order.',
			'Drag a column heading to move that column to a new place.',
			'Use the page links below the table to see more rows.',
			'Click Totals to add a row of sums at the bottom.',
			'Click the box at the start of a row to select it. Click Delete selected to remove it from the view.',
		],
		tip   => 'The program remembers your sort order and column order in this browser. Delete selected only changes the view, not the file.',
		routes => [ '/view/:table' ],
	},
	{
		id    => 'filter',
		part  => 'Work with a table',
		title => 'Keep only the rows you need',
		lead  => 'A filter hides rows that do not match a rule.',
		steps => [
			'Find the filter row below the toolbar.',
			'Choose a column. The comparison options change to match the column type.',
			'For a date column a date picker appears. For a number column a number box appears. For text, type a value.',
			'To keep rows between two dates, choose Date range and pick a start and an end date.',
			'To keep just a recent window instead, pick a Time range such as the last 30 days.',
			'Choose the column that window applies to, then click Apply range.',
			'Press Enter or click Apply filter.',
			'Each active filter is shown as a small label in the toolbar. Click the x on a label to remove it.',
			'For more rules, click Merge / Filter... and use the Filter results section.',
		],
		tip   => 'A filter does not change your file. It only changes what you see and what you export. A time range is worked out from today every time.',
		routes => [ '/view/:table' ],
	},
	{
		id    => 'dedup',
		part  => 'Work with a table',
		title => 'Hide duplicate rows',
		lead  => 'A duplicate row is exactly the same as another row in every column.',
		steps => [
			'Click Hide duplicates in the toolbar.',
			'The table now shows one copy of each row.',
			'Click Show duplicates to see every row again.',
		],
		tip   => 'Export uses the same rows that you see. Check this button before you export. Charts, the pivot table and the statistics also use one copy of each row.',
		routes => [],
	},
	{
		id    => 'join',
		part  => 'Work with a table',
		title => 'Add columns from another file',
		lead  => 'A merge joins two tables by a value that both tables share. A customer number is one example.',
		steps => [
			'Open the main table.',
			'Click Merge / Filter...',
			'Choose the second table. You can also type its path.',
			'Choose the column in the main table and the matching column in the second table.',
			'Choose which rows to keep. The option Keep all rows from the left table is a safe first choice.',
			'Click Apply.',
		],
		tip   => 'A merge can make the table much wider. Start with a second table that has only a few columns.',
		walkthrough => {
			title => 'Walk through: add customer names to sales',
			intro => 'This example merges the sales and customer tables inside the store database.',
			steps => [
				{ do => 'On the home page, click store.', see => 'The schema page lists customer, product and sales.' },
				{ do => 'Click sales. The table opens with four rows.', see => 'The rows show four sales, each with a customer_id from 1 to 3.' },
				{ do => 'Click Merge / Filter...', see => 'The panel asks for a table, two columns and a row rule.' },
				{ do => 'Under Table from the data directory, choose store / customer.', see => 'The matching column list fills with id, name and email.' },
				{ do => 'Choose customer_id for the left key and id for the right key.', see => 'The panel describes a match from customer_id to id.' },
				{ do => 'Choose Keep all rows from the left table and click Apply.', see => 'The result has four rows and new name and email columns.' },
			],
			result => 'Alice Smith appears twice; Bob Jones and Carol White appear once, so every sale now names its customer.',
		},
		routes => [ '/join' ],
	},
	{
		id    => 'combine',
		part  => 'Work with a table',
		title => 'Put one file under another',
		lead  => 'Combine stacks the rows of a second file under the rows of the first file.',
		steps => [
			'Open the first table.',
			'Click Combine data...',
			'Choose the second table or type its path.',
			'Click Combine.',
			'You can merge a table and then combine another, in either order. The table keeps both, and so do its charts.',
		],
		tip   => 'The files do not need the same columns. A missing value is left blank.',
		routes => [ '/combine' ],
	},
	{
		id    => 'calc',
		part  => 'Work with a table',
		title => 'Make a new column with a calculation',
		lead  => 'A calculated column is a new column made from a formula.',
		steps => [
			'Open the table and click Calc fields...',
			'Type a name for the new column, for example margin.',
			'Type the formula, for example revenue - cost. Use the column names that you see in the table.',
			'Click Save & apply. The new column appears in the table.',
		],
		tip   => 'The program remembers the field for this data file. It is applied the next time you open the file.',
		walkthrough => {
			title => 'Walk through: add a tax column',
			intro => 'This example adds a column to the sales table.',
			steps => [
				{ do => 'Open the sales table and click Calc fields...', see => 'The panel asks for a column name and an expression.' },
				{ do => 'Type tax_amount in the Column name box.', see => 'The name is ready for the new column.' },
				{ do => 'Type amount * 1.2 in the Expression box.', see => 'The formula uses the amount column that is already in the table.' },
				{ do => 'Click Save & apply.', see => 'A tax_amount column appears at the right of the table.' },
				{ do => 'Use tax_amount in a chart or pivot table.', see => 'The chart sums the calculated values like any other number column.' },
			],
			result => 'The calculation is saved for this data file, so tax_amount is there the next time you open sales.',
		},
		routes => [],
	},
	{
		id    => 'cross-row',
		part  => 'Work with a table',
		title => 'Add a running total or a moving average',
		lead  => 'A cross-row column is worked out from the rows around each row, not from the row alone.',
		steps => [
			'Open the table and click Cross-row...',
			'Choose the number column to read, for example amount.',
			'Choose what to work out, for example Running total.',
			'Choose the column that says which order to read the rows in, for example the date.',
			'Type a name for the new column and click Add column.',
		],
		tip   => 'The new column is in the table and in every chart list. The Cross-row chip removes it. A calculated column can read it by name. Restart for each groups the rows before counting. On a canvas, a card can hold cross-row columns of its own. Choose Has a column of its own in Add current view, then Add this column once for each. Each one is listed there and can be taken out before the card is added.',
		walkthrough => {
			title => 'Walk through: a running total per region',
			intro => 'This example adds a running total to the sales table.',
			steps => [
				{ do => 'Open the sales table and click Cross-row...', see => 'The panel asks for a number column, a function and a name.' },
				{ do => 'Choose amount as the number column.', see => 'The new column will add up the amounts.' },
				{ do => 'Choose Running total, and id as the column to read rows in order of.', see => 'A running total needs an order, so the order box is required.' },
				{ do => 'Type running_amount as the name and click Add column.', see => 'The table gains a running_amount column and a Cross-row chip.' },
				{ do => 'Choose region under Restart for each and add a second column.', see => 'Each region now starts again from its own first row.' },
				{ do => 'Click Bar chart... and pick running_amount as the value.', see => 'A chart reads the new column like any other number column.' },
			],
			result => 'A running total is a column of the view, so the table, the charts and the export all show the same numbers.',
		},
		routes => [],
	},
	{
		id    => 'groups',
		part  => 'Work with a table',
		title => 'Group values into your own labels',
		lead  => 'A group gives several values one shared name.',
		steps => [
			'Click Group values...',
			'Choose the source column.',
			'Click Add group. Type a label, for example Northern.',
			'Type the values for this group, one on each line. Click Save group.',
			'The table gains a column named after the source column, for example region_group. Use it in a chart or pivot table.',
		],
		tip   => 'A value that is not in a group becomes (other).',
		routes => [],
	},
	{
		id    => 'dates',
		part  => 'Work with a table',
		title => 'Tell the program how your dates look',
		lead  => 'Dates can be written in many ways. The program needs to know which way your file uses.',
		steps => [
			'Click Date format...',
			'Choose the date column.',
			'Choose the format that matches your data, for example D/M/YYYY.',
			'If the column also holds a time, set Clock time. Then hour() and time buckets work.',
			'Click Save & apply.',
		],
		tip   => 'After you set the format, This year, This quarter and This month work in the date panel.',
		routes => [],
	},
	{
		id    => 'lookups',
		part  => 'Work with a table',
		title => 'Add columns from another file',
		lead  => 'A lookup adds columns from a second file, matched on one value, such as a region to its manager.',
		steps => [
			'Put the second file in the data folder.',
			'Open the table and click Lookups...',
			'Type a name, then choose the Lookup file.',
			'Choose its Key in that file, and the Match column here that holds the same values.',
			'Pick the Columns to add, or pick none to add them all. Type a Default for values the file does not have.',
			'Click Save & apply.',
		],
		tip   => 'Click Skip in this view to see one view without a lookup. It stays saved for the others.',
		routes => [],
	},
	{
		id    => 'extract',
		part  => 'Work with a table',
		title => 'Split a column into new columns',
		lead  => 'An extraction pulls parts out of a text column with a pattern, such as the domain of an email address.',
		steps => [
			'Open the table and click Extract fields...',
			'Type a name and choose the column.',
			'Type a pattern. Each named part, written (?<name>...), becomes a column.',
			'For example, @(?<domain>[\\w.-]+) makes a domain column from an email address.',
			'Click Save & apply.',
		],
		tip   => 'A row that the pattern does not match shows (unparseable), so you can count those rows.',
		routes => [],
	},
	{
		id    => 'folder',
		part  => 'Work with a table',
		title => 'Browse records in folders',
		lead  => 'Folder view groups rows by the first letters of a code column.',
		steps => [
			'Click Folder view...',
			'Choose the code column. Order numbers such as A10 and B3 are a good example.',
			'Click Open.',
			'Click a folder to see the rows in it.',
		],
		tip   => 'Folder view is a fast way to find a record when you know the start of its code.',
		routes => [ '/folder' ],
	},

	# ---------------------------------------------------------------
	# Charts and summaries
	# ---------------------------------------------------------------
	{
		id    => 'first-chart',
		part  => 'Charts and summaries',
		title => 'Make your first chart',
		lead  => 'A chart shows a pattern that is hard to see in a long table.',
		steps => [
			'Open a table.',
			'Click a chart button in the toolbar. Bar chart... is a good first choice.',
			'Choose a category column and a number column.',
			'Click Plot.',
			'Use Export SVG, Export PNG or Export PDF to save the chart. Use Copy link to share the page.',
		],
		tip   => 'If the chart is empty, check that you chose a number column for the value.',
		routes => [],
	},
	{
		id    => 'chart-types',
		part  => 'Charts and summaries',
		title => 'Choose the right chart',
		lead  => 'Each chart answers a different question. This table can help you choose.',
		steps => [],
		table => {
			caption => 'Chart types and what they are good for',
			head    => [ 'Chart', 'Good for', 'What to choose' ],
			rows    => [
				[ 'Line chart',      'A value over time',                  'A date or number for X, and a number for Y' ],
				[ 'Pie chart',       'Parts of one whole',                 'A category and a number, with few categories' ],
				[ 'Heatmap',         'Two groups compared by colour',      'Two category columns, and a count or sum' ],
				[ 'Bar chart',       'Sizes of different groups',          'A category and a number' ],
				[ 'Stacked bar chart', 'Groups and their parts',           'A category, a segment, and a number' ],
				[ 'Scatter plot',    'A link between two numbers',         'Two number columns' ],
				[ 'Combo chart',     'A bar value and a line value together', 'X, a bar number, and a line number' ],
				[ 'Treemap',         'Big and small groups in boxes',      'A category and an optional number' ],
				[ 'Histogram',       'How numbers are spread out',         'A number column and a bin count' ],
				[ 'Map',             'Where the rows are in the world',    'Latitude and longitude, or a place column' ],
				[ 'Word cloud',      'Which words a text column repeats',  'A text column' ],
			],
		},
		tip   => 'A bar chart is a good first choice for most data.',
		routes => [],
	},
	{
		id    => 'time-bucket',
		part  => 'Charts and summaries',
		title => 'Group by hour, day or month',
		lead  => 'A time bucket turns a column of dates into one group per hour, day, month or year.',
		steps => [
			'Open a table and click a chart button, for example Bar chart...',
			'Choose the date or timestamp column for the category or X axis.',
			'Set Time bucket to the period you want, such as 1 hour or 1 month.',
			'Click Plot.',
		],
		tip   => 'The bucket is a new column, so the chart still has the original timestamp beside it. Use the pivot table to bucket a row group the same way.',
		routes => [],
	},
	{
		id    => 'line-chart',
		part  => 'Charts and summaries',
		title => 'Line chart',
		chart => 1,
		lead  => 'A line chart shows how a number changes along a series, often over time.',
		steps => [
			'Open the table and click Line graph...',
			'Choose the X axis. A date column or a number column works well.',
			'Choose the Y axis. This must be a number column.',
			'Optional: choose Lines by to draw one line for each value of a column, such as one per region.',
			'For a total per period, set Time bucket and then set Aggregate to Sum.',
			'Click Plot.',
		],
		tip   => 'Use Copy link to share the chart. Use Export SVG, Export PNG or Export PDF to save the picture.',
		routes => [ '/graph', '/line' ],
	},
	{
		id    => 'pie-chart',
		part  => 'Charts and summaries',
		title => 'Pie chart',
		chart => 1,
		lead  => 'A pie chart shows the parts of one whole.',
		steps => [
			'Open the table and click Pie chart...',
			'Choose the column for Slice by. This gives the slices.',
			'Choose Value. Count (rows) counts each row; a number column sums its values.',
			'Set Top N slices if you want only the largest slices. The rest become Other.',
			'Click Plot.',
		],
		tip   => 'Click a slice to open the matching rows in the table.',
		walkthrough => {
			title => 'Walk through: population share by region',
			intro => 'This example uses the virginia_counties table in the data folder.',
			steps => [
				{ do => 'Open the virginia_counties table and click Pie chart...', see => 'The pie panel opens.' },
				{ do => 'Choose region for Slice by.', see => 'Seven regions will become slices.' },
				{ do => 'Choose population for Value.', see => 'Each slice will show the total population for that region.' },
				{ do => 'Click Plot.', see => 'A pie chart appears. Northern Virginia is the largest slice.' },
			],
			result => 'Northern Virginia holds the most people. Its slice is larger than all Southside and Southwest counties combined.',
		},
		try    => { href => '/pie?l=table:virginia_counties&cat=region&val=population', label => 'Try population by region' },
		routes => [ '/pie' ],
	},
	{
		id    => 'heatmap-chart',
		part  => 'Charts and summaries',
		title => 'Heatmap',
		chart => 1,
		lead  => 'A heatmap compares two groups with colour.',
		steps => [
			'Open the table and click Heatmap...',
			'Choose X axis (columns).',
			'Choose Y axis (rows).',
			'Leave Value on Count (rows), or choose a number column to sum.',
			'Click Plot.',
		],
		tip   => 'A darker colour means a larger count or sum.',
		routes => [ '/heatmap' ],
	},
	{
		id    => 'bar-chart',
		part  => 'Charts and summaries',
		title => 'Bar chart',
		chart => 1,
		lead  => 'A bar chart compares the sizes of different groups.',
		steps => [
			'Open the table and click Bar chart...',
			'Choose Category (bars).',
			'Leave Value on Count (rows), or choose a number column to sum.',
			'Use Sort bars and Orientation if you want a different order or direction.',
			'Click Plot.',
		],
		tip   => 'A bar chart is a good first choice for most data.',
		walkthrough => {
			title => 'Walk through: top Virginia counties by population',
			intro => 'This example uses the virginia_counties table in the data folder.',
			steps => [
				{ do => 'Open the virginia_counties table and click Bar chart...', see => 'The bar panel opens.' },
				{ do => 'Choose county for Category.', see => 'There are 95 counties. Set a limit in the next step.' },
				{ do => 'Choose population for Value. Set Top N to 10 and Sort to By value.', see => 'The form is ready.' },
				{ do => 'Click Plot.', see => 'Ten bars appear. Fairfax County stands far above the rest.' },
			],
			result => 'The ten most populous counties appear, sorted largest first. Fairfax County has more people than the bottom 30 counties together.',
		},
		try    => { href => '/bar?l=table:virginia_counties&cat=county&val=population&sort=value&topn=10', label => 'Try top 10 counties by population' },
		routes => [ '/bar' ],
	},
	{
		id    => 'stacked-chart',
		part  => 'Charts and summaries',
		title => 'Stacked bar chart',
		chart => 1,
		lead  => 'A stacked bar chart shows groups and their parts.',
		steps => [
			'Open the table and click Stacked bar...',
			'Choose Category (X axis).',
			'Choose Segment (series). This gives the parts of each bar.',
			'Leave Value on Count (rows), or choose a number column to sum.',
			'Click Plot.',
		],
		tip   => 'Click a part of the legend to hide or show that segment.',
		routes => [ '/stacked' ],
	},
	{
		id    => 'scatter-chart',
		part  => 'Charts and summaries',
		title => 'Scatter plot',
		chart => 1,
		lead  => 'A scatter plot shows a link between two numbers.',
		steps => [
			'Open the table and click Scatter...',
			'Choose X axis (horizontal, numeric).',
			'Choose Y axis (vertical, numeric).',
			'Optional: choose Colour by to colour the points by a group. Use Bubble size to size them by a number.',
			'Click Plot.',
		],
		tip   => 'If a column is not numeric, it does not appear in the axis lists. A scatter card on a canvas keeps its colours and bubbles. In Add current view, choose Scatter chart to set Colour by and Bubble size there too.',
		walkthrough => {
			title => 'Walk through: county location and size',
			intro => 'This example uses the virginia_counties table in the data folder.',
			steps => [
				{ do => 'Open the virginia_counties table and click Scatter...', see => 'The scatter panel opens.' },
				{ do => 'Choose lon for X axis and lat for Y axis.', see => 'Each dot will sit at its map position.' },
				{ do => 'Choose region for Colour by.', see => 'Each region gets its own colour.' },
				{ do => 'Choose population for Bubble size. Click Plot.', see => 'Northern Virginia circles are much bigger than the rest.' },
			],
			result => 'The chart mirrors Virginia shape. Large bubbles in the northeast show the high-population Northern Virginia counties.',
		},
		try    => { href => '/scatter?l=table:virginia_counties&x=lon&y=lat&series=region&size=population', label => 'Try Virginia counties scatter plot' },
		routes => [ '/scatter' ],
	},
	{
		id    => 'combo-chart',
		part  => 'Charts and summaries',
		title => 'Combo chart',
		chart => 1,
		lead  => 'A combo chart puts a bar value and a line value on the same X axis.',
		steps => [
			'Open the table and click Combo chart...',
			'Choose X axis.',
			'Choose Bar column (numeric).',
			'Choose Line column (numeric).',
			'Optional: choose a scheme in Colours. The bars take its first colour and the line its second.',
			'Click Plot.',
		],
		tip   => 'Use a combo chart when two numbers are measured in different units. A combo card on a canvas keeps its colours.',
		routes => [ '/combo' ],
	},
	{
		id    => 'treemap-chart',
		part  => 'Charts and summaries',
		title => 'Treemap',
		chart => 1,
		lead  => 'A treemap shows big and small groups as boxes.',
		steps => [
			'Open the table and click Treemap...',
			'Choose Category column.',
			'Leave Value (tile size) on Count (rows), or choose a number column to sum.',
			'Set Top N tiles if you want only the largest groups.',
			'Optional: choose Colour by to shade each tile by another number, such as a margin.',
			'Colour from says how that number is worked out for each tile. Average is the default.',
			'Colour scale picks the colours, from light for low values to dark for high ones.',
			'Click Plot.',
		],
		tip   => 'A treemap is useful when one level has many groups. Size and colour can show two numbers at once: size for sales, colour for margin. A treemap card on a canvas keeps its colours.',
		routes => [ '/treemap' ],
	},
	{
		id    => 'histogram-chart',
		part  => 'Charts and summaries',
		title => 'Histogram',
		chart => 1,
		lead  => 'A histogram shows how numbers are spread out.',
		steps => [
			'Open the table and click Histogram...',
			'Choose Numeric column.',
			'Set Number of bins. More bins show more detail.',
			'Optional: choose Bar colour to fill the bars with the first colour of a scheme.',
			'Click Plot.',
		],
		tip   => 'A histogram works best with a number column that has many different values.',
		routes => [ '/histogram' ],
	},
	{
		id    => 'map-chart',
		part  => 'Charts and summaries',
		title => 'Map',
		chart => 1,
		lead  => 'A map shows where the rows are in the world.',
		steps => [
			'Open the table and click Map...',
			'Keep Coordinate columns, then choose the latitude and longitude columns.',
			'If your table has places instead, choose Place-name column and pick that column.',
			'If the place is split over two columns, such as an address and its country, choose the second one under Followed by. The map then looks up "Brezje 8, Cerknica, Slovenia".',
			'Tick Remember columns. Next time, the panel chooses the same columns for this table. Click Forget remembered columns to stop this.',
			'Tick Heatmap layer to colour the busy areas. Choose a Heat weight column to make some rows count for more.',
			'Type an Initial zoom from 0 to 19 to start closer in. Leave it empty to fit every marker.',
			'To colour the markers, choose Colour by column, then click Add rule. The first rule that matches gives the colour.',
			'Type a Default colour for the markers that match no rule.',
			'Click Open map.',
			'If some rows could not be plotted, the map says how many, and why.',
			'Click Show the rows that were not plotted in the table to see them all.',
			'Or click List the places that were not plotted to see each place.',
			'Click the number of rows beside a place to see those rows in the table.',
		],
		tip   => 'Rows at one place become one marker. Click a marker to see every row it stands for. What the rows share is shown once, and the rest is a short table. A place with many rows shows the first ten, with a link to them all. The scale bar and the key change as you zoom. The key lists only the colours you can see. To size each marker by a number, add &size= and a column name to the map address. To give each category its own colour and a legend, add &series= and a column name instead. A place the local data does not know is looked up on OpenStreetMap. The map opens at once with the places already known. A bar shows each new place as it is looked up. Click Cancel to stop and see the map with the places found so far. Every place found is kept, so the next map of it opens at once.',
		walkthrough => {
			title => 'Walk through: Virginia counties on a map',
			intro => 'This example uses the virginia_counties table in the data folder.',
			steps => [
				{ do => 'Open the virginia_counties table and click Map...', see => 'The map panel opens.' },
				{ do => 'Keep Coordinate columns. Choose lat for Latitude and lon for Longitude.', see => 'The form shows lat and lon selected.' },
				{ do => 'Click Open map.', see => 'A map appears with 95 markers, one for each Virginia county.' },
				{ do => 'Click any marker.', see => 'A popup shows the county name, population and region.' },
			],
			result => 'All 95 Virginia counties appear as markers. Markers near one another cluster at low zoom.',
		},
		try    => { href => '/map?l=table:virginia_counties&lat=lat&lon=lon', label => 'Try the Virginia counties map' },
		routes => [ '/map' ],
	},
	{
		id    => 'wordcloud-chart',
		part  => 'Charts and summaries',
		title => 'Word cloud',
		chart => 1,
		lead  => 'A word cloud shows which words a text column repeats most.',
		steps => [
			'Open the table and click Word cloud...',
			'Choose Text column. This column holds words, such as a product name or a note.',
			'Set Words to show to the number of different words you want.',
			'Set Shortest word to hide very short words such as "at".',
			'Click Draw cloud.',
			'To keep the cloud on a saved canvas, open the canvas and click Add current view, then choose Word cloud.',
			'On a canvas, click a word to filter every other card to the rows that contain it.',
		],
		tip   => 'The biggest word appears in the most rows. Click a word to open the rows that contain it, or to cross-filter the canvas around it.',
		try    => { href => '/wordcloud?l=table:sales&col=product', label => 'Try a word cloud of the sales table' },
		routes => [ '/wordcloud' ],
	},
	{
		id    => 'pivot',
		part  => 'Charts and summaries',
		title => 'Summarise with a pivot table',
		lead  => 'A pivot table puts one group down the side and another group across the top. Each cell is a summary.',
		steps => [
			'Click Pivot table...',
			'Add a row group. For example, choose region.',
			'Add a measure. For example, choose Sum of amount.',
			'The measure can also be Median, Std dev, First, Last, Range or a percentile.',
			'Set Time bucket to group a row group by hour, day, month or year.',
			'Click Build pivot.',
			'Click Show subtotals and grand total if you want totals.',
		],
		tip   => 'Start with one row group and one measure. Add more only when you need them.',
		walkthrough => {
			title => 'Walk through: sales by region and product',
			intro => 'This example uses the sales table in the data folder.',
			steps => [
				{ do => 'Open the sales table and click Pivot table...', see => 'The panel opens with one empty row group and one measure.' },
				{ do => 'In the first row group, choose region.', see => 'region becomes the group down the side.' },
				{ do => 'Click Add column and choose product.', see => 'Each product will become a column across the top.' },
				{ do => 'In the measure row, choose amount and keep Sum.', see => 'The measure is called amount_sum unless you type another alias.' },
				{ do => 'Tick Show subtotals and grand total, then click Build pivot.', see => 'The pivot shows a total for each region and one grand total.' },
			],
			result => 'Regions run down the side, products run across the top, and each cell holds the sum of amount.',
		},
		routes => [ '/pivot' ],
	},
	{
		id    => 'stats',
		part  => 'Charts and summaries',
		title => 'See statistics for each column',
		lead  => 'Statistics give you a quick summary of every column.',
		steps => [
			'Open a table and click Column stats.',
			'Read one row for each column.',
			'Rows is the number of rows. Non-null is the number of cells with a value. Null is the number of blank cells.',
			'Distinct is the number of different values.',
			'For a number column you also see Min, Max, Range, Mean, Median, Std dev and a percentile.',
			'Mean is the average. Median is the middle value. Range is the largest value minus the smallest.',
			'Std dev shows how widely the values spread.',
			'First and Last are the values the column holds in the first and the last row that has one.',
			'Change Percentile column to choose which percentile the extra column shows.',
		],
		tip   => 'Statistics use the rows that are visible after joins and filters.',
		walkthrough => {
			title => 'Walk through: column statistics for Virginia counties',
			intro => 'This example uses the virginia_counties table in the data folder.',
			steps => [
				{ do => 'Open the virginia_counties table and click Column stats.', see => 'The stats page shows one row per column.' },
				{ do => 'Find the population row.', see => 'Min is 2214 and Max is 1150309.' },
				{ do => 'Look at the Distinct count for region.', see => 'There are 7 distinct regions.' },
				{ do => 'Look at Mean and Median for population.', see => 'Mean is much higher than Median. A few large counties pull the average up.' },
				{ do => 'Look at Range for population.', see => 'Min is 2214, so Range is 1148095.' },
			],
			result => 'Population is highly uneven. The maximum county is over 500 times larger than the minimum.',
		},
		try    => { href => '/stats?l=table:virginia_counties', label => 'Try statistics on Virginia counties' },
		routes => [ '/stats' ],
	},
	{
		id    => 'insights',
		part  => 'Charts and summaries',
		title => 'Find outliers and trends automatically',
		lead  => 'Insights scans your data and flags unusual values, changes over time, and repeating patterns.',
		steps => [
			'Open a table and click Insights.',
			'Each card shows one finding: an outlier, a period change, a top mover, or a seasonal pattern.',
			'An outlier is a value far outside the normal range for its group.',
			'A period change compares the most recent month to the one before it.',
			'A top mover is the category that changed the most between two periods.',
			'Seasonality means the same pattern repeats from one period to the next.',
			'Click View in chart on any card to open the chart that shows it.',
			'Click Summarize to read the findings as a few plain sentences.',
			'If the program has an AI key, tick Use AI for better prose first. Only the findings are sent, never your rows.',
		],
		tip   => 'Insights need a date column and a number column to detect period changes and top movers.',
		routes => [ '/insights' ],
	},
	{
		id    => 'ask',
		part  => 'Charts and summaries',
		title => 'Ask for a chart in plain English',
		lead  => 'Ask turns a question such as "sales by region as a pie chart" into a chart.',
		steps => [
			'Open a table and click Ask...',
			'Type what you want to see, for example: show me sales by region as a pie chart.',
			'Click Ask. The panel names the chart that it suggests.',
			'Click Run it to open that chart.',
			'Click Save to canvas to keep it as a card on a new canvas.',
		],
		tip   => 'Ask appears only when the person who runs the program has set an AI key. Only the column names and their types are sent, never your rows.',
	},

	# ---------------------------------------------------------------
	# Save and share
	# ---------------------------------------------------------------
	{
		id    => 'export',
		part  => 'Save and share',
		title => 'Save the data as a new file',
		lead  => 'Export writes the rows that you see to a new file.',
		steps => [
			'Click Export...',
			'Choose the folder and type a file name.',
			'The ending of the name chooses the format: .csv, .sql or .json.',
			'Click Save. The program writes a new file. Your source file is not changed.',
		],
		tip   => 'Export includes your joins, filters and duplicate setting.',
		routes => [ '/export' ],
	},
	{
		id    => 'catalog',
		part  => 'Save and share',
		title => 'See all your data files at a glance',
		lead  => 'The dataset catalog lists every file in the data folder and shows which canvases use it.',
		steps => [
			'Open the home page and click Dataset catalog.',
			'Each row shows the file name, type, size, and when it was last changed.',
			'The Used by column lists the canvases that include this file.',
			'Click a file name to open it as a table.',
			'Use the catalog to check which canvases will be affected if a file changes.',
		],
		tip   => 'A file that appears in Used by is linked to a canvas. Moving or renaming it will break that canvas.',
		try   => { href => '/catalog', label => 'Open the dataset catalog' },
		routes => [ '/catalog' ],
	},
	{
		id    => 'canvas',
		part  => 'Save and share',
		title => 'Save a canvas with several charts',
		lead  => 'A canvas is a saved page that can hold tables and charts side by side.',
		steps => [
			'Open a table and set up the view that you want.',
			'Click New canvas...',
			'Type a name and click Save.',
			'Click Open canvas. The current table or chart is the first card.',
			'Click Add visual... to add another view from a data file.',
			'In that panel, choose the Aggregate a chart works out: Sum, Average, Median, Std dev, or a percentile.',
			'Drag a card by its header to move it. Use the Size menu to change its width and height.',
			'Click Add text to put a title or an explanation on the canvas. The next chapter shows how.',
			'To show only a recent window on every card, choose a Time range and its column above the cards. Then click Apply range.',
			'Click Edit cross-row in a card header to see that card\'s cross-row columns, and to change or remove one.',
		],
		tip   => 'Click Canvases at the top of any page to see all your saved canvases. The home page lists them too. A banner appears if a data file has changed since the canvas was saved.',
		walkthrough => {
			title => 'Walk through: arrange and filter a canvas',
			intro => 'This example starts from a canvas with at least two visuals. Open one from the home page.',
			steps => [
				{ do => 'Click a bar or a slice in one chart.', see => 'The other cards show only rows for that value, and a chip names the filter.' },
				{ do => 'Click Clear on the filter chip.', see => 'Every card returns to the full data set.' },
				{ do => 'Open the Size menu in a card header and choose Half width.', see => 'The card takes half a row, and the cards beside it move to fit.' },
				{ do => 'Click Edit cross-row in a card header and click one of its columns.', see => 'The chip puts its column, function and name back in the fields, ready to change.' },
				{ do => 'Click Bookmarks, type a name and click Save.', see => 'A link to this exact view appears under the button.' },
				{ do => 'Click Print.', see => 'The browser print window opens with the canvas ready for paper or PDF.' },
				{ do => 'To save just one chart, use the SVG, PNG or PDF button in its card header.', see => 'The chart downloads as a file named after the card.' },
			],
			result => 'You filtered and arranged one dashboard, and saved a named view without changing any data file.',
		},
		routes => [ '/a/:id', '/canvases' ],
	},
	{
		id    => 'canvas-text',
		part  => 'Save and share',
		title => 'Add a title or an explanation to a canvas',
		lead  => 'A text card puts your own words on a canvas, in the font, size and colours that you choose.',
		steps => [
			'Open a saved canvas.',
			'Click Add text in the toolbar.',
			'Type your words in the Text box. Press Enter to start a new line.',
			'Choose how the text looks. The preview under the box changes as you choose.',
			'Click Add to canvas. The card appears at the end of the canvas, across its full width.',
			'Drag the card by its header to where you want it. The cards in the way move down.',
			'Use the Size menu in the header to make the card narrower, or to make it taller.',
			'To change the words or the look, double-click the text. You can also click Edit text in the header.',
			'Change what you want and click Save text. The card shows each change as you make it, and Cancel puts it back.',
			'To remove the card, double-click the text, click Remove card and confirm.',
		],
		tip   => 'Text is shown exactly as you type it, so HTML tags and Markdown appear as ordinary characters. A filter never changes a text card, because a text card reads no data.',
		table => {
			caption => 'What you can choose for a text card',
			head    => [ 'Setting', 'What it does' ],
			rows    => [
				[ 'Font', 'Same as the page, Arial, Georgia, Times New Roman, Verdana, Trebuchet MS or Courier New.' ],
				[ 'Size (points)', 'Any whole number from 8 to 96. A new card starts at 14.' ],
				[ 'Alignment', 'Left, Centre or Right.' ],
				[ 'Text colour', 'Pick a colour, or tick Follow the theme to match the light or dark page.' ],
				[ 'Background', 'Pick a colour to fill the card, or tick None to leave it clear.' ],
				[ 'Bold and Italic', 'Tick either one, or both.' ],
				[ 'Hide the frame until pointed at', 'The card shows only its words until you point at it. This is ticked for a new card.' ],
			],
		},
		walkthrough => {
			title => 'Walk through: put a heading on a canvas',
			intro => 'This example starts from a canvas with at least one chart. Open one from the home page.',
			steps => [
				{ do => 'Click Add text and type Quarterly sales in the Text box.', see => 'The words appear in the preview under the box.' },
				{ do => 'Choose Georgia, type 24 for the size, choose Centre and tick Bold.', see => 'The preview shows large, bold, centred text.' },
				{ do => 'Click Add to canvas.', see => 'The heading appears below the other cards, with no frame around it.' },
				{ do => 'Point at the heading.', see => 'A frame appears, with a header above the words.' },
				{ do => 'Drag the header to the top of the canvas.', see => 'The heading moves to the top row, and the charts move down below it.' },
				{ do => 'Reload the page.', see => 'The heading is still at the top, in a row only as tall as its text.' },
			],
			result => 'You gave the canvas a heading that is saved with it and does not depend on any data file.',
		},
		routes => [],
	},
	{
		id    => 'share',
		part  => 'Save and share',
		title => 'Share a link to a view',
		lead  => 'A link can open the same table, filters and chart for another person.',
		steps => [
			'Open a chart, or a table that has at least one filter.',
			'Click Copy link. The program puts the address on your clipboard.',
			'Paste the address into an email or a chat message.',
		],
		tip   => 'On a table, Copy link appears when a filter is active. On a chart, it is always there. The other person needs access to the file.',
		routes => [],
	},
	{
		id    => 'share-canvas',
		part  => 'Save and share',
		title => 'Share a canvas with a signed link',
		lead  => 'A canvas share link lets anyone with the link view the canvas for 30 days.',
		steps => [
			'Open a saved canvas.',
			'Click Share... in the canvas toolbar.',
			'Click Make a link, then Copy link. The link is now on your clipboard.',
			'Send the link by email or in a message.',
			'To show the canvas inside another page of this site, click Copy embed code instead.',
			'The link stops working after 30 days. Click Make a new link to create another.',
		],
		tip   => 'The link gives read-only access. To keep a copy of the canvas, click Download as JSON. Import canvas on the Canvases page reads it back.',
		routes => [],
	},

	# ---------------------------------------------------------------
	# Help
	# ---------------------------------------------------------------
	{
		id    => 'keyboard',
		part  => 'Help',
		title => 'Use the program with the keyboard',
		lead  => 'Every control can be used without a mouse.',
		steps => [
			'Press Tab to move to the next control. Press Shift+Tab to move back.',
			'Press Enter or Space to press a button or open a link.',
			'On a column heading, press Enter to sort. Press Shift+Left or Shift+Right to move the column.',
			'On a chart, press Tab until the resize grip has focus. Use the arrow keys to resize. Hold Shift for bigger steps.',
			'On a canvas, focus a card header and use the arrow keys to move the card. Hold Shift to move it to the edge.',
		],
		tip   => 'The page says each change out loud for screen readers.',
		routes => [],
	},
	{
		id    => 'preferences',
		part  => 'Help',
		title => 'Set your preferences',
		lead  => 'The Preferences page chooses how the program looks to you. It has one setting: the theme.',
		steps => [
			'Click Preferences at the top of any page.',
			'Under Theme, choose Same as this device, Light or Dark.',
			'Same as this device is the choice until you change it. The program follows the light or dark setting on your computer or phone, even while a page is open.',
			'The page changes as soon as you choose. There is no Save button.',
			'Every other page follows, including pages that are open in other tabs.',
			'Tables and charts change with the page. A map keeps its usual colours.',
		],
		tip   => 'The choice is saved in this browser, so another browser or computer keeps its own. Saved charts and printed pages always use the light colours.',
		try   => { href => '/preferences', label => 'Open your preferences' },
		routes => [ '/preferences' ],
	},

	# ---------------------------------------------------------------
	# For maintainers
	# ---------------------------------------------------------------
	{
		id    => 'alerts',
		part  => 'For maintainers',
		title => 'Alert when a number crosses a limit',
		lead  => 'The bi-alert script checks a canvas measure and signals when it crosses a threshold.',
		steps => [
			'Find the script at script/bi-alert in the application folder.',
			'Run bi-alert --help to see all options.',
			'Pass --analysis with the canvas id and --threshold with the measure, comparison and value.',
			'For example: bi-alert --analysis abc123 --threshold count:gt:0 exits with code 1 when count is above 0.',
			'Pass --analysis or --threshold more than once to check several in the same run.',
			'Prefix a threshold with an analysis id, such as abc123:count:gt:10, to check a second canvas.',
			'Pass --dry-run to run the check and print the result without sending anything. A dry run does not count towards --suppress.',
			'A threshold that stays crossed is only worth hearing about once, so pass --suppress 1h to be told at most hourly.',
			'The script remembers the last alert in a small state file, and forgets it when the crossing ends.',
			'Pass --recovery to be told when the crossing ends as well as when it starts.',
			'The script can only see a crossing end when it remembers one starting, so --recovery keeps its state file.',
			'Pass --notify-cmd with a command such as mail to have the script deliver the alert and the recovery itself.',
			'Wire the script into a cron job or a monitoring system to get automatic alerts.',
		],
		tip   => 'Exit code 0 means no alert: the threshold was not crossed, or it was crossed and already reported in this period. Exit code 1 means it was crossed and reported now. Exit code 3 means a crossing that was reported has ended, which is what --recovery asks for. Exit code 2 means an error. When one run reports a crossing and a recovery together, exit code 1 wins.',
		routes => [],
	},
	{
		id    => 'geocode',
		part  => 'For maintainers',
		title => 'Look up place names before anyone opens the map',
		lead  => 'The bi-geocode script finds the coordinates of every place in a column and keeps them for the map.',
		steps => [
			'Find the script at script/bi-geocode in the application folder.',
			'Pass --spec with the table, and --col with the column that holds the place names.',
			'Give --col twice for a place split over two columns, such as --col Address --col Country.',
			'For example: bi-geocode --spec table:virginia_counties --col county --region US.',
			'Pass --region with a country code, such as GB or US, when the names could be in several countries.',
			'Pass --dry-run to look the places up without keeping the result.',
			'Places the local data does not know are looked up on OpenStreetMap, one each second. Pass --offline to stop that.',
			'Run it again at any time. Places that it already knows are not looked up twice.',
		],
		tip   => 'The map with a Place-name column then opens at once, because no place has to be looked up. The script needs Geo::Coder::List 0.39 and Geo::Coder::Free 0.48 or later. OpenStreetMap also needs Geo::Coder::OSM 0.03 or later. Exit code 0 means success.',
		routes => [],
	},
	{
		id    => 'settings',
		part  => 'For maintainers',
		title => 'Change the program settings',
		lead  => 'A file called database_bi.conf in the application folder changes how the program runs.',
		steps => [
			'Create database_bi.conf next to the script folder. It holds one Perl hash, such as { data_dir => \'/srv/data\' }.',
			'data_dir is the folder that the home page lists. It can be a full path or a path inside the application folder.',
			'uploads_dir is where dropped files are kept. Set it when the application folder cannot be written.',
			'model_dir holds the saved canvases and settings. It must not be inside data_dir.',
			'Set page_cache_dir to keep a copy of the Catalog and Tutorial pages on disc. page_cache_duration says for how long.',
			'Set ai_api_key to show the Ask button and the AI choice on the insights page.',
			'Restart the program after you change the file.',
		],
		tip   => 'Every setting is optional. Without the file, the program lists the data folder and keeps its own files in .bi and .uploads.',
		routes => [],
	},
	{
		id    => 'developers',
		part  => 'For maintainers',
		title => 'Where this page lives',
		lead  => 'This tutorial is part of the application. It is not in the Perl documentation.',
		steps => [
			'The text of this page is a list of chapters in lib/Database/BI/Tutorial.pm.',
			'The page itself is templates/web/en/tutorial.html.tt. The route is GET /tutorial.',
			'To add a chapter, add one entry to the list. Give it a title, a short lead, the steps, and the routes that it covers.',
			'Each page finds its Help link through the action map in the same module. Add a new page action there.',
			'Run prove -l t/tutorial.t. The test fails if a GET page has no chapter and no reason to be exempt.',
			'Read README.md for how to start the program and run the full test suite.',
		],
		tip   => 'Keep the words simple. The test also checks that no step is a very long sentence.',
		routes => [],
	},
);

my @FAQ = (
	{
		question => 'The file is not in the list. What can I do?',
		answer   => 'Put the file in the data folder, or open it from Browse your files. The program only lists files that it can read.',
	},
	{
		question => 'The home address shows one file, not the list.',
		answer   => 'The program was started with the name of that file. Click Home in the breadcrumb to see the list. To stop this, start the program without a file name.',
	},
	{
		question => 'The program says that only one database can be opened.',
		answer   => 'You named more than one file when you started the program. Name one, then use Merge or Combine on its page to add the others.',
	},
	{
		question => 'The table says its extract is stale.',
		answer   => 'The file has changed since its fast copy was made, so the file itself was read. Run script/bi-extract --all to make the copy again.',
	},
	{
		question => 'An extracted column says (unparseable).',
		answer   => 'The pattern did not match the value in that row. Those rows are kept and grouped together, so you can see how many there are.',
	},
	{
		question => 'New columns appeared that are not in my file.',
		answer   => 'A lookup or an extraction adds them. Open the Lookups or Extract fields panel to see them. Delete one there, or skip a lookup in this view.',
	},
	{
		question => 'The table says its saved columns could not be added.',
		answer   => 'The file has changed, and a saved column can no longer be worked out. The note names it. Click the panel the note names, then correct or delete it.',
	},
	{
		question => 'A chart says it cannot be drawn.',
		answer   => 'The page says why, for example a column that the view does not have. Click Back, then choose other columns.',
	},
	{
		question => 'The program will not open my file.',
		answer   => 'Check the end of the file name. The program reads CSV, TSV, PSV, XLSX, XML, SQLite and Berkeley DB files.',
	},
	{
		question => 'The page is dark, but my saved chart is white.',
		answer   => 'This is on purpose. Saved charts and printed pages always use the light colours, so that they look the same to whoever receives them.',
	},
	{
		question => 'My text on a canvas is hard to read in the dark theme.',
		answer   => 'A colour that you pick stays the same in both themes. Tick Follow the theme, or give the card a background colour too.',
	},
	{
		question => 'I cannot find the controls on my text card.',
		answer   => 'The card hides its frame and header until you point at it. Point at the text, or double-click it to open its settings.',
	},
	{
		question => 'My text card is too tall or too short.',
		answer   => 'A card one row high is as tall as its text when its row holds only text. Next to a chart, it is as tall as the chart. Choose 2 rows high in the Size menu for a taller card.',
	},
	{
		question => 'Undo did not bring back my text card.',
		answer   => 'Undo and Redo step through filters and other page state. They do not undo a change to a card, so a removed text card has to be added again.',
	},
	{
		question => 'Can I open a MariaDB or MySQL database?',
		answer   => 'Yes, once the server has been added to mariadb_servers in the configuration file. The home page then has a card for it, which lists its tables. Choose a table to open it. You can also type mariadb:shop/orders in the path box, or in Merge and Combine. Only a page of the table is read at a time, until you filter it.',
		link     => { text => 'the configuration file', href => 'https://github.com/nigelhorne/Database-BI#configuration' },
	},
	{
		question => 'A number filter leaves out my blank cells.',
		answer   => 'This is on purpose. Less than and greater than compare numbers, so a blank or a word in the cell does not match. Use the empty filter to find blank cells.',
	},
	{
		question => 'The program does not remember my theme.',
		answer   => 'The choice is saved in this browser. A private window forgets it when you close the window. If the browser will not save it, the Preferences page says so.',
	},
	{
		question => 'My chart is empty.',
		answer   => 'Check that you chose a number column for the value. Check also that your filters still show some rows.',
	},
	{
		question => 'A merge added blank cells.',
		answer   => 'The two tables had no matching value in the key columns. Check the spelling and the type of the values.',
	},
	{
		question => 'My changes disappeared.',
		answer   => 'A filter or a join lives in the page address. Save the view as a canvas, or copy the link before you close the page.',
	},
	{
		question => 'A table in my SQLite file says Cannot be opened.',
		answer   => 'The name of that table has characters other than letters, digits and underscores, such as a colon or a space. The other tables in the file still open. To open this one, rename it in a copy of the file. The message shows the command to use.',
	},
	{
		question => 'The page says Page not found.',
		answer   => 'The address names a table, a canvas or a page that is not there. Use the breadcrumb or Go to Home to find it again.',
	},
);

my @GLOSSARY = (
	{ term => 'Berkeley DB', meaning => 'A database file that ends in .db.' },
	{ term => 'Breadcrumb',  meaning => 'The row of links that shows each page between Home and this one.' },
	{ term => 'Browser',     meaning => 'The program that shows web pages, for example Firefox or Chrome.' },
	{ term => 'Canvas',      meaning => 'A saved page with several tables and charts.' },
	{ term => 'Cell',        meaning => 'One value in a table, at one row and one column.' },
	{ term => 'Chart',       meaning => 'A picture of numbers, for example a bar chart.' },
	{ term => 'Column',      meaning => 'One kind of value in a table, for example the price column.' },
	{ term => 'Combine',     meaning => 'Put the rows of one file under the rows of another file.' },
	{ term => 'Cross-row column', meaning => 'A column worked out from several rows, for example a running total.' },
	{ term => 'CSV',         meaning => 'A text file with values separated by commas.' },
	{ term => 'Data file',   meaning => 'A file with rows and columns that the program can read.' },
	{ term => 'Duplicate',   meaning => 'A row that is exactly the same as another row.' },
	{ term => 'Export',      meaning => 'Write the rows that you see to a new file.' },
	{ term => 'Expression',  meaning => 'A small formula, for example revenue - cost.' },
	{ term => 'Filter',      meaning => 'A rule that hides rows which do not match.' },
	{ term => 'Geocode',     meaning => 'Change a place name into a latitude and a longitude.' },
	{ term => 'Join',        meaning => 'Add columns from a second table by matching a shared value.' },
	{ term => 'Pivot table', meaning => 'A grid that summarises rows and columns.' },
	{ term => 'PSV',         meaning => 'A text file with values separated by pipe characters.' },
	{ term => 'Row',         meaning => 'One record in a table.' },
	{ term => 'Server',      meaning => 'The program on a computer that sends pages to your browser.' },
	{ term => 'SQLite',      meaning => 'A database file that can hold more than one table.' },
	{ term => 'Time bucket', meaning => 'One group for each hour, day, month or other period.' },
	{ term => 'Time range',  meaning => 'A recent window, such as the last 30 days, worked out from today.' },
	{ term => 'TSV',         meaning => 'A text file with values separated by tab characters.' },
	{ term => 'URL',         meaning => 'The address of a web page, shown in the address bar.' },
	{ term => 'XLSX',        meaning => 'An Excel spreadsheet file.' },
	{ term => 'XML',         meaning => 'A text file with data inside tags.' },
);

# Routes that are GET pages but are not chapters.  Every entry needs a reason:
# it is a decision to leave a page out of the tutorial, not an accident.
# Actions that render a page, mapped to the chapter that helps with that page.
# The layout turns this into a "Help: ..." link beside the main Tutorial link,
# so a reader on the pie chart screen lands on the pie chart chapter.  A new
# page action belongs here; t/tutorial.t checks that every covered GET route
# has an entry.
my %ACTION_CHAPTERS = (
	index          => 'open-file',
	browse         => 'other-files',
	open_file      => 'read-table',
	import_url     => 'web-table',
	view           => 'read-table',
	join_tables    => 'join',
	combine_tables => 'combine',
	export_data    => 'export',
	tables_view    => 'other-files',
	graph_view     => 'line-chart',
	pie_view       => 'pie-chart',
	heatmap_view   => 'heatmap-chart',
	bar_view       => 'bar-chart',
	folder_view    => 'folder',
	pivot_view     => 'pivot',
	stats_view     => 'stats',
	insights_view  => 'insights',
	scatter_view   => 'scatter-chart',
	stacked_view   => 'stacked-chart',
	combo_view     => 'combo-chart',
	treemap_view   => 'treemap-chart',
	histogram_view => 'histogram-chart',
	wordcloud_view => 'wordcloud-chart',
	map_view       => 'map-chart',
	canvas_render  => 'canvas',
	catalog_view   => 'catalog',
	canvases_view  => 'canvas',
	preferences    => 'preferences',
);

my %EXEMPT_ROUTES = (
	'/a/:id/visual/:n/:fmt'    => 'per-visual CSV/PNG download; not a navigable page',
	'/api/analyses'            => 'JSON for the saved-canvas list',
	'/api/analyses/:id'        => 'JSON for one saved canvas',
	'/api/analyses/:id/export' => 'JSON export of one saved canvas',
	'/api/columns'             => 'JSON list of columns for the join and filter panels',
	'/api/dirs'                => 'JSON folder list for the browse and export panels',
	'/api/range'               => 'JSON min/max ISO dates for the filter date-picker constraints',
	'/api/stat'                => 'JSON file details for the home-page tooltips',
	'/calc/list'               => 'JSON list of calculated fields for the Calc panel',
	'/dates/list'              => 'JSON list of date formats for the Date panel',
	'/geo/list'                => 'JSON list of saved coordinate column preferences for the Map panel',
	'/embed/:id'               => 'chrome-less embed view; requires a share token and is not a standalone page',
	'/groups/list'             => 'JSON list of value groups for the Group panel',
	'/extract/list'            => 'JSON list of the stored field extractions of a dataset',
	'/lookups/list'            => 'JSON list of the stored lookups of a dataset',
	'/share/:id'               => 'shared read-only canvas view; requires a signed token and cannot be navigated to directly',
	'/tutorial'                => 'this page',
);

sub intro     { return \@INTRO }
sub chapters  { return \@CHAPTERS }
sub faq       { return \@FAQ }
sub glossary  { return \@GLOSSARY }

sub parts {
	my @parts;

	for my $chapter (@CHAPTERS) {
		my $name = $chapter->{part};

		if (!@parts || $parts[-1]{name} ne $name) {
			push @parts, {
				name     => $name,
				id       => _slug($name),
				chapters => [],
			};
		}

		push @{ $parts[-1]{chapters} }, $chapter;
	}

	return \@parts;
}

sub covered_routes {
	my %routes;

	for my $chapter (@CHAPTERS) {
		for my $route (@{ $chapter->{routes} // [] }) {
			$routes{$route} = $chapter->{id};
		}
	}

	return \%routes;
}

sub exempt_routes {
	return { %EXEMPT_ROUTES };
}

sub chapter_for_action {
	my $action = $_[1];
	return unless defined $action;

	my $id = $ACTION_CHAPTERS{$action} or return;

	for my $chapter (@CHAPTERS) {
		return $chapter if $chapter->{id} eq $id;
	}

	return;
}

sub _slug {
	my ($text) = @_;

	my $slug = lc $text;
	$slug =~ s/[^a-z0-9]+/-/g;
	$slug =~ s/\A-+|-+\z//g;

	return $slug;
}

1;

=head1 NAME

Database::BI::Tutorial - the chapters of the in-application tutorial

=head1 SYNOPSIS

  use Database::BI::Tutorial;

  for my $part (@{ Database::BI::Tutorial->parts }) {
      print $part->{name}, ": ", scalar @{ $part->{chapters} }, " chapters\n";
  }

  my $chapter = Database::BI::Tutorial->chapter_for_action('bar_view');
  print $chapter->{title}, "\n" if $chapter;

=head1 DESCRIPTION

The tutorial that the application shows at C<GET /tutorial> is built from the
data in this module.  A chapter is one feature: a title, a short lead, numbered
steps, and the C<routes> that it covers.  The template renders the chapters in
order, so adding a feature means adding a hash here, not editing HTML.

A chapter may also have a C<walkthrough>: a worked example with a C<title>, an
C<intro>, a list of C<steps> that each say what to C<do> and what to C<see>,
and a C<result>.  The template shows it as one box, and the contents marks the
chapter so a reader can find it.

C<t/tutorial.t> checks that every GET page in L<Database::BI> is either covered
by a chapter or listed in C<exempt_routes()> with a reason.  Keep the sentences
short: the same test fails a lead, step, tip or walk-through sentence longer
than 25 words.

C<chapter_for_action()> maps a controller action to the chapter that helps with
that page.  The application calls it from a C<before_render> hook and the shared
layout shows the result as a C<Help: ...> link beside the main Tutorial link.
A new page action belongs in C<%ACTION_CHAPTERS>; the test fails until it is
there.

=head1 FUNCTIONS

Each is called as a class method or a plain function; none takes arguments
except C<chapter_for_action>.  The returned structures are the module's own
data: read them, do not change them.

=head2 intro

=head3 API SPECIFICATION

=head4 OUTPUT

	[ 'string', ... ]   # the introduction's sentences

=head2 chapters

=head3 API SPECIFICATION

=head4 OUTPUT

	[ {
	    id     => 'string',     # anchor, unique
	    part   => 'string',     # the part the chapter belongs to
	    title  => 'string',
	    lead   => 'string',
	    steps  => 'arrayref',   # sentences
	    tip    => 'string',     # optional
	    try    => 'hashref',    # optional; { href, label }
	    routes => 'arrayref',   # the GET routes the chapter covers
	    walkthrough => 'hashref', # optional; { title, intro, steps => [ { do, see } ], result }
	}, ... ]

In the order the page shows them.

=head2 faq

=head3 API SPECIFICATION

=head4 OUTPUT

	[ { question => 'string', answer => 'string', link => { text, href }? }, ... ]

C<link> makes the words C<text>, which occur once in C<answer>, a link to C<href>.

=head2 glossary

=head3 API SPECIFICATION

=head4 OUTPUT

	[ { term => 'string', meaning => 'string' }, ... ]

=head2 parts

=head3 API SPECIFICATION

=head4 OUTPUT

	[ { name => 'string', id => 'string', chapters => 'arrayref' }, ... ]

The chapters grouped by C<part>, in order.  C<id> is the part name in lower
case with each run of other characters replaced by C<->.  A new list is built
on each call.

=head2 covered_routes

=head3 API SPECIFICATION

=head4 OUTPUT

	{ '/route' => 'chapter-id', ... }

A route named by two chapters maps to the later one.

=head2 exempt_routes

=head3 API SPECIFICATION

=head4 OUTPUT

	{ '/route' => 'reason', ... }   # a copy: GET pages with no chapter, and why

=head2 chapter_for_action

=head3 API SPECIFICATION

=head4 INPUT

	$action   # a controller action name, e.g. 'bar_view'

=head4 OUTPUT

	A chapter hashref (as C<chapters> returns), or an empty list

An undefined or unknown action returns an empty list.  It must be called as a
class method: the action is the second argument.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
