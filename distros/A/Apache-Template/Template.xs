#include "modules/perl/mod_perl.h"

static mod_perl_perl_dir_config *newPerlConfig(pool *p)
{
    mod_perl_perl_dir_config *cld =
	(mod_perl_perl_dir_config *)
	    palloc(p, sizeof (mod_perl_perl_dir_config));
    cld->obj = Nullsv;
    cld->pclass = "Apache::Template";
    register_cleanup(p, cld, perl_perl_cmd_cleanup, null_cleanup);
    return cld;
}

static void *create_dir_config_sv (pool *p, char *dirname)
{
    return newPerlConfig(p);
}

static void *create_srv_config_sv (pool *p, server_rec *s)
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

static mod_perl_cmd_info cmd_info_TT2Tags = { 
"Apache::Template::TT2Tags", "", 
};
static mod_perl_cmd_info cmd_info_TT2PreChomp = { 
"Apache::Template::TT2PreChomp", "", 
};
static mod_perl_cmd_info cmd_info_TT2PostChomp = { 
"Apache::Template::TT2PostChomp", "", 
};
static mod_perl_cmd_info cmd_info_TT2Trim = { 
"Apache::Template::TT2Trim", "", 
};
static mod_perl_cmd_info cmd_info_TT2AnyCase = { 
"Apache::Template::TT2AnyCase", "", 
};
static mod_perl_cmd_info cmd_info_TT2Interpolate = { 
"Apache::Template::TT2Interpolate", "", 
};
static mod_perl_cmd_info cmd_info_TT2IncludePath = { 
"Apache::Template::TT2IncludePath", "", 
};
static mod_perl_cmd_info cmd_info_TT2Absolute = { 
"Apache::Template::TT2Absolute", "", 
};
static mod_perl_cmd_info cmd_info_TT2Relative = { 
"Apache::Template::TT2Relative", "", 
};
static mod_perl_cmd_info cmd_info_TT2Delimiter = { 
"Apache::Template::TT2Delimiter", "", 
};
static mod_perl_cmd_info cmd_info_TT2PreProcess = { 
"Apache::Template::TT2PreProcess", "", 
};
static mod_perl_cmd_info cmd_info_TT2PostProcess = { 
"Apache::Template::TT2PostProcess", "", 
};
static mod_perl_cmd_info cmd_info_TT2Process = { 
"Apache::Template::TT2Process", "", 
};
static mod_perl_cmd_info cmd_info_TT2Wrapper = { 
"Apache::Template::TT2Wrapper", "", 
};
static mod_perl_cmd_info cmd_info_TT2Default = { 
"Apache::Template::TT2Default", "", 
};
static mod_perl_cmd_info cmd_info_TT2Error = { 
"Apache::Template::TT2Error", "", 
};
static mod_perl_cmd_info cmd_info_TT2Tolerant = { 
"Apache::Template::TT2Tolerant", "", 
};
static mod_perl_cmd_info cmd_info_TT2Variable = { 
"Apache::Template::TT2Variable", "", 
};
static mod_perl_cmd_info cmd_info_TT2Constant = { 
"Apache::Template::TT2Constant", "", 
};
static mod_perl_cmd_info cmd_info_TT2ConstantsNamespace = { 
"Apache::Template::TT2ConstantsNamespace", "", 
};
static mod_perl_cmd_info cmd_info_TT2EvalPerl = { 
"Apache::Template::TT2EvalPerl", "", 
};
static mod_perl_cmd_info cmd_info_TT2LoadPerl = { 
"Apache::Template::TT2LoadPerl", "", 
};
static mod_perl_cmd_info cmd_info_TT2Recursion = { 
"Apache::Template::TT2Recursion", "", 
};
static mod_perl_cmd_info cmd_info_TT2PluginBase = { 
"Apache::Template::TT2PluginBase", "", 
};
static mod_perl_cmd_info cmd_info_TT2AutoReset = { 
"Apache::Template::TT2AutoReset", "", 
};
static mod_perl_cmd_info cmd_info_TT2CacheSize = { 
"Apache::Template::TT2CacheSize", "", 
};
static mod_perl_cmd_info cmd_info_TT2CompileExt = { 
"Apache::Template::TT2CompileExt", "", 
};
static mod_perl_cmd_info cmd_info_TT2CompileDir = { 
"Apache::Template::TT2CompileDir", "", 
};
static mod_perl_cmd_info cmd_info_TT2Debug = { 
"Apache::Template::TT2Debug", "", 
};
static mod_perl_cmd_info cmd_info_TT2Headers = { 
"Apache::Template::TT2Headers", "", 
};
static mod_perl_cmd_info cmd_info_TT2Params = { 
"Apache::Template::TT2Params", "", 
};
static mod_perl_cmd_info cmd_info_TT2ContentType = { 
"Apache::Template::TT2ContentType", "", 
};
static mod_perl_cmd_info cmd_info_TT2ServiceModule = { 
"Apache::Template::TT2ServiceModule", "", 
};


static command_rec mod_cmds[] = {
    
    { "TT2Tags", perl_cmd_perl_TAKE12,
      (void*)&cmd_info_TT2Tags,
      RSRC_CONF | ACCESS_CONF, TAKE12, "tag style or start and end tags for template directives" },

    { "TT2PreChomp", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2PreChomp,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to remove newline and whitespace before directives" },

    { "TT2PostChomp", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2PostChomp,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to remove newline and whitespace after directives" },

    { "TT2Trim", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2Trim,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to trim whitespace surrounding template output" },

    { "TT2AnyCase", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2AnyCase,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to allow directive keywords in any case" },

    { "TT2Interpolate", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2Interpolate,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to interpolate embedded variable references" },

    { "TT2IncludePath", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_TT2IncludePath,
      RSRC_CONF | ACCESS_CONF, ITERATE, "local path(s) containing templates" },

    { "TT2Absolute", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2Absolute,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to enable absolute filenames" },

    { "TT2Relative", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2Relative,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to enable relative filenames" },

    { "TT2Delimiter", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2Delimiter,
      RSRC_CONF | ACCESS_CONF, TAKE1, "alternative directory delimiter" },

    { "TT2PreProcess", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_TT2PreProcess,
      RSRC_CONF | ACCESS_CONF, ITERATE, "template(s) to process before each main template" },

    { "TT2PostProcess", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_TT2PostProcess,
      RSRC_CONF | ACCESS_CONF, ITERATE, "template(s) to process after each main template" },

    { "TT2Process", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_TT2Process,
      RSRC_CONF | ACCESS_CONF, ITERATE, "template(s) to process instead of each main template" },

    { "TT2Wrapper", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_TT2Wrapper,
      RSRC_CONF | ACCESS_CONF, ITERATE, "template(s) to wrap around each main template" },

    { "TT2Default", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2Default,
      RSRC_CONF | ACCESS_CONF, TAKE1, "default template to process when another template is not found" },

    { "TT2Error", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2Error,
      RSRC_CONF | ACCESS_CONF, TAKE1, "template to process when an uncaught error occurs" },

    { "TT2Tolerant", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2Tolerant,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to set error tolerance for providers" },

    { "TT2Variable", perl_cmd_perl_TAKE2,
      (void*)&cmd_info_TT2Variable,
      RSRC_CONF | ACCESS_CONF, TAKE2, "define a template variable" },

    { "TT2Constant", perl_cmd_perl_TAKE2,
      (void*)&cmd_info_TT2Constant,
      RSRC_CONF | ACCESS_CONF, TAKE2, "define a constant variable" },

    { "TT2ConstantsNamespace", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2ConstantsNamespace,
      RSRC_CONF | ACCESS_CONF, TAKE1, "define variable namespace for constants" },

    { "TT2EvalPerl", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2EvalPerl,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to allow PERL blocks to be evaluated" },

    { "TT2LoadPerl", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2LoadPerl,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to allow regular Perl modules to be loaded as plugins" },

    { "TT2Recursion", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2Recursion,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to enable recursion into templates" },

    { "TT2PluginBase", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_TT2PluginBase,
      RSRC_CONF | ACCESS_CONF, ITERATE, "packages in which to locate for plugins" },

    { "TT2AutoReset", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2AutoReset,
      RSRC_CONF | ACCESS_CONF, TAKE1, "flag to reset (clear) any BLOCK definitions before processing" },

    { "TT2CacheSize", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2CacheSize,
      RSRC_CONF | ACCESS_CONF, TAKE1, "integer limit to the number of compiled templates to cache in memory" },

    { "TT2CompileExt", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2CompileExt,
      RSRC_CONF | ACCESS_CONF, TAKE1, "filename extension for caching compiled templates back to disk" },

    { "TT2CompileDir", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2CompileDir,
      RSRC_CONF | ACCESS_CONF, TAKE1, "path to directory for caching compiled templates back to disk" },

    { "TT2Debug", perl_cmd_perl_FLAG,
      (void*)&cmd_info_TT2Debug,
      RSRC_CONF | ACCESS_CONF, FLAG, "flag to enable debugging" },

    { "TT2Headers", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_TT2Headers,
      RSRC_CONF | ACCESS_CONF, ITERATE, "list of keywords indicating HTTP headers to add" },

    { "TT2Params", perl_cmd_perl_ITERATE,
      (void*)&cmd_info_TT2Params,
      RSRC_CONF | ACCESS_CONF, ITERATE, "list of keywords indicating parameters to add as template variables" },

    { "TT2ContentType", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2ContentType,
      RSRC_CONF | ACCESS_CONF, TAKE1, "content type of generated response (default: text/html)" },

    { "TT2ServiceModule", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_TT2ServiceModule,
      RSRC_CONF | ACCESS_CONF, TAKE1, "name of class which implements template service module" },

    { NULL }
};

module MODULE_VAR_EXPORT XS_Apache__Template = {
    STANDARD_MODULE_STUFF,
    NULL,               /* module initializer */
    create_dir_config_sv,  /* per-directory config creator */
    perl_perl_merge_dir_config,   /* dir config merger */
    create_srv_config_sv,       /* server config creator */
    perl_perl_merge_srv_config,        /* server config merger */
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

#define this_module "Apache/Template.pm"

static void remove_module_cleanup(void *data)
{
    if (find_linked_module("Apache::Template")) {
        /* need to remove the module so module index is reset */
        remove_module(&XS_Apache__Template);
    }
    if (data) {
        /* make sure BOOT section is re-run on restarts */
        (void)hv_delete(GvHV(incgv), this_module,
                        strlen(this_module), G_DISCARD);
         if (dowarn) {
             /* avoid subroutine redefined warnings */
             perl_clear_symtab(gv_stashpv("Apache::Template", FALSE));
         }
    }
}

MODULE = Apache::Template		PACKAGE = Apache::Template

PROTOTYPES: DISABLE

BOOT:
    XS_Apache__Template.name = "Apache::Template";
    add_module(&XS_Apache__Template);
    stash_mod_pointer("Apache::Template", &XS_Apache__Template);
    register_cleanup(perl_get_startup_pool(), (void *)1,
                     remove_module_cleanup, null_cleanup);

void
END()

    CODE:
    remove_module_cleanup(NULL);
