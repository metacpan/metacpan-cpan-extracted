/* ************************************************************************

   qooxdoo - the new era of web development

   http://qooxdoo.org

   Copyright:
     2007 Visionet GmbH, http://www.visionet.de

   License:
     LGPL: http://www.gnu.org/licenses/lgpl.html
     EPL: http://www.eclipse.org/org/documents/epl-v10.php
     See the LICENSE file in the project's top-level directory for details.

   Authors:
     * Dietrich Streifert (level420)
   
   Contributors:
     * Petr Kobalicek (e666e)
     * Tobi Oetiker (oetiker)

************************************************************************ */

/*
  The 'change' event on the input field requires that this handler be available:
*/

/**
 * @use(qx.event.handler.Input)
 */



/**
 * An upload button to use in a toolbar. Like a normal 
 * {@link callbackery.ui.form.UploadButton}
 * but with a style matching the toolbar and without keyboard support.
 *
 * After qx.ui.form.Button <> qx.ui.toolbar.Button
 */
qx.Class.define("callbackery.ui.form.UploadToolbarButton",
{
  extend : callbackery.ui.form.UploadButton,

  // --------------------------------------------------------------------------
  // [Constructor]
  // --------------------------------------------------------------------------

  /**
   * @param label {String} button label
   * @param icon {String} icon path
   * @param command {Command} command instance to connect with
   */

  construct: function(label, icon, command)
  {
    this.base(arguments,label, icon, command);

    // Toolbar buttons should not support the keyboard events
    this.removeListener("keydown", this._onKeyDown);
    this.removeListener("keyup", this._onKeyUp);
  },

  // --------------------------------------------------------------------------
  // [Properties]
  // --------------------------------------------------------------------------

   properties:
   {
    appearance :
    {
      refine : true,
      init : "toolbar-button"
    },

    show :
    {
      refine : true,
      init : "inherit"
    },

    focusable :
    {
      refine : true,
      init : false
    }
   }, 
  
  // --------------------------------------------------------------------------
  // [Members]
  // --------------------------------------------------------------------------

  members :
  {
    // overridden
    _applyVisibility : function(value, old) {
      this.base(arguments, value, old);
      // trigger a appearance recalculation of the parent
      var parent = this.getLayoutParent();
      if (parent && parent instanceof qx.ui.toolbar.PartContainer) {
        qx.ui.core.queue.Appearance.add(parent);
      }
    }
  }

});
