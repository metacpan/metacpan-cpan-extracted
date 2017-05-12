// Copyright 2003-2015 - Paul Seamons - ver 2.44
// Distributed under the Perl Artistic License without warranty
// See perldoc CGI::Ex::Validate for usage

var v_did_inline  = {};
var v_event;

function ValidateError (errors, extra) {
 this.errors = errors;
 this.extra  = extra;
 this.as_string = eob_as_string;
 this.as_array  = eob_as_array;
 this.as_hash   = eob_as_hash;
 this.first_field = eob_first_field;
}

//

function v_error (err) { alert (err); return 1 }

function v_get_ordered_fields (val_hash) {
 if (typeof(val_hash) != 'object') return {error: v_error("Validation must be an associative array (hash)")};

 var ARGS = {};
 var field_keys = [];
 var m;
 for (var key in val_hash) {
  if (!val_hash.hasOwnProperty(key)) continue;
  if (m = key.match(/^(general|group)\s+(\w+)/)) {
    ARGS[m[2]] = val_hash[key];
    continue;
  }
  field_keys.push(key);
 }
 field_keys = field_keys.sort();

 var f = ARGS.set_hook;   if (f && typeof(f) == 'string') eval("ARGS.set_hook = "+f);
 f = ARGS.clear_hook;     if (f && typeof(f) == 'string') eval("ARGS.clear_hook = "+f);
 f = ARGS.set_all_hook;   if (f && typeof(f) == 'string') eval("ARGS.set_all_hook = "+f);
 f = ARGS.clear_all_hook; if (f && typeof(f) == 'string') eval("ARGS.clear_all_hook = "+f);

 if (f = ARGS.validate_if) {
   if (typeof(f) == 'string' || ! f.length) f = [f];
   var deps = v_clean_cond(f);
 }

 var fields = [];
 var ref;
 if (ref = ARGS.fields || ARGS['order']) {
  if (typeof(ref) != 'object' || ! ref.length)
   return {error:v_error("'group fields' must be a non-empty array")};
  for (var i = 0; i < ref.length; i++) {
   var field = ref[i];
   if (typeof(field) == 'object') {
    if (! field.field) return {error:v_error("Missing field key in validation")};
    fields.push(field);
   } else if (field == 'OR') {
    fields.push('OR');
   } else {
    var field_val = val_hash[field];
    if (! field_val) return {error:v_error('No element found in group for '+field)};
    if (typeof(field_val) == 'object' && ! field_val['field']) field_val['field'] = field;
    fields.push(field_val);
   }
  }
 }

 var found = {};
 for (var i = 0; i < fields.length; i++) {
  var field_val = fields[i];
  if (typeof(field_val) != 'object') continue;
  found[field_val.field] = 1;
 }

 for (var i = 0; i < field_keys.length; i++) {
  var field = field_keys[i];
  if (found[field]) continue;
  var field_val = val_hash[field];
  if (typeof(field_val) != 'object' || field_val.length) return {error:v_error('Found a non-hash value on field '+field)};
  if (! field_val.field) field_val.field = field;
  fields.push(field_val);
 }

 for (var i = 0; i < fields.length; i++) v_clean_field_val(fields[i]);

 val_hash['group was_checked'] = {};
 val_hash['group was_valid'] = {};
 val_hash['group had_error'] = {};

 return {'fields':fields, 'args':ARGS};
}

function v_clean_field_val (field_val, N_level) {
 if (! field_val.order) field_val.order = v_field_order(field_val);
 if (! field_val.deps) field_val.deps = {};
 for (var i = 0; i < field_val.order.length; i++) {
  var k = field_val.order[i];
  var v = field_val[k];
  if (typeof(v) == 'undefined') return {error:v_error('No matching validation found on field '+field+' for type '+k)};
  if (k.match(/^(min|max)_in_set_?(\d*)$/)) {
   if (typeof(v) == 'string') {
    if (! (m = v.match(/^\s*(\d+)(?:\s*[oO][fF])?\s+(.+)\s*$/))) return {error:v_error("Invalid "+k+" check "+v)};
    field_val[k] = m[2].split(/[\s,]+/);
    field_val[k].unshift(m[1]);
   }
   for (var j = 1; j < field_val[k].length; j++) if (field_val[k][j] != field_val.field) field_val.deps[field_val[k][j]] = 1;
  } else if (k.match(/^(enum|compare)_?\d*$/)) {
   if (typeof(v) == 'string') field_val[k] = v.split(/\s*\|\|\s*/);
  } else if (k.match(/^match_?\d*$/)) {
   if (typeof(v) == 'string') v = field_val[k] = v.split(/\s*\|\|\s*/);
   for (var j = 0; j < v.length; j++) {
    if (typeof(v[j]) != 'string' || v[j] == '!') continue;
    var m = v[j].match(/^\s*(!\s*|)m([^\s\w])(.*)\2([eigsmx]*)\s*$/);
    if (! m) return {error:v_error("Not sure how to parse that match ("+v[j]+")")};
    var not = m[1];
    var pat = m[3];
    var opt = m[4];
    if (opt.indexOf('e') != -1) return {error:v_error("The e option cannot be used on field "+field_val.field+", test "+k)};
    opt = opt.replace(/[sg]/g,'');
    v[j] = new RegExp(pat, opt);
    if (not) v.splice(j, 0, '!');
   }
  } else if (k.match(/^custom_js_?\d*$/)) {
   if (typeof(v) == 'string' && v.match(/^\s*function\s*\(/)) eval("field_val[k] = "+v);
  } else if (k.match(/^(validate|required)_if_?\d*$/)) {
   if (typeof(v) == 'string' || ! v.length) v = field_val[k] = [v];
   var deps = v_clean_cond(v, N_level);
   for (var k in deps) field_val.deps[k] = 2;
  } else if (k.match(/^equals_?\d*$/)) {
   if (!/^[\"\']/.test(field_val[k])) {
    var deps = v_clean_cond([field_val[k].replace(/^!\s*/,'')], N_level);
    for (var k in deps) field_val.deps[k] = 3;
   }
  }
 }
}

function v_clean_cond (ifs, N_level, ifs_match) {
 if (typeof(ifs) != 'object') { v_error("Need reference v_clean_cond "+typeof(ifs)); return [] }
 if (! N_level) N_level = 0;
 if (++N_level > 10) { v_error("Max dependency level reached " + N_level); return [] }

 var deps = {};
 var m;
 for (var i = 0; i < ifs.length; i++) {
  if (typeof(ifs[i]) == 'string') {
   if (ifs[i].match(/^\s*function\s*\(/)) eval("ifs[i] = "+ifs[i]);
   else if (m = ifs[i].match(/^(.+?)\s+was_valid$/)) ifs[i] = {field: m[1], was_valid:1}
   else if (m = ifs[i].match(/^(.+?)\s+had_error$/)) ifs[i] = {field: m[1], had_error:1}
   else if (m = ifs[i].match(/^(.+?)\s+was_checked$/)) ifs[i] = {field: m[1], was_checked:1}
   else if (m = ifs[i].match(/^(\s*!\s*)(.+)\s*$/)) ifs[i] = {field: m[2], max_in_set: [0, m[2]]};
   else if (ifs[i] != 'OR') ifs[i] = {field: ifs[i], required: 1};
  }
  if (typeof(ifs[i]) != 'object') continue;
  if (! ifs[i].field) { v_error("Missing field key during validate_if"); return [] }
  deps[ifs[i].field] = 2;
  v_clean_field_val(ifs[i], N_level);
  for (var k in ifs[i].deps) deps[k] = 2;
 }
 return deps;
}

function v_validate (form, val_hash) {
 var clean  = v_get_ordered_fields(val_hash);
 if (clean.error) return;
 var fields = clean.fields;

 var ERRORS = [];
 var EXTRA  = [];
 var title       = val_hash['group title'];
 var v_if = val_hash['group validate_if'];
 if (v_if && ! v_check_conditional(form, v_if, val_hash)) return;

 var is_found  = 1;
 var errors = [];
 var hold_err;

 var chk = {};
 for (var j = 0; j < fields.length; j++) {
  var ref = fields[j];
  if (typeof(ref) != 'object' && ref == 'OR') {
   if (is_found) j++;
   is_found = 1;
   continue;
  }
  is_found = 1;
  var names = v_field_names(form, ref.field);
  if (!names) names = [[ref.field, null]];
  for (var i = 0; i < names.length; i++) {
   var f = names[i][0];
   var ifs_match = names[i][1];
   if (! chk[f]) {
    chk[f] = 1;
    val_hash['group was_checked'][f] = 1;
    val_hash['group was_valid'][f]   = 1;
    val_hash['group had_error'][f]   = 0;
   }
   var err = v_validate_buddy(form, f, ref, val_hash, ifs_match);
   if (err.length) {
    val_hash['group had_error'][f] = 1;
    val_hash['group was_valid'][f] = 0;
    if (j <= fields.length && typeof(fields[j + 1] != 'object') && fields[j + 1] == 'OR') {
     hold_err = err;
    } else {
     if (hold_err) err = hold_err;
     for (var k = 0; k < err.length; k++) errors.push(err[k]);
     hold_err = '';
    }
   } else {
    hold_err = '';
   }
  }
 }

 if (errors.length) {
  if (title) ERRORS.push(title);
  for (var j = 0; j < errors.length; j++) ERRORS.push(errors[j]);
 }

 for (var field in clean.args) {
  if (errors.length == 0 || field.match(/^(field|order|title|validate_if)$/)) continue;
  EXTRA[field] = clean.args[field];
 }

 if (ERRORS.length) return new ValidateError(ERRORS, EXTRA);
 return;
}

function v_check_conditional (form, ifs, val_hash, ifs_match) {
 var is_ok = 1;
 for (var i = 0; i < ifs.length; i++) {
  if (typeof(ifs[i]) == 'function') {
   if (! is_ok) break;
   if (! ifs[i]({'form':form})) is_ok = 0;
  } else if (typeof(ifs[i]) == 'string') {
   if (ifs[i] != 'OR') { v_error("Found non-OR string"); return }
   if (is_ok) i++;
   is_ok = 1;
   continue;
  } else {
   if (! is_ok) break;
   var field = ifs[i].field;
   field = field.replace(/\$(\d+)/g, function (all, N) {
    return (typeof(ifs_match) != 'object' || typeof(ifs_match[N]) == 'undefined') ? '' : ifs_match[N];
   });
   var err = v_validate_buddy(form, field, ifs[i], val_hash);
   if (err.length) is_ok = 0;
  }
 }
 return is_ok;
}

function v_filter_types (type, types) {
 var values = [];
 var regexp = new RegExp('^'+type+'_?\\d*$');
 for (var i = 0; i < types.length; i++)
  if (types[i].match(regexp)) values.push(types[i]);
 return values;
}

function v_add_error (errors,field,type,field_val,ifs_match,form,custom_err) {
 errors.push([field, type, field_val, ifs_match, custom_err]);
 if (field_val.clear_on_error) {
  var el = form[field];
  if (el && el.type && el.type.match(/(hidden|password|text|textarea|submit)/)) el.value = '';
 }
 return errors;
}

function v_field_order (field_val) {
 var o = [];
 for (var k in field_val)
   if (field_val.hasOwnProperty(k) && ! k.match(/^(field|name|required|was_valid|was_checked|had_error)$/) && ! k.match(/_error$/)) o.push(k);
 return o.sort();
}

function v_field_names (form, field) {
 var m = field.match(/^(!\s*|)m([^\s\w])(.*)\2([eigsmx]*)$/);
 if (!m) return;
 var fields = [];
 var not = m[1];
 var pat = m[3];
 var opt = m[4];
 if (opt.indexOf('e') != -1) { v_error("The e option cannot be used on field "+field); return [] }
 opt = opt.replace(/[sg]/g,'');
 var reg = new RegExp(pat, opt);

 for (var i = 0; i < form.elements.length; i++) {
  var _field = form.elements[i].name;
  if (_field && (not && ! (m = _field.match(reg))) || (m = _field.match(reg))) fields.push([_field, m]);
 }
 return fields;
}

function v_validate_buddy (form, field, field_val, val_hash, ifs_match) {
 var errors = [];
 if (! form.elements || field_val.exclude_js) return [];
 var types = field_val.order || v_field_order(field_val);
 var m;

 var names = v_field_names(form, field);
 if (names) {
  for (var i = 0; i < names.length; i++) {
   var err = v_validate_buddy(form, names[i][0], field_val, val_hash, names[i][1]);
   for (var j = 0; j < err.length; j++) errors.push(err[j]);
  }
  return errors;
 }

 if (field_val.was_valid   && ! val_hash['group was_valid'][field])   return v_add_error(errors, field, 'was_valid',   field_val, ifs_match, form);
 if (field_val.had_error   && ! val_hash['group had_error'][field])   return v_add_error(errors, field, 'had_error',   field_val, ifs_match, form);
 if (field_val.was_checked && ! val_hash['group was_checked'][field]) return v_add_error(errors, field, 'was_checked', field_val, ifs_match, form);

 var _value   = v_get_form_value(form[field]);
 var modified = 0;

 if (typeof(field_val['default']) != 'undefined'
     && (typeof(_value) == 'undefined'
         || (typeof(_value) == 'object' && _value.length == 0)
         || ! _value.length)) {
  _value = ''+field_val['default'];
  modified = 1;
 }

 var values   = (typeof(_value) == 'object') ? _value : [_value];
 var n_values = (typeof(_value) == 'undefined') ? 0 : values.length;

 for (var i = 0; i < values.length; i++) {
  if (typeof(values[i]) == 'undefined') continue;
  var orig = values[i];
  if (! field_val.do_not_trim) {
    values[i] = values[i].replace(/^\s+/,'');
    if (v_event != 'change') values[i] = values[i].replace(/\s+$/,'');
  }
  if (field_val.trim_control_chars) values[i] = values[i].replace(/\t/g,' ').replace(/[\x00-\x1F]/g,'');
  if (field_val.to_upper_case) values[i] = values[i].toUpperCase();
  if (field_val.to_lower_case) values[i] = values[i].toLowerCase();

  var tests = v_filter_types('replace', types);
  for (var k = 0; k < tests.length; k++) {
   var ref = field_val[tests[k]];
   ref = (typeof(ref) == 'object') ? ref : ref.split(/\s*\|\|\s*/);
   for (var j = 0; j < ref.length; j++) {
    if (! (m = ref[j].match(/^\s*s([^\s\w])(.+)\1(.*)\1([eigmx]*)$/)))
     return v_error("Not sure how to parse that replace "+ref[j]);
    var pat  = m[2];
    var swap = m[3];
    var opt  = m[4];
    if (opt.indexOf('e') != -1) { v_error("The e option cannot be used on field "+field+", replace "+tests[i]); return [] }
    var regexp = new RegExp(pat, opt);
    values[i] = values[i].replace(regexp, swap);
   }
  }

  if (orig != values[i]) modified = 1;
 }
 if (modified) {
  var el = form[field];
  if (el) v_set_form_value(el, values);
 }


 var needs_val = 0;
 var tests = v_filter_types('validate_if', types);
 for (var i = 0; i < tests.length; i++) {
  var ifs = field_val[tests[i]];
  var ret = v_check_conditional(form, ifs, val_hash, ifs_match);
  if (ret) needs_val++;
 }
 if (tests.length && ! needs_val) {
  if (field_val.vif_disable && val_hash['group was_valid'][field]) v_set_disable(form[field], true);
  val_hash['group was_valid'][field] = 0;
  return [];
 }
 if (field_val.vif_disable) v_set_disable(form[field], false);

 var is_required = field_val['required'] ? 'required' : '';
 if (! is_required) {
  var tests = v_filter_types('required_if', types);
  for (var i = 0; i < tests.length; i++) {
   var ifs = field_val[tests[i]];
   if (! v_check_conditional(form, ifs, val_hash, ifs_match)) continue;
   is_required = tests[i];
   break;
  }
 }
 if (is_required) {
  var found;
  for (var i = 0; i < values.length; i++) {
   if (values[i].length) {
    found = 1;
    break;
   }
  }
  if (! found) return v_add_error(errors, field, is_required, field_val, ifs_match, form);
 }

 if (field_val.min_values && n_values < field_val.min_values)
  return v_add_error(errors, field, 'min_values', field_val, ifs_match, form);

 if (typeof(field_val.max_values) == 'undefined') field_val.max_values = 1;
 if (field_val.max_values && n_values > field_val.max_values)
  return v_add_error(errors, field, 'max_values', field_val, ifs_match, form);

 for (var h = 0; h < 2 ; h++) {
  var minmax = (h == 0) ? 'min' : 'max';
  var tests = v_filter_types(minmax+'_in_set', types);
  for (var i = 0; i < tests.length; i++) {
   var a = field_val[tests[i]];
   var n = a[0];
   for (var k = 1; k < a.length; k++) {
    var _value = v_get_form_value(form[a[k]]);
    var _values;
    if (typeof(_value) == 'undefined') continue;
    _values = (typeof(_value) == 'object') ? _value : [_value];
    for (var l = 0; l < _values.length; l++) {
     var _value = _values[l];
     if (typeof(_value) != 'undefined' && _value.length) n--;
    }
   }
   if (   (minmax == 'min' && n > 0)
     || (minmax == 'max' && n < 0)) {
    v_add_error(errors, field, tests[i], field_val, ifs_match, form);
    return errors;
   }
  }
 }

 for (var n = 0; n < values.length; n++) {
  var value = values[n];

  if (typeof field_val['enum'] != 'undefined') {
   var is_found = 0;
   for (var j = 0; j < field_val['enum'].length; j++) if (value == field_val['enum'][j]) { is_found = 1; break }
   if (! is_found) {
    v_add_error(errors, field, 'enum', field_val, ifs_match, form);
    continue;
   }
  }

  if (typeof field_val['type'] != 'undefined')
   if (! v_check_type(value, field_val['type'], field, form)) {
    v_add_error(errors, field, 'type', field_val, ifs_match, form);
    continue;
   }

  for (var i = 0; i < types.length; i++) {
   var type = types[i];
   var _fv  = field_val[type];

   if (type.match(/^equals_?\d*$/)) {
    var not = _fv.match(/^!\s*/);
    if (not) _fv = _fv.substring(not[0].length);
    var success = 0;
    if (m = _fv.match(/^([\"\'])(.*)\1$/)) {
     if (value == m[2]) success = 1;
    } else {
     var _fv2 = _fv.replace(/\$(\d+)/g, function (all, N) {
      return (typeof(ifs_match) != 'object' || typeof(ifs_match[N]) == 'undefined') ? '' : ifs_match[N];
     });
     var value2 = v_get_form_value(form[_fv2]);
     if (typeof(value2) == 'undefined') value2 = '';
     if (value == value2) success = 1;
    }
    if (not && success || ! not && ! success) {
     v_add_error(errors, field, type, field_val, ifs_match, form);
     break;
    }
   }

   if (type == 'min_len' && value.length < _fv) v_add_error(errors, field, 'min_len', field_val, ifs_match, form);
   if (type == 'max_len' && value.length > _fv) v_add_error(errors, field, 'max_len', field_val, ifs_match, form);

   if (type.match(/^match_?\d*$/)) {
    for (var j = 0; j < _fv.length; j++) {
     if (typeof(_fv[j]) == 'string') continue;
     var not = (j > 0 && typeof(_fv[j-1]) == 'string' && _fv[j-1] == '!') ? 1 : 0;
     if (   (  not &&   value.match(_fv[j]))
         || (! not && ! value.match(_fv[j]))) v_add_error(errors, field, type, field_val, ifs_match, form);
    }
   }

   if (type.match(/^compare_?\d*$/)) {
    for (var j = 0; j < _fv.length; j++) {
     var comp = _fv[j];
     if (! comp) continue;
     var hold = false;
     var copy = value;
     if (m = comp.match(/^\s*(>|<|[><!=]=)\s*([\d\.\-]+)\s*$/)) {
      if (! copy) copy = 0;
      copy *= 1;
      if      (m[1] == '>' ) hold = (copy >  m[2])
      else if (m[1] == '<' ) hold = (copy <  m[2])
      else if (m[1] == '>=') hold = (copy >= m[2])
      else if (m[1] == '<=') hold = (copy <= m[2])
      else if (m[1] == '!=') hold = (copy != m[2])
      else if (m[1] == '==') hold = (copy == m[2])
     } else if (m = comp.match(/^\s*(eq|ne|gt|ge|lt|le)\s+(.+?)\s*$/)) {
      if (     m[2].match(/^\"/)) m[2] = m[2].replace(/^"(.*)"$/,'$1');
      else if (m[2].match(/^\'/)) m[2] = m[2].replace(/^'(.*)'$/,'$1');
      if      (m[1] == 'gt') hold = (copy >  m[2])
      else if (m[1] == 'lt') hold = (copy <  m[2])
      else if (m[1] == 'ge') hold = (copy >= m[2])
      else if (m[1] == 'le') hold = (copy <= m[2])
      else if (m[1] == 'ne') hold = (copy != m[2])
      else if (m[1] == 'eq') hold = (copy == m[2])
     } else {
      v_error("Not sure how to compare \""+comp+"\"");
      return errors;
     }
     if (! hold) v_add_error(errors, field, type, field_val, ifs_match, form);
    }
   }
  }
 }

 for (var i = 0; i < types.length; i++) {
  var type = types[i];
  var _fv  = field_val[type];
  // the js is evaluated and should return 1 for success
  // or 0 for failure - the variables field, value, and field_val (the hash) are available
  if (type.match(/^custom_js_?\d*$/)) {
   var value = values.length == 1 ? values[0] : values;
   var err;
   var ok;
   try { ok = (typeof _fv == 'function') ? _fv({'value':value, 'field_val':field_val, 'form':form, 'key':field_val.field, 'errors':errors, 'event':v_event}) : eval(_fv) } catch (e) { err = e }
   if (!ok) v_add_error(errors, field, type, field_val, ifs_match, form, err);
  }
 }

 return errors;
}

function v_check_type (value, type, field, form) {
 var m;
 type = type.toUpperCase();

 if (type == 'EMAIL') {
  if (! value) return 0;
  if (! (m = value.match(/^(.+)@(.+?)$/))) return 0;
  if (m[1].length > 60)  return 0;
  if (m[2].length > 100) return 0;
  if (! v_check_type(m[2],'DOMAIN') && ! v_check_type(m[2],'IP')) return 0;
  if (! v_check_type(m[1],'LOCAL_PART')) return 0;

 } else if (type == 'LOCAL_PART') {
  if (typeof(value) == 'undefined' || ! value.length) return 0;
  if (typeof(v_local_part) != 'undefined') return (value.match(v_local_part) ? 1 : 0);
  // ignoring all valid quoted string local parts
  if (value.match(/[^\w.~!\#\$%\^&*\-=+?]/)) return 0;

 } else if (type == 'IP') {
  if (! value) return 0;
  var dig = value.split(/\./);
  if (dig.length != 4) return 0;
  for (var i = 0; i < 4; i++)
   if (typeof(dig[i]) == 'undefined' || dig[i].match(/\D/) || dig[i] > 255) return 0;

 } else if (type == 'DOMAIN') {
  if (! value) return 0;
  if (! value.match(/^[a-z0-9.-]{4,255}$/)) return 0;
  if (value.match(/^[.\-]/))             return 0;
  if (value.match(/(\.-|-\.|\.\.)/))  return 0;
  if (! (m = value.match(/^(.+\.)([a-z]{2,10})$/))) return 0;
  if (! m[1].match(/^([a-z0-9\-]{1,63}\.)+$/)) return 0;

 } else if (type == 'URL') {
  if (! value) return 0;
  if (! (m = value.match(/^https?:\/\/([^\/]+)/i))) return 0;
  value = value.substring(m[0].length);
  var dom = m[1].replace(/:\d+$/).replace(/\.$/);
  if (! v_check_type(dom,'DOMAIN') && ! v_check_type(m[1],'IP')) return 0;
  if (value && ! v_check_type(value,'URI')) return 0;

 } else if (type == 'URI') {
  if (! value) return 0;
  if (value.match(/\s/)) return 0;

 } else if (type == 'INT') {
  if (!value.match(/^-?(?:0|[1-9]\d*)$/)) return 0;
  if ((value < 0) ? value < -Math.pow(2,31) : value > Math.pow(2,31)-1) return 0;
 } else if (type == 'UINT') {
  if (!value.match(/^(?:0|[1-9]\d*)$/)) return 0;
  if (value > Math.pow(2,32)-1) return 0;
 } else if (type == 'NUM') {
  if (!value.match(/^-?(?:0|[1-9]\d*(?:\.\d+)?|0?\.\d+)$/)) return 0;

 } else if (type == 'CC') {
  if (! value) return 0;
  if (value.match(/[^\d\- ]/)) return 0;
  value = value.replace(/[\- ]/g, '');
  if (value.length > 16 || value.length < 13) return 0;
  // mod10
  var sum = 0;
  var swc = 0;
  for (var i = value.length - 1; i >= 0; i--) {
   if (++swc > 2) swc = 1;
   var y = value.charAt(i) * swc;
   if (y > 9) y -= 9;
   sum += y;
  }
  if (sum % 10) return 0;
 }

 return 1;
}

function v_set_form_value (el, values, form) {
 if (typeof(el) == 'string') el = form[el];
 if (typeof(values) != 'object') values = [values];
 if (! el) return;
 var type = (el.type && ! (''+el).match(/HTMLCollection/)) ? el.type.toLowerCase() : '';
 if (el.length && type != 'select-one') {
  for (var i = 0; i < el.length; i++) {
   if (! el[i] || ! el[i].type) continue;
   v_set_form_value(el[i], (el[i].type.match(/^(checkbox|radio)$/) ? values : i < values.length ? [values[i]] : ['']));
  }
  return;
 }
 if (! type) return;
 if (type.indexOf('select') != -1) {
   if (el.length) for (var i = 0; i < el.length; i++) el[i].selected = (el[i].value == values[0]) ? true : false;
   return;
 }
 if (type == 'checkbox' || type == 'radio') {
  var f; for (var i = 0; i < values.length; i++) if (values[i] == el.value) f = 1;
  return el.checked = f ? true : false;
 }
 if (type == 'file') return;
 return el.value = values[0];
}

function v_set_disable (el, disable) {
 if (! el) return
 var type = el.type ? el.type.toLowerCase() : '';
 if (el.length && type != 'select-one') {
  for (var j=0;j<el.length;j++) el[i].disabled = disable;
 } else el.disabled = disable;
}

function v_get_form_value (el, form) {
 if (typeof(el) == 'string') el = form[el];
 if (! el) return '';
 var type = (el.type && ! (''+el).match(/HTMLCollection/)) ? el.type.toLowerCase() : '';
 if (el.length && type != 'select-one') {
  var a = [];
  for (var j=0;j<el.length;j++) {
   if (type.indexOf('multiple') != -1) {
    if (el[j].selected) a.push(el[j].value);
   } else {
    if (el[j].checked)  a.push(v_get_form_value(el[j]));
   }
  }
  if (a.length == 0) return '';
  if (a.length == 1) return a[0];
  return a;
 }
 if (! type) return '';
 if (type.indexOf('select') != -1) {
  if (! el.length) return '';
  if (el.selectedIndex == -1) return '';
  return el[el.selectedIndex].value;
 }
 if (type == 'checkbox' || type == 'radio') return el.checked ? el.value : '';
 return el.value;
}

function v_find_val () {
 var key = arguments[0];
 for (var i = 1; i < arguments.length; i++) {
  if (typeof(arguments[i]) == 'string') return arguments[i];
  if (typeof(arguments[i]) == 'undefined') continue;
  if (typeof(arguments[i][key]) != 'undefined') return arguments[i][key];
 }
 return '';
}

function v_get_error_text (err, extra1, extra2) {
 var field     = err[0];
 var type      = err[1];
 var field_val = err[2];
 var ifs_match = err[3];
 if (err.length == 5 && typeof err[4] != 'undefined' && err[4].length) return err[4]; // custom error from throw in custom_js

 var m;
 var dig = '';
 if (m = type.match(/^(.+?)(_?\d+)$/)) { type = m[1] ; dig = m[2] }
 var type_lc = type.toLowerCase();
 var v = field_val[type + dig];

 if (field_val.delegate_error) {
  field = field_val.delegate_error;
  field = field.replace(/\$(\d+)/g, function (all, N) {
   if (typeof(ifs_match) != 'object'
     || typeof(ifs_match[N]) == 'undefined') return ''
   return ifs_match[N];
  });
 }

 var name = field_val.name;
 if (! name && (field.match(/\W/) || (field.match(/\d/) && field.match(/\D/)))) {
  name = "The field " +field;
 }
 if (! name) name = field.replace(/_/g, ' ').replace(/\b(\w)/g, function(all,str){return str.toUpperCase()});
 name = name.replace(/\$(\d+)/g, function (all, N) {
  if (typeof(ifs_match) != 'object'
    || typeof(ifs_match[N]) == 'undefined') return ''
  return ifs_match[N];
 });

 var msg = v_find_val(type + '_error', extra1, extra2);
 if (! msg) {
   if (dig.length) msg = field_val[type + dig + '_error'];
   if (! msg)      msg = field_val[type +       '_error'];
   if (! msg)      msg = field_val['error'];
 }
 if (msg) {
  msg = msg.replace(/\$(\d+)/g, function (all, N) {
   if (typeof(ifs_match) != 'object' || typeof(ifs_match[N]) == 'undefined') return '';
   return ifs_match[N];
  });
  msg = msg.replace(/\$field/g, field);
  msg = msg.replace(/\$name/g, name);
  if (v && typeof(v) == 'string') msg = msg.replace(/\$value/g, v);
  return msg;
 }

 if (type == 'equals') {
  var field2 = field_val["equals" + dig];
  var name2  = field_val["equals" +dig+ "_name"];
  if (! name2) name2 = "the field " +field2;
  name2 = name2.replace(/\$(\d+)/g, function (all, N) {
   return (typeof(ifs_match) != 'object' || typeof(ifs_match[N]) == 'undefined') ? '' : ifs_match[N];
  });
  return name + " did not equal " + name2 +".";
 }
 if (type == 'min_in_set') return "Not enough fields were chosen from the set ("+v[0]+' of '+v.join(", ").replace(/^\d+,\s*/,'')+")";
 if (type == 'max_in_set') return "Too many fields were chosen from the set ("  +v[0]+' of '+v.join(", ").replace(/^\d+,\s*/,'')+")";

 return name + (
  (type == 'required' || type == 'required_if') ? " is required."
  : type == 'match'      ? " contains invalid characters."
  : type == 'compare'    ? " did not fit comparison."
  : type == 'custom_js'  ? " did not match custom_js"+dig+" check."
  : type == 'enum'       ? " is not in the given list."
  : type == 'min_values' ? " had less than "+v+" value"+(v == 1 ? '' : 's')+"."
  : type == 'max_values' ? " had more than "+v+" value"+(v == 1 ? '' : 's')+"."
  : type == 'min_len'    ? " was less than "+v+" character"+(v == 1 ? '' : 's')+"."
  : type == 'max_len'    ? " was more than "+v+" character"+(v == 1 ? '' : 's')+"."
  : type == 'type'       ? " did not match type "+v+"."
  : type == 'had_error'  ? " had no error (but should have had)."
  : type == 'was_valid'  ? " was not valid."
  : type == 'was_checked'? " was not checked."
  : alert("Missing error on field "+field+" for type "+type+dig));
}

//

function eob_as_string (extra) {
 var joiner = v_find_val('as_string_join',   extra, this.extra, '\n');
 var header = v_find_val('as_string_header', extra, this.extra, '');
 var footer = v_find_val('as_string_footer', extra, this.extra, '');
 return header + this.as_array(extra).join(joiner) + footer;
}

function eob_as_array (extra) {
 var errors = this.errors;
 var title  = v_find_val('as_array_title', extra, this.extra, 'Please correct the following items:');

 var has_headings;
 if (title) has_headings = 1;
 else for (var i = 0; i < errors.length; i++) if (typeof(errors[i]) == 'string') has_headings = 1;

 var prefix = v_find_val('as_array_prefix', extra, this.extra, (has_headings ? '  ' : ''));

 var arr = [];
 if (title && title.length) arr.push(title);

 var found = {};
 for (var i = 0; i < errors.length; i++) {
  if (typeof(errors[i]) == 'string') {
   arr.push(errors[i]);
   found = {};
  } else {
   var text = v_get_error_text(errors[i], extra, this.extra);
   if (found[text]) continue;
   found[text] = 1;
   arr.push(prefix + text);
  }
 }

 return arr;
}

function eob_as_hash (extra) {
 var errors = this.errors;
 var suffix = v_find_val('as_hash_suffix', extra, this.extra, '_error');
 var joiner = v_find_val('as_hash_join',   extra, this.extra, '<br/>');

 var found = {};
 var ret   = {};
 for (var i = 0; i < errors.length; i++) {
  if (typeof(errors[i]) == 'string') continue;
  if (! errors[i].length) continue;

  var field     = errors[i][0];
  var type      = errors[i][1];
  var field_val = errors[i][2];
  var ifs_match = errors[i][3];

  if (! field) return alert("Missing field name");
  if (field_val['delegate_error']) {
   field = field_val['delegate_error'];
   field = field.replace(/\$(\d+)/g, function (all, N) {
    if (typeof(ifs_match) != 'object'
        || typeof(ifs_match[N]) == 'undefined') return ''
    return ifs_match[N];
   });
  }

  var text = v_get_error_text(errors[i], extra, this.extra);
  if (! found[field]) found[field] = {};
  if (found[field][text]) continue;
  found[field][text] = 1;

  field += suffix;
  if (! ret[field]) ret[field] = [];
  ret[field].push(text);
 }

 if (joiner) {
  var header = v_find_val('as_hash_header', extra, this.extra, '');
  var footer = v_find_val('as_hash_footer', extra, this.extra, '');
  for (var key in ret) {
   if (!ret.hasOwnProperty(key)) continue;
   ret[key] = header + ret[key].join(joiner) + footer;
  }
 }

 return ret;
}

function eob_first_field () {
 for (var i = 0; i < this.errors.length; i++) {
  if (typeof(this.errors[i]) != 'object') continue;
  if (! this.errors[i][0]) continue;
  return this.errors[i][0];
 }
 return;
}

//

document.validate = function (form, val_hash) {
 val_hash = document.load_val_hash(form, val_hash);
 if (typeof(val_hash) == 'undefined') return true;

 if (v_event != 'load') {
  for (var key in v_did_inline) {
   if (!v_did_inline.hasOwnProperty(key)) continue;
   v_inline_error_clear(key, val_hash, form);
  }
 }

 var err_obj = v_validate(form, val_hash);
 if (! err_obj) {
   var f = val_hash['group clear_all_hook'] || document.validate_clear_all_hook;
   if (f) f();
   return true;
 }

 var f = val_hash['group set_all_hook'] || document.validate_set_all_hook;
 if (f) f(err_obj, val_hash, form);

 var field = err_obj.first_field();
 if (field && form[field]) {
   if (form[field].focus) form[field].focus();
   else if (form[field].length && form[field][0].focus) form[field][0].focus();
 }

 if (! val_hash['group no_inline']) {
  var hash = err_obj.as_hash({as_hash_suffix:""});
  for (var key in hash) {
   if (!hash.hasOwnProperty(key)) continue;
   v_inline_error_set(key, hash[key], val_hash, form);
  }
 }

 if (v_event == 'load') {
   return false;
 } else if (! val_hash['group no_confirm']) {
  return confirm(err_obj.as_string()) ? false : true;
 } else if (! val_hash['group no_alert']) {
  alert(err_obj.as_string());
  return false;
 } else if (! val_hash['group no_inline']) {
  return false;
 } else {
  return true;
 }
}

document.load_val_hash = function (form, val_hash) {
 if (! form) return alert('Missing form or form name');
 if (typeof(form) == 'string') {
  if (! document[form]) return alert('No form by name '+form);
  form = document[form];
 }

 if (form.val_hash) return form.val_hash;

 if (typeof(val_hash) != 'object') {
  if (typeof(val_hash) == 'function') {
   val_hash = val_hash(formname);
  } else if (typeof(val_hash) == 'undefined') {
   var el;
   if (typeof(document.validation) != 'undefined') {
    val_hash = document.validation;
   } else if (el = document.getElementById('validation')) {
    val_hash = el.innerHTML.replace(/&lt;/ig,'<').replace(/&gt;/ig,'>').replace(/&amp;/ig,'&');
   } else {
    var order = [];
    var str   = '';
    var yaml  = form.getAttribute('validation');
    if (yaml) {
     if (m = yaml.match(/^( +)/)) yaml = yaml.replace(new RegExp('^'+m[1], 'g'), '');
     yaml = yaml.replace(/\s*$/,'\n');
     str += yaml;
    }
    var m;
    for (var i = 0; i < form.elements.length; i++) {
     var name = form.elements[i].name;
     var yaml = form.elements[i].getAttribute('validation');
     if (! name || ! yaml) continue;
     yaml = yaml.replace(/\s*$/,'\n').replace(/^(.)/mg,' $1').replace(/^( *[^\s&*\[\{])/,'\n$1');
     str += name +':' + yaml;
     order.push(name);
    }
    if (str) val_hash = str + "group order: [" + order.join(', ') + "]\n";
   }
  }
  if (typeof(val_hash) == 'string') {
   if (! document.yaml_load) return;
   document.hide_yaml_errors = (! document.show_yaml_errors);
   if (location.search && location.search.indexOf('show_yaml_errors') != -1)
    document.hide_yaml_errors = 0;
   val_hash = document.yaml_load(val_hash);
   if (document.yaml_error_occured) return;
   val_hash = val_hash[0];
  }
 }

 form.val_hash = val_hash;
 return form.val_hash;
}

document.check_form = function (form, val_hash) {
 if (! form) return alert('Missing form or form name');
 if (typeof(form) == 'string') {
  if (! document[form]) return alert('No form by name '+form);
  form = document[form];
 }

 val_hash = document.load_val_hash(form, val_hash);
 if (! val_hash) return;

 var types = val_hash['group onevent'] || {submit:1};
 if (typeof(types) == 'string') types = types.split(/\s*,\s*/);
 if (typeof(types.length) != 'undefined') {
  var t = {};
  for (var i = 0; i < types.length; i++) t[types[i]] = 1;
  types = t;
 }
 val_hash['group onevent'] = types;

 if (types.change || types.blur) {
  var clean = v_get_ordered_fields(val_hash);
  if (clean.error) return clean.error;
  var h = {};
  _add = function (k, v) { if (! h[k]) h[k] = []; h[k].push(v) };
  for (var i = 0; i < clean.fields.length; i++) {
   var k = clean.fields[i].field;
   var names = v_field_names(form,k);
   if (!names) names = [[k,null]];
    for (var ii = 0; ii < names.length; ii++) {
     var k = names[ii][0];
     var ifs_match = names[ii][1];
     _add(k, [clean.fields[i],k,ifs_match]);
     for (var j in clean.fields[i].deps) {
      if (ifs_match) j = j.replace(/\$(\d+)/g, function (all, N) {
       return (typeof(ifs_match) != 'object' || typeof(ifs_match[N]) == 'undefined') ? '' : ifs_match[N];
      });
      if (j != k) _add(j, [clean.fields[i],k,ifs_match]);
     }
    }
  }
  for (var k in h) {
   if (!h.hasOwnProperty(k)) continue;
   var el = form[k];
   if (! el) return v_error("No form element by the name "+k);
   var _change = !types.change ? 0 : typeof(types.change) == 'object' ? types.change[k] : 1;
   var _blur   = !types.blur   ? 0 : typeof(types.blur)   == 'object' ? types.blur[k]   : 1;
   v_el_attach(el, h[k], form, val_hash, _change, _blur, ifs_match);
  }
 }

 if (types.submit) {
  var orig_submit = form.onsubmit || function () { return true };
  form.onsubmit = function (e) { v_event = 'submit'; return document.validate(this) && orig_submit(e, this) };
 }

 if (types.load) { v_event = 'load'; document.validate(form) }
}

function v_el_attach (el, fvs, form, val_hash, _change, _blur, ifs_match) {
 if (!_change && !_blur) return;
 if (! el.type) {
  if (el.length) for (var i = 0; i < el.length; i++) v_el_attach(el[i], fvs, form, val_hash, _change, _blur);
  return;
 }
 var types = val_hash['group onevent'];
 var func = function () {
  v_event = 'change';
  var e = [];
  var f = {};
  var chk = {};
  for (var i = 0; i < fvs.length; i++) {
   var field_val = fvs[i][0];
   var k = fvs[i][1];
   var ifs_match = fvs[i][2];
   if (! chk[k]) {
    chk[k] = 1;
    val_hash['group was_checked'][k] = 1;
    val_hash['group was_valid'][k]   = 1;
    val_hash['group had_error'][k]   = 0;
   }
   var _e = v_validate_buddy(form, k, field_val, val_hash, ifs_match);
   if (_e.length) {
    val_hash['group had_error'][k] = 1;
    val_hash['group was_valid'][k] = 0;
    for (var j = 0; j < _e.length; j++) e.push(_e[j]);
   }
   if (field_val.delegate_error) {
    k = field_val.delegate_error;
    if (ifs_match) k = k.replace(/\$(\d+)/g, function (all, N) {
     return (typeof(ifs_match) != 'object' || typeof(ifs_match[N]) == 'undefined') ? '' : ifs_match[N];
    });
   }
   f[k] = _e.length ? 0 : 1;
  }
  for (var k in f) if (f[k]) v_inline_error_clear(k, val_hash, form);
  if (! e.length) return;
  e = new ValidateError(e, {});
  e = e.as_hash({as_hash_suffix:"", first_only:(val_hash['group first_only']?1:0)});
  for (var k in e) {
   if (!e.hasOwnProperty(k)) continue;
   v_inline_error_set(k, e[k], val_hash, form);
  }
 };
 if (_blur) el.onblur = func;
 if (_change && ! (''+el).match(/HTMLCollection/)) { // find better way on opera
  var type = el.type ? el.type.toLowerCase() : '';
  if (type.match(/(password|text|textarea)/)) el.onkeyup = func;
  else if (type.match(/(checkbox|radio)/)) el.onclick = func;
  else if (type.match(/(select)/)) el.onchange = func;
 }
}

function v_inline_error_clear (key, val_hash, form) {
   delete(v_did_inline[key]);
   var f = val_hash['group clear_hook'] || document.validate_clear_hook;
   var g = val_hash['group was_valid'] || {};
   if (typeof(f) == 'function') if (f({'key':key, 'val_hash':val_hash, 'form':form, was_valid:g[key], 'event':v_event})) return 1;
   var el = document.getElementById(key + v_find_val('as_hash_suffix', val_hash, '_error'));
   if (el) el.innerHTML = '';
}

function v_inline_error_set (key, val, val_hash, form) {
   v_did_inline[key] = 1;
   var f = val_hash['group set_hook'] || document.validate_set_hook;
   if (typeof(f) == 'function') if (f({'key':key, 'value':val, 'val_hash':val_hash, 'form':form, 'event':v_event})) return 1;
   var el = document.getElementById(key + v_find_val('as_hash_suffix', val_hash, '_error'));
   if (el) el.innerHTML = val;
}
