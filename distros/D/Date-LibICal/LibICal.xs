#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <libical/ical.h>

MODULE = Date::LibICal		PACKAGE = Date::LibICal

void
expand_recurrence(rule, start=0, count=INT_MAX)
        const char * rule
        int          start
        int          count
    PPCODE:
        struct icalrecurrencetype recur, err;
        icalrecur_iterator *ritr;
        struct icaltimetype icstart, next;

        icalrecurrencetype_clear(&err);

        icstart = icaltime_from_timet_with_zone((time_t)start, 0, 0);

        recur = icalrecurrencetype_from_string(rule);
        if (
               memcmp(&recur, &err, sizeof recur) == 0
            || !(ritr = icalrecur_iterator_new(recur, icstart))
        ) {
            croak("Error during extending ical: %s", icalerror_perror());
            return 2;
        }

        long i = 0;
        for (
            next = icalrecur_iterator_next(ritr);
            !icaltime_is_null_time(next) && i < count;
            next = icalrecur_iterator_next(ritr)
        ) {
            time_t tt = icaltime_as_timet(next);

            if (tt >= start) {
                XPUSHs(sv_2mortal(newSVnv((long)tt)));
                i++;
            }
        }
        icalrecur_iterator_free(ritr);

