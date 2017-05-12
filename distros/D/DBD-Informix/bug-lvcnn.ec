/*
** @(#)$Id: bug-lvcnn.ec,v 1.4 2007/06/14 05:13:20 jleffler Exp $
**
** Demonstration of bug originally reported in DBD::Informix
** as RT#13708 at http://rt.cpan.org/ and ignored for a couple of years.
** Primarily seems to afflict 32-bit ports of CSDK (ESQL/C).
** And primarily the more recent versions - 2.90 and maybe 2.81.
**
** Bug: SQL DESCRIPTOR does not handle LVARCHAR NOT NULL properly.
**
** Demonstrated on Solaris 10 with         CSDK 2.90.UC4.
** No bug with 64-bit on Solaris 10 with   CSDK 2.90.FC4.
** No bug with 64-bit on Linux PPC 64 with CSDK 3.00.FN125 (nightly build).
** No bug with 32-bit on Solaris 10 with   CSDK 2.80.UC1
** Core dump on 64-bit on Solaris 10 with  CSDK 2.81.FC2
** Core dump on 32-bit on Solaris 10 with  CSDK 2.81.UC2
** In each of the above cases, the test DBMS is IDS 10.00.UC5 running on Solaris 10.
** Also seen by customers on various platforms - primarily 32-bit.
*/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

$ static char lvc1[] = "This is row 1";
$ static char lvc2[] = "And this is in row 1 too";

static int num_bugs = 0;

static void print_descriptor(const char *p_name, int p_index)
{
    $ int         index = p_index;
    $ const char *name = p_name;
    $ long        coltype;
    $ long        collength;
    $ long        colind;
    $ char        colname[129];
    $ int         nullable;

    $ whenever error stop;

    $ get descriptor :name VALUE :index
            :coltype = TYPE, :collength = LENGTH,
            :nullable = NULLABLE,
            :colind = INDICATOR, :colname = NAME;
    colname[byleng(colname, strlen(colname))] = '\0';
    printf("%s:%02d: type = %2d, length = %4d, nulls = %2d, indicator = %2d, name = %s\n",
        name, index, coltype, collength, nullable, colind, colname);
}

static void check_data(void)
{
    $ lvarchar *lv1 = 0;
    $ lvarchar *lv2 = 0;
    $ int       row;
    $ short     ind;

    $ prepare p from "select row_number, lvc_with_null, lvc_wout_null from lvarchar_test order by row_number";
    $ declare c cursor for p;

    $ allocate descriptor "d" with max 3;
    $ describe p using sql descriptor "d";
    /*
    ** The following two lines do not work around the problem.
    ** $ set descriptor "d" value 2 NULLABLE = 1;
    ** $ set descriptor "d" value 3 NULLABLE = 1;
    */

    /* Print allocator description */
    print_descriptor("d", 1);
    print_descriptor("d", 2);
    print_descriptor("d", 3);

    ifx_var_flag(&lv1, 1);
    ifx_var_flag(&lv2, 1);

    $ open c;

    while (sqlca.sqlcode == 0)
    {
        $ fetch c using sql descriptor "d";
        if (sqlca.sqlcode != 0)
            break;
        $ get descriptor "d" VALUE 1 :row = DATA, :ind = INDICATOR;
        if (ind == 0)
            printf("row_number = %d:\n", row);
        else
            printf("row_number IS NULL (ind = %d)\n", ind);

        $ get descriptor "d" VALUE 2 :lv1 = DATA, :ind = INDICATOR;
        if (ind != 0)
            printf("  lvc_with_null IS NULL (ind = %d)\n", ind);
        else
        {
            char *result = (char *)ifx_var_getdata(&lv1);
            int   length = ifx_var_getlen(&lv1);
            if (length < 0)
            {
                printf("Length of lvarchar < 0\n");
                length = 0;
            }
            if (result == 0)
            {
                printf("Result of lvarchar == 0x00000000\n");
            }
            printf("  lvc_with_null = <<%.*s>>\n", length, result);
            if (strcmp(result, lvc1) != 0)
            {
                printf("**BUG** wanted  = <<%s>>\n", lvc1);
                num_bugs++;
            }
        }

        $ get descriptor "d" VALUE 3 :lv2 = DATA, :ind = INDICATOR;
        if (ind != 0)
            printf("  lvc_wout_null IS NULL (ind = %d)\n", ind);
        else
        {
            char *result = (char *)ifx_var_getdata(&lv2);
            int   length = ifx_var_getlen(&lv2);
            if (length < 0)
            {
                printf("Length of lvarchar < 0\n");
                length = 0;
            }
            if (result == 0)
            {
                printf("Result of lvarchar == 0x00000000\n");
            }
            printf("  lvc_wout_null = <<%.*s>>\n", length, result);
            if (strcmp(result, lvc2) != 0)
            {
                printf("**BUG** wanted  = <<%s>>\n", lvc2);
                num_bugs++;
            }
        }
    }

    ifx_var_freevar(&lv1);
    ifx_var_freevar(&lv2);

    $ close c;
    $ free c;
    $ free p;
    $ deallocate descriptor "d";
}

int main(int argc, char **argv)
{
    $ char *dbname = "stores";

    if (argc > 1)
        dbname = argv[1];
    $ database :dbname;

    $ whenever error continue;
    $ drop table lvarchar_test;
    $ whenever error stop;

    printf("\nTest 1: LVARCHAR(128) - with NOT NULL\n");
    $ create table lvarchar_test
      (
      row_number    serial not null primary key,
      lvc_with_null lvarchar(128),
      lvc_wout_null lvarchar(128) not null
      );
    $ insert into lvarchar_test values(1, :lvc1, :lvc2);
    check_data();

    printf("\nTest 2: LVARCHAR - with NOT NULL\n");
    $ drop table lvarchar_test;
    $ create table lvarchar_test
      (
      row_number    serial not null primary key,
      lvc_with_null lvarchar,
      lvc_wout_null lvarchar not null
      );
    $ insert into lvarchar_test values(1, :lvc1, :lvc2);
    check_data();

    printf("\nTest 3: LVARCHAR(128) - without NOT NULL\n");
    $ drop table lvarchar_test;
    $ create table lvarchar_test
      (
      row_number    serial not null primary key,
      lvc_with_null lvarchar(128),
      lvc_wout_null lvarchar(128)
      );
    $ insert into lvarchar_test values(1, :lvc1, :lvc2);
    check_data();

    printf("\nTest 4: LVARCHAR - without NOT NULL\n");
    $ drop table lvarchar_test;
    $ create table lvarchar_test
      (
      row_number    serial not null primary key,
      lvc_with_null lvarchar,
      lvc_wout_null lvarchar
      );
    $ insert into lvarchar_test values(1, :lvc1, :lvc2);
    check_data();

    printf("\nTest 5: LVARCHAR(128) - with NOT NULL in TEMP TABLE\n");
    $ drop table lvarchar_test;
    $ create temp table lvarchar_test
      (
      row_number    serial not null primary key,
      lvc_with_null lvarchar(128),
      lvc_wout_null lvarchar(128) not null
      );
    $ insert into lvarchar_test values(1, :lvc1, :lvc2);
    check_data();

    $ close database;
    if (num_bugs == 0)
        printf("== PASSED ==\n");
    else
        printf("** FAILED ** %d bugs detected\n", num_bugs);
    return(num_bugs > 0);   /* 0 on no bugs; 1 otherwise */
}
