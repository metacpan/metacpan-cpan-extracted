Business-RO-TaxDeduction
========================
Ștefan Suciu
2016-06-05

Version: 0.010

A Romanian salary tax deduction calculator.

Starting with the v0.010 version, there is a new optional `year`
parameter that can be used to choose between the current regulations
(OMFP 52/2016), or the previous - OMFP 1016/2005.

This is an alternative to the database driven implementation for the
tax deductions calculation.  It may be suitable for small programs or
even for oneliners line this:

```
$ perl -MBusiness::RO::TaxDeduction -E'$td=Business::RO::TaxDeduction->new(vbl=>1400);say $td->tax_deduction'
300
```

It's a little too long but it works ;)
