#   @(#)$Id: DBD-Informix.msd,v 2018.1 2018/05/11 17:02:43 jleffler Exp $
#   @(#)DBD::Informix - Perl Database Driver for Informix
#   @(#)Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31)
#   @(#)Definitive list of files -- Modifiable Source Distribution
#
#   -- The MSD RCS file column contains the name of the RCS file to be
#      created.  The name is quoted relative to the destination directory.
#   -- The master file column contains the name of the master file.
#      Relative names are quoted relative to the source directory.
#
#   -- It is assumed that all files are under RCS or SCCS control.
#      Despite this, the `,v' suffix or `s.' prefix and the RCS or SCCS
#      sub-directory name MUST be specified.
#
#   -- Note that it is possible to rename files using this mechanism.
#
#   -- Note that it is possible to include variable definitions as in a
#      shell script.  If necessary, these can include defaults such as
#      ${JH:-/u/j/h} but not termination constructs such as: ${XYZ:?}
#      Note that spaces are not allowed in definitions.
#
#   -- Comment lines start with a hash (#)
#   -- Blank lines are ignored
#   -- Tabs are non-preferred characters
##################################################################

JL=/Users/jleffler
JLBS=${JL}/bin/RCS
JLIS=${JL}/inc/RCS
JLES=${JL}/lib/ESQL/RCS
JLLS=${JL}/lib/JL/RCS
JLSSDIST=${JL}/bin/JLSS-Dist/RCS

##################################################################
# MSD RCS file                  Master RCS file                  #
##################################################################

# Library Files
RCS/debug.h,v                   ${JLLS}/debug.h,v
RCS/dumpesql.h,v                ${JLES}/dumpesql.h,v
RCS/esql5_00.h,v                ${JLES}/esql5_00.h,v
RCS/esql7_20.h,v                ${JLES}/esql7_20.h,v
RCS/esql_ius.h,v                ${JLES}/esql_ius.h,v
RCS/esqlc.h,v                   ${JLES}/esqlc.h,v
RCS/esqlcver.ec,v               ${JLES}/esqlcver.ec,v
RCS/esqllib.h,v                 ${JLES}/esqllib.h,v
RCS/esqltype.h,v                ${JLES}/esqltype.h,v
RCS/esqlutil.h,v                ${JLES}/esqlutil.h,v
RCS/ifmxdec.h,v                 ${JLES}/ifmxdec.h,v
RCS/ixblob.ec,v                 ${JLES}/ixblob.ec,v
RCS/ixblob.h,v                  ${JLES}/ixblob.h,v
RCS/kludge.c,v                  ${JLLS}/kludge.c,v
RCS/kludge.h,v                  ${JLLS}/kludge.h,v
RCS/sqltoken.c,v                ${JLES}/sqltoken.c,v
RCS/sqltoken.h,v                ${JLES}/sqltoken.h,v
RCS/sqltype.ec,v                ${JLES}/sqltype.ec,v

# Source Files
RCS/Announce,v                  RCS/Announce,v
RCS/BugReport,v                 RCS/BugReport,v
RCS/ChangeLog,v                 RCS/ChangeLog,v

RCS/InformixTechSupport,v       RCS/InformixTechSupport,v
RCS/ItWorks,v                   RCS/ItWorks,v
RCS/MANIFEST,v                  RCS/MANIFEST,v
RCS/MANIFEST.SKIP,v             RCS/MANIFEST.SKIP,v
RCS/META.yml,v                  RCS/META.yml,v
RCS/Makefile.PL,v               RCS/Makefile.PL,v
RCS/README,v                    RCS/README,v
RCS/TODO,v                      RCS/TODO,v

RCS/Informix.h,v                RCS/Informix.h,v
RCS/Informix.pm,v               RCS/Informix.pm,v
RCS/Informix.xs,v               RCS/Informix.xs,v
RCS/dbdattr.ec,v                RCS/dbdattr.ec,v
RCS/dbdimp.ec,v                 RCS/dbdimp.ec,v
RCS/dbdimp.h,v                  RCS/dbdimp.h,v
RCS/dbdixmap.h,v                RCS/dbdixmap.h,v
RCS/eprintf.c,v                 RCS/eprintf.c,v
RCS/esqlbasic.ec,v              RCS/esqlbasic.ec,v
RCS/esqlc_v6.ec,v               RCS/esqlc_v6.ec,v
RCS/esqlperl.h,v                RCS/esqlperl.h,v
RCS/esqltest.ec,v               RCS/esqltest.ec,v
RCS/link.c,v                    RCS/link.c,v
RCS/link.h,v                    RCS/link.h,v
RCS/setminref.pl,v              RCS/setminref.pl,v
RCS/setperl.pl,v                RCS/setperl.pl,v

RCS/odbctype.c,v                RCS/odbctype.c,v
RCS/odbctype.h,v                RCS/odbctype.h,v
RCS/test.all.sh,v               RCS/test.all.sh,v
RCS/test.one.sh,v               RCS/test.one.sh,v
RCS/test.quiet.sh,v             RCS/test.quiet.sh,v
RCS/test.run.sh,v               RCS/test.run.sh,v

# Supporting tools
lib/Bundle/DBD/RCS/Informix.pm,v        lib/Bundle/DBD/RCS/Informix.pm,v
lib/DBD/Informix/RCS/Configure.pm,v     lib/DBD/Informix/RCS/Configure.pm,v
lib/DBD/Informix/RCS/GetInfo.pm,v       lib/DBD/Informix/RCS/GetInfo.pm,v
lib/DBD/Informix/RCS/Metadata.pm,v      lib/DBD/Informix/RCS/Metadata.pm,v
lib/DBD/Informix/RCS/Summary.pm,v       lib/DBD/Informix/RCS/Summary.pm,v
lib/DBD/Informix/RCS/TechSupport.pm,v   lib/DBD/Informix/RCS/TechSupport.pm,v
lib/DBD/Informix/RCS/TestHarness.pm,v   lib/DBD/Informix/RCS/TestHarness.pm,v
lib/DBD/Informix/RCS/TypeInfo.pm,v      lib/DBD/Informix/RCS/TypeInfo.pm,v

# Test scripts
RCS/bug-lvcnn.ec,v              RCS/bug-lvcnn.ec,v
RCS/bug-lvcnn.pl,v              RCS/bug-lvcnn.pl,v
t/RCS/decgen.pl,v               t/RCS/decgen.pl,v
t/RCS/dtgen.pl,v                t/RCS/dtgen.pl,v
t/RCS/t00basic.t,v              t/RCS/t00basic.t,v
t/RCS/t01stproc.t,v             t/RCS/t01stproc.t,v
t/RCS/t02ixtype.t,v             t/RCS/t02ixtype.t,v
t/RCS/t05dbase.t,v              t/RCS/t05dbase.t,v
t/RCS/t07dblist.t,v             t/RCS/t07dblist.t,v
t/RCS/t08fork.t,v               t/RCS/t08fork.t,v
t/RCS/t09date.t,v               t/RCS/t09date.t,v
t/RCS/t10sqlca.t,v              t/RCS/t10sqlca.t,v
t/RCS/t12bindval.t,v            t/RCS/t12bindval.t,v
t/RCS/t13bindref.t,v            t/RCS/t13bindref.t,v
t/RCS/t14bindcol.t,v            t/RCS/t14bindcol.t,v
t/RCS/t15bindtyp.t,v            t/RCS/t15bindtyp.t,v
t/RCS/t20error.t,v              t/RCS/t20error.t,v
t/RCS/t21mconn.t,v              t/RCS/t21mconn.t,v
t/RCS/t22mconn.t,v              t/RCS/t22mconn.t,v
t/RCS/t23mconn.t,v              t/RCS/t23mconn.t,v
t/RCS/t24mcurs.t,v              t/RCS/t24mcurs.t,v
t/RCS/t25dratt.t,v              t/RCS/t25dratt.t,v
t/RCS/t28dtlit.t,v              t/RCS/t28dtlit.t,v
t/RCS/t29update.t,v             t/RCS/t29update.t,v
t/RCS/t30update.t,v             t/RCS/t30update.t,v
t/RCS/t31nulls.t,v              t/RCS/t31nulls.t,v
t/RCS/t32nulls.t,v              t/RCS/t32nulls.t,v
t/RCS/t33holdcurs.t,v           t/RCS/t33holdcurs.t,v
t/RCS/t35cursor.t,v             t/RCS/t35cursor.t,v
t/RCS/t40rows.t,v               t/RCS/t40rows.t,v
t/RCS/t41txacoff.t,v            t/RCS/t41txacoff.t,v
t/RCS/t42txacon.t,v             t/RCS/t42txacon.t,v
t/RCS/t43trans.t,v              t/RCS/t43trans.t,v
t/RCS/t44txansi.t,v             t/RCS/t44txansi.t,v
t/RCS/t46chpblk.t,v             t/RCS/t46chpblk.t,v
t/RCS/t50update.t,v             t/RCS/t50update.t,v
t/RCS/t51getinfo.t,v            t/RCS/t51getinfo.t,v
t/RCS/t53types.t,v              t/RCS/t53types.t,v
t/RCS/t54native.t,v             t/RCS/t54native.t,v
t/RCS/t55mdata.t,v              t/RCS/t55mdata.t,v
t/RCS/t56tabinfo.t,v            t/RCS/t56tabinfo.t,v
t/RCS/t57tables.t,v             t/RCS/t57tables.t,v
t/RCS/t58typeinfoall.t,v        t/RCS/t58typeinfoall.t,v
t/RCS/t60unlog.t,v              t/RCS/t60unlog.t,v
t/RCS/t61varchar.t,v            t/RCS/t61varchar.t,v
t/RCS/t65updcur.t,v             t/RCS/t65updcur.t,v
t/RCS/t66insert.t,v             t/RCS/t66insert.t,v
t/RCS/t72blob.t,v               t/RCS/t72blob.t,v
t/RCS/t73blobupd.t,v            t/RCS/t73blobupd.t,v
t/RCS/t74blob.t,v               t/RCS/t74blob.t,v
t/RCS/t75blob.t,v               t/RCS/t75blob.t,v
t/RCS/t76blob.t,v               t/RCS/t76blob.t,v
t/RCS/t77varchar.t,v            t/RCS/t77varchar.t,v
t/RCS/t78varchar.t,v            t/RCS/t78varchar.t,v
t/RCS/t90ius.t,v                t/RCS/t90ius.t,v
t/RCS/t91udts.t,v               t/RCS/t91udts.t,v
t/RCS/t92rows.t,v               t/RCS/t92rows.t,v
t/RCS/t93lvarchar.t,v           t/RCS/t93lvarchar.t,v
t/RCS/t94bool.t,v               t/RCS/t94bool.t,v
t/RCS/t95int8.t,v               t/RCS/t95int8.t,v
t/RCS/t96bigint.t,v             t/RCS/t96bigint.t,v
t/RCS/t98pod.t,v                t/RCS/t98pod.t,v
t/RCS/t99clean.t,v              t/RCS/t99clean.t,v

# Various scraps of documentation.
Notes/RCS/FAQ,v                     Notes/RCS/FAQ,v
Notes/RCS/Working.Versions,v        Notes/RCS/Working.Versions,v
Notes/RCS/bug.reports,v             Notes/RCS/bug.reports,v
Notes/RCS/environment.variables,v   Notes/RCS/environment.variables,v
Notes/RCS/eprintf,v                 Notes/RCS/eprintf,v
Notes/RCS/hpux,v                    Notes/RCS/hpux,v
Notes/RCS/hpux-gcc-build.sh,v       Notes/RCS/hpux-gcc-build.sh,v
Notes/RCS/linux,v                   Notes/RCS/linux,v
Notes/RCS/load.unload,v             Notes/RCS/load.unload,v
Notes/RCS/nonroot.install,v         Notes/RCS/nonroot.install,v
Notes/RCS/olipcshm,v                Notes/RCS/olipcshm,v
Notes/RCS/static.build,v            Notes/RCS/static.build,v
Notes/RCS/web.servers,v             Notes/RCS/web.servers,v

# Examples - how to use Perl + DBI + DBD::Informix
examples/RCS/README,v                   examples/RCS/README,v
examples/RCS/fixin.pl,v                 examples/RCS/fixin.pl,v
examples/RCS/x01fetchall.pl,v           examples/RCS/x01fetchall.pl,v
examples/RCS/x02fetchrow_array.pl,v     examples/RCS/x02fetchrow_array.pl,v
examples/RCS/x03fetchrow_arrayref.pl,v  examples/RCS/x03fetchrow_arrayref.pl,v
examples/RCS/x04fetchrow_hashref.pl,v   examples/RCS/x04fetchrow_hashref.pl,v
examples/RCS/x05fetchall_arrayref.pl,v  examples/RCS/x05fetchall_arrayref.pl,v
examples/RCS/x06chopblanks.pl,v         examples/RCS/x06chopblanks.pl,v
examples/RCS/x07fetchrow_array.pl,v     examples/RCS/x07fetchrow_array.pl,v
examples/RCS/x10cgi_nodbi.pl,v          examples/RCS/x10cgi_nodbi.pl,v
examples/RCS/x11cgi_nodbi.pl,v          examples/RCS/x11cgi_nodbi.pl,v
examples/RCS/x12cgi_noform.pl,v         examples/RCS/x12cgi_noform.pl,v
examples/RCS/x13cgi_noform.pl,v         examples/RCS/x13cgi_noform.pl,v
examples/RCS/x14cgi_form.pl,v           examples/RCS/x14cgi_form.pl,v
examples/RCS/x15cgi_form.pl,v           examples/RCS/x15cgi_form.pl,v

# Experiment - simulate scroll cursors.
examples/RCS/fetchscroll.pl,v           examples/RCS/fetchscroll.pl,v

# Custom Distribution Tools
# Release mechanism stuff - not needed except by maintainers, mostly.
RCS/Release.Checklist,v         RCS/Release.Checklist,v
RCS/DBD-Informix.jdc,v          RCS/DBD-Informix.jdc,v
RCS/DBD-Informix.msd,v          RCS/DBD-Informix.msd,v
RCS/DBD-Informix.nmd,v          RCS/DBD-Informix.nmd,v

# Recommended mechanism for using ExtUtils::AutoInstall
inc/ExtUtils/AutoInstall.pm     inc/ExtUtils/AutoInstall.pm

# Generic installation tools
RCS/mknmd.sh,v                  ${JLSSDIST}/mknmd.sh,v
RCS/prodverstamp.sh,v           ${JLSSDIST}/prodverstamp.sh,v
