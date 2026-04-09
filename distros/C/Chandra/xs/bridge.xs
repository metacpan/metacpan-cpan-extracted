MODULE = Chandra    PACKAGE = Chandra::Bridge

PROTOTYPES: DISABLE

SV *
js_code(...)
CODE:
{
    static const char CHANDRA_BRIDGE_JS[] =
    "(function() {\n"
    "    if (window.chandra) return;\n"
    "\n"
    "    window.chandra = {\n"
    "        _callbacks: {},\n"
    "        _id: 0,\n"
    "\n"
    "        invoke: function(method, args) {\n"
    "            var self = this;\n"
    "            return new Promise(function(resolve, reject) {\n"
    "                var id = ++self._id;\n"
    "                self._callbacks[id] = { resolve: resolve, reject: reject };\n"
    "                window.external.invoke(JSON.stringify({\n"
    "                    type: 'call',\n"
    "                    id: id,\n"
    "                    method: method,\n"
    "                    args: args || []\n"
    "                }));\n"
    "            });\n"
    "        },\n"
    "\n"
    "        call: function(method) {\n"
    "            var args = Array.prototype.slice.call(arguments, 1);\n"
    "            return this.invoke(method, args);\n"
    "        },\n"
    "\n"
    "        _resolve: function(id, result, error) {\n"
    "            var cb = this._callbacks[id];\n"
    "            if (!cb) return;\n"
    "            delete this._callbacks[id];\n"
    "            if (error) {\n"
    "                cb.reject(new Error(error));\n"
    "            } else {\n"
    "                cb.resolve(result);\n"
    "            }\n"
    "        },\n"
    "\n"
    "        _event: function(handlerId, eventData) {\n"
    "            window.external.invoke(JSON.stringify({\n"
    "                type: 'event',\n"
    "                handler: handlerId,\n"
    "                event: eventData || {}\n"
    "            }));\n"
    "        },\n"
    "\n"
    "        _eventData: function(e, extra) {\n"
    "            var data = {\n"
    "                type: e.type,\n"
    "                targetId: e.target ? e.target.id : null,\n"
    "                targetName: e.target ? e.target.name : null,\n"
    "                value: e.target ? e.target.value : null,\n"
    "                checked: e.target ? e.target.checked : null,\n"
    "                key: e.key || null,\n"
    "                keyCode: e.keyCode || null\n"
    "            };\n"
    "            if (extra) {\n"
    "                for (var k in extra) {\n"
    "                    data[k] = extra[k];\n"
    "                }\n"
    "            }\n"
    "            return data;\n"
    "        }\n"
    "    };\n"
    "})();\n";

    RETVAL = newSVpvn(CHANDRA_BRIDGE_JS, sizeof(CHANDRA_BRIDGE_JS) - 1);
    /* append any registered extensions */
    if (_ext_count > 0) {
        SV *ext_js = chandra_ext_generate_js(aTHX);
        sv_catsv(RETVAL, ext_js);
        SvREFCNT_dec(ext_js);
    }
}
OUTPUT:
    RETVAL

SV *
js_code_escaped(...)
CODE:
{
    static const char CHANDRA_BRIDGE_JS[] =
    "(function() {\n"
    "    if (window.chandra) return;\n"
    "\n"
    "    window.chandra = {\n"
    "        _callbacks: {},\n"
    "        _id: 0,\n"
    "\n"
    "        invoke: function(method, args) {\n"
    "            var self = this;\n"
    "            return new Promise(function(resolve, reject) {\n"
    "                var id = ++self._id;\n"
    "                self._callbacks[id] = { resolve: resolve, reject: reject };\n"
    "                window.external.invoke(JSON.stringify({\n"
    "                    type: 'call',\n"
    "                    id: id,\n"
    "                    method: method,\n"
    "                    args: args || []\n"
    "                }));\n"
    "            });\n"
    "        },\n"
    "\n"
    "        call: function(method) {\n"
    "            var args = Array.prototype.slice.call(arguments, 1);\n"
    "            return this.invoke(method, args);\n"
    "        },\n"
    "\n"
    "        _resolve: function(id, result, error) {\n"
    "            var cb = this._callbacks[id];\n"
    "            if (!cb) return;\n"
    "            delete this._callbacks[id];\n"
    "            if (error) {\n"
    "                cb.reject(new Error(error));\n"
    "            } else {\n"
    "                cb.resolve(result);\n"
    "            }\n"
    "        },\n"
    "\n"
    "        _event: function(handlerId, eventData) {\n"
    "            window.external.invoke(JSON.stringify({\n"
    "                type: 'event',\n"
    "                handler: handlerId,\n"
    "                event: eventData || {}\n"
    "            }));\n"
    "        },\n"
    "\n"
    "        _eventData: function(e, extra) {\n"
    "            var data = {\n"
    "                type: e.type,\n"
    "                targetId: e.target ? e.target.id : null,\n"
    "                targetName: e.target ? e.target.name : null,\n"
    "                value: e.target ? e.target.value : null,\n"
    "                checked: e.target ? e.target.checked : null,\n"
    "                key: e.key || null,\n"
    "                keyCode: e.keyCode || null\n"
    "            };\n"
    "            if (extra) {\n"
    "                for (var k in extra) {\n"
    "                    data[k] = extra[k];\n"
    "                }\n"
    "            }\n"
    "            return data;\n"
    "        }\n"
    "    };\n"
    "})();\n";

    STRLEN src_len = sizeof(CHANDRA_BRIDGE_JS) - 1;
    const char *src = CHANDRA_BRIDGE_JS;
    SV *out = newSV(src_len * 2);
    char *dst = SvPVX(out);
    STRLEN dlen = 0;
    STRLEN i;

    for (i = 0; i < src_len; i++) {
        switch (src[i]) {
            case '\\': dst[dlen++] = '\\'; dst[dlen++] = '\\'; break;
            case '\'': dst[dlen++] = '\\'; dst[dlen++] = '\''; break;
            case '\n': dst[dlen++] = '\\'; dst[dlen++] = 'n';  break;
            case '\r': dst[dlen++] = '\\'; dst[dlen++] = 'r';  break;
            default:   dst[dlen++] = src[i]; break;
        }
    }
    dst[dlen] = '\0';
    SvCUR_set(out, dlen);
    SvPOK_on(out);
    /* append escaped extensions */
    if (_ext_count > 0) {
        SV *ext_js = chandra_ext_generate_js(aTHX);
        SV *ext_esc = chandra_ext_escape_sv(aTHX_ ext_js);
        sv_catsv(out, ext_esc);
        SvREFCNT_dec(ext_js);
        SvREFCNT_dec(ext_esc);
    }
    RETVAL = out;
}
OUTPUT:
    RETVAL
