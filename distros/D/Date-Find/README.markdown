A minute tool to move files into a directory hierarchy using the date/time
in the filenames.

# Usage

    move-year --create -ymd -i ~/Downloads/bank-statement-2022-01-01.pdf ~/Documents/finance/my-bank/
    move-year --create -dmy -i ~/Downloads/tax-report-31112021.pdf ~/Documents/finance/taxes/

The files will be moved to the directories `~/Documents/finance/my-bank/2022`
and `~/Documents/finance/taxes/2021` respectively. Directories will be created.

Move files into subdirectories according to year/month

    move-year --create -s ym --part-separator "/" -ym -i foo-2022-03.pdf ~/Documents/foo
    # Moves the file into ~/Documents/foo/2022/03

# Options

  * dry-run|n - only print, don't change anything
  * verbose - output verbose messages
  * date-regex|d - (Perl) regular expression to recognize the date parts
  * date-regex-order|o - order of the components if you don't use named captures
  * date-type - the date type to look for (dmy, ymd, ym, my, y)
  * ymd - shorthand for --date-type=ymd
  * dmy - shorthand for --date-type=dmy
  * ym - shorthand for --date-type=ym
  * my - shorthand for --date-type=my
  * y - shorthand for --date-type=y
  * force|f - overwrite files if they exist
  * create - create intermediate directories
  * directory-style|s - style of the directory (default: y)
  * part-separator - separator of the directory parts, use "/" for subdirectories
  * i - don't overwrite (the default)
  * strict - stop if a file does not have a timestamp in its name
