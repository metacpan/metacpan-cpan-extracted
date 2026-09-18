/* *************************************************
   Copyright: 2019 OETIKER+PARTNER AG
   License: GNU GPL 3
   Authors: Tobias Oetiker <tobi@oetiker.ch>
************************************************** */

/**
 * Translation helper which can process backend translatable objects
 */

qx.Mixin.define("callbackery.locale.MTranslation", {

    members: {
        /**
         * override the regular tr with this magic version which is able to handle
         * data coming in from the backend. This is for backward compatibility.
         * Better use the xtr call as this will not trigger the translation
         * string extraction.
         */
        tr: function() {
            return this.xtr.apply(this,arguments);
        },
        /**
         * Translate incoming data. Do NOT mark the string for translation
         * use the tr function for this. xtr is meant for backend strings.
         */
        xtr: function(messageId,varargs) {
            var nlsManager = qx.locale.Manager;
            if (messageId == ''){
                return '';
            }
            if (messageId instanceof Array) {
                return nlsManager.tr.apply(nlsManager, this._xtrArgs(messageId));
            }
            if (messageId instanceof qx.data.Array) {
                return nlsManager.tr.apply(
                    nlsManager, this._xtrArgs(messageId.toArray()));
            }
            return nlsManager.tr.apply(nlsManager, arguments);
        },

        /**
         * Resolve a backend message's arguments before it is substituted.
         *
         * An argument that is an array is a trm() of its own -- a message
         * built from a fixed part and some optional ones, which is what any
         * message with a warning or a code appended to it looks like. Each
         * piece is translated in its own right, then substituted as text.
         *
         * @param msg {Array} [msgid, arg, ...] as the backend sent it
         * @return {Array} the same, with nested messages rendered to text
         */
        _xtrArgs: function(msg) {
            if (msg.length < 2) {
                return msg;
            }
            return msg.map(function(part, i) {
                return i > 0 && part instanceof Array
                    ? String(this.xtr(part)) : part;
            }, this);
        }
    }
});
