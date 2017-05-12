#ifndef AWXS_ADMIN_M
#define AWXS_ADMIN_M 1


#define AWXS_BROKERADMINTYPEDEF(x)   ((xsBrokerAdminTypeDef *)SvIV((SV*)SvRV( ST(x) )))
#define AWXS_BROKERLOGCONFIG(x)      ((xsBrokerLogConfig *)SvIV((SV*)SvRV( ST(x) )))
#define AWXS_ACCESSCONTROLLIST(x)    ((xsAccessControlList *)SvIV((SV*)SvRV( ST(x) )))
#define AWXS_SERVERCLIENT(x)         ((xsServerClient *)SvIV((SV*)SvRV( ST(x) )))


#endif /* AWXS_ADMIN_M */
