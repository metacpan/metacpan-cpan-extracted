package Catalyst::Helper::Firebug;
use strict;
use warnings;

use MIME::Base64;
use File::Spec;

=head1 NAME

Catalyst::Helper::Firebug - Catalyst Helper to generate Firebug Lite files

=head1 SYNOPSIS

    ./script/myapp_create.pl Firebug [path]
    
    path:  output directory path (default: root/js/firebug)

=head1 DESCRIPTION

Catalyst Helper to generate Firebug Lite files

=head1 SEE ALSO

Firebug, http://getfirebug.com/

Firebug Lite, http://getfirebug.com/lite.html

=head1 METHODS

=head2 mk_stuff

Create Firebug Lite files

=cut

sub mk_stuff {
    my ($self, $helper, $path) = @_;
    $path ||= File::Spec->catfile(qw/root js firebug/);

    $helper->mk_dir( File::Spec->catfile( $helper->{base}, $path ) );

    my @files = qw/errorIcon.png firebug.css firebug.html firebug.js firebugx.js infoIcon.png warningIcon.png/;

    for my $file (@files) {
        my $data = $helper->get_file(__PACKAGE__, $file);
        $data = decode_base64($data) if $file =~ /\.png$/;
        $helper->mk_file( File::Spec->catfile( $helper->{base}, $path, $file ), $data );
    }
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;

__DATA__

__errorIcon.png__
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABGdBTUEAANbY1E9YMgAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAFbSURBVHjafJI9SwNBEIZnE8HKRrDQNAr6Cw78AZI6IBzYploQrKz8ATYprCWVhaWgEkWUa1JYieksRCEWKhaBi1/Br2J952Yntx6YhSc7OzNvZmZvjXOOdB0YU8ZmQQ1Mefcd2F12rkXBMiqEqG6IdmZhT4NxnzAA9+AJKdi28QdJFmDhPtHaGcyUj//wCI4BcpeyYjAmD+F4HSFSHkS4x8ISiq4u4GeCy1erkmJtPgzb7EOsImPEGKs2BjuuaFK3S9TvEzWbuZBt9nEMa0bmjbnV5++wpShyLk3dcLHNPh/vSbvtEhVXp0PUaORnttmnn0G2Mle8fgsrWptX0srsK1wQC7duwzbD9sK2fbuXIqyzcP4Ih4EKk+TPTKFP53MSyR7ARhvm14hv+A5ORbgyFHrx5gmON/7mfsAnwNW7K9AS0brmm8Ijn+MHARZBBD7ABTj37/RFc38FGACwGjGO2PzGygAAAABJRU5ErkJggg==
__firebug.css__

html, body {
    margin: 0;
    background: #FFFFFF;
    font-family: Lucida Grande, Tahoma, sans-serif;
    font-size: 11px;
    overflow: hidden;
}

a {
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

.toolbar {
    height: 14px;
    border-top: 1px solid ThreeDHighlight;
    border-bottom: 1px solid ThreeDShadow;
    padding: 2px 6px;
    background: ThreeDFace;
}

.toolbarRight {
    position: absolute;
    top: 4px;
    right: 6px;
}

#log {
    overflow: auto;
    position: absolute;
    left: 0;
    width: 100%;
}

#commandLine {
    position: absolute;
    bottom: 0;
    left: 0;
    width: 100%;
    height: 18px;
    border: none;
    border-top: 1px solid ThreeDShadow;
}

/************************************************************************************************/

.logRow {
    position: relative;
    border-bottom: 1px solid #D7D7D7;
    padding: 2px 4px 1px 6px;
    background-color: #FFFFFF;
}

.logRow-command {
    font-family: Monaco, monospace;
    color: blue;
}

.objectBox-null {
    padding: 0 2px;
    border: 1px solid #666666;
    background-color: #888888;
    color: #FFFFFF;
}

.objectBox-string {
    font-family: Monaco, monospace;
    color: red;
    white-space: pre;
}

.objectBox-number {
    color: #000088;
}

.objectBox-function {
    font-family: Monaco, monospace;
    color: DarkGreen;
}

.objectBox-object {
    color: DarkGreen;
    font-weight: bold;
}

/************************************************************************************************/

.logRow-info,
.logRow-error,
.logRow-warning {
    background: #FFFFFF no-repeat 2px 2px;
    padding-left: 20px;
    padding-bottom: 3px;
}

.logRow-info {
    background-image: url(infoIcon.png);
}

.logRow-warning {
    background-color: cyan;
    background-image: url(warningIcon.png);
}

.logRow-error {
    background-color: LightYellow;
    background-image: url(errorIcon.png);
}

.errorMessage {
    vertical-align: top;
    color: #FF0000;
}

.objectBox-sourceLink {
    position: absolute;
    right: 4px;
    top: 2px;
    padding-left: 8px;
    font-family: Lucida Grande, sans-serif;
    font-weight: bold;
    color: #0000FF;
}

/************************************************************************************************/

.logRow-group {
    background: #EEEEEE;
    border-bottom: none;
}

.logGroup {
    background: #EEEEEE;
}

.logGroupBox {
    margin-left: 24px;
    border-top: 1px solid #D7D7D7;
    border-left: 1px solid #D7D7D7;
}

/************************************************************************************************/

.selectorTag,
.selectorId,
.selectorClass {
    font-family: Monaco, monospace;
    font-weight: normal;
}

.selectorTag {
    color: #0000FF;
}

.selectorId {
    color: DarkBlue;
}

.selectorClass {
    color: red;
}

/************************************************************************************************/

.objectBox-element {
    font-family: Monaco, monospace;
    color: #000088;
}

.nodeChildren {
    margin-left: 16px;
}

.nodeTag {
    color: blue;
}

.nodeValue {
    color: #FF0000;
    font-weight: normal;
}

.nodeText,
.nodeComment {
    margin: 0 2px;
    vertical-align: top;
}

.nodeText {
    color: #333333;
}

.nodeComment {
    color: DarkGreen;
}

/************************************************************************************************/

.propertyNameCell {
    vertical-align: top;
}

.propertyName {
    font-weight: bold;
}

__firebug.html__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
         "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">

<head>
    <title>Firebug</title>
    <link rel="stylesheet" type="text/css" href="firebug.css">
</head>

<body>
    <div id="toolbar" class="toolbar">
        <a href="#" onclick="parent.console.clear()">Clear</a>
        <span class="toolbarRight">
            <a href="#" onclick="parent.console.close()">Close</a>
        </span>
    </div>
    <div id="log"></div>
    <input type="text" id="commandLine">
    
    <script>parent.onFirebugReady(document);</script>
</body>
</html>

__firebug.js__

if (!("console" in window) || !("firebug" in console)) {
(function()
{
    window.console = 
    {
        log: function()
        {
            logFormatted(arguments, "");
        },
        
        debug: function()
        {
            logFormatted(arguments, "debug");
        },
        
        info: function()
        {
            logFormatted(arguments, "info");
        },
        
        warn: function()
        {
            logFormatted(arguments, "warning");
        },
        
        error: function()
        {
            logFormatted(arguments, "error");
        },
        
        assert: function(truth, message)
        {
            if (!truth)
            {
                var args = [];
                for (var i = 1; i < arguments.length; ++i)
                    args.push(arguments[i]);
                
                logFormatted(args.length ? args : ["Assertion Failure"], "error");
                throw message ? message : "Assertion Failure";
            }
        },
        
        dir: function(object)
        {
            var html = [];
                        
            var pairs = [];
            for (var name in object)
            {
                try
                {
                    pairs.push([name, object[name]]);
                }
                catch (exc)
                {
                }
            }
            
            pairs.sort(function(a, b) { return a[0] < b[0] ? -1 : 1; });
            
            html.push('<table>');
            for (var i = 0; i < pairs.length; ++i)
            {
                var name = pairs[i][0], value = pairs[i][1];
                
                html.push('<tr>', 
                '<td class="propertyNameCell"><span class="propertyName">',
                    escapeHTML(name), '</span></td>', '<td><span class="propertyValue">');
                appendObject(value, html);
                html.push('</span></td></tr>');
            }
            html.push('</table>');
            
            logRow(html, "dir");
        },
        
        dirxml: function(node)
        {
            var html = [];
            
            appendNode(node, html);
            logRow(html, "dirxml");
        },
        
        group: function()
        {
            logRow(arguments, "group", pushGroup);
        },
        
        groupEnd: function()
        {
            logRow(arguments, "", popGroup);
        },
        
        time: function(name)
        {
            timeMap[name] = (new Date()).getTime();
        },
        
        timeEnd: function(name)
        {
            if (name in timeMap)
            {
                var delta = (new Date()).getTime() - timeMap[name];
                logFormatted([name+ ":", delta+"ms"]);
                delete timeMap[name];
            }
        },
        
        count: function()
        {
            this.warn(["count() not supported."]);
        },
        
        trace: function()
        {
            this.warn(["trace() not supported."]);
        },
        
        profile: function()
        {
            this.warn(["profile() not supported."]);
        },
        
        profileEnd: function()
        {
        },
        
        clear: function()
        {
            consoleBody.innerHTML = "";
        },

        open: function()
        {
            toggleConsole(true);
        },
        
        close: function()
        {
            if (frameVisible)
                toggleConsole();
        }
    };
 
    // ********************************************************************************************
       
    var consoleFrame = null;
    var consoleBody = null;
    var commandLine = null;
    
    var frameVisible = false;
    var messageQueue = [];
    var groupStack = [];
    var timeMap = {};
    
    var clPrefix = ">>> ";
    
    var isFirefox = navigator.userAgent.indexOf("Firefox") != -1;
    var isIE = navigator.userAgent.indexOf("MSIE") != -1;
    var isOpera = navigator.userAgent.indexOf("Opera") != -1;
    var isSafari = navigator.userAgent.indexOf("AppleWebKit") != -1;

    // ********************************************************************************************

    function toggleConsole(forceOpen)
    {
        frameVisible = forceOpen || !frameVisible;
        if (consoleFrame)
            consoleFrame.style.visibility = frameVisible ? "visible" : "hidden";
        else
            waitForBody();
    }

    function focusCommandLine()
    {
        toggleConsole(true);
        if (commandLine)
            commandLine.focus();
    }

    function waitForBody()
    {
        if (document.body)
            createFrame();
        else
            setTimeout(waitForBody, 200);
    }    

    function createFrame()
    {
        if (consoleFrame)
            return;
        
        window.onFirebugReady = function(doc)
        {
            window.onFirebugReady = null;

            var toolbar = doc.getElementById("toolbar");
            toolbar.onmousedown = onSplitterMouseDown;

            commandLine = doc.getElementById("commandLine");
            addEvent(commandLine, "keydown", onCommandLineKeyDown);

            addEvent(doc, isIE || isSafari ? "keydown" : "keypress", onKeyDown);
            
            consoleBody = doc.getElementById("log");
            layout();
            flush();
        }

        var baseURL = getFirebugURL();

        consoleFrame = document.createElement("iframe");
        consoleFrame.setAttribute("src", baseURL+"/firebug.html");
        consoleFrame.setAttribute("frameBorder", "0");
        consoleFrame.style.visibility = (frameVisible ? "visible" : "hidden");    
        consoleFrame.style.zIndex = "2147483647";
        consoleFrame.style.position = "fixed";
        consoleFrame.style.width = "100%";
        consoleFrame.style.left = "0";
        consoleFrame.style.bottom = "0";
        consoleFrame.style.height = "200px";
        document.body.appendChild(consoleFrame);
    }
    
    function getFirebugURL()
    {
        var scripts = document.getElementsByTagName("script");
        for (var i = 0; i < scripts.length; ++i)
        {
            if (scripts[i].src.indexOf("firebug.js") != -1)
            {
                var lastSlash = scripts[i].src.lastIndexOf("/");
                return scripts[i].src.substr(0, lastSlash);
            }
        }
    }
    
    function evalCommandLine()
    {
        var text = commandLine.value;
        commandLine.value = "";

        logRow([clPrefix, text], "command");
        
        var value;
        try
        {
            value = eval(text);
        }
        catch (exc)
        {
        }

        console.log(value);
    }
    
    function layout()
    {
        var toolbar = consoleBody.ownerDocument.getElementById("toolbar");
        var height = consoleFrame.offsetHeight - (toolbar.offsetHeight + commandLine.offsetHeight);
        consoleBody.style.top = toolbar.offsetHeight + "px";
        consoleBody.style.height = height + "px";
        
        commandLine.style.top = (consoleFrame.offsetHeight - commandLine.offsetHeight) + "px";
    }
    
    function logRow(message, className, handler)
    {
        if (consoleBody)
            writeMessage(message, className, handler);
        else
        {
            messageQueue.push([message, className, handler]);
            waitForBody();
        }
    }
    
    function flush()
    {
        var queue = messageQueue;
        messageQueue = [];
        
        for (var i = 0; i < queue.length; ++i)
            writeMessage(queue[i][0], queue[i][1], queue[i][2]);
    }

    function writeMessage(message, className, handler)
    {
        var isScrolledToBottom =
            consoleBody.scrollTop + consoleBody.offsetHeight >= consoleBody.scrollHeight;

        if (!handler)
            handler = writeRow;
        
        handler(message, className);
        
        if (isScrolledToBottom)
            consoleBody.scrollTop = consoleBody.scrollHeight - consoleBody.offsetHeight;
    }
    
    function appendRow(row)
    {
        var container = groupStack.length ? groupStack[groupStack.length-1] : consoleBody;
        container.appendChild(row);
    }

    function writeRow(message, className)
    {
        var row = consoleBody.ownerDocument.createElement("div");
        row.className = "logRow" + (className ? " logRow-"+className : "");
        row.innerHTML = message.join("");
        appendRow(row);
    }

    function pushGroup(message, className)
    {
        logFormatted(message, className);

        var groupRow = consoleBody.ownerDocument.createElement("div");
        groupRow.className = "logGroup";
        var groupRowBox = consoleBody.ownerDocument.createElement("div");
        groupRowBox.className = "logGroupBox";
        groupRow.appendChild(groupRowBox);
        appendRow(groupRowBox);
        groupStack.push(groupRowBox);
    }

    function popGroup()
    {
        groupStack.pop();
    }
    
    // ********************************************************************************************

    function logFormatted(objects, className)
    {
        var html = [];

        var format = objects[0];
        var objIndex = 0;

        if (typeof(format) != "string")
        {
            format = "";
            objIndex = -1;
        }

        var parts = parseFormat(format);
        for (var i = 0; i < parts.length; ++i)
        {
            var part = parts[i];
            if (part && typeof(part) == "object")
            {
                var object = objects[++objIndex];
                part.appender(object, html);
            }
            else
                appendText(part, html);
        }

        for (var i = objIndex+1; i < objects.length; ++i)
        {
            appendText(" ", html);
            
            var object = objects[i];
            if (typeof(object) == "string")
                appendText(object, html);
            else
                appendObject(object, html);
        }
        
        logRow(html, className);
    }

    function parseFormat(format)
    {
        var parts = [];

        var reg = /((^%|[^\\]%)(\d+)?(\.)([a-zA-Z]))|((^%|[^\\]%)([a-zA-Z]))/;    
        var appenderMap = {s: appendText, d: appendInteger, i: appendInteger, f: appendFloat};

        for (var m = reg.exec(format); m; m = reg.exec(format))
        {
            var type = m[8] ? m[8] : m[5];
            var appender = type in appenderMap ? appenderMap[type] : appendObject;
            var precision = m[3] ? parseInt(m[3]) : (m[4] == "." ? -1 : 0);

            parts.push(format.substr(0, m[0][0] == "%" ? m.index : m.index+1));
            parts.push({appender: appender, precision: precision});

            format = format.substr(m.index+m[0].length);
        }

        parts.push(format);

        return parts;
    }

    function escapeHTML(value)
    {
        function replaceChars(ch)
        {
            switch (ch)
            {
                case "<":
                    return "&lt;";
                case ">":
                    return "&gt;";
                case "&":
                    return "&amp;";
                case "'":
                    return "&#39;";
                case '"':
                    return "&quot;";
            }
            return "?";
        };
        return String(value).replace(/[<>&"']/g, replaceChars);
    }

    function objectToString(object)
    {
        try
        {
            return object+"";
        }
        catch (exc)
        {
            return null;
        }
    }

    // ********************************************************************************************

    function appendText(object, html)
    {
        html.push(escapeHTML(objectToString(object)));
    }

    function appendNull(object, html)
    {
        html.push('<span class="objectBox-null">', escapeHTML(objectToString(object)), '</span>');
    }

    function appendString(object, html)
    {
        html.push('<span class="objectBox-string">&quot;', escapeHTML(objectToString(object)),
            '&quot;</span>');
    }

    function appendInteger(object, html)
    {
        html.push('<span class="objectBox-number">', escapeHTML(objectToString(object)), '</span>');
    }

    function appendFloat(object, html)
    {
        html.push('<span class="objectBox-number">', escapeHTML(objectToString(object)), '</span>');
    }

    function appendFunction(object, html)
    {
        var reName = /function ?(.*?)\(/;
        var m = reName.exec(objectToString(object));
        var name = m ? m[1] : "function";
        html.push('<span class="objectBox-function">', escapeHTML(name), '()</span>');
    }
    
    function appendObject(object, html)
    {
        try
        {
            if (object == undefined)
                appendNull("undefined", html);
            else if (object == null)
                appendNull("null", html);
            else if (typeof object == "string")
                appendString(object, html);
            else if (typeof object == "number")
                appendInteger(object, html);
            else if (typeof object == "function")
                appendFunction(object, html);
            else if (object.nodeType == 1)
                appendSelector(object, html);
            else if (typeof object == "object")
                appendObjectFormatted(object, html);
            else
                appendText(object, html);
        }
        catch (exc)
        {
        }
    }
        
    function appendObjectFormatted(object, html)
    {
        var text = objectToString(object);
        var reObject = /\[object (.*?)\]/;

        var m = reObject.exec(text);
        html.push('<span class="objectBox-object">', m ? m[1] : text, '</span>')
    }
    
    function appendSelector(object, html)
    {
        html.push('<span class="objectBox-selector">');

        html.push('<span class="selectorTag">', escapeHTML(object.nodeName.toLowerCase()), '</span>');
        if (object.id)
            html.push('<span class="selectorId">#', escapeHTML(object.id), '</span>');
        if (object.className)
            html.push('<span class="selectorClass">.', escapeHTML(object.className), '</span>');

        html.push('</span>');
    }

    function appendNode(node, html)
    {
        if (node.nodeType == 1)
        {
            html.push(
                '<div class="objectBox-element">',
                    '&lt;<span class="nodeTag">', node.nodeName.toLowerCase(), '</span>');

            for (var i = 0; i < node.attributes.length; ++i)
            {
                var attr = node.attributes[i];
                if (!attr.specified)
                    continue;
                
                html.push('&nbsp;<span class="nodeName">', attr.nodeName.toLowerCase(),
                    '</span>=&quot;<span class="nodeValue">', escapeHTML(attr.nodeValue),
                    '</span>&quot;')
            }

            if (node.firstChild)
            {
                html.push('&gt;</div><div class="nodeChildren">');

                for (var child = node.firstChild; child; child = child.nextSibling)
                    appendNode(child, html);
                    
                html.push('</div><div class="objectBox-element">&lt;/<span class="nodeTag">', 
                    node.nodeName.toLowerCase(), '&gt;</span></div>');
            }
            else
                html.push('/&gt;</div>');
        }
        else if (node.nodeType == 3)
        {
            html.push('<div class="nodeText">', escapeHTML(node.nodeValue),
                '</div>');
        }
    }

    // ********************************************************************************************
    
    function addEvent(object, name, handler)
    {
        if (document.all)
            object.attachEvent("on"+name, handler);
        else
            object.addEventListener(name, handler, false);
    }
    
    function removeEvent(object, name, handler)
    {
        if (document.all)
            object.detachEvent("on"+name, handler);
        else
            object.removeEventListener(name, handler, false);
    }
    
    function cancelEvent(event)
    {
        if (document.all)
            event.cancelBubble = true;
        else
            event.stopPropagation();        
    }

    function onError(msg, href, lineNo)
    {
        var html = [];
        
        var lastSlash = href.lastIndexOf("/");
        var fileName = lastSlash == -1 ? href : href.substr(lastSlash+1);
        
        html.push(
            '<span class="errorMessage">', msg, '</span>', 
            '<div class="objectBox-sourceLink">', fileName, ' (line ', lineNo, ')</div>'
        );
        
        logRow(html, "error");
    };

    function onKeyDown(event)
    {
        if (event.keyCode == 123)
            toggleConsole();
        else if ((event.keyCode == 108 || event.keyCode == 76) && event.shiftKey
                 && (event.metaKey || event.ctrlKey))
            focusCommandLine();
        else
            return;
        
        cancelEvent(event);
    }

    function onSplitterMouseDown(event)
    {
        if (isSafari || isOpera)
            return;
        
        addEvent(document, "mousemove", onSplitterMouseMove);
        addEvent(document, "mouseup", onSplitterMouseUp);

        for (var i = 0; i < frames.length; ++i)
        {
            addEvent(frames[i].document, "mousemove", onSplitterMouseMove);
            addEvent(frames[i].document, "mouseup", onSplitterMouseUp);
        }
    }
    
    function onSplitterMouseMove(event)
    {
        var win = document.all
            ? event.srcElement.ownerDocument.parentWindow
            : event.target.ownerDocument.defaultView;

        var clientY = event.clientY;
        if (win != win.parent)
            clientY += win.frameElement ? win.frameElement.offsetTop : 0;
        
        var height = consoleFrame.offsetTop + consoleFrame.clientHeight;
        var y = height - clientY;
        
        consoleFrame.style.height = y + "px";
        layout();
    }
    
    function onSplitterMouseUp(event)
    {
        removeEvent(document, "mousemove", onSplitterMouseMove);
        removeEvent(document, "mouseup", onSplitterMouseUp);

        for (var i = 0; i < frames.length; ++i)
        {
            removeEvent(frames[i].document, "mousemove", onSplitterMouseMove);
            removeEvent(frames[i].document, "mouseup", onSplitterMouseUp);
        }
    }
    
    function onCommandLineKeyDown(event)
    {
        if (event.keyCode == 13)
            evalCommandLine();
        else if (event.keyCode == 27)
            commandLine.value = "";
    }
    
    window.onerror = onError;
    addEvent(document, isIE || isSafari ? "keydown" : "keypress", onKeyDown);
    
    if (document.documentElement.getAttribute("debug") == "true")
        toggleConsole(true);
})();
}

__firebugx.js__

if (!("console" in window) || !("firebug" in console))
{
    var names = ["log", "debug", "info", "warn", "error", "assert", "dir", "dirxml",
    "group", "groupEnd", "time", "timeEnd", "count", "trace", "profile", "profileEnd"];

    window.console = {};
    for (var i = 0; i < names.length; ++i)
        window.console[names[i]] = function() {}
}
__infoIcon.png__
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABGdBTUEAANbY1E9YMgAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAGeSURBVHjajFJNKERRFP7efc+YMTNhpIaFmmRkZeFna0E2pGjULK1GykYUZaukxGIWkgVlg41SFiKllLKwIgthITUbmfE3P557nfNmHm8k+eq755zb+c6577yjKaVgo7RpXicTI/YRqwvXt8T17OXEDhzQbCGJhihcld5mSHc9lCjLJ5gpiPQFROZ6m8IlKrD/JSTRqDIq4mZFD5SrBpV+YHksX3l4EXh8BgmvYCT3AJnpJPGhIFEAmh43A/2WiNHSAAx25Mk+Q7obYJZ3szvCh8HOh68Nyqj6ev/BGTC18u3bkJ4wZLo+Qs36BMUR6Q47vxuTUepEV10teeuE9DSyiXDHkNLL8RP8TEalr/he6X42dQK/YG4Df8CS6HwmNPmK/0L7sHITLNwVmZt/C0XWyt1l4ZL+ckKVnoqGYyPW6+iWu4N4Oz+i/7hmL8CUctXOvgcGqKTbmqRzKPxLNDMJ42GLG0RJuOlcuRklvNPS1wrpCkKVBGmE7xC5BHW6h/56xvE4iRaKdrUgDhU2o50XiJgmnhKPC3uasnM/BRgAWJKYVu7pMGEAAAAASUVORK5CYII=
__warningIcon.png__
iVBORw0KGgoAAAANSUhEUgAAAA4AAAAOCAYAAAAfSC3RAAAABGdBTUEAANbY1E9YMgAAABl0RVh0U29mdHdhcmUAQWRvYmUgSW1hZ2VSZWFkeXHJZTwAAAGWSURBVHjaYvz//z8DDKzu5mEGUmlA7AfEolDh+0C8OLT0yyYGJMAI0wjUlMDIyDBfSf83g5TKXwZ2Loj41w9MDA+vsTA8u8O8HsidDjRgN1gCpHFVF3fOttmc/98+YwJx/585w/C/o4Ph/927YGkwfnKL+f+GSVz/gWqdwJYBGUJrern/f3zDBFfk4sIAsg6sGSYGwo9vsIA0rgZxmIAKMtVNfzPwCf9jIARk1P+AvBEC9JYfSGMISIBYIKMGVhsC0qjIzf8fRdLYGEIrKWFq5OIDq5VjwmaqoCAqjRINjGCKGaTxxY+vjAz4DEAGULUvWIDE1uf3mNV5hRCBk5aG6mRkAFQLoraCbJx+7Rgrw7dPCFtXr2Zg2LOHgeHsWVRNrx8zMzy4wnIQmAgWMAGJO79/Mlae2MzB8OsHRDNIEwzDwJf3TAyntrGDmNPRk1wLB/f/ajWT3wxMXP8Y7j35x+Bgx8Dw7gUTw5snzAx3zrMw/PnFWAy0qA9FI1SzIihBALEZyItA/B2ITwHxEWg6/QhTCxBgAB4kvHiHyye8AAAAAElFTkSuQmCC
