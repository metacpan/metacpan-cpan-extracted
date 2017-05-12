var varreg = /^%(\d+)$/;
function _(str, args)
{
	if(dict[str])
		str = dict[str];
	var tokens = str.split(/(%\d+)/);
	for(var i = 0; i < tokens.length; i++) {
		var match = varreg.exec(tokens[i]);
		if(match) {
			tokens[i] = args[parseInt(match[1]) - 1];
		}
	}
	return tokens.join("");
}
