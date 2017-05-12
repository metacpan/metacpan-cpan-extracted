#include "modules/perl/mod_perl.h"

static mod_perl_perl_dir_config *newPerlConfig(pool *p)
{
    mod_perl_perl_dir_config *cld =
	(mod_perl_perl_dir_config *)
	    palloc(p, sizeof (mod_perl_perl_dir_config));
    cld->obj = Nullsv;
    cld->pclass = "Apache::Imager::Resize";
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

static mod_perl_cmd_info cmd_info_ImgResizeNoCache = { 
"Apache::Imager::Resize::ImgResizeNoCache", "", 
};
static mod_perl_cmd_info cmd_info_ImgResizeCacheDir = { 
"Apache::Imager::Resize::ImgResizeCacheDir", "", 
};
static mod_perl_cmd_info cmd_info_ImgResizeWidthParam = { 
"Apache::Imager::Resize::ImgResizeWidthParam", "", 
};
static mod_perl_cmd_info cmd_info_ImgResizeHeightParam = { 
"Apache::Imager::Resize::ImgResizeHeightParam", "", 
};


static command_rec mod_cmds[] = {
    
    { "ImgResizeNoCache", perl_cmd_perl_FLAG,
      (void*)&cmd_info_ImgResizeNoCache,
      RSRC_CONF|ACCESS_CONF, FLAG, "If true, the image cache is disabled." },

    { "ImgResizeCacheDir", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_ImgResizeCacheDir,
      RSRC_CONF|ACCESS_CONF, TAKE1, "The (optional) directory that will be used for the cache of resized image files." },

    { "ImgResizeWidthParam", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_ImgResizeWidthParam,
      RSRC_CONF|ACCESS_CONF, TAKE1, "The (optional) name of the width parameter." },

    { "ImgResizeHeightParam", perl_cmd_perl_TAKE1,
      (void*)&cmd_info_ImgResizeHeightParam,
      RSRC_CONF|ACCESS_CONF, TAKE1, "The (optional) name of the height parameter." },

    { NULL }
};

module MODULE_VAR_EXPORT XS_Apache__Imager__Resize = {
    STANDARD_MODULE_STUFF,
    NULL,               /* module initializer */
    create_dir_config_sv,  /* per-directory config creator */
    NULL,   /* dir config merger */
    create_srv_config_sv,       /* server config creator */
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

#define this_module "Apache/Imager/Resize.pm"

static void remove_module_cleanup(void *data)
{
    if (find_linked_module("Apache::Imager::Resize")) {
        /* need to remove the module so module index is reset */
        remove_module(&XS_Apache__Imager__Resize);
    }
    if (data) {
        /* make sure BOOT section is re-run on restarts */
        (void)hv_delete(GvHV(incgv), this_module,
                        strlen(this_module), G_DISCARD);
         if (dowarn) {
             /* avoid subroutine redefined warnings */
             perl_clear_symtab(gv_stashpv("Apache::Imager::Resize", FALSE));
         }
    }
}

MODULE = Apache::Imager::Resize		PACKAGE = Apache::Imager::Resize

PROTOTYPES: DISABLE

BOOT:
    XS_Apache__Imager__Resize.name = "Apache::Imager::Resize";
    add_module(&XS_Apache__Imager__Resize);
    stash_mod_pointer("Apache::Imager::Resize", &XS_Apache__Imager__Resize);
    register_cleanup(perl_get_startup_pool(), (void *)1,
                     remove_module_cleanup, null_cleanup);

void
END()

    CODE:
    remove_module_cleanup(NULL);
