#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "AntTweakBar.h"
#include "SDL.h"

#define CONSTANT(NAME) newCONSTSUB(stash, #NAME, newSViv((int)NAME))

void TW_CALL _int_getter(void* value, void* data);
void TW_CALL _int_setter(const void* value, void* data);
void TW_CALL _int_getter_cb(void* value, void* data);
void TW_CALL _int_setter_cb(const void* value, void* data);

static HV * _btn_callback_mapping = NULL;
static HV * _type_map = NULL;
static HV * _getters_map = NULL;
static HV * _setters_map = NULL;
static HV * _getters_cb_map = NULL;
static HV * _setters_cb_map = NULL;
static HV * _cb_marker_map = NULL;
static HV * _cb_read_map = NULL;
static HV * _cb_write_map = NULL;
static HV * _sv_copy_names = NULL;
static SV* _modifiers_callback = NULL;

static void _add_type(const char* name, TwType type,
		      TwGetVarCallback getter, TwSetVarCallback setter,
		      TwGetVarCallback getter_cb, TwSetVarCallback setter_cb) {
  dTHX;
  hv_store(_type_map, name, strlen(name), newSViv(type), 0);
  hv_store(_getters_map, name, strlen(name), newSViv(PTR2IV(getter)), 0);
  hv_store(_setters_map, name, strlen(name), newSViv(PTR2IV(setter)), 0);
  hv_store(_getters_cb_map, name, strlen(name), newSViv(PTR2IV(getter_cb)), 0);
  hv_store(_setters_cb_map, name, strlen(name), newSViv(PTR2IV(setter_cb)), 0);
}

int _disabled_lib_mode() {
  dTHX;
  HV* env = get_hv("main::ENV", 0);
  const char* env_flag = "ANTTWEAKBAR_DISABLE_LIB";
  int marker = hv_exists(env, env_flag, strlen(env_flag));
  return marker;
}

void init(TwGraphAPI graphic_api) {
  dTHX;
  int result = TwInit(TW_OPENGL, NULL);
  if(!result)
    Perl_croak(aTHX_ "Initialization error: %s", TwGetLastError());
}

void terminate() {
  dTHX;
  int result = TwTerminate();
  if(!result)
    Perl_croak( aTHX_ "Termination error: %s", TwGetLastError());
}

void window_size(int width, int height) {
  dTHX;
  int result = TwWindowSize(width, height);
  if(!result)
    Perl_croak(aTHX_ "Set window size error: %s", TwGetLastError());
}

TwBar* _create(const char *name) {
  if(_disabled_lib_mode()) return (TwBar*)-1;
  return TwNewBar(name);
}

void _destroy(TwBar* bar) {
  dTHX;
  if(_disabled_lib_mode()) return;
  int result = TwDeleteBar(bar);
  if(!result)
    Perl_croak(aTHX_ "AntTweakBar deletion error: %s", TwGetLastError());
}

void draw() {
  dTHX;
  int result = TwDraw();
  if(!result)
    Perl_croak(aTHX_ "AntTweakBar drawing error: %s", TwGetLastError());
}

void _button_callback_bridge(void *data) {
  dTHX;
  dSP;
  SV* callback = (SV*) data;
  PUSHMARK(SP);
  call_sv(callback, G_NOARGS|G_DISCARD|G_VOID);
}

void _add_button(TwBar* bar, const char *name, SV* callback, const char *definition) {
  dTHX;
  SvGETMAGIC(callback);
  if(!SvROK(callback)
     || (SvTYPE(SvRV(callback)) != SVt_PVCV))
  {
    croak("Callback for _add_button should be a closure...\n");
  }
  if(!_btn_callback_mapping) _btn_callback_mapping = newHV();
  SV* callback_copy = newSVsv(callback);

  int result = TwAddButton(bar, name, (TwButtonCallback)_button_callback_bridge, (void*) callback_copy, definition);
  if(!result)
    Perl_croak(aTHX_ "Button addition error: %s", TwGetLastError());
  hv_store(_btn_callback_mapping, (char*)callback_copy, sizeof(callback_copy), callback_copy, 0);
}

void _add_separator(TwBar* bar, const char *name, const char *definition) {
  dTHX;
  int result = TwAddSeparator(bar, name, definition);
  if(!result)
    Perl_croak(aTHX_ "Separator addition error: %s", TwGetLastError());
}

/* returns 1 if it has been handled by AntTweekBar */
int eventMouseButtonGLUT(int button, int state, int x, int y){
  return TwEventMouseButtonGLUT(button, state, x, y);
}

/* returns 1 if it has been handled by AntTweekBar */
int eventMouseMotionGLUT(int mouseX, int mouseY){
  return TwEventMouseMotionGLUT(mouseX, mouseY);
}

/* returns 1 if it has been handled by AntTweekBar */
int eventKeyboardGLUT(unsigned char key, int mouseX, int mouseY) {
  return TwEventKeyboardGLUT(key, mouseX, mouseY);
}

/* returns 1 if it has been handled by AntTweekBar */
int eventSpecialGLUT(int key, int mouseX, int mouseY) {
  return TwEventSpecialGLUT(key, mouseX, mouseY);
}

int eventSDL(SDL_Event* event){
  return TwEventSDL(event, SDL_MAJOR_VERSION, SDL_MINOR_VERSION);
}

int TW_CALL _modifiers_callback_bridge(void){
  dTHX;
  if(!_modifiers_callback){
    croak("internal error: no _modifiers_callback\n");
    return -1;
  }
  dSP;
  PUSHMARK(SP);
  call_sv(_modifiers_callback, G_NOARGS|G_DISCARD|G_VOID);
}

int GLUTModifiersFunc(SV* callback){
  dTHX;
  SvGETMAGIC(callback);
  if(!SvROK(callback)
     || (SvTYPE(SvRV(callback)) != SVt_PVCV))
  {
    croak("Callback for GLUTModifiersFunc should be a closure...\n");
  }
  if(_modifiers_callback) {
     SvREFCNT_dec(_modifiers_callback);
  }
  _modifiers_callback = newSVsv(callback);
  return TwGLUTModifiersFunc(&_modifiers_callback_bridge);
}

void _add_variable(TwBar* bar, const char* mode, const char* name,
		   const char* type, SV* value_ref,
		   SV* cb_read, SV* cb_write, const char* definition) {
  dTHX;
  SV** sv_type_ref = hv_fetch(_type_map, type, strlen(type), 0);
  TwType tw_type;
  if(sv_type_ref) {
    tw_type = (TwType) SvIV(*sv_type_ref);
  } else {
    Perl_croak(aTHX_ "Undefined var type: %s", type);
  }

  SV** getter_ref;
  SV** setter_ref = NULL;

  SV* cb_or_value;
  if(SvOK(value_ref) && SvROK(value_ref)){
    cb_or_value = newSVsv(value_ref);
    getter_ref = hv_fetch(_getters_map, type, strlen(type), 0);
    hv_store(_sv_copy_names, name, strlen(name), cb_or_value, 0);
    if(strcmp(mode, "rw") == 0) {
      setter_ref = hv_fetch(_setters_map, type, strlen(type), 0);
    }
  } else {
    cb_or_value = newSVpv(name, 0);
    getter_ref = hv_fetch(_getters_cb_map, type, strlen(type), 0);
    if(strcmp(mode, "rw") == 0) {
      setter_ref = hv_fetch(_setters_cb_map, type, strlen(type), 0);
    }
    hv_store(_cb_marker_map, name, strlen(name), cb_or_value, 0);
    hv_store(_cb_read_map, (char*)cb_or_value, sizeof(SV*), newSVsv(cb_read), 0);
    if(SvROK(cb_write))
      hv_store(_cb_write_map, (char*)cb_or_value, sizeof(SV*), newSVsv(cb_write), 0);
  }

  IV iv_getter = SvIV(*getter_ref);
  TwGetVarCallback tw_getter = (TwGetVarCallback) INT2PTR(IV, iv_getter);
  TwSetVarCallback tw_setter = NULL;
  if(setter_ref) {
    IV iv_setter = SvIV(*setter_ref);
    tw_setter = (TwSetVarCallback) INT2PTR(IV, iv_setter);
  }

  if(_disabled_lib_mode()) return;
  int result = TwAddVarCB(bar, name, tw_type, tw_setter, tw_getter,
			  cb_or_value, definition);
  if(!result){
    hv_delete(_sv_copy_names, name, strlen(name), 0);
    hv_delete(_cb_marker_map, name, strlen(name), 0);
    Perl_croak(aTHX_ "Variable addition error: %s", TwGetLastError());
  }
}

void _remove_variable(TwBar* bar, const char* name) {
  dTHX;
  SV* cb_or_value =
	  hv_exists(_sv_copy_names, name, strlen(name))
	  ? hv_delete(_sv_copy_names, name, strlen(name), 0)
	  : hv_exists(_cb_marker_map, name, strlen(name))
	  ? hv_delete(_cb_marker_map, name, strlen(name), 0)
	  : NULL;
  if(!cb_or_value) {
    Perl_croak(aTHX_ "No variable with name '%s'", name);
  }
  if(_disabled_lib_mode()) return;
  int result = TwRemoveVar(bar, name);
  if(!result)
    Perl_croak(aTHX_ "Removing variable %s error: %s", name, TwGetLastError());
}

TwType _register_enum(const char* name, SV* hash_ref){
  dTHX;
  if(!SvOK(hash_ref) || !SvROK(hash_ref)){
    Perl_croak(aTHX_ "Hashref cannot be undefined");
  }
  HV* hv =(HV*) SvRV(hash_ref);
  HE* entry;
  U32 total_keys = 0;
  hv_iterinit(hv);
  while((entry = hv_iternext(hv)) != NULL){
    I32 key_length;
    char* key = hv_iterkey(entry, &key_length);
    SV* sv_index = hv_iterval(hv, entry);
    if(sv_index && SvOK(sv_index)){
      total_keys++;
    }
  }
  TwEnumVal* enum_values = (TwEnumVal*) malloc(sizeof(TwEnumVal) * total_keys);
  TwEnumVal* enum_ptr = enum_values;
  while((entry = hv_iternext(hv)) != NULL){
    I32 key_length;
    char* key = hv_iterkey(entry, &key_length);
    SV* sv_label = hv_iterval(hv, entry);
    if(sv_label && SvOK(sv_label)){
      const char* label = SvPV_nolen(sv_label);
      (*enum_ptr).Value = atoi(key);
      (*enum_ptr).Label = label;
      enum_ptr++;
    }
  }
  TwType new_type = !_disabled_lib_mode()
    ? TwDefineEnum(name, enum_values, total_keys)
    : TW_TYPE_UNDEF;
  _add_type(name, new_type, &_int_getter, &_int_setter, &_int_getter_cb, &_int_setter_cb);
  free(enum_values);
  return new_type;
}

void _refresh(TwBar* bar){
  dTHX;
  int result = TwRefreshBar(bar);
  if(!result)
    Perl_croak(aTHX_ "Refreshing error: %s", TwGetLastError());
}

void _set_bar_parameter(TwBar* bar, const char* param_name, const char* param_value) {
  dTHX;
  int result = TwSetParam(bar, NULL, param_name, TW_PARAM_CSTRING, 1, param_value);
  if(!result)
    Perl_croak(aTHX_ "Error applying value '%s' to parameter %s : %s",
	       param_value, param_name, TwGetLastError());
}

void _set_variable_parameter(TwBar* bar, const char* variable, 
			     const char* param_name, const char* param_value) {
  dTHX;
  int result = TwSetParam(bar, variable, param_name, TW_PARAM_CSTRING, 1, param_value);
  if(!result)
    Perl_croak(aTHX_ "Error applying value '%s' of parameter %s to variable %s : %s",
	       param_value, param_name, variable, TwGetLastError());
}

/* CALLBACKS */
/* int/bool callbacks */

void TW_CALL _int_getter(void* value, void* data){
  dTHX;
  SV* sv = SvRV((SV*) data);
  SvGETMAGIC(sv);
  int iv = SvOK(sv) ? SvIV(sv) : 0;
  *(int*)value = iv;
}

void TW_CALL _int_getter_cb(void* value, void* data){
  dTHX;
  SV** cb = hv_fetch(_cb_read_map, (char*) data, sizeof(SV*), 0);
  dSP;
  PUSHMARK(SP);
  int count = call_sv(*cb, G_NOARGS|G_SCALAR);
  SPAGAIN;
  if (count != 1)
    Perl_croak(aTHX_ "Expected 1 arg to be returned from _int_getter \n");
  SV* sv = POPs;
  *(int*)value = SvOK(sv) ? SvIV(sv) : 0;
}

void TW_CALL _int_setter(const void* value, void* data){
  dTHX;
  SV* sv = SvRV((SV*) data);
  sv_setiv(sv, *(int*)value );
  SvSETMAGIC(sv);
}

void TW_CALL _int_setter_cb(const void* value, void* data){
  dTHX;
  SV** cb = hv_fetch(_cb_write_map, (char*) data, sizeof(SV*), 0);
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSViv(*(int*)value)));
  PUTBACK;
    call_sv(*cb, G_DISCARD);
  FREETMPS;
  LEAVE;
}

/* number(double) callbacks */

void TW_CALL _number_getter(void* value, void* data){
  dTHX;
  SV* sv = SvRV((SV*) data);
  SvGETMAGIC(sv);
  double dv = SvOK(sv) ? SvNV(sv) : 0.0;
  *(double*)value = dv;
}

void TW_CALL _number_setter(const void* value, void* data){
  dTHX;
  SV* sv = SvRV((SV*) data);
  sv_setnv(sv, *(double*)value );
  SvSETMAGIC(sv);
}

void TW_CALL _number_getter_cb(void* value, void* data){
  dTHX;
  SV** cb = hv_fetch(_cb_read_map, (char*) data, sizeof(SV*), 0);
  dSP;
  PUSHMARK(SP);
  int count = call_sv(*cb, G_NOARGS|G_SCALAR);
  SPAGAIN;
  if (count != 1)
    Perl_croak(aTHX_ "Expected 1 arg to be returned from _number_getter_cb \n");
  SV* sv = POPs;
  *(double*)value = SvOK(sv) ? SvNV(sv) : 0.0;
}

void TW_CALL _number_setter_cb(const void* value, void* data){
  dTHX;
  SV** cb = hv_fetch(_cb_write_map, (char*) data, sizeof(SV*), 0);
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVnv(*(double*)value)));
  PUTBACK;
    call_sv(*cb, G_DISCARD);
  FREETMPS;
  LEAVE;
}

/* string callbacks */

void TW_CALL _string_getter(void* value, void* data){
  dTHX;
  SV* sv = SvRV((SV*) data);
  SvGETMAGIC(sv);
  const char* string = SvOK(sv) ? SvPV_nolen(sv) : "";
  *(const char**)value = string;
}

void TW_CALL _string_getter_cb(void* value, void* data){
  dTHX;
  SV** cb = hv_fetch(_cb_read_map, (char*) data, sizeof(SV*), 0);
  dSP;
  PUSHMARK(SP);
  int count = call_sv(*cb, G_NOARGS|G_SCALAR);
  SPAGAIN;
  if (count != 1)
    Perl_croak(aTHX_ "Expected 1 arg to be returned from _string_getter_cb \n");
  SV* sv_string = POPs;
  if(!SvPOK(sv_string)) {
    Perl_croak(aTHX_ "_string_getter_cb got not a string\n");
  }
  *(const char**)value = SvPV_nolen(sv_string);
}

void TW_CALL _string_setter(const void* value, void* data){
  dTHX;
  SV* sv = SvRV((SV*) data);
  const char* string = *(const char**)value;
  printf("set string: %s\n", string);
  sv_force_normal(sv);
  sv_setpv(sv, string);
  SvSETMAGIC(sv);
}

void TW_CALL _string_setter_cb(const void* value, void* data){
  dTHX;
  SV** cb = hv_fetch(_cb_write_map, (char*) data, sizeof(SV*), 0);
  dSP;
  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  XPUSHs(sv_2mortal(newSVpv(*(char**)value, 0)));
  PUTBACK;
    call_sv(*cb, G_DISCARD);
  FREETMPS;
  LEAVE;
}

/* double/float array callback generators */

#define DOUBLE_CALLBACK_GETTER(NAME, NUMBER, TYPE)	 \
void TW_CALL NAME(void* value, void* data) { \
  dTHX; \
  SV* sv = SvRV((SV*) data); \
  if(!(SvTYPE(SvRV(sv)) == SVt_PVAV)){ \
    croak("reference does not point to array any more\n"); \
  } \
  SvGETMAGIC(sv); \
  AV* av = (AV*)SvRV(sv); \
  int my_last = (NUMBER-1); \
  TYPE* values = (TYPE*) value; \
  int i; \
  for(i = 0; i <= my_last; i++) { \
    SV** element = av_fetch(av, i, 0); \
    if(element && SvNOK(*element)) { \
      SvGETMAGIC(*element); \
      values[i] = (TYPE)SvNV(*element); \
    } \
  } \
};

#define DOUBLE_CALLBACK_GETTER_CB(NAME, NUMBER, TYPE) \
void TW_CALL NAME(void* value, void* data) { \
  dTHX;\
  SV** cb = hv_fetch(_cb_read_map, (char*) data, sizeof(SV*), 0); \
  dSP; \
  PUSHMARK(SP); \
  int count = call_sv(*cb, G_NOARGS|G_SCALAR); \
  SPAGAIN; \
  if (count != 1) {\
	char buf[256] = {0}; \
	sprintf(buf, "Expected 1 arg to be returned from %s \n", #NAME); \
	croak(buf); \
  } \
  SV* sv = POPs; \
  if(!(SvTYPE(SvRV(sv)) == SVt_PVAV)){ \
    croak("reference does not point to array any more\n"); \
  } \
  SvGETMAGIC(sv); \
  AV* av = (AV*)SvRV(sv); \
  int my_last = (NUMBER-1);						\
  TYPE* values = (TYPE*) value; \
  int i; \
  for(i = 0; i <= my_last; i++) { \
    SV** element = av_fetch(av, i, 0); \
    if(element && SvNOK(*element)) { \
      SvGETMAGIC(*element); \
      values[i] = (TYPE)SvNV(*element); \
    } \
  } \
};

#define DOUBLE_CALLBACK_SETTER(NAME, NUMBER, TYPE)	 \
void TW_CALL NAME(const void* value, void* data) { \
  dTHX;\
  SV* sv = SvRV((SV*) data); \
  if(!(SvTYPE(SvRV(sv)) == SVt_PVAV)){ \
    croak("reference does not point to array any more\n"); \
  } \
  SvGETMAGIC(sv); \
  AV* av = (AV*)SvRV(sv); \
  int my_last = (NUMBER-1); \
  TYPE* values = (TYPE*) value; \
  int i; \
  for(i = 0; i <= my_last; i++) { \
    SV** element = av_fetch(av, i, 0); \
    if(element) { \
      double value = values[i]; \
      sv_setnv(*element, value); \
      SvGETMAGIC(*element); \
      SvSETMAGIC(sv); \
    } \
  } \
};

#define DOUBLE_CALLBACK_SETTER_CB(NAME, NUMBER, TYPE)	 \
void TW_CALL NAME(const void* value, void* data) { \
  dTHX;\
  SV** cb = hv_fetch(_cb_write_map, (char*) data, sizeof(SV*), 0); \
  dSP; \
  ENTER; \
  SAVETMPS; \
  \
  AV* av = (AV*)sv_2mortal((SV*)newAV()); \
  TYPE* values = (TYPE*) value; \
  int i; \
  for(i = 0; i < NUMBER; i++) { \
    av_push(av, newSVnv(values[i])); \
  } \
  \
  PUSHMARK(SP); \
  XPUSHs(sv_2mortal(newRV_inc((SV*)av))); \
  PUTBACK; \
  \
  call_sv(*cb, G_DISCARD); \
  \
  FREETMPS; \
  LEAVE; \
};


DOUBLE_CALLBACK_GETTER   (_color3f_getter,    3, float);
DOUBLE_CALLBACK_GETTER_CB(_color3f_getter_cb, 3, float);
DOUBLE_CALLBACK_SETTER   (_color3f_setter,    3, float);
DOUBLE_CALLBACK_SETTER_CB(_color3f_setter_cb, 3, float);
DOUBLE_CALLBACK_GETTER   (_color4f_getter,    4, float);
DOUBLE_CALLBACK_GETTER_CB(_color4f_getter_cb, 4, float);
DOUBLE_CALLBACK_SETTER   (_color4f_setter,    4, float);
DOUBLE_CALLBACK_SETTER_CB(_color4f_setter_cb, 4, float);
DOUBLE_CALLBACK_GETTER   (_dir3d_getter,      3, double);
DOUBLE_CALLBACK_GETTER_CB(_dir3d_getter_cb,   3, double);
DOUBLE_CALLBACK_SETTER   (_dir3d_setter,      3, double);
DOUBLE_CALLBACK_SETTER_CB(_dir3d_setter_cb,   3, double);
DOUBLE_CALLBACK_GETTER   (_quat4d_getter,     4, double);
DOUBLE_CALLBACK_GETTER_CB(_quat4d_getter_cb,  4, double);
DOUBLE_CALLBACK_SETTER   (_quat4d_setter,     4, double);
DOUBLE_CALLBACK_SETTER_CB(_quat4d_setter_cb,  4, double);

void _bootstap(){
  dTHX;
  HV *stash = gv_stashpv("AntTweakBar", TRUE);
  CONSTANT(TW_OPENGL);
  CONSTANT(TW_OPENGL_CORE);
  CONSTANT(TW_DIRECT3D9);
  CONSTANT(TW_DIRECT3D10);
  CONSTANT(TW_DIRECT3D11);

  _type_map = newHV();
  _getters_map = newHV();
  _setters_map = newHV();
  _getters_cb_map = newHV();
  _setters_cb_map = newHV();
  _sv_copy_names = newHV();
  _cb_read_map = newHV();
  _cb_write_map = newHV();
  _cb_marker_map = newHV();

  _add_type("bool", TW_TYPE_BOOL32, _int_getter, _int_setter, _int_getter_cb, _int_setter_cb);
  _add_type("integer", TW_TYPE_INT32,  _int_getter, _int_setter, _int_getter_cb, _int_setter_cb);
  _add_type("number", TW_TYPE_DOUBLE,  _number_getter, _number_setter, _number_getter_cb, _number_setter_cb);
  _add_type("string", TW_TYPE_CDSTRING, _string_getter, _string_setter, _string_getter_cb, _string_setter_cb);
  _add_type("color3f", TW_TYPE_COLOR3F, _color3f_getter, _color3f_setter, _color3f_getter_cb, _color3f_setter_cb);
  _add_type("color4f", TW_TYPE_COLOR4F, _color4f_getter, _color4f_setter, _color4f_getter_cb, _color4f_setter_cb);
  _add_type("direction", TW_TYPE_DIR3D, _dir3d_getter, _dir3d_setter, _dir3d_getter_cb, _dir3d_setter_cb);
  _add_type("quaternion", TW_TYPE_QUAT4D, _quat4d_getter, _quat4d_setter, _quat4d_getter_cb, _quat4d_setter_cb);
}

MODULE = AntTweakBar		PACKAGE = AntTweakBar

BOOT:
_bootstap();

void
init(graphic_api)
  TwGraphAPI graphic_api
  PROTOTYPE: $

void
terminate()


TwBar*
_create(name)
  const char *name
  PROTOTYPE: $

void
_destroy(bar)
  TwBar* bar
  PROTOTYPE: $

void
window_size(width, height)
  int width
  int height
  PROTOTYPE: $$

void
_add_button(bar, name, callback, definition)
  TwBar* bar
  const char *name
  SV* callback
  const char *definition
  PROTOTYPE: $$$$

void
_add_separator(bar, name, definition)
  TwBar* bar
  const char *name
  const char *definition
  PROTOTYPE: $$$

void
draw()

int
eventMouseButtonGLUT(button, state, x, y)
  int button
  int state
  int x
  int y
  PROTOTYPE: $$$$

int
eventMouseMotionGLUT(mouseX, mouseY)
  int mouseX
  int mouseY
  PROTOTYPE: $$

int
eventKeyboardGLUT(key, mouseX, mouseY)
  unsigned char key
  int mouseX
  int mouseY
  PROTOTYPE: $$$

int
eventSpecialGLUT(key, mouseX, mouseY)
  int key
  int mouseX
  int mouseY
  PROTOTYPE: $$$

int
GLUTModifiersFunc(callback)
  SV* callback
  PROTOTYPE: $

int
eventSDL(event)
 SDL_Event* event
 PROTOTYPE: $

void
_add_variable(bar, mode, name, type, value, cb_read, cb_write, definition)
  TwBar* bar
  const char* mode
  const char* name
  const char* type
  SV* value
  SV* cb_read
  SV* cb_write
  const char* definition
  PROTOTYPE: $$$$$$$$

void
_remove_variable(bar, name)
  TwBar* bar
  const char* name
  PROTOTYPE: $$$$$$

TwType
_register_enum(name, hash_ref)
  const char* name
  SV* hash_ref
  PROTOTYPE: $$

void
_refresh(bar)
  TwBar* bar
  PROTOTYPE: $

void
_set_bar_parameter(bar, param_name, param_value)
  TwBar* bar
  const char* param_name
  const char* param_value
  PROTOTYPE: $$$

void
_set_variable_parameter(bar, variable, param_name, param_value)
  TwBar* bar
  const char* variable
  const char* param_name
  const char* param_value
  PROTOTYPE: $$$$
