# ControlBreak
cpan distribution ControlBreak

The ControlBreak module provides a class that is used to detect control
breaks; i.e. when a value changes.

Typically, the data being retrieved or iterated over is ordered and
there may be more than one value that is of interest. For example
consider a table of population data with columns for country, district
and city, sorted by country and district. With this module you can
create an object that will detect changes in the district or country,
considered level 1 and level 2 respectively. The calling program can
take action, such as printing subtotals, whenever level changes are
detected.

Ordered data is not a requirement. An example using unordered data would
be counting consecutive numbers within a data stream; e.g. 0 0 1 1 1 1 0
1 1. Using ControlBreak you can detect each change and count the
consecutive values, yielding two zeros, four 1's, one zero, and two 1's.
