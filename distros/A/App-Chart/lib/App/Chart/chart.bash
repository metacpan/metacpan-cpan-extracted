# Chart support for bash command line completions.

# Copyright 2006, 2007, 2008, 2009 Kevin Ryde

# This file is part of Chart.
#
# Chart is free software; you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation; either version 3, or (at your option) any later version.
#
# Chart is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
# details.
#
# You should have received a copy of the GNU General Public License
# along with Chart.  If not, see <http://www.gnu.org/licenses/>.


# This script sets up command line completions in bash for the chart
# program.  See "Programmable Completion" and "Commands For Completion" in
# the bash manual for how that works.
#
# Stock symbols from the Chart database are completed, as are the various
# chart command line options.
#
# This script can be used standalone, or with the bash_completion project
#
#     http://freshmeat.net/projects/bashcompletion/
#

# To install you can either
#
# 1) Source from your .bashrc,
#
#        . /usr/share/perl5/App/Chart/chart.bash
#
# 2) Or load it with bash_completion, to have it only when using that, either
#
#    2a) Source from your ~/.bash_completion file,
#
#            . /usr/share/perl5/App/Chart/chart.bash
#
#    2b) Or put it in the $BASH_COMPLETION_DIR directory (which might be for
#        instance "/etc/bash_completion.d"), and bash_completion will source
#        it (along with everything else in that directory).
#


# $_chart_completions__database_file is per App::Chart::chart_directory().
# If you point that directory somewhere new in your ~/Chart/init.pl then you
# can set _chart_completions__data_directory in your .bashrc to match.
#
# It'd be possible to run up a chart process to query it, but that'd be a
# bit slow for interactive use.  Maybe just on the first run.
#
if [ -z "$_chart_completions__data_directory" ]; then
  _chart_completions__data_directory=~/Chart
fi


_chart_completions()
{
  # $1 is command being completed, ie. "chart"
  # $2 is current word, ie. the one to complete
  # $3 is the preceding word

  # names $cur and $prev are needed if using _filedir() or similar from the
  # bash_completion package
  local cur=$2 prev=$3
  COMPREPLY=()

  if [ "$prev" = --display ]; then
    # a display name, but alas there's no easy way to find out what's available
    return 0
  fi

  # command line option
  case "$cur" in
    -*)
      # a command line option
      #
      local options='
    	--alerts
    	--all
    	--backto
    	--debug
    	--display
    	--download
    	--favourites
    	--historical
    	--help -h
    	--ticker
    	--vacuum
    	--verbose
    	--version -v
        --watchlist'
      local IFS=$' \n\t'
      COMPREPLY=( $( compgen -W "$options" -- $cur ) )
      return 0
      ;;
  esac

  # Otherwise a Chart symbol, being symbols queried from the database info
  # table.
  #
  # "LIKE 'foo%'" is a case-insensitive pattern match.
  #
  # The expression ${cur//\'/''} doubles up any single quotes to quote them
  # as an sql string literal.
  #
  local IFS=$'\n'
  COMPREPLY=$( sqlite3 $_chart_completions__data_directory/database.sqdb \
               "SELECT symbol FROM info WHERE symbol LIKE '${cur//\'/''}%'" )
  return 0
}

# "-o filenames" ensures spaces in symbols are escaped.  However that's a
# feature introduced in bash 2.05, which dates from early 2001, so if you're
# using a very ancient bash you might have to take it out.
#
complete -o filenames -F _chart_completions chart



# Local variables:
# mode: sh
# sh-shell: bash
# sh-indentation: 2
# End:
