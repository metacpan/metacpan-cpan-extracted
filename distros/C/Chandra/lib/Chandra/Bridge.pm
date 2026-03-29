package Chandra::Bridge;

use strict;
use warnings;

our $VERSION = '0.02';

# JavaScript bridge code that gets injected into every page
# This provides the window.chandra object for JS -> Perl communication

use constant JS_BRIDGE => <<'END_EOF';
(function() {
    if (window.chandra) return;
    
    window.chandra = {
        _callbacks: {},
        _id: 0,
        
        invoke: function(method, args) {
            var self = this;
            return new Promise(function(resolve, reject) {
                var id = ++self._id;
                self._callbacks[id] = { resolve: resolve, reject: reject };
                window.external.invoke(JSON.stringify({
                    type: 'call',
                    id: id,
                    method: method,
                    args: args || []
                }));
            });
        },
        
        call: function(method) {
            var args = Array.prototype.slice.call(arguments, 1);
            return this.invoke(method, args);
        },
        
        _resolve: function(id, result, error) {
            var cb = this._callbacks[id];
            if (!cb) return;
            delete this._callbacks[id];
            if (error) {
                cb.reject(new Error(error));
            } else {
                cb.resolve(result);
            }
        },
        
        _event: function(handlerId, eventData) {
            window.external.invoke(JSON.stringify({
                type: 'event',
                handler: handlerId,
                event: eventData || {}
            }));
        },
        
        _eventData: function(e, extra) {
            var data = {
                type: e.type,
                targetId: e.target ? e.target.id : null,
                targetName: e.target ? e.target.name : null,
                value: e.target ? e.target.value : null,
                checked: e.target ? e.target.checked : null,
                key: e.key || null,
                keyCode: e.keyCode || null
            };
            if (extra) {
                for (var k in extra) {
                    data[k] = extra[k];
                }
            }
            return data;
        }
    };
})();
END_EOF

# Return the bridge code
sub js_code {
    return JS_BRIDGE;
}

# Return bridge code wrapped for eval
sub js_code_escaped {
    my $code = JS_BRIDGE;
    $code =~ s/\\/\\\\/g;
    $code =~ s/'/\\'/g;
    $code =~ s/\n/\\n/g;
    return $code;
}

1;

__END__

=head1 NAME

Chandra::Bridge - JavaScript bridge code for Perl communication

=head1 SYNOPSIS

    use Chandra::Bridge;
    
    # Get the JS code to inject
    my $js = Chandra::Bridge->js_code;
    
    # Inject into webview
    $app->eval_js($js);

=head1 DESCRIPTION

This module contains the JavaScript bridge code that enables
communication between JavaScript and Perl via window.chandra.

=head2 JavaScript API

After injection, the following is available in JavaScript:

    // Call a Perl function (returns Promise)
    const result = await window.chandra.invoke('method_name', [arg1, arg2]);
    
    // Shorthand
    const result = await window.chandra.call('method_name', arg1, arg2);

=cut
