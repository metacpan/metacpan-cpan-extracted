/* ************************************************************************

   Copyrigtht: OETIKER+PARTNER AG
   License:    GPL V3 or later
   Authors:    Tobias Oetiker, Fritz Zaucker
   Utf8Check:  äöü

************************************************************************ */

/**
 * A window to display HTML with JavaScript enabled.

 * <pre code='javascript'>
 * var box = new callbackery.ui.HtmlBox(content);
 * </pre>
 */
qx.Class.define("callbackery.ui.HtmlBox", {
    extend : qx.ui.window.Window,

    construct : function(content) {
        this.base(arguments);
        this.set({
            modal:                   true,
            showMinimize:            false,
            showMaximize:            false,
            resizable:               true,
            contentPaddingLeft:      30,
            contentPaddingRight:     30,
            contentPaddingTop:       20,
            contentPaddingBottom:    20,
            height:                  700,
            width:                   800,
            layout:                  new qx.ui.layout.VBox(10),
            centerOnAppear:          true,
            centerOnContainerResize: true
        });
        this.getChildControl('captionbar').exclude();

        var html = new qx.ui.embed.Html(content).set({
            overflowX:         "hidden",
            overflowY:         "auto",
            nativeContextMenu: true
        });
        html.addListenerOnce('appear', function() {
            var h = html.getContentElement().getDomElement();
            qx.lang.Array.fromCollection(h.getElementsByTagName("script")).forEach(function(el) {
                var s = document.createElement('script');
                s.type = 'text/javascript';
                var parent = el.parentNode;
                var code = parent.removeChild(el).innerHTML;
                try {
                    s.appendChild(document.createTextNode(code));
                    parent.appendChild(s);
                }
                catch (e) {
                    s.text = code;
                    parent.appendChild(s);
                }
            });
        });
        this.add(html, {flex: 1});

        var closeBtn = new qx.ui.form.Button(this.tr('Close')).set({
            alignX:     'right',
            allowGrowX: false
        });
        this.add(closeBtn);
        closeBtn.addListener('execute', function() {
            this.close();
        }, this);
        this.addListener('close', function() {
            this.dispose();
        }, this);
    }
});
