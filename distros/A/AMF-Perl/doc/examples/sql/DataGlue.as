// test w/ combobox, listbox, tree, chart?

_global.DataGlue = function(dataProvider)
{
	this.dataProvider = dataProvider;
}
 
// specify a format string for each line of text
_global.DataGlue.bindFormatStrings = function (dataConsumer, dataProvider, labelString, dataString)
{
	var proxy = new DataGlue(dataProvider);
	proxy.labelString = labelString;
	proxy.dataString = dataString;
	proxy.getItemAt = _global.DataGlue.getItemAt_FormatString;
	dataConsumer.setDataProvider(proxy);
}
 
// let a user-supplied function handle formatting of each data record
_global.DataGlue.bindFormatFunction = function (dataConsumer, dataProvider, formatFunction)
{
	var proxy = new DataGlue(dataProvider);
	proxy.formatFunction = formatFunction;
	proxy.getItemAt = _global.DataGlue.getItemAt_FormatFunction;
	dataConsumer.setDataProvider(proxy);
}

_global.DataGlue.prototype.addView = function(viewRef)
{
	return this.dataProvider.addView(viewRef);
}

_global.DataGlue.prototype.getLength = function()
{
	return this.dataProvider.getLength();
}

_global.DataGlue.prototype.format = function(formatString, record)
{
	var tokens = formatString.split("#");
	var result = "";
	for (var i = 0; i < tokens.length; i += 2)
	{
		result += tokens[i];
		result += (tokens[i+1] == "") ? "#" : record[tokens[i+1]];
	}	
	return result;
}

_global.DataGlue.getItemAt_FormatString = function(index)
{
	var record = this.dataProvider.getItemAt(index);
	if (record == "in progress" || record==undefined)
		return record;
	return {label: this.format(this.labelString, record), data: (this.dataString == null) ? record : this.format(this.dataString, record)};
}

_global.DataGlue.getItemAt_FormatFunction = function(index)
{	
	var record = this.dataProvider.getItemAt(index);
	if (record == "in progress" || record==undefined)
		return record;
	return this.formatFunction(record);
}

_global.DataGlue.prototype.getItemID = function(index)
{
	return this.dataProvider.getItemID(index);
}

_global.DataGlue.prototype.addItemAt = function(index, value)
{
	return this.dataProvider.addItemAt(index, value);
}

_global.DataGlue.prototype.addItem = function(value)
{ 
	return this.dataProvider.addItem(value);
}

_global.DataGlue.prototype.removeItemAt = function(index) 
{
	return this.dataProvider.removeItemAt(index);
}

_global.DataGlue.prototype.removeAll = function()
{
	return this.dataProvider.removeAll();
}

_global.DataGlue.prototype.replaceItemAt = function(index, itemObj) 
{
	return this.dataProvider.replaceItemAt(index, itemObj);
}

_global.DataGlue.prototype.sortItemsBy = function(fieldName, order)
{
	return this.dataProvider.sortItemsBy(fieldName, order);
}
