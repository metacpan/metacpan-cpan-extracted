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
         * override the regular tr with this magic version which is able to
         * data coming in from the backend. This is for backward compatibility
         * better use the xtr call as this will not trigger the translation
         * string extraction
         */
        tr: function() {
            return this.xtr.apply(this,arguments);
        },
        /**
         * Translate incoming data. Do NOT mark the string for translation
         * use the tr function for this. xtr is meant for backend strings.
         * 
         * @param {String|Array|qx.data.Array} messageId 
         */
        xtr: function(messageId,varargs) {
            var nlsManager = qx.locale.Manager;
            if (messageId == ''){
                return '';
            }
            if (messageId instanceof Array) {
                return nlsManager.tr.apply(nlsManager, messageId);
            }
            if (messageId instanceof qx.data.Array) {
                return nlsManager.tr.apply(nlsManager, messageId.toArray());
            }
            return nlsManager.tr.apply(nlsManager, arguments);
        }
    }
});
