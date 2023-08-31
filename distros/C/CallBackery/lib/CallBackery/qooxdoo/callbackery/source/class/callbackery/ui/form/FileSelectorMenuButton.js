/* ************************************************************************

   After Qooxdoo FileSelectorMenuButton
   Copyright:
     2023 Oetiker+Partner AG

   License:
     LGPL: http://www.gnu.org/licenses/lgpl.html
     See the LICENSE file in the project's top-level directory for details.

   Authors:
     * Tobias Oetiker
 
************************************************************************ */

qx.Class.define("callbackery.ui.form.FileSelectorMenuButton", {
    extend: qx.ui.menu.Button,
    statics: {
        _fileInputElementIdCounter: 0
    },
    properties: {
        /**
         * What type of files should be offered in the fileselection dialog.
         * Use a comma separated list of [Unique file type specifiers](https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file#unique_file_type_specifiers). If you dont set anything, all files
         * are allowed.
         *
         * *Example*
         *
         * `.doc,.docx,application/msword`
         */
        accept: {
            nullable: true,
            check: "String",
            apply: "_applyAttribute"
        },

        /**
         * Specify that the camera should be used for getting the "file". The
         * value defines which camera should be used for capturing images.
         * `user` indicates the user-facing camera.
         * `environment` indicates the camera facing away from the user.
         */
        capture: {
            nullable: true,
            check: ["user", "environment"],
            apply: "_applyAttribute"
        },

        /**
         * Set to "true" if you want to allow the selection of multiple files.
         */
        multiple: {
            nullable: true,
            check: "Boolean",
            apply: "_applyAttribute"
        },

        /**
         * If present, indicates that only directories should be available for
         * selection.
         */
        directoriesOnly: {
            nullable: true,
            check: "Boolean",
            apply: "_applyAttribute"
        }
    },

    members: {
        __inputObjec: null,
        _applyAttribute(value, old, attr) {
            if (attr === "directoriesOnly") {
                // while the name of the attribute indicates that this only
                // works for webkit browsers, this is not the case. These
                // days the attribute is supported by
                // [everyone](https://caniuse.com/?search=webkitdirectory).
                attr = "webkitdirectory";
            }
            this.__inputObject.setAttribute(attr, value);
        },
        setEnabled(value) {
            this.__inputObject.setEnabled(value);
            super.setEnabled(value);
        },
        _createContentElement() {
            let id = "qxMenuFileSelector_" + (++callbackery.ui.form.FileSelectorMenuButton._fileInputElementIdCounter);
            let input = (this.__inputObject = new qx.html.Input(
                "file",
                null,
                { id: id }
            ));

            let label = new qx.html.Element("label", {}, { for: id });
            label.addListenerOnce("appear", e => {
                label.add(input);
            });

            input.addListenerOnce("appear", e => {
                let inputEl = input.getDomElement();
                // since qx.html.Node does not even create the
                // domNode if it is not set to visible initially
                // we have to quickly hide it after creation.
                input.setVisible(false);
                inputEl.addEventListener("change", e => {
                    this.fireDataEvent("changeFileSelection", inputEl.files);
                    inputEl.value = "";
                });
            });
            return label;
        }
    }
});
