package DBI::Dumper::C;
# vi: ft=c

use strict;
use warnings;

our $VERSION = '1.00';

use Inline 
	C => 'DATA',
	VERSION => '1.00',
	NAME => 'DBI::Dumper::C';

1;

__DATA__

=pod

=cut

__C__

SV *escape;
char *escape_ptr;
STRLEN escape_len = 0;

SV *terminator;
char *terminator_ptr;
STRLEN terminator_len = 0;

SV *left_delim;
char *left_delim_ptr;
STRLEN left_delim_len = 0;

SV *right_delim;
char *right_delim_ptr;
STRLEN right_delim_len = 0;

void init(SV *self_ref) {
	HV *self;

	/* dereference self */
	self = (HV *)SvRV(self_ref);

	/* values for self members */
	escape = *hv_fetch(self, "escape", 6, 0);
	terminator = *hv_fetch(self, "terminator", 10, 0);
	left_delim = *hv_fetch(self, "left_delim", 10, 0);
	right_delim = *hv_fetch(self, "right_delim", 11, 0);

	/* get string values */
	if(SvOK(escape)) {
		escape_ptr = SvPV( escape, escape_len );
	}

	if(SvOK(terminator)) {
		terminator_ptr = SvPV( terminator, terminator_len );
	}

	if(SvOK(left_delim)) {
		left_delim_ptr = SvPV( left_delim, left_delim_len );
	}

	if(SvOK(right_delim)) {
		right_delim_ptr = SvPV( right_delim, right_delim_len );
	}
}


SV *build(SV *self_ref, SV *row_ref) {
	AV *row;
	int row_len;
	SV *data; /* return value */

    #define BLOCK_SIZE 4096
    char *buf;
    char *buf_p;
    I32 buf_size;

    buf_size = BLOCK_SIZE;

	I32 col_iter;

    /* allocate new buffer for buf */
    buf = malloc(BLOCK_SIZE * sizeof(char));
    buf_p = buf;

	/* dereference self and row */
	if(! SvOK(row_ref)) {
		return Nullsv;
	}

	row = (AV *)SvRV(row_ref);
	row_len = av_len(row);
	for(col_iter = 0; col_iter <= row_len; col_iter++) {
		SV *col;
		char *col_ptr;
		STRLEN col_len;

        col = *av_fetch(row, col_iter, 0);

        /* realloc as necessary */
        while(buf_p - buf + terminator_len + left_delim_len + 
            (SvOK(col) ? SvLEN(col) : 0) + right_delim_len + 1 > buf_size
        ) {
            buf_size += BLOCK_SIZE;
            buf = realloc(buf, buf_size * sizeof(char));
        }

		/* append terminator to string if not first column */
		if(col_iter > 0) {
            memcpy(buf_p, terminator_ptr, terminator_len * sizeof(char));
            buf_p += terminator_len;
		}

		if(SvOK(left_delim)) {
            memcpy(buf_p, left_delim_ptr, left_delim_len * sizeof(char));
            buf_p += left_delim_len;
		}

        if(SvOK(col) && SvLEN(col) > 0) {
            /* fetch column data and string */
            col_ptr = SvPV(col, col_len);

            /* do escaping and append to data */
            int i;
            for(i = 0; i < col_len; ) {
                char *c = col_ptr + i;
                int shift_len = 1;
                int do_escape = 0;

                /* escape embedded escapes */
                if(
                    escape_len > 0 &&
                    strncmp(c, escape_ptr, escape_len) == 0
                ) {
                    do_escape = 1;
                    shift_len = escape_len;
                }

                /* escape embedded terminators */
                else if(
                    left_delim_len == 0 && /* don't have to escape */
                    right_delim_len == 0 && /* if I have enclosures */
                    terminator_len > 0 &&
                    strncmp(c, terminator_ptr, terminator_len) == 0
                ) {
                    do_escape = 1;
                    shift_len = terminator_len;
                }

                /* escape embedded enclosures */
                else if(
                    left_delim_len > 0 && 
                    strncmp(c, left_delim_ptr, left_delim_len) == 0
                ) {
                    do_escape = 1;
                    shift_len = left_delim_len;
                }

                else if(
                    right_delim_len > 0 && 
                    strncmp(c, right_delim_ptr, right_delim_len) == 0
                ) {
                    do_escape = 1;
                    shift_len = right_delim_len;
                }

                /* escape as needed */
                if(escape_len > 0 && do_escape) {
                    memcpy(buf_p, escape_ptr, escape_len * sizeof(char));
                    buf_p += escape_len;
                }

                /* copy our c pointer to the buf pointer */
                memcpy(buf_p, c, shift_len * sizeof(char));
                buf_p += shift_len;
                i += shift_len;
            } /* for(i = 0; i < col_len; ) */
        } /* if(SvOK(col)) */

		if(SvOK(right_delim)) {
            memcpy(buf_p, right_delim_ptr, right_delim_len * sizeof(char));
            buf_p += right_delim_len;
		}
	}

    memcpy(buf_p, "\n", sizeof(char));
    buf_p += sizeof(char);

	data = newSVpv(buf, buf_p - buf);
    free(buf);
	return data;
}

