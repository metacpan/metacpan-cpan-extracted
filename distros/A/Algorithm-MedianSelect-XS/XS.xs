#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#define croak_msg(msg) \
    croak ("median(): %s", msg)
#define croak_msg_internal(msg) \
    croak ("median(): internal error: %s", msg)

enum { LESS_THAN = -1, EQUAL_TO, GREATER_THAN };

static int
quick_sort (const void *arg1, const void *arg2)
{
    const long num1 = *(long *)arg1, num2 = *(long *)arg2;
    if (num1 < num2)
      return LESS_THAN;
    else if (num1 == num2)
      return EQUAL_TO;
    else if (num1 > num2)
      return GREATER_THAN;
    else
      croak_msg_internal ("quick sort did not return a long integer");
}

#define SWAP(num_curr, num_next) \
    const long tmp = num_curr;   \
    num_curr = num_next;         \
    num_next = tmp;

static void
bubble_sort (long *numbers, unsigned int realitems)
{
    bool sort;

    do
      {
        unsigned int i;
        sort = FALSE;
        for (i = 0; i < (realitems - 1); i++)
          {
            if (i >= 1
            && (numbers[i - 1] <= numbers[i]) && (numbers[i] <= numbers[i + 1]))
              continue; /* optimization */
            else if (numbers[i] > numbers[i + 1])
              {
                SWAP (numbers[i], numbers[i + 1]);
                sort = TRUE;
              }
          }
      }
    while (sort);
}

MODULE = Algorithm::MedianSelect::XS        PACKAGE = Algorithm::MedianSelect::XS

void
xs_median (...)
    PROTOTYPE: @\@
    INIT:
      long *numbers = NULL;
      unsigned int median, realitems;
      enum { BUBBLE_SORT = 1, QUICK_SORT };
    PPCODE:
      if (items == 1)
        {
          if (SvROK (ST(0)))
            {
              if (SvTYPE (SvRV(ST(0))) == SVt_PVAV)
                {
                  AV *aref = (AV *)SvRV (ST(0));
                  unsigned int i;
                  realitems = av_len (aref) + 1;
                  Newx (numbers, realitems, long);
                  for (i = 0; i < realitems; i++)
                    numbers[i] = (long)SvIV (*av_fetch(aref, i, 0));
                }
              else
                croak_msg ("reference is not an array reference");
            }
          else
            croak_msg ("requires either list or reference to an array");
        }
      else
        {
          unsigned int i;
          realitems = items;
          Newx (numbers, realitems, long);
          for (i = 0; i < realitems; i++)
            numbers[i] = (long)SvIV (ST(i));
        }

      switch (SvIV (get_sv("Algorithm::MedianSelect::XS::ALGORITHM", FALSE)))
        {
          case BUBBLE_SORT:
            bubble_sort (numbers, realitems);
            break;
          case QUICK_SORT:
            qsort (numbers, realitems, sizeof (long), quick_sort);
            break;
          default:
            croak_msg_internal ("no mode available");
        }

      if (realitems % 2 == 0)
        median = realitems / 2;
      else
        median = (realitems - 1) / 2;

      EXTEND (SP, 1);
      PUSHs (sv_2mortal(newSViv(numbers[median])));

      Safefree (numbers);
