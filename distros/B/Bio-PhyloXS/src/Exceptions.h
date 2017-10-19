#ifndef EXCEPTIONS_H
#define EXCEPTIONS_H

typedef struct {
	char * message;
	char * class_name;
} Exceptions;

//SV* except( char * name, char * message );
//char* error(SV* self);

SV* except(char* name, char* message) {
      char class_name[80];
      strcpy(class_name, "Bio::Phylo::Util::Exceptions::");
      strcat(class_name, name);
      
      Exceptions* exception;
      SV* obj;
      SV* obj_ref;

      Newx(exception, 1, Exceptions);
      exception->message = savepv(message);

      obj = newSViv((IV)exception);
      obj_ref = newRV_noinc(obj);
      sv_bless(obj_ref, gv_stashpv(class_name, GV_ADD));
      SvREADONLY_on(obj);

      return obj_ref;
}

char* error(SV* self) {
	return ((Exceptions*)SvIV(SvRV(self)))->message;
}

#endif
