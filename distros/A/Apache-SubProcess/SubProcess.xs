#include "mod_perl.h" 

typedef struct {
    SV *cv;
    request_rec *r;
} subprocess_info;

enum io_hook_type { 
    io_hook_read,
    io_hook_write,
}; 

static FILE *io_dup(FILE *fp, char *mode)
{
    int fd = PerlIO_fileno(fp);
    FILE *retval;

    fd = PerlLIO_dup(fd); 
    if (!(retval = PerlIO_fdopen(fd, mode))) { 
	PerlLIO_close(fd);
	croak("fdopen failed!");
    } 

    return retval;
}

static SV *io_hook(FILE *fp, enum io_hook_type type)
{
    SV *RETVAL = mod_perl_gensym("Apache::SubProcess"); 
    GV *gv = (GV*)SvRV(RETVAL); 

    gv_IOadd(gv); 

    switch (type) {
    case io_hook_write:
	IoOFP(GvIOp(gv)) = io_dup(fp, "w");
	IoFLAGS(GvIOp(gv)) |= IOf_FLUSH;
	break;
    default:
	IoIFP(GvIOp(gv)) = io_dup(fp, "r");
    };

    return sv_2mortal(RETVAL);
}

static int subprocess_child(void *ptr, child_info *pinfo) 
{
    int count;
    subprocess_info *info = (subprocess_info *)ptr;
    dSP;

    info->r->request_config = (void*)pinfo;
    ENTER;SAVETMPS;
    PUSHMARK(sp); 
    XPUSHs(perl_bless_request_rec(info->r));
    PUTBACK; 
    count = perl_call_sv(info->cv, G_EVAL | G_SCALAR); 
    if(perl_eval_ok(info->r->server) != OK) {
	fprintf(stderr, "FAIL: %s\n", SvPV(ERRSV,na));
    }
    /*
    SPAGAIN; 

    PUTBACK; 
    */
    FREETMPS;LEAVE; 

}

MODULE = Apache::SubProcess   PACKAGE = Apache    PREFIX = ap_

PROTOTYPES: DISABLE 
 
BOOT: 
    items = items; /*avoid warning*/  

void
ap_spawn_child(r, cvrv)
    Apache r
    SV *cvrv

    PREINIT:
    FILE *ioip, *ioop, *ioep;
    subprocess_info *info;

    PPCODE:
    info = (subprocess_info *)ap_pcalloc(r->pool, sizeof(subprocess_info));
    info->cv = cvrv;
    info->r  = r;
    if (!ap_spawn_child(r->pool, subprocess_child, 
			(void *)info, kill_after_timeout, 
			&ioip, &ioop, &ioep)) { 
        ap_log_error(APLOG_MARK, APLOG_ERR, r->server, 
                     "couldn't spawn child process: %s", r->filename); 
    } 

    if (GIMME == G_SCALAR) {
	XPUSHs(io_hook(ioop, io_hook_read));
    }
    else {
	XPUSHs(io_hook(ioip, io_hook_write));
	XPUSHs(io_hook(ioop, io_hook_read));
	XPUSHs(io_hook(ioep, io_hook_read));
    }

int
ap_call_exec(r, pgm=r->filename)
    Apache r
    char *pgm

    PREINIT:
    char **env;

    CODE:
    env = ap_create_environment(r->pool, r->subprocess_env);  
    ap_error_log2stderr(r->server);  
    ap_cleanup_for_exec();  
    RETVAL = ap_call_exec(r, (child_info *)r->request_config, pgm, env, 0);  

    ap_log_error(APLOG_MARK, APLOG_ERR, NULL,
    "Apache::SubProcess exec of %s failed", pgm);
    exit(0);  

    OUTPUT:
    RETVAL

void
pfclose(r, sv)
    Apache r
    SV *sv

    PREINIT:
    IO *iop;

    CODE:
    iop = sv_2io(sv);
    ap_pfclose(r->pool, IoIFP(iop));
    IoIFP(iop) = NULL;

void
cleanup_for_exec(r=NULL)
    Apache r

    CODE:
    ap_cleanup_for_exec();
