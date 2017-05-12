#include "mongo_support.h"

MODULE = AnyMongo  PACKAGE = AnyMongo

PROTOTYPES: DISABLE

BOOT:
    gv_fetchpv("AnyMongo::BSON::bson_char",  GV_ADDMULTI, SVt_IV);
    gv_fetchpv("AnyMongo::BSON::utf8_flag_on",  GV_ADDMULTI, SVt_IV);
    gv_fetchpv("AnyMongo::BSON::use_boolean",  GV_ADDMULTI, SVt_IV);

MODULE = AnyMongo  PACKAGE = AnyMongo::BSON
PROTOTYPES: DISABLE

SV*
bson_encode(SV *sv)
    INIT:
        buffer buf;
    CODE:
        CREATE_BUF(INITIAL_BUF_SIZE);
        perl_mongo_sv_to_bson(&buf,sv,NO_PREP);
        RETVAL = newSVpvn(buf.start, buf.pos-buf.start);
        Safefree(buf.start);
    OUTPUT:
        RETVAL

SV *
bson_decode(char *bson)
    INIT:
        buffer buf;
    CODE:
        buf.start = bson;
        buf.end = bson+strlen(bson);
        buf.pos = bson;
        RETVAL = perl_mongo_bson_to_sv(&buf);
    OUTPUT:
        RETVAL

MODULE = AnyMongo  PACKAGE = AnyMongo::BSON::OID

PROTOTYPES: DISABLE

SV *
_build_value (self, c_str)
        SV *self
        const char *c_str;
    PREINIT: 
        char id[12], oid[25];
    CODE:
        if (c_str && strlen(c_str) == 24) {
          memcpy(oid, c_str, 25);
        }
        else {
          perl_mongo_make_id(id);
          perl_mongo_make_oid(id, oid);
        }
        RETVAL = newSVpvn(oid, 24);
    OUTPUT:
        RETVAL

MODULE = AnyMongo  PACKAGE = AnyMongo::MongoSupport
PROTOTYPES: DISABLE

SV*
build_query_message(request_id,ns, opts, skip, limit, query, fields = 0)
         SV *request_id
         char *ns
         int opts
         int skip
         int limit
         SV *query
         SV *fields
     PREINIT:
         buffer buf;
         mongo_msg_header header;
     CODE:
         CREATE_BUF(INITIAL_BUF_SIZE);
         CREATE_HEADER_WITH_OPTS(buf, ns, OP_QUERY, opts);

         perl_mongo_serialize_int(&buf, skip);
         perl_mongo_serialize_int(&buf, limit);

         perl_mongo_sv_to_bson(&buf, query, NO_PREP);

         if (fields && SvROK(fields)) {
           perl_mongo_sv_to_bson(&buf, fields, NO_PREP);
         }
         perl_mongo_serialize_size(buf.start, &buf);
         RETVAL = newSVpvn(buf.start, buf.pos-buf.start);
         Safefree(buf.start);
    OUTPUT:
        RETVAL

void
build_insert_message(request_id,ns, a)
         SV *request_id
         char *ns
         AV *a
     PREINIT:
         buffer buf;
         mongo_msg_header header;
         int i;
         AV *ids = newAV();
     PPCODE:
         CREATE_BUF(INITIAL_BUF_SIZE);
         CREATE_HEADER(buf, ns, OP_INSERT);

         for (i=0; i<=av_len(a); i++) {
           int start = buf.pos-buf.start;
           SV **obj = av_fetch(a, i, 0);
           perl_mongo_sv_to_bson(&buf, *obj, ids);

           if (buf.pos - (buf.start + start) > MAX_OBJ_SIZE) {
             croak("insert is larger than 4 MB: %d bytes", buf.pos - (buf.start + start));
           }

         }
         perl_mongo_serialize_size(buf.start, &buf);

         XPUSHs(sv_2mortal(newSVpvn(buf.start, buf.pos-buf.start)));
         XPUSHs(sv_2mortal(newRV_noinc((SV*)ids)));

         Safefree(buf.start);

SV*
build_remove_message(request_id,ns, criteria, flags)
         SV *request_id;
         char *ns
         SV *criteria
         int flags
     PREINIT:
         buffer buf;
         mongo_msg_header header;
     CODE:
         CREATE_BUF(INITIAL_BUF_SIZE);
         CREATE_HEADER(buf, ns, OP_DELETE);
         perl_mongo_serialize_int(&buf, flags);
         perl_mongo_sv_to_bson(&buf, criteria, NO_PREP);
         perl_mongo_serialize_size(buf.start, &buf);
         RETVAL = newSVpvn(buf.start, buf.pos-buf.start);
         Safefree(buf.start);
    OUTPUT:
         RETVAL

SV*
build_update_message(request_id,ns, criteria, obj, flags)
         SV *request_id;
         char *ns
         SV *criteria
         SV *obj
         int flags
    PREINIT:
         buffer buf;
         mongo_msg_header header;
         
    CODE:
         CREATE_BUF(INITIAL_BUF_SIZE);
         CREATE_HEADER(buf, ns, OP_UPDATE);
         perl_mongo_serialize_int(&buf, flags);
         perl_mongo_sv_to_bson(&buf, criteria, NO_PREP);
         perl_mongo_sv_to_bson(&buf, obj, NO_PREP);
         perl_mongo_serialize_size(buf.start, &buf);
         RETVAL = newSVpvn(buf.start, buf.pos-buf.start);
         Safefree(buf.start);
    OUTPUT:
         RETVAL

SV*
build_get_more_message(request_id,ns, cursor_id,size)
        SV *request_id
        char *ns
        SV *cursor_id
        int size
    PREINIT:
        buffer buf;
        mongo_msg_header header;
    CODE:
    
        size = 34+strlen(ns);
        New(0, buf.start, size, char);
        buf.pos = buf.start;
        buf.end = buf.start + size;

        CREATE_RESPONSE_HEADER(buf, ns, SvIV(request_id), OP_GET_MORE);
        perl_mongo_serialize_int(&buf, size);
        perl_mongo_serialize_long(&buf, (int64_t)SvIV(cursor_id));
        perl_mongo_serialize_size(buf.start, &buf);
    
        // CREATE_BUF(INITIAL_BUF_SIZE);
        // // standard message head
        // CREATE_MSG_HEADER(SvIV(request_id), 0, OP_GET_MORE);
        // APPEND_HEADER_NS(buf, ns, 0);
        // // batch size
        // perl_mongo_serialize_int(&buf, SvIV(size));
        // // cursor id
        // perl_mongo_serialize_long(&buf, (int64_t) SvIV(cursor_id));
        // perl_mongo_serialize_size(buf.start, &buf);
        RETVAL = newSVpvn(buf.start, buf.pos-buf.start);
        Safefree(buf.start);
    OUTPUT:
        RETVAL

SV*
build_kill_cursor_message(request_id_sv,cursor_id)
        SV *request_id_sv
        SV *cursor_id
    PREINIT:
        buffer buf;
        char quickbuf[128];
        mongo_msg_header header;
    CODE:
        buf.pos = quickbuf;
        buf.start = buf.pos;
        buf.end = buf.start + 128;
        // std header
        CREATE_MSG_HEADER(SvIV(request_id_sv), 0, OP_KILL_CURSORS);
        APPEND_HEADER(buf, 0);
        // # of cursors
        perl_mongo_serialize_int(&buf, 1);
        // cursor ids
        perl_mongo_serialize_long(&buf, (int64_t)SvIV(cursor_id));
        perl_mongo_serialize_size(buf.start, &buf);
        RETVAL = newSVpvn(buf.start, buf.pos-buf.start);
    OUTPUT:
        RETVAL

SV*
decode_bson_documents(SV *documents)
    PREINIT:
        buffer buf;
        AV *ret;
        char *bson;
    CODE:
        ret = newAV ();
        bson = SvPVbyte_nolen(documents);
        buf.start = bson;
        buf.end = buf.start + SvCUR(documents);
        buf.pos = buf.start;
        int i =0;
        // warn("buf.start:%p buf.end:%p document_lenth:%d",buf.start,buf.end,(int)SvCUR(documents));
        do {
            SV *sv;
            // warn("perl_mongo_bson_to_sv...\n");
            sv = perl_mongo_bson_to_sv(&buf);
            // warn("perl_mongo_bson_to_sv END...\n");
            av_push (ret, sv);
            buf.start = buf.pos;
        } while( buf.pos < buf.end);
        
        RETVAL = newRV_noinc ((SV *)ret);
    OUTPUT:
        RETVAL
