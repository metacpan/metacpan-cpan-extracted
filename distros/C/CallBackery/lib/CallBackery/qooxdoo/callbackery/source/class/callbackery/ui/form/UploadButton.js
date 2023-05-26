var idCntr=0;
qx.Class.define("callbackery.ui.form.UploadButton", {
    // https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/file
    extend : qx.ui.form.Button,
    events: {
        changeFileSelection: "qx.event.type.Data"
    },
    properties: {
      accept: {
        nullable: true,
        apply : "_applyAttribute"
      },
      multiple: {
        nullable: true,
        apply : "_applyAttribute"
      },
      webkitdirectory: {
        nullable: true,
        apply : "_applyAttribute"
      }
    },
    members: {
      __inputObject: null,
      _applyAttribute: function(value,old,attr){
        this.__inputObject.setAttribute(attr,value);
      },
      _createContentElement: function() {
        var id = 'uploadId_'+(idCntr++);
        var input = this.__inputObject 
          = new qx.html.Input("file",{display: 'none'},{id: id});
        var label = new qx.html.Element("label",{},{'for': id});
        label.addListenerOnce('appear',function(e){
          label.add(input);
          qx.html.Element.flush();
          var inputEl = input.getDomElement();
          var that = this;
          inputEl.addEventListener('change',function(e){
            that.fireDataEvent('changeFileSelection',inputEl.files);
            inputEl.value = "";
          });
        },this);
        return label;
      }
    }
  });

  