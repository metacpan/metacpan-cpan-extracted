/**
 * Untabable TextField as SearchField for VirtualSelectBox
 */

qx.Class.define("callbackery.ui.form.SearchField",
{
  extend : qx.ui.form.TextField,

  construct : function(value)
  {
    this.base(arguments, value);
  },
  members :
  {
    isTabable: function() {
      return false;
    }
  }
    
});
