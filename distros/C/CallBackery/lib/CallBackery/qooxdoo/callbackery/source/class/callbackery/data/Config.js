/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL V3 or later
   Authors:    Tobias Oetiker
   Utf8Check:  äöü

************************************************************************ */
/**
 * This object holds the global configuration for the web frontend.
 * it gets read at application startup
 */

qx.Class.define('callbackery.data.Config', {
    extend : qx.core.Object,
    type : 'singleton',

    properties : {
        /**
         * the FRONTEND config from the master config file.
         */
        baseConfig : {
            nullable : true,
            event : 'changeBaseConfig'
        },
        userConfig : {
            nullable : true,
            event : 'changeUserConfig',
            apply: '_applyUserConfig'
        }
    },
    members: {
        /* get access to the parameters specified after # in the url */
        getUrlConfig: function(){
            var ha = {};
            var base = window.location.hash.match(/^#(.+)/);
            if (base){
                base[1].split(/;/).forEach(function(kv){
                    var list = kv.split('=');
                    ha[list[0]] = decodeURIComponent(list[1]);
                });
            }
            return ha;
        },
        /* if there is a sessonCookie in the userConfig start using it. This allows for seemless login */
        _applyUserConfig: function(newData,oldData) {
            if (newData.userInfo.sessionCookie) {
                callbackery.data.Server.getInstance().setSessionCookie(newData.userInfo.sessionCookie);
            }
        }

    }
});
