#include "modules/perl/mod_perl.h"

static mod_perl_perl_dir_config *newPerlConfig(pool *p)
{
    mod_perl_perl_dir_config *cld =
	(mod_perl_perl_dir_config *)
	    palloc(p, sizeof (mod_perl_perl_dir_config));
    cld->obj = Nullsv;
    cld->pclass = "Apache::AuthCASSimple";
    register_cleanup(p, cld, perl_perl_cmd_cleanup, null_cleanup);
    return cld;
}

static void *create_dir_config_sv (pool *p, char *dirname)
{
    return newPerlConfig(p);
}

static void stash_mod_pointer (char *class, void *ptr)
{
    SV *sv = newSV(0);
    sv_setref_pv(sv, NULL, (void*)ptr);
    hv_store(perl_get_hv("Apache::XS_ModuleConfig",TRUE), 
	     class, strlen(class), sv, FALSE);
}

static mod_perl_cmd_info cmd_info_CASServerName = { 
"Apache::AuthCASSimple::CASServerName", "", 
};
static mod_perl_cmd_info cmd_info_CASServerPath = { 
"Apache::AuthCASSimple::CASServerPath", "", 
};
static mod_perl_cmd_info cmd_info_CASServerPort = { 
"Apache::AuthCASSimple::CASServerPort", "", 
};
static mod_perl_cmd_info cmd_info_CASServerNoSSL = { 
"Apache::AuthCASSimple::CASServerNoSSL", "", 
};
static mod_perl_cmd_info cmd_info_CASCaFile = { 
"Apache::AuthCASSimple::CASCaFile", "", 
};
static mod_perl_cmd_info cmd_info_CASSessionDirectory = { 
"Apache::AuthCASSimple::CASSessionDirectory", "", 
};
static mod_perl_cmd_info cmd_info_CASSessionTimeout = { 
"Apache::AuthCASSimple::CASSessionTimeout", "", 
};
static mod_perl_cmd_info cmd_info_NOModProxy = { 
"Apache::AuthCASSimple::NOModProxy", "", 
};
static mod_perl_cmd_info cmd_info_CASFixDirectory = { 
"Apache::AuthCASSimple::CASFixDirectory", "", 
};


static command_rec mod_cmds[] = {
    
    { "CASServerName", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_CASServerName,
      OR_AUTHCFG, TAKE1, "URL of the CAS server" },

    { "CASServerPath", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_CASServerPath,
      OR_AUTHCFG, TAKE1, "Path on CAS on the server (default is /)" },

    { "CASServerPort", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_CASServerPort,
      OR_AUTHCFG, TAKE1, "Port the CAS server is listenning on (default is 443)" },

    { "CASServerNoSSL", perl_cmd_perl_NO_ARGS,
      (void*)&cmd_info_CASServerNoSSL,
      OR_AUTHCFG, NO_ARGS, "Disable SSL transaction (HTTPS) with the CAS server" },

    { "CASCaFile", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_CASCaFile,
      OR_AUTHCFG, TAKE1, "Location of the CAS server public key" },

    { "CASSessionDirectory", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_CASSessionDirectory,
      OR_AUTHCFG, TAKE1, "Directory where session data are stored" },

    { "CASSessionTimeout", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_CASSessionTimeout,
      OR_AUTHCFG, TAKE1, "Timeout (in second) for session create by Apache::AuthCASSimple" },

    { "NOModProxy", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_NOModProxy,
      OR_AUTHCFG, TAKE1, "Apache mod_perl don't be use with mod_proxy. Default is off." },
	  
    { "CASFixDirectory", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_CASFixDirectory,
      OR_AUTHCFG, TAKE1, "Force the path for the session cookie for same policy for all subdirectories" },

    { NULL }
};

module MODULE_VAR_EXPORT XS_Apache__AuthCASSimple = {
    STANDARD_MODULE_STUFF,
    NULL,               /* module initializer */
    create_dir_config_sv,  /* per-directory config creator */
    NULL,   /* dir config merger */
    NULL,       /* server config creator */
    NULL,        /* server config merger */
    mod_cmds,               /* command table */
    NULL,           /* [7] list of handlers */
    NULL,  /* [2] filename-to-URI translation */
    NULL,      /* [5] check/validate user_id */
    NULL,       /* [6] check user_id is valid *here* */
    NULL,     /* [4] check access by host address */
    NULL,       /* [7] MIME type checker/setter */
    NULL,        /* [8] fixups */
    NULL,             /* [10] logger */
    NULL,      /* [3] header parser */
    NULL,         /* process initializer */
    NULL,         /* process exit/cleanup */
    NULL,   /* [1] post read_request handling */
};

#define this_module "Apache/AuthCASSimple.pm"

static void remove_module_cleanup(void *data)
{
    if (find_linked_module("Apache::AuthCASSimple")) {
        /* need to remove the module so module index is reset */
        remove_module(&XS_Apache__AuthCASSimple);
    }
    if (data) {
        /* make sure BOOT section is re-run on restarts */
        (void)hv_delete(GvHV(incgv), this_module,
                        strlen(this_module), G_DISCARD);
         if (dowarn) {
             /* avoid subroutine redefined warnings */
             perl_clear_symtab(gv_stashpv("Apache::AuthCASSimple", FALSE));
         }
    }
}

MODULE = Apache::AuthCASSimple		PACKAGE = Apache::AuthCASSimple

PROTOTYPES: DISABLE

BOOT:
    XS_Apache__AuthCASSimple.name = "Apache::AuthCASSimple";
    add_module(&XS_Apache__AuthCASSimple);
    stash_mod_pointer("Apache::AuthCASSimple", &XS_Apache__AuthCASSimple);
    register_cleanup(perl_get_startup_pool(), (void *)1,
                     remove_module_cleanup, null_cleanup);

void
END()

    CODE:
    remove_module_cleanup(NULL);
