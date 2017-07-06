#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <stdint.h>
#include "define.h"
#include "type.h"
#include "proto.h"
#include "decode.h"

typedef struct {
    int column_count;
    struct cc_column *columns;
} Cassandra__Client__RowMeta;

MODULE = Cassandra::Client  PACKAGE = Cassandra::Client::Protocol
PROTOTYPES: DISABLE

void
unpack_metadata2(data)
    SV *data
  PPCODE:
    STRLEN pos, size;
    char *ptr;
    int32_t flags, column_count;
    Cassandra__Client__RowMeta *row_meta;

    ST(0) = &PL_sv_undef; /* Will have our RowMeta instance */
    ST(1) = &PL_sv_undef; /* Will have our paging state */

    ptr = SvPV(data, size);
    pos = 0;

    if (UNLIKELY(!ptr))
        croak("Missing data argument to unpack_metadata");

    flags = unpack_int(aTHX_ ptr, size, &pos);
    column_count = unpack_int(aTHX_ ptr, size, &pos);

    if (UNLIKELY(flags < 0 || flags > 7))
        croak("Invalid protocol data passed to unpack_metadata (reason: invalid flags)");
    if (UNLIKELY(column_count < 0))
        croak("Invalid protocol data passed to unpack_metadata (reason: invalid column count)");

    if (flags & CC_METADATA_FLAG_HAS_MORE_PAGES) {
        ST(1) = unpack_bytes_sv(aTHX_ ptr, size, &pos);
        sv_2mortal(ST(1));
    }

    if (!(flags & CC_METADATA_FLAG_NO_METADATA)) {
        int i, have_global_spec;
        SV *global_keyspace, *global_table;

        have_global_spec = flags & CC_METADATA_FLAG_GLOBAL_TABLES_SPEC;

        if (have_global_spec) {
            global_keyspace = unpack_string_sv(aTHX_ ptr, size, &pos);
            sv_2mortal(global_keyspace);
            global_table = unpack_string_sv(aTHX_ ptr, size, &pos);
            sv_2mortal(global_table);
        }

        Newxz(row_meta, 1, Cassandra__Client__RowMeta);
        ST(0) = sv_newmortal();
        sv_setref_pv(ST(0), "Cassandra::Client::RowMetaPtr", (void*)row_meta);

        if (UNLIKELY(column_count > size))
            croak("Invalid protocol data passed to unpack_metadata (reason: column count unlikely)");

        row_meta->column_count = column_count;
        Newxz(row_meta->columns, column_count, struct cc_column);

        for (i = 0; i < column_count; i++) {
            struct cc_column *column = &(row_meta->columns[i]);
            if (have_global_spec) {
                column->keyspace = global_keyspace;
                SvREFCNT_inc(column->keyspace);
                column->table = global_table;
                SvREFCNT_inc(column->table);
            } else {
                column->keyspace = unpack_string_sv(aTHX_ ptr, size, &pos);
                column->table = unpack_string_sv(aTHX_ ptr, size, &pos);
            }

            column->name = unpack_string_sv_hash(aTHX_ ptr, size, &pos, &column->name_hash);
            unpack_type(aTHX_ ptr, size, &pos, &column->type);
        }
    }

    sv_chop(data, ptr+pos);

    XSRETURN(2);

MODULE = Cassandra::Client  PACKAGE = Cassandra::Client::RowMetaPtr

AV*
decode(self, data, use_hashes)
    Cassandra::Client::RowMeta *self
    SV *data
    int use_hashes
  CODE:
    STRLEN size, pos;
    char *ptr;
    int32_t row_count;
    int i, j, col_count;
    struct cc_column *columns;

    RETVAL = newAV();
    sv_2mortal((SV*)RETVAL); /* work around a bug in perl */

    ptr = SvPV(data, size);
    pos = 0;

    if (UNLIKELY(!ptr))
        croak("Invalid input to decode()");

    col_count = self->column_count;
    columns = self->columns;

    row_count = unpack_int(aTHX_ ptr, size, &pos);

    // This came up while fuzzing: when we have 1000000 rows but no columns, we
    // just flood the memory with empty arrays/hashes. Let's just reject this
    // corner case. If you need this, please contact the author!
    if (UNLIKELY(row_count > 1000 && !col_count))
        croak("Refusing to decode %d rows without known column information", row_count);

    for (i = 0; i < row_count; i++) {
        if (use_hashes) {
            HV *this_row = newHV();
            av_push(RETVAL, newRV_noinc((SV*)this_row));

            for (j = 0; j < col_count; j++) {
                SV *decoded = newSV(0);
                hv_store_ent(this_row, columns[j].name, decoded, columns[j].name_hash);

                decode_cell(aTHX_ ptr, size, &pos, &columns[j].type, decoded);
            }

        } else {
            AV *this_row = newAV();
            av_push(RETVAL, newRV_noinc((SV*)this_row));

            for (j = 0; j < col_count; j++) {
                SV *decoded = newSV(0);
                av_push(this_row, decoded);

                decode_cell(aTHX_ ptr, size, &pos, &columns[j].type, decoded);
            }
        }
    }

  OUTPUT:
    RETVAL

AV*
column_names(self)
    Cassandra::Client::RowMeta *self
  CODE:
    int i;

    RETVAL = newAV();
    sv_2mortal((SV*)RETVAL); /* work around a bug in perl */

    for (i = 0; i < self->column_count; i++) {
        av_push(RETVAL, SvREFCNT_inc(self->columns[i].name));
    }
  OUTPUT:
    RETVAL

void
DESTROY(self)
    Cassandra::Client::RowMeta *self
  CODE:
    int i;
    for (i = 0; i < self->column_count; i++) {
        struct cc_column *column = &(self->columns[i]);
        SvREFCNT_dec(column->keyspace);
        SvREFCNT_dec(column->table);
        SvREFCNT_dec(column->name);
        cc_type_destroy(aTHX_ &column->type);
    }
    Safefree(self->columns);
    Safefree(self);
