package Database::BI::Tutorial;

use strict;
use warnings;

our $VERSION = '0.015.0';

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
		],
		tip   => 'A dropped file is a copy. Changes in the view do not change your original file.',
		routes => [ '/browse', '/open', '/tables' ],
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
			'Choose a column. Choose how to compare, such as equals or contains. Type a value.',
			'Press Enter or click Apply filter.',
			'Each filter is shown as a small label. Click the x on a label to remove that filter.',
			'For more rules, click Merge / Filter... and use the Filter results section.',
		],
		tip   => 'A filter does not change your file. It only changes what you see and what you export.',
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
		tip   => 'Export uses the same rows that you see. Check this button before you export.',
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
		id    => 'groups',
		part  => 'Work with a table',
		title => 'Group values into your own labels',
		lead  => 'A group gives several values one shared name.',
		steps => [
			'Click Group values...',
			'Choose the source column.',
			'Click Add group. Type a label, for example Northern.',
			'Type the values for this group, one on each line. Click Save group.',
			'Use the new col_group column in a chart or pivot table.',
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
			'Click Save & apply.',
		],
		tip   => 'After you set the format, This year, This quarter and This month work in the date panel.',
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
			'Use Export SVG or Export PNG to save the chart. Use Copy link to share the page.',
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
			],
		},
		tip   => 'A bar chart is a good first choice for most data.',
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
			'Click Plot.',
		],
		tip   => 'Use Copy link to share the chart. Use Export SVG or Export PNG to save the picture.',
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
		tip   => 'If a column is not numeric, it does not appear in the axis lists.',
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
			'Click Plot.',
		],
		tip   => 'Use a combo chart when two numbers are measured in different units.',
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
			'Click Plot.',
		],
		tip   => 'A treemap is useful when one level has many groups.',
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
			'Click Open map.',
		],
		tip   => 'Rows at one place become one marker. Click a marker to see what it stands for.',
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
		id    => 'pivot',
		part  => 'Charts and summaries',
		title => 'Summarise with a pivot table',
		lead  => 'A pivot table puts one group down the side and another group across the top. Each cell is a summary.',
		steps => [
			'Click Pivot table...',
			'Add a row group. For example, choose region.',
			'Add a measure. For example, choose Sum of amount.',
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
			'For a number column you also see Min, Max, Mean and Median. Mean is the average. Median is the middle value.',
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
			],
			result => 'Population is highly uneven. The maximum county is over 500 times larger than the minimum.',
		},
		try    => { href => '/stats?l=table:virginia_counties', label => 'Try statistics on Virginia counties' },
		routes => [ '/stats' ],
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
			'Drag a card by its header to move it. Use the Size menu to change its width and height.',
		],
		tip   => 'The home page lists your saved canvases under Saved canvases. A banner appears if a data file has changed since the canvas was saved.',
		walkthrough => {
			title => 'Walk through: arrange and filter a canvas',
			intro => 'This example starts from a canvas with at least two visuals. Open one from the home page.',
			steps => [
				{ do => 'Click a bar or a slice in one chart.', see => 'The other cards show only rows for that value, and a chip names the filter.' },
				{ do => 'Click Clear on the filter chip.', see => 'Every card returns to the full data set.' },
				{ do => 'Open the Size menu in a card header and choose Half width.', see => 'The card takes half a row, and the cards beside it move to fit.' },
				{ do => 'Click Bookmarks, type a name and click Save.', see => 'A link to this exact view appears under the button.' },
				{ do => 'Click Print.', see => 'The browser print window opens with the canvas ready for paper or PDF.' },
			],
			result => 'You filtered and arranged one dashboard, and saved a named view without changing any data file.',
		},
		routes => [ '/a/:id' ],
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
			'Click Share in the canvas toolbar.',
			'Click Copy share link. The link is now on your clipboard.',
			'Send the link by email or in a message.',
			'The link stops working after 30 days. Click Share again to create a new one.',
		],
		tip   => 'The link gives read-only access. The person can see every visual but cannot change the canvas or the data.',
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
			'Pass --dry-run to print what would be checked without running the check.',
			'Wire the script into a cron job or a monitoring system to get automatic alerts.',
		],
		tip   => 'Exit code 0 means the threshold was not crossed. Exit code 1 means it was. Exit code 2 means an error.',
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
		question => 'The program will not open my file.',
		answer   => 'Check the end of the file name. The program reads CSV, TSV, PSV, XLSX, XML, SQLite and Berkeley DB files.',
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
);

my @GLOSSARY = (
	{ term => 'Berkeley DB', meaning => 'A database file that ends in .db.' },
	{ term => 'Browser',     meaning => 'The program that shows web pages, for example Firefox or Chrome.' },
	{ term => 'Canvas',      meaning => 'A saved page with several tables and charts.' },
	{ term => 'Cell',        meaning => 'One value in a table, at one row and one column.' },
	{ term => 'Chart',       meaning => 'A picture of numbers, for example a bar chart.' },
	{ term => 'Column',      meaning => 'One kind of value in a table, for example the price column.' },
	{ term => 'Combine',     meaning => 'Put the rows of one file under the rows of another file.' },
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
	scatter_view   => 'scatter-chart',
	stacked_view   => 'stacked-chart',
	combo_view     => 'combo-chart',
	treemap_view   => 'treemap-chart',
	histogram_view => 'histogram-chart',
	map_view       => 'map-chart',
	canvas_render  => 'canvas',
	catalog_view   => 'catalog',
);

my %EXEMPT_ROUTES = (
	'/a/:id/visual/:n/:fmt'    => 'per-visual CSV/PNG download; not a navigable page',
	'/api/analyses'            => 'JSON for the saved-canvas list',
	'/api/analyses/:id'        => 'JSON for one saved canvas',
	'/api/analyses/:id/export' => 'JSON export of one saved canvas',
	'/api/columns'             => 'JSON list of columns for the join and filter panels',
	'/api/dirs'                => 'JSON folder list for the browse and export panels',
	'/api/stat'                => 'JSON file details for the home-page tooltips',
	'/calc/list'               => 'JSON list of calculated fields for the Calc panel',
	'/dates/list'              => 'JSON list of date formats for the Date panel',
	'/embed/:id'               => 'chrome-less embed view; requires a share token and is not a standalone page',
	'/groups/list'             => 'JSON list of value groups for the Group panel',
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

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
