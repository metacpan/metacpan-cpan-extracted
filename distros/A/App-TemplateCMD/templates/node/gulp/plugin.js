/* global require, module */

var through  = require('through2'),
	gulputil = require('gulp-util'),
	path     = require('path'),
	PluginError = gulputil.PluginError;

const PLUGIN_NAME = '[% plugin %]';

function [% plugin %](options) {
	var stream = through.obj(function (file, enc, callback) {
		if (file.isStream()) {
			this.emit('error', new PluginError(PLUGIN_NAME, 'Streams are not supported!'));
			return callback();
		}

		var objectName = file.history[0].split(path.sep).slice(-2)[0],
			filecontents = '',
			prefix = '';

		try {
			filecontents = String(file.contents);

			if (options && options.prefix) {
				prefix = options.prefix + '.';
			}

			filecontents = options.prefix + '[\'' + objectName + '\'] = ' + filecontents;

			file.contents = new Buffer(filecontents);
			this.push(file);
		}
		catch (e) {
			console.warn('Error caught: ' + e);
			this.push(file);
			return callback();
		}

		callback();
	});

	return stream;
}

module.exports = [% plugin %];
