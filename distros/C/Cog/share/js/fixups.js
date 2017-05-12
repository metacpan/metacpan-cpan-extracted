if (typeof console == 'undefined') console = {};
if (typeof console.log == 'undefined') console.log =
(function(called) {
    return function() {
        if (called) return;
        var msg = "console.log called:\n" +
            Array.prototype.join.call(arguments,"\n");
        called = ! confirm(msg);
    };
})(false);
