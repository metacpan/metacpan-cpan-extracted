/* ************************************************************************
   Copyright: 2013 OETIKER+PARTNER AG
   License:   GPLv3 or later
   Authors:   Tobi Oetiker <tobi@oetiker.ch>
   Utf8Check: äöü
************************************************************************ */

/**
 * A special renderer for AutoForms which includes notes below the section header
 * widget and next to the individual form widgets.
 */
qx.Class.define("callbackery.ui.form.renderer.NoteForm", {
    extend : qx.ui.form.renderer.Single,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embed
     */
    construct: function(form) {
        this._gotNote = false;
        this.base(arguments,form);
        var fl = this._getLayout();
        // have plenty of space for input, not for the labels
        fl.setColumnFlex(0, 0);
        fl.setColumnAlign(0, "left", "top");
        fl.setColumnFlex(1, 4);
        fl.setColumnMinWidth(1, 130);
        fl.setColumnFlex(2, this._gotNote ? 1 : 0);
        fl.setColumnMaxWidth(2,250);
        fl.setSpacingY(0);
    },

    members: {
        _gotNote: null,
        addItems: function(items,names,title,itemOptions,headerOptions){
            // add the header
            if (title != null) {
                if (headerOptions && headerOptions.widget){
                    this._add(
                        headerOptions.widget.set({
                            value: title,
                            paddingTop: this._row == 0 ? 0 :10
                        }),{
                            row: this._row++, 
                            column: 0, 
                            colSpan: 3
                        }
                    );
                }
                else {
                    this._add(
                        this._createHeader(title), {
                            row: this._row++,
                            column: 0,
                            colSpan: 3
                        }
                    );
                }
                this._row++;
                if (headerOptions 
                    && headerOptions.note){
                    var note = new qx.ui.basic.Label(
                        headerOptions.note).set({
                        rich: true,
                        alignX: 'left',
                        paddingBottom: 12,
                        paddingRight: 10
                    });
                    this._add(note,{ 
                        row: this._row++,
                        column: 0,
                        colSpan: 3
                    });
                    if (headerOptions.widget) {
                        this._connectVisibility(
                            headerOptions.widget,note);
                    }
                }
            }

            // add the items
            var msg = callbackery.ui.MsgBox.getInstance();
            var that = this;
            for (var i = 0; i < items.length; i++) { (function(){ // context
                var label = that._createLabel(names[i], items[i]);
                var item = items[i];
                item.set({
                    marginTop: 2,
                    marginBottom: 2
                });
                var labelName = names[i];
                // allow form items without label
                if (label) {
                    label.set({
                        marginTop: 2,
                        marginBottom: 2
                    });
                    label.setBuddy(item);
                    that._add(label, {row: that._row, column: 0});
                }
                that._add(item, {row: that._row, column: 1});
                if (itemOptions != null && itemOptions[i] != null) {
                    if ( itemOptions[i].note ){
                        that._gotNote = true;
                        var note = new qx.ui.basic.Label(
                            itemOptions[i].note).set({
                            rich: true,
                            paddingLeft: 20,
                            paddingRight: 20
                        });
                        that._add(note,{
                            row: that._row,
                            column: 2
                        });
                        that._connectVisibility(item, note);
                    }
                }
                if ( itemOptions[i].copyOnTap
                        && item.getReadOnly()){
                    var copyFailMsg = itemOptions[i].copyFailMsg
                        ? that.xtr(itemOptions[i].copyFailMsg)
                        : that.tr("Select %1 and press [ctrl]+[c]",labelName);
                    var copySuccessMsg = itemOptions[i].copySuccessMsg
                        ? that.xtr(itemOptions[i].copySuccessMsg)
                        : that.tr("%1 copied",labelName);

                    item.addListener('tap',function(e){
                        try {
                            navigator.clipboard.writeText(item.getValue())
                            .then(function(ret){ 
                                msg.info(that.tr("Success"),copySuccessMsg);
                            })
                            .catch(function(err){ 
                                msg.info(that.tr("Copy failed"),copyFailMsg);
                            })
                        } catch (err) {
                            msg.info(that.tr("Copy failed"),copyFailMsg);
                        }
                    });
                }
                that._row++;
                that._connectVisibility(item, label);
                
                // store the names for translation
                if (qx.core.Environment.get("qx.dynlocale")) {
                    that._names.push({
                        name: names[i], label: label, item: items[i]
                    });
                }
            })(); } // end context
        }
    }
});
