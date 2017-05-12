// depends: keyMap.js

GvaScript.CustomButtons = {};

GvaScript.CustomButtons.Button = Class.create();
// Renders Buttons in the following HTML structure
// <span class="gva-btn-container">
//         <span class="left"/>
//         <span class="center">
//                 <button class="btn" style="width: auto;" id="btn_1227001526005">
//                         Créer
//                 </button>
//         </span>
//         <span class="right"/>
// </span>
Object.extend(GvaScript.CustomButtons.Button.prototype, function() {
    var bcss = CSSPREFIX();

    function _extendCss(button_options) {
        // basic class
        var button_css = bcss+'-btn-container';

        // extended classes
        switch (typeof button_options.css) {
            case 'object': button_css += (' ' + button_options.css.join(' ')); break;
            case 'string': button_css += (' ' + button_options.css); break;
            default: break;
        }
        button_options.button_css = button_css;
    }
    var _button_template = new Template(
          '<span class="#{button_css}" id="#{id}">'
        + '<span class="left"></span>'
        + '<span class="center">'
            + '<button type="#{type}" style="width:#{width}" '
            + ' class="btn">#{label}'
            + '</button>'
        + '</span>'
        + '<span class="right"></span>'
        + '</span>'
    );
    function _render(button_options) {
        _extendCss(button_options);
        return _button_template.evaluate(button_options);
    }
    function _evalCondition(button_condition) {
        if(typeof button_condition == 'function') return button_condition();
        else
        if(eval(button_condition)) return true;
        else                       return false;
    }
    return {
        destroy: function() {
            // test that element still in DOM
            if(this.btnElt) this.btnElt.stopObserving('click');
        },
        initialize: function(container, options) {
            var defaults = {
                id: 'btn_' + (new Date()).getTime(),
                callback: Prototype.emptyFunction,
                condition: true,
                width: 'auto',
                type: 'button',
                label: 'GVA_SCRIPT_BUTTON'
            };
            this.options = Object.extend(defaults, options || {});

            if(_evalCondition(this.options.condition)) {
                try {
                    this.container = $(container);
                    this.container.insert(_render(this.options));
                    this.btnContainer = $(this.options.id); // the outer <span/>

                    this.btnElt = this.btnContainer.down('.btn'); // the <button/>

                    // setting inline style on the button container
                    if(typeof this.options.style != 'undefined') {
                        this.btnContainer.setStyle(this.options.style);
                    }

                    // setting tabindex on button if any
                    if(typeof this.options.tabindex != 'undefined') {
                        this.btnElt.writeAttribute('tabindex', this.options.tabindex);
                    }

                    this.btnElt.observe('click', this.options.callback.bind(this.btnElt));
                } catch (e) {}
            }
        }
    }
}());

GvaScript.CustomButtons.ButtonNavigation = Class.create();
Object.extend(GvaScript.CustomButtons.ButtonNavigation.prototype, function() {
        // private members
        var bcss = CSSPREFIX();

        function _leftHandler(event) {
            var selectedBtn = this.selectedBtn;
            if (selectedBtn) {
                var nextBtn = this.previousBtn(selectedBtn);

                if (nextBtn) this.select(nextBtn);
                else         selectedBtn.flash();

                Event.stop(event);
            }
        }
        function _rightHandler(event) {
            var selectedBtn = this.selectedBtn;
            if (selectedBtn) {
                var prevBtn = this.nextBtn(selectedBtn);

                if (prevBtn) this.select(prevBtn);
                else         selectedBtn.flash();

                Event.stop(event);
            }
        }
        function _tabHandler(event) {
            if (this.options.preventListBlur)
                if (this.isLast(this.selectedBtn))
                    Event.stop(event);
        }
        function _shiftTabHandler(event) {
            if (this.options.preventListBlur)
                if (this.isFirst(this.selectedBtn))
                    Event.stop(event);
        }
        function _homeHandler(event) {
            if (this.selectedBtn) {
                this.select(this.firstBtn());
                Event.stop(event);
            }
        }
        function _endHandler(event) {
            if (this.selectedBtn) {
                this.select(this.lastBtn());
                Event.stop(event);
            }
        }
        function _addHandlers() {
            this.buttons.each(function(btnContainer) {
                var btn;
                // if the button is a GvaScript.CustomButtons.BUTTON, then the actual <button> element
                // will be embedded and selectable via .btn classname:
                // <span class="gva-btn-container">
                //         <span class="left"/>
                //         <span class="center">
                //                 <button accesskey="r" class="btn" style="width: auto;" id="btn_1226916357164">
                //                         Rechercher dans Calvin
                //                 </button>
                //         </span>
                //         <span class="right"/>
                // </span>
                // this will be cleaner when all application buttons are transformed into
                // GvaScript.CustomButtons.Button instances
                if(btnContainer.tagName.search(/^(INPUT|BUTTON)$/i) > -1) btn = btnContainer;
                else {
                    btn = btnContainer.down('.btn');
                    btn.visible        = function() {return btnContainer.visible();}
                    // support focus function on span.buttonContainer
                    btnContainer.focus = function() {btn.focus();}
                }

                if(typeof btn == 'undefined') return;

            }, this);

            this.container.register('button.btn', 'focus', function(e) {
                this.select.call(this, e._target.up('.'+bcss+'-btn-container'));
            }.bind(this));
            this.container.register('button.btn', 'blur', function(e) {
                this.select.call(this, null);
            }.bind(this));
        }

        // public members
        return {
            destroy: function() {
                // test that element still in DOM
                if(this.container) this.container.unregister();
                this.keymap.destroy();
            },
            initialize: function(container, options) {
                var defaults = {
                    preventListBlur     : false,
                    flashDuration       : 100,     // milliseconds
                    flashClassName      : 'flash',
                    keymap              : null,
                    selectFirstBtn      : true,
                    className           : bcss+'-button'
                };
                this.options   = Object.extend(defaults, options || {});
                this.container = $(container);

                // initializing the keymap
                var keyHandlers = {
                    LEFT:       _leftHandler     .bindAsEventListener(this),
                    RIGHT:      _rightHandler    .bindAsEventListener(this),
                    TAB:        _tabHandler      .bindAsEventListener(this),
                    S_TAB:      _shiftTabHandler .bindAsEventListener(this),
                    HOME:       _homeHandler     .bindAsEventListener(this),
                    END:        _endHandler      .bindAsEventListener(this)
                };
                this.keymap = new GvaScript.KeyMap(keyHandlers);
                this.keymap.observe("keydown", container, {
                    preventDefault:false,
                    stopPropagation:false
                });

                // get all buttons of designated className regardless of their
                // visibility jump over hidden ones when navigating
                this.buttons = this.container.select('.'+this.options.className);
                _addHandlers.call(this);

                if (this.options.selectFirstBtn) {
                    if(firstButObj = this.firstBtn()) {
                        this.select(firstButObj);
                    }
                    // set the focus on the container anyways so that the focus
                    // gets trasferred successfully to windows with empty
                    // actionsbar
                    else {
                        this.container.writeAttribute('tabindex', 0);
                        this.container.focus();
                    }
                }
            },
            select: function (btn) {
                var previousBtn = this.selectedBtn || null;
                if (previousBtn === btn) return; // selection already handled

                // blur the previously selected button
                if (previousBtn) {
                    previousBtn.removeClassName('btn-focus');
                }
                this.selectedBtn = btn;
                if (btn) {
                    btn.addClassName('btn-focus');
                    try {
                        if(btn.tagName.search(/^(INPUT|BUTTON)$/i) > -1)
                            btn.focus();
                        else
                            btn.down('.btn').focus();
                    } catch (err) {}
                }
            },
            // returns the next visible button
            // null if none exists
            nextBtn: function (btn) {
                var _idx = this.buttons.indexOf(btn);
                var _nextBtn = null;

                do    _nextBtn = this.buttons[++_idx]
                while(_nextBtn && !(_nextBtn.visible()));

                return _nextBtn;
            },
            // returns the previous visible button
            // null if none exists
            previousBtn: function (btn) {
                var _idx = this.buttons.indexOf(btn);
                var _prevBtn = null;

                do    _prevBtn = this.buttons[--_idx]
                while(_prevBtn && !(_prevBtn.visible()));

                return _prevBtn;
            },
            isFirst: function(btn) { return btn == this.firstBtn() },
            isLast:  function(btn) { return btn == this.lastBtn() },
            // return first visible button
            firstBtn: function() {
                return this.buttons.find(function(e) {
                    return e.visible();
                });
            },
            // return last visible button
            lastBtn: function() {
                return this.buttons.reverse(false).find(function(e) {
                    return e.visible();
                });
            }
        }
}());


GvaScript.CustomButtons.ActionsBar = Class.create();
Object.extend(GvaScript.CustomButtons.ActionsBar.prototype, {
    initialize: function(container, options) {
        var bcss = CSSPREFIX();
        var defaults = {
            actions: [],
            selectfirst: false
        }
        this.container = $(container);
        this.container.update('');
        this.options = Object.extend(defaults, options || {});
        this.container.addClassName(bcss+'-actionsbar');

        this.options.actions.each(function(action_props, index) {
            action_props.id = action_props.id || this.container.id + '_btn_' + index;
            // renders a <button> element and appends it to container
            new GvaScript.CustomButtons.Button(this.container, action_props);
        }, this);

        this.buttonNavigation = new GvaScript.CustomButtons.ButtonNavigation(this.container, {
            selectFirstBtn: this.options.selectfirst,
            className: bcss+'-btn-container'
        });

        this.container.store('widget', this);
        this.container.addClassName(bcss+'-widget');
    },
    destroy: function() {
        this.buttonNavigation.destroy();
    }
});

document.register('.'+CSSPREFIX()+'-btn-container', 'mouseover', function(e) {
    e._target.addClassName('btn-hover');
});
document.register('.'+CSSPREFIX()+'-btn-container', 'mouseout', function(e) {
    e._target.removeClassName('btn-hover');
});
