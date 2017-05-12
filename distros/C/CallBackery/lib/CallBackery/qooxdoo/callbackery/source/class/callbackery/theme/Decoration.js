/* ************************************************************************

   Copyright:

   License:

   Authors:

************************************************************************ */

qx.Theme.define("callbackery.theme.Decoration", {
  extend : qx.theme.indigo.Decoration,

  decorations :
  {
    "tabview-page-button-top" :
    {
      style :
      {
        width : [1, 1, 1, 1],
        color : "tabview-button-border",
        colorBottom: "tabview-button-checked-border",
        radius : [3, 3, 0, 0]
      }
    },
    "tabview-page-button-top-checked" :
    {
      include: "tabview-page-button-top",
      style :
      {
        width : [1, 1, 0, 1],
        color : "tabview-button-checked-border"
      }
    },
    "tabview-page": {
        include: "main",
        style : {
            color: "tabview-page-border"
        }
    }
  }
});