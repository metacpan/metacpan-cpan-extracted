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
#include "encode.h"

typedef struct {
    int column_count;
    int uniq_column_count;
    struct cc_column *columns;
} Cassandra__Client__RowMeta;

MODULE = Cassandra::Client  PACKAGE = Cassandra::Client::Protocol
PROTOTYPES: DISABLE

void
unpack_metadata(protocol_version, is_result, data)
    int protocol_version
    int is_result
    SV *data
  PPCODE:
    STRLEN pos, size;
    unsigned char *ptr;
    int32_t flags, column_count, uniq_column_count;
    Cassandra__Client__RowMeta *row_meta;

    ST(0) = &PL_sv_undef; /* Will have our RowMeta instance */
    ST(1) = &PL_sv_undef; /* Will have our paging state */

    ptr = (unsigned char*)SvPV(data, size);
    pos = 0;

    if (UNLIKELY(!ptr))
        croak("Missing data argument to unpack_metadata");
    if (UNLIKELY(protocol_version != 3 && protocol_version != 4))
        croak("Invalid protocol version");

    flags = unpack_int(aTHX_ ptr, size, &pos);
    column_count = unpack_int(aTHX_ ptr, size, &pos);

    if (protocol_version >= 4 && !is_result) {
        int i, pk_count;

        pk_count = unpack_int(aTHX_ ptr, size, &pos);
        if (UNLIKELY(pk_count < 0))
            croak("Protocol error: pk_count<0");

        for (i = 0; i < pk_count; i++) {
            // Read the short, but throw it away for now.
            unpack_short(aTHX_ ptr, size, &pos);
        }
    }

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
        HV *name_hash;

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

        name_hash = (HV*)sv_2mortal( (SV*)newHV() );
        uniq_column_count = 0;

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
            if (!hv_exists_ent(name_hash, column->name, column->name_hash)) {
                uniq_column_count++;
                hv_store_ent(name_hash, column->name, &PL_sv_undef, column->name_hash);
            }
        }

        row_meta->uniq_column_count = uniq_column_count;
    }

    sv_chop(data, (char*)ptr+pos);

    XSRETURN(2);

MODULE = Cassandra::Client  PACKAGE = Cassandra::Client::RowMetaPtr

AV*
decode(self, data, use_hashes)
    Cassandra::Client::RowMeta *self
    SV *data
    int use_hashes
  CODE:
    STRLEN size, pos;
    unsigned char *ptr;
    int32_t row_count;
    int i, j, col_count;
    struct cc_column *columns;

    RETVAL = newAV();
    sv_2mortal((SV*)RETVAL); /* work around a bug in perl */

    ptr = (unsigned char*)SvPV(data, size);
    pos = 0;

    if (UNLIKELY(!ptr))
        croak("Invalid input to decode()");

    col_count = self->column_count;
    columns = self->columns;

    row_count = unpack_int(aTHX_ ptr, size, &pos);

    /* This came up while fuzzing: when we have 1000000 rows but no columns, we
     * just flood the memory with empty arrays/hashes. Let's just reject this
     * corner case. If you need this, please contact the author! */
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

SV*
encode(self, row)
    Cassandra::Client::RowMeta *self
    SV* row
  CODE:
    int column_count, i, use_hash;
    STRLEN size_estimate;
    AV *row_a;
    HV *row_h;

    if (UNLIKELY(row == NULL))
        croak("row must be passed");
    if (UNLIKELY(!SvROK(row)))
        croak("encode: argument must be a reference");

    column_count = self->column_count;

    if (SvTYPE(SvRV(row)) == SVt_PVAV) {
        row_a = (AV*)SvRV(row);
        use_hash = 0;
        if (UNLIKELY((av_len(row_a)+1) != column_count))
            croak("row encoder expected %d column(s), but got %d", column_count, ((int)av_len(row_a))+1);

    } else if (SvTYPE(SvRV(row)) == SVt_PVHV) {
        row_h = (HV*)SvRV(row);
        use_hash = 1;
        if (UNLIKELY(HvUSEDKEYS(row_h) != self->uniq_column_count))
            croak("row encoder expected %d column(s), but got %d", self->uniq_column_count, (int)HvUSEDKEYS(row_h));

    } else {
        croak("encode: argument must be an ARRAY or HASH reference");
    }

    /* Rough estimate. We only use it to predict Sv size, we don't rely on it being accurate.
       If we overshoot, we waste some memory, and if we undershoot we copy a bit too often. */
    size_estimate = 2 + (column_count * 12);
    if (size_estimate <= 0) /* overflows aren't impossible, I guess */
        size_estimate = 0; /* wing it */

    RETVAL = newSV(size_estimate);
    sv_setpvn(RETVAL, "", 0);
    pack_short(aTHX_ RETVAL, column_count);

    if (!use_hash) {
        for (i = 0; i < column_count; i++) {
            SV **maybe_cell = av_fetch(row_a, i, 0);
            if (UNLIKELY(maybe_cell == NULL))
                croak("row encoder error. bailing out");
            encode_cell(aTHX_ RETVAL, *maybe_cell, &self->columns[i].type);
        }

    } else {
        for (i = 0; i < column_count; i++) {
            struct cc_column *column;
            HE *ent;

            column = &self->columns[i];
            ent = hv_fetch_ent(row_h, column->name, 0, column->name_hash);
            if (UNLIKELY(!ent)) {
                croak("missing value for required entry <%s>", SvPV_nolen(column->name));
            }

            encode_cell(aTHX_ RETVAL, HeVAL(ent), &column->type);
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
