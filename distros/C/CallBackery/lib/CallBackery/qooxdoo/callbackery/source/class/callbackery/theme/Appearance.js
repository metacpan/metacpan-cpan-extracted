/* ************************************************************************

   Copyright:

   License:

   Authors:

************************************************************************ */

qx.Theme.define("callbackery.theme.Appearance", {
  extend : qx.theme.indigo.Appearance,

  appearances: {
    "textfield": {
        base: true,
        style: function(states){
            if (states.readonly){
                return {
                    decorator: null,
                    backgroundColor: 'textfield-readonly'
                }
            }
            return {};
        }
    },
    "tabview/pane" :    {
      base: true,
      style : function(states)
      {
        return {
          backgroundColor : "tabview-page-background",
          decorator : "tabview-page",
          padding : 20
        };
      }
    },

    "tabview-page/button" : {
      base: true,
      style : function(states)
      {
        var decorator;
        if (states.barTop) {
            decorator = states.checked ? "tabview-page-button-top-checked" : "tabview-page-button-top";
        }
        return {
          decorator : decorator,
          textColor : states.checked ? "tabview-button-checked-text": "tabview-button-text",
          backgroundColor: states.checked ? "tabview-button-checked-background" : "tabview-button-background"
        };
      }
    },
    "toolbar" :
    {
      base: true,
      style : function(states)
      {
        return {
          backgroundColor : null,
          padding : [0, 0,4,0]
        };
      }
    }
  }
});