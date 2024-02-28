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
    extend: qx.ui.form.renderer.Single,
    /**
     * create a page for the View Tab with the given title
     *
     * @param vizWidget {Widget} visualization widget to embed
     */
    construct: function (form) {
        this._gotNote = false;
        this._mobileMode;
        this._reflowQueue = [];
        this.base(arguments, form);
        var fl = this._getLayout();
        // have plenty of space for input, not for the labels
        fl.setColumnFlex(0, 0);
        fl.setColumnAlign(0, "left", "top");
        fl.setColumnFlex(1, 4);
        fl.setColumnMinWidth(1, 130);
        fl.setColumnFlex(2, this._gotNote ? 1 : 0);
        fl.setColumnMaxWidth(2, 250);
        fl.setSpacingY(0);
        this.addListener('resize', (e) => {
            this._updateForm(e.getData().width);
        });
    },
    events: {
        'reflowForm': 'qx.event.type.Event'
    },
    members: {
        _gotNote: null,
        _reflowQueue: null,
        _updateForm(width) {
            let update = true;
            if (width < 400) {
                if (this._mobileMode === true) {
                    update = false;
                }
                else {
                    this._mobileMode = true;
                }
            } else {
                if (this._mobileMode === false) {
                    update = false;
                }
                else {
                    this._mobileMode = false;
                }
            }
            if (update) {
                this._reflowQueue.forEach((element) => {
                    element();
                });
            }
        },
        addItems(items, names, title, itemOptions, headerOptions) {
            // add the header
            let rfq = this._reflowQueue;
            if (title != null) {
                let widget = null;
                if (headerOptions && headerOptions.widget) {
                    widget = headerOptions.widget.set({
                        value: title,
                        paddingTop: this._row == 0 ? 0 : 10
                    });

                }
                else {
                    widget = this._createHeader(title);
                }
                let row = this._row;
                rfq.push(() => {
                    if (this._mobileMode) {
                        this._add(
                            widget, {
                            row: row,
                            column: 1,
                            colSpan: 2
                        });
                    }
                    else {
                        this._add(
                            widget, {
                            row: row,
                            column: 0,
                            colSpan: 3
                        });
                    }
                });
                this._row++;
                if (headerOptions
                    && headerOptions.note) {
                    let note = new qx.ui.basic.Label(
                        headerOptions.note).set({
                            rich: true,
                            alignX: 'left',
                            paddingBottom: 12,
                            paddingRight: 10
                        });
                    let row = this._row;
                    rfq.push(() => {
                        if (this._mobileMode) {
                            this._add(
                                note, {
                                row: row,
                                column: 1,
                                colSpan: 2
                            }
                            );
                        }
                        else {
                            this._add(
                                note, {
                                row: row,
                                column: 0,
                                colSpan: 3
                            }
                            );
                        }
                    });
                    this._row++;
                    if (headerOptions.widget) {
                        this._connectVisibility(
                            headerOptions.widget, note);
                    }
                }
            }

            // add the items
            var msg = callbackery.ui.MsgBox.getInstance();
            var that = this;
            for (let i = 0; i < items.length; i++) {
                (function () { // context
                    let label = that._createLabel(names[i], items[i]);
                    let item = items[i];
                    item.set({
                        marginTop: 2,
                        marginBottom: 2
                    });
                    let labelName = names[i];

                    // rerender form to update required flag
                    item.addListener("changeRequired", (e) => {
                        that._onChangeLocale(e);
                    }, that);

                    // allow form items without label
                    if (label) {

                        label.setBuddy(item);
                        let row = that._row;
                        rfq.push(() => {
                            let newLabel = label.getValue().replace(/\s*:\s*$/, '');
                            if (that._mobileMode) {
                                label.set({
                                    value: newLabel,
                                    marginTop: 2,
                                    marginBottom: 0,
                                    paddingBottom: 0,
                                    font: 'small',
                                });
                                that._add(label, {
                                    row: row,
                                    column: 1,
                                });
                            }
                            else {
                                label.set({
                                    value: newLabel + ':',
                                    marginTop: 2,
                                    marginBottom: 2,
                                    font: 'default',
                                });
                                that._add(label, {
                                    row: row + 1,
                                    column: 0,
                                });
                            }
                        });
                    }
                    that._add(item, { row: that._row + 1, column: 1 });

                    if (itemOptions != null && itemOptions[i] != null) {
                        if (itemOptions[i].note) {
                            that._gotNote = true;
                            var note = new qx.ui.basic.Label(
                                itemOptions[i].note).set({
                                    rich: true,
                                    paddingLeft: 20,
                                    paddingRight: 20
                                });
                            that._add(note, {
                                row: that._row + 1,
                                column: 2
                            });
                            that._connectVisibility(item, note);
                        }
                    }
                    if (itemOptions[i].copyOnTap
                        && item.getReadOnly()) {
                        var copyFailMsg = itemOptions[i].copyFailMsg
                            ? that.xtr(itemOptions[i].copyFailMsg)
                            : that.tr("Select %1 and press [ctrl]+[c]", labelName);
                        var copySuccessMsg = itemOptions[i].copySuccessMsg
                            ? that.xtr(itemOptions[i].copySuccessMsg)
                            : that.tr("%1 copied", labelName);

                        item.addListener('tap', function (e) {
                            try {
                                navigator.clipboard.writeText(item.getValue())
                                    .then(function (ret) {
                                        msg.info(that.tr("Success"), copySuccessMsg);
                                    })
                                    .catch(function (err) {
                                        msg.info(that.tr("Copy failed"), copyFailMsg);
                                    })
                            } catch (err) {
                                msg.info(that.tr("Copy failed"), copyFailMsg);
                            }
                        });
                    }
                    that._row += 2;
                    that._connectVisibility(item, label);

                    // store the names for translation
                    if (qx.core.Environment.get("qx.dynlocale")) {
                        that._names.push({
                            name: names[i], label: label, item: items[i]
                        });
                    }
                })();
            } // end context
            let bounds = this.getBounds();
            if (bounds) {
                this._updateForm(bounds.width);
            }
        }
    }
});
