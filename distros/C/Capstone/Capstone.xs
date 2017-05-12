/****************************************************************************/
/* perl-capstone - A Perl wrapper for the capstone-engine library           */
/*                                                                          */
/* Copyright 2015, -TOSH-                                                   */
/* File coded by -TOSH-                                                     */
/*                                                                          */
/* This file is part of perl-capstone.                                      */
/*                                                                          */
/* perl-capstone is free software: you can redistribute it and/or modify    */
/* it under the terms of the GNU General Public License as published by     */
/* the Free Software Foundation, either version 3 of the License, or        */
/* (at your option) any later version.                                      */
/*                                                                          */
/* perl-capstone is distributed in the hope that it will be useful,         */
/* but WITHOUT ANY WARRANTY; without even the implied warranty of           */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            */
/* GNU General Public License for more details.                             */
/*                                                                          */
/* You should have received a copy of the GNU General Public License        */
/* along with perl-capstone.  If not, see <http://www.gnu.org/licenses/>    */
/****************************************************************************/

/* Perl XS wrapper for capstone-engine */

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#ifdef CAPSTONE_FROM_PKGCONFIG
#include <capstone.h>
#else
#include <capstone/capstone.h>
#endif


MODULE = Capstone   PACKAGE = cshPtr  PREFIX = csh_

# csh object destructor
void
csh_DESTROY(handle)
    csh *handle

    CODE:
        cs_close(handle);
        Safefree(handle);



MODULE = Capstone   PACKAGE = Capstone

# Wrapper to cs_open()
csh*
open(arch,mode)
    cs_arch arch
    cs_mode mode

    PREINIT:
        cs_err err;

    CODE:
        Newx(RETVAL, 1, csh);

        err = cs_open(arch, mode, RETVAL);

        if(err != CS_ERR_OK) {
               Safefree(RETVAL);
               XSRETURN_UNDEF;
        }

    OUTPUT:
        RETVAL

# Wrapper to cs_option()
int
option(handle,type,value)
    csh *handle
    cs_opt_type type
    size_t value


    PREINIT:
        cs_err err;

    CODE:
        err = cs_option(*handle, type, value);

        if(err != CS_ERR_OK) {
            RETVAL = 0;
        } else {
            RETVAL = 1;
        }

    OUTPUT:
        RETVAL


# Wrapper to cs_disasm()
SV*
disasm(handle,code,address,count,details)
    csh *handle
    SV *code
    UV address
    size_t count
    int details

    PREINIT:
        size_t ret, i;
        HV *hash;
        cs_insn *insn;

    PPCODE:
        if(SvTYPE(code) != SVt_PV) {
            croak("<code> argument not an array scalar");
        }

        ret = cs_disasm(*handle, SvPVbyte(code, SvCUR(code)), SvCUR(code), address, count, &insn);

        for(i = 0; i < ret; i++) {
            hash = newHV();

            hv_store(hash, "id", 2, newSVuv(insn[i].id), 0);
            hv_store(hash, "address", 7, newSVuv(insn[i].address), 0);
            hv_store(hash, "mnemonic", 8, newSVpv(insn[i].mnemonic, strlen(insn[i].mnemonic)), 0);
            hv_store(hash, "op_str", 6, newSVpv(insn[i].op_str, strlen(insn[i].op_str)), 0);
            hv_store(hash, "bytes", 5, newSVpv(insn[i].bytes, insn[i].size), 0);

            if(details) {
                AV *regs_read, *regs_write, *groups;
                int j;

                regs_read = newAV();

                for(j = 0; j < insn[i].detail->regs_read_count; j++) {
                    av_push(regs_read, newSVuv(insn[i].detail->regs_read[j]));
                }

                regs_write = newAV();

                for(j = 0; j < insn[i].detail->regs_write_count; j++) {
                    av_push(regs_write, newSVuv(insn[i].detail->regs_write[j]));
                }

                groups = newAV();

                for(j = 0; j < insn[i].detail->groups_count; j++) {
                    av_push(groups, newSVuv(insn[i].detail->groups[j]));
                }

                hv_store(hash, "regs_read", 9, newRV_noinc((SV*)regs_read), 0);
                hv_store(hash, "regs_write", 10, newRV_noinc((SV*)regs_write), 0);
                hv_store(hash, "groups", 6, newRV_noinc((SV*)groups), 0);

            }

            PUSHs(newRV_noinc((SV *)hash) );
        }

        if(ret) {
            cs_free(insn, ret);
        }

# Wrapper to cs_version()
SV*
version()

    PREINIT:
        int major, minor;

    PPCODE:
        cs_version(&major, &minor);

        EXTEND(SP, 2);
        XST_mIV(0, major);
        XST_mIV(1, minor);
        XSRETURN(2);


# Wrapper to cs_support()
int
support(query)
    int query

    CODE:
        RETVAL = cs_support(query);

    OUTPUT:
        RETVAL

# Wrapper to cs_reg_name()
SV*
cs_reg_name(handle, reg_id)
    csh *handle
    unsigned int reg_id


    PREINIT:
        const char *ret;

    CODE:
        ret = cs_reg_name(*handle, reg_id);

        if(ret == NULL) {
            RETVAL = newSVpv("", 0);
        } else {
            RETVAL = newSVpv(ret, strlen(ret));
        }
    OUTPUT:
        RETVAL

# Wrapper to cs_insn_name()
SV*
cs_insn_name(handle, insn_id)
    csh *handle
    unsigned int insn_id


    PREINIT:
        const char *ret;

    CODE:
        ret = cs_insn_name(*handle, insn_id);

         if(ret == NULL) {
            RETVAL = newSVpv("", 0);
        } else {
            RETVAL = newSVpv(ret, strlen(ret));
        }

    OUTPUT:
        RETVAL

# Wrapper to cs_group_name()
SV*
cs_group_name(handle, group_id)
    csh *handle
    unsigned int group_id


    PREINIT:
        const char *ret;

    CODE:
        ret = cs_group_name(*handle, group_id);

         if(ret == NULL) {
            RETVAL = newSVpv("", 0);
        } else {
            RETVAL = newSVpv(ret, strlen(ret));
        }

    OUTPUT:
        RETVAL
