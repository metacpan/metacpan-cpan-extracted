#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

enum { false, true };

bool
quick_sort (const long *num1, const long *num2)
{
    if (*num1 <  *num2) return -1;
    if (*num1 == *num2) return  0;
    if (*num1 >  *num2) return  1;
}

void
bubble_sort (long *numbers, unsigned int realitems)
{
    bool sorted;
    unsigned int i;
    long buffer;

    do
      {
        sorted = true;
        for (i = 0; i < (realitems - 1); i++)
          {
            if ((numbers[i - 1] < numbers[i]) && (numbers[i] < numbers[i + 1]))
              continue;
            if (numbers[i] > numbers[i + 1])
              {
                buffer         = numbers[i];
                numbers[i]     = numbers[i + 1];
                numbers[i + 1] = buffer;
                sorted = false;
              }
          }
      }
    while (!sorted);
}

MODULE = Algorithm::MedianSelect::XS        PACKAGE = Algorithm::MedianSelect::XS

void
xs_median (...)
    PROTOTYPE: @\@
    INIT:
      long numbers[items > 1 ? items : (av_len ((AV*)SvRV(ST(0))) + 1)];
      unsigned int i, median, realitems;
      AV* aref;
    PPCODE:
      if (items == 1)
        {
          if (SvROK (ST(0)))
            {
              if (SvTYPE (SvRV(ST(0))) == SVt_PVAV)
                {
                  aref = (AV*) SvRV (ST(0));
                  for (i = 0; i <= av_len (aref); i++)
                    numbers[i] = SvIV (*av_fetch(aref, i, 0));
                  realitems = av_len (aref) + 1;
                }
              else
                croak ("median(): reference is not a list reference");
            }
          else
            croak ("median(): requires either list or reference to list");
        }
      else
        {
          for (i = 0; i < items; i++)
            numbers[i] = SvIV (ST(i));
          realitems = items;
        }

      switch (SvIV (get_sv("Algorithm::MedianSelect::XS::ALGORITHM", FALSE)))
        {
          case 1:
            bubble_sort (numbers, realitems);
            break;
          case 2:
            qsort (numbers, realitems, sizeof (long), (void *) quick_sort);
            break;
          default:
            croak ("median(): internal error: no mode available");
            break;
        }

      if (realitems % 2 == 0)
        median = realitems / 2;
      else
        median = (realitems - 1) / 2;

      EXTEND (SP, 1);
      PUSHs (sv_2mortal(newSViv(numbers[median])));
