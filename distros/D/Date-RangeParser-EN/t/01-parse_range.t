#!/usr/bin/perl

use strict;
use warnings;

use Date::RangeParser::EN;
use Test::More;

my @tests = (
    {
        description       => 'date range for today',
        date_range_string => 'today',
        as_of         => '2011-12-31',
        beg           => '12/31/2011 12:00:00AM',
        end           => '12/31/2011 11:59:59PM',
    }, {
        date_range_string => 'the next 2 days',
        as_of         => '1980-02-28',
        beg           => '02/29/1980 12:00:00AM',
        end           => '03/01/1980 11:59:59PM',
    }, {
        date_range_string => 'last month',
        as_of         => '2008-01-15',
        beg           => '12/01/2007 12:00:00AM',
        end           => '12/31/2007 11:59:59PM',
    }, {
        date_range_string => 'next month',
        as_of         => '2010-01-21',
        beg           => '02/01/2010 12:00:00AM',
        end           => '02/28/2010 11:59:59PM',
    }, {
        date_range_string => 'this month',
        as_of         => '1980-08-10',
        beg           => '08/01/1980 12:00:00AM',
        end           => '08/31/1980 11:59:59PM',
    }, {
        description       => 'last 3 months (includes current month)',
        date_range_string => 'last 3 months',
        as_of         => '2008-01-15',
        beg           => '11/01/2007 12:00:00AM',
        end           => '01/31/2008 11:59:59PM',
    }, {
        description       => 'last three months (includes current month)',
        date_range_string => 'last three months',
        as_of         => '2008-01-15',
        beg           => '11/01/2007 12:00:00AM',
        end           => '01/31/2008 11:59:59PM',
    }, {
        description       => 'next 3 weeks from a Sunday',
        date_range_string => 'next 3 weeks',
        as_of         => '2012-12-09',
        beg           => '12/16/2012 12:00:00AM',
        end           => '01/05/2013 11:59:59PM',
    }, {
        description       => 'next three weeks from a Sunday',
        date_range_string => 'next three weeks',
        as_of         => '2012-12-09',
        beg           => '12/16/2012 12:00:00AM',
        end           => '01/05/2013 11:59:59PM',
    }, {
        description       => 'next week from a Wednesday',
        date_range_string => 'next week',
        as_of         => '2013-09-04',
        beg           => '09/08/2013 12:00:00AM',
        end           => '09/14/2013 11:59:59PM',
    }, {
        description       => 'this week from a Sunday',
        date_range_string => 'this week',
        as_of         => '2013-09-08',
        beg           => '09/08/2013 12:00:00AM',
        end           => '09/14/2013 11:59:59PM',
    }, {
        description       => 'last week from a Sunday',
        date_range_string => 'last week',
        as_of         => '2014-11-16',
        beg           => '11/09/2014 12:00:00AM',
        end           => '11/15/2014 11:59:59PM',
    }, {
        description       => 'last 3 weeks (includes current week)',
        date_range_string => 'last 3 weeks',
        as_of         => '2008-08-10', # sunday
        beg           => '07/27/2008 12:00:00AM',
        end           => '08/16/2008 11:59:59PM',
    }, {
        description       => 'last three weeks (includes current week)',
        date_range_string => 'last three weeks',
        as_of         => '2008-08-10', # sunday
        beg           => '07/27/2008 12:00:00AM',
        end           => '08/16/2008 11:59:59PM',
    }, {
        description       => 'last 8 weeks (includes current week)',
        date_range_string => 'last 8 weeks',
        as_of         => '2008-08-16', # saturday
        beg           => '06/22/2008 12:00:00AM',
        end           => '08/16/2008 11:59:59PM',
    }, {
        description       => 'last eight weeks (includes current week)',
        date_range_string => 'last eight weeks',
        as_of         => '2008-08-16', # saturday
        beg           => '06/22/2008 12:00:00AM',
        end           => '08/16/2008 11:59:59PM',
    }, {
        description       => 'last Monday from a Wednesday is 9 days ago',
        date_range_string => 'last Monday',
        as_of         => '2009-10-21',
        beg           => '10/12/2009 12:00:00AM',
        end           => '10/12/2009 11:59:59PM',
    }, {
        description       => 'this past Monday from a Wednesday is 2 days ago',
        date_range_string => 'this past Monday',
        as_of         => '2009-10-21',
        beg           => '10/19/2009 12:00:00AM',
        end           => '10/19/2009 11:59:59PM',
    }, {
        description       => '4 Sundays from a Tuesday',
        date_range_string => '4 Sundays from now',
        as_of         => '2010-01-19',
        beg           => '02/14/2010 12:00:00AM',
        end           => '02/14/2010 11:59:59PM',
    }, {
        description       => '4 Fridays from a Sunday',
        date_range_string => '4 Fridays from now',
        as_of         => '2010-01-17',
        beg           => '02/12/2010 12:00:00AM',
        end           => '02/12/2010 11:59:59PM',
    }, {
        date_range_string => '2nd of 2 months from now',
        as_of         => '2010-01-21',
        beg           => '03/02/2010 12:00:00AM',
        end           => '03/02/2010 11:59:59PM',
    }, {
        date_range_string => '28th of 2 months from now',
        as_of         => '2010-01-21',
        beg           => '03/28/2010 12:00:00AM',
        end           => '03/28/2010 11:59:59PM',
    }, {
        date_range_string => '1st of 4 months ago',
        as_of         => '2010-03-31',
        beg           => '11/01/2009 12:00:00AM',
        end           => '11/01/2009 11:59:59PM',
    }, {
        date_range_string => 'the end of this month',
        as_of         => '2001-02-23',
        beg           => '02/28/2001 12:00:00AM',
        end           => '02/28/2001 11:59:59PM',
    }, {
        date_range_string => 'yesterday',
        as_of         => '2015-04-01',
        beg           => '03/31/2015 12:00:00AM',
        end           => '03/31/2015 11:59:59PM',
    }, {
        date_range_string => 'tomorrow',
        as_of         => '2012-11-30',
        beg           => '12/01/2012 12:00:00AM',
        end           => '12/01/2012 11:59:59PM',
    }, {
        date_range_string => 'this year',
        as_of         => '2017-01-01',
        beg           => '01/01/2017 12:00:00AM',
        end           => '12/31/2017 11:59:59PM',
    }, {
        date_range_string => 'last 17 years',
        as_of         => '2010-03-31',
        beg           => '01/01/1994 12:00:00AM',
        end           => '12/31/2010 11:59:59PM',
    }, {
        date_range_string => 'last seventeen years',
        as_of         => '2010-03-31',
        beg           => '01/01/1994 12:00:00AM',
        end           => '12/31/2010 11:59:59PM',
    }, {
        date_range_string => 'next 20 years',
        as_of         => '1999-12-31',
        beg           => '01/01/2000 12:00:00AM',
        end           => '12/31/2019 11:59:59PM',
    }, {
        date_range_string => 'next twenty years',
        as_of         => '1999-12-31',
        beg           => '01/01/2000 12:00:00AM',
        end           => '12/31/2019 11:59:59PM',
    }, {
        date_range_string => 'this quarter',
        as_of         => '2010-03-31',
        beg           => '01/01/2010 12:00:00AM',
        end           => '03/31/2010 11:59:59PM',
    }, {
        date_range_string => 'last quarter',
        as_of         => '2010-01-01',
        beg           => '10/01/2009 12:00:00AM',
        end           => '12/31/2009 11:59:59PM',
    }, {
        date_range_string => 'next quarter',
        as_of         => '2010-10-18',
        beg           => '01/01/2011 12:00:00AM',
        end           => '03/31/2011 11:59:59PM',
    }, {
        date_range_string => 'last 7 quarters',
        as_of         => '2010-07-19',
        beg           => '01/01/2009 12:00:00AM',
        end           => '09/30/2010 11:59:59PM',
    }, {
        date_range_string => 'next 3 quarters',
        as_of         => '2010-02-02',
        beg           => '04/01/2010 12:00:00AM',
        end           => '12/31/2010 11:59:59PM',
    }, {
        description       => '3 Thursdays ago from a Sunday',
        date_range_string => '3 Thursdays ago',
        as_of         => '2010-03-14',
        beg           => '02/25/2010 12:00:00AM',
        end           => '02/25/2010 11:59:59PM',
    }, {
        description       => '3 Thursdays ago from a Thursday',
        date_range_string => '3 Thursdays ago',
        as_of         => '2011-06-23',
        beg           => '06/02/2011 12:00:00AM',
        end           => '06/02/2011 11:59:59PM',
    }, {
        description       => 'this coming Saturday from a Saturday is in 7 days',
        date_range_string => 'this coming Saturday',
        as_of         => '2011-05-21',
        beg           => '05/28/2011 12:00:00AM',
        end           => '05/28/2011 11:59:59PM',
    }, {
        description       => 'this past Monday from a Monday is last week',
        date_range_string => 'this past Monday',
        as_of         => '2011-07-04',
        beg           => '06/27/2011 12:00:00AM',
        end           => '06/27/2011 11:59:59PM',
    }, {
        description       => 'this Sunday from a Monday is yesterday',
        date_range_string => 'this Sunday',
        as_of         => '2011-08-15',
        beg           => '08/14/2011 12:00:00AM',
        end           => '08/14/2011 11:59:59PM',
    }, {
        description       => 'this Monday from a Sunday is tomorrow',
        date_range_string => 'this Monday',
        as_of         => '2006-12-31',
        beg           => '01/01/2007 12:00:00AM',
        end           => '01/01/2007 11:59:59PM',
    }, {
        description       => 'last Tuesday from a Sunday',
        date_range_string => 'last Tuesday',
        as_of         => '2014-01-05',
        beg           => '12/31/2013 12:00:00AM',
        end           => '12/31/2013 11:59:59PM',
    }, {
        description       => 'this Sunday from a Monday is yesterday',
        date_range_string => 'this Sunday',
        as_of         => '2011-08-15',
        beg           => '08/14/2011 12:00:00AM',
        end           => '08/14/2011 11:59:59PM',
    }, {
        description       => 'this January from a March is 2 months ago',
        date_range_string => 'this January',
        as_of         => '2011-03-15',
        beg           => '01/01/2011 12:00:00AM',
        end           => '01/31/2011 11:59:59PM',
    }, {
        description       => 'this Apr from a January is in 3 months',
        date_range_string => 'this Apr',
        as_of         => '2011-01-31',
        beg           => '04/01/2011 12:00:00AM',
        end           => '04/30/2011 11:59:59PM',
    }, {
        description       => 'last Feb from a November is Feb last year',
        date_range_string => 'last Feb',
        as_of         => '2011-11-30',
        beg           => '02/01/2010 12:00:00AM',
        end           => '02/28/2010 11:59:59PM',
    }, {
        description       => 'next June from a June is next year',
        date_range_string => 'next June',
        as_of         => '2012-06-15',
        beg           => '06/01/2013 12:00:00AM',
        end           => '06/30/2013 11:59:59PM',
    }, {
        description       => '3 days ago from June 15 is June 12',
        date_range_string => '3 days ago',
        as_of         => '2013-06-15',
        beg           => '06/12/2013 12:00:00AM',
        end           => '06/12/2013 11:59:59PM',
    }, {
        description       => '3 months ago from June 15 is March 15',
        date_range_string => '3 months ago',
        as_of         => '2013-06-15',
        beg           => '03/15/2013 12:00:00AM',
        end           => '03/15/2013 11:59:59PM',
    }, {
        description       => '3 weeks ago from June 22 is June 1',
        date_range_string => '3 weeks ago',
        as_of         => '2013-06-22',
        beg           => '06/01/2013 12:00:00AM',
        end           => '06/01/2013 11:59:59PM',
    }, {
        description       => '3 quarters ago from June 21 is Sept 21',
        date_range_string => '3 quarters ago',
        as_of         => '2013-06-21',
        beg           => '09/21/2012 12:00:00AM',
        end           => '09/21/2012 11:59:59PM',
    }, {
        date_range_string => '9/1/2012-9/30/2012',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => '9/1/12-9/30/12',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => '9/1-9/30',
        as_of             => '2013-06-22',
        beg               => '09/01/2013 12:00:00AM',
        end               => '09/30/2013 11:59:59PM',
    }, {
        date_range_string => '9/1/2012 to 9/30/2012',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => '9/1/12 thru 9/30/12',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => '9/1 through the 9/30',
        as_of             => '2013-06-22',
        beg               => '09/01/2013 12:00:00AM',
        end               => '09/30/2013 11:59:59PM',
    }, {
        date_range_string => '9-1-2012 thru the 9-30-2012',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => '9-1-2012 - 9-30-2012',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => '9-1-12 to 9-30-12',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => '9-1 through the 9-30',
        as_of             => '2013-06-22',
        beg               => '09/01/2013 12:00:00AM',
        end               => '09/30/2013 11:59:59PM',
    }, {
        date_range_string => '2012-9-1 to 2012-9-30',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => '2012-9-1 - 2012-9-30',
        as_of             => '2013-06-22',
        beg               => '09/01/2012 12:00:00AM',
        end               => '09/30/2012 11:59:59PM',
    }, {
        date_range_string => 'August 2012',
        as_of             => '2013-06-22',
        beg               => '08/01/2012 12:00:00AM',
        end               => '08/31/2012 11:59:59PM',
    }, {
        date_range_string => 'August',
        as_of             => '2013-06-22',
        beg               => '08/01/2013 12:00:00AM',
        end               => '08/31/2013 11:59:59PM',
    }, {
        date_range_string => 'August 29',
        as_of             => '2013-06-22',
        beg               => '08/29/2013 12:00:00AM',
        end               => '08/29/2013 11:59:59PM',
    }, {
        date_range_string => 'August 29th',
        as_of             => '2013-06-22',
        beg               => '08/29/2013 12:00:00AM',
        end               => '08/29/2013 11:59:59PM',
    }, {
        date_range_string => 'Aug 2012',
        as_of             => '2013-06-22',
        beg               => '08/01/2012 12:00:00AM',
        end               => '08/31/2012 11:59:59PM',
    }, {
        date_range_string => 'Aug',
        as_of             => '2013-06-22',
        beg               => '08/01/2013 12:00:00AM',
        end               => '08/31/2013 11:59:59PM',
    }, {
        date_range_string => 'Aug 29',
        as_of             => '2013-06-22',
        beg               => '08/29/2013 12:00:00AM',
        end               => '08/29/2013 11:59:59PM',
    }, {
        date_range_string => 'Aug 29th',
        as_of             => '2013-06-22',
        beg               => '08/29/2013 12:00:00AM',
        end               => '08/29/2013 11:59:59PM',
    }, {
        date_range_string => 'Jun - 2/12/2014',
        as_of             => '2013-06-22',
        beg               => '06/01/2013 12:00:00AM',
        end               => '02/12/2014 11:59:59PM',
    }, {
        date_range_string => 'Since 1/27/1993',
        as_of             => '2012-10-02',
        beg               => '01/27/1993 12:00:00AM',
        end               => '10/02/2012 11:59:59PM',
    }, {
        date_range_string => 'since 8/24/1989',
        as_of             => '2012-10-01',
        beg               => '08/24/1989 12:00:00AM',
        end               => '10/01/2012 11:59:59PM',
    }, {
        date_range_string => '31st of last month',
        as_of             => '2012-11-12',
        beg               => '10/31/2012 12:00:00AM',
        end               => '10/31/2012 11:59:59PM',
    }, {
        date_range_string => '31st of 1 month from now',
        as_of             => '2012-11-12',
        beg               => '12/31/2012 12:00:00AM',
        end               => '12/31/2012 11:59:59PM',
    }, {
        date_range_string => 'before 4/18/2014',
        as_of             => '2014-04-18',
        beg               => '-inf',
        end               => '04/17/2014 11:59:59PM',
    }, {
        date_range_string => '< 4/18/2014',
        as_of             => '2010-01-28',
        beg               => '-inf',
        end               => '04/17/2014 11:59:59PM',
    }, {
        # same as previous test, w/o a space after <
        date_range_string => '<4/18/2014',
        as_of             => '2010-01-28',
        beg               => '-inf',
        end               => '04/17/2014 11:59:59PM',
    }, {
        date_range_string => '<= 12/25/2013',
        as_of             => '2014-04-18',
        beg               => '-inf',
        end               => '12/25/2013 11:59:59PM',
    }, {
        # same as previous test, w/o a space after <=
        date_range_string => '<=12/25/2013',
        as_of             => '2014-04-18',
        beg               => '-inf',
        end               => '12/25/2013 11:59:59PM',
    }, {
        date_range_string => 'after 2/5/1990',
        as_of             => '2014-04-18',
        beg               => '02/06/1990 12:00:00AM',
        end               => 'inf',
    }, {
        date_range_string => '> 2/5/1990',
        as_of             => '2010-01-28',
        beg               => '02/06/1990 12:00:00AM',
        end               => 'inf',
    }, {
        # same as previous test, w/o a space after >
        date_range_string => '>2/5/1990',
        as_of             => '2010-01-28',
        beg               => '02/06/1990 12:00:00AM',
        end               => 'inf',
    }, {
        date_range_string => '>= 07/04/2776',
        as_of             => '1776-07-04',
        beg               => '07/04/2776 12:00:00AM',
        end               => 'inf',
    }, {
        # same as previous test, w/o a space after >=
        date_range_string => '>=07/04/2776',
        as_of             => '1776-07-04',
        beg               => '07/04/2776 12:00:00AM',
        end               => 'inf',
    }, {
        # "after X" means "after the end of X"
        # "after today" extends into infinity (it doesn't end)
        # thus "after after today" means "after the end of infinity"
        # and begins in infinity :)
        date_range_string => 'after after today',
        as_of             => '2000-01-01',
        beg               => 'inf',
        end               => 'inf',
    }, {
        date_range_string => 'before before today',
        as_of             => '2000-01-01',
        beg               => '-inf',
        end               => '-inf',
    }, {
        date_range_string => 'before after today',
        as_of             => '2000-01-01',
        beg               => '-inf',
        end               => '01/01/2000 11:59:59PM',
    }, {
        # "since" truncates ->{end} to the end of the as_of date
        date_range_string => 'since before 01/01/3000',
        as_of             => '2000-01-01',
        beg               => '-inf',
        end               => '01/01/2000 11:59:59PM',
    }, {
        # this isn't really a range, but that's expected
        date_range_string => 'after after today - before before today',
        as_of             => '2000-01-01',
        beg               => 'inf',
        end               => '-inf',
    }, {
        # ISO format without the seconds
        date_range_string => '2023-06-16 15:47:12 - 2023-06-24 12:23:45',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:12PM',
        end               => '06/24/2023 12:23:45PM',
    }, {
        # 12 hour format with noon
        date_range_string => '2023-06-16 3pm - 2023-06-24 noon',
        as_of             => '2023-06-16 15:47:12',
        beg               => '06/16/2023 03:00:00PM',
        end               => '06/24/2023 12:00:00PM',
    }, {
        # 12 hour format with noon
        date_range_string => '2023-06-16 3pm - 2023-06-24 noon',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:00:00PM',
        end               => '06/24/2023 12:00:00PM',
    }, {
        # Guess minutes
        date_range_string => '2023-06-16 3pm',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:00:00PM',
        end               => '06/16/2023 03:59:59PM',
    }, {
        # 2nd in a date
        date_range_string => 'August 2nd 1985',
        as_of             => '2023-06-16 15:47:23',
        beg               => '08/02/1985 12:00:00AM',
        end               => '08/02/1985 11:59:59PM',
    }, {
        # second in a date
        date_range_string => 'August second 1985',
        as_of             => '2023-06-16 15:47:23',
        beg               => '08/02/1985 12:00:00AM',
        end               => '08/02/1985 11:59:59PM',
    }, {
        # 2nd of this month
        date_range_string => '2nd of this month',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/02/2023 12:00:00AM',
        end               => '06/02/2023 11:59:59PM',
    }, {
        # second of this month
        date_range_string => 'second of this month',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/02/2023 12:00:00AM',
        end               => '06/02/2023 11:59:59PM',
    }, {
        # second of this month
        date_range_string => 'second of 2 months ago',
        as_of             => '2023-06-16 15:47:23',
        beg               => '04/02/2023 12:00:00AM',
        end               => '04/02/2023 11:59:59PM',
    }, {
        # second of this month
        date_range_string => '2nd of two months ago',
        as_of             => '2023-06-16 15:47:23',
        beg               => '04/02/2023 12:00:00AM',
        end               => '04/02/2023 11:59:59PM',
    }, {
        # this hour
        date_range_string => 'this hour',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:00:00PM',
        end               => '06/16/2023 03:59:59PM',
    }, {
        # this minute
        date_range_string => 'this minute',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:00PM',
        end               => '06/16/2023 03:47:59PM',
    }, {
        # this second
        date_range_string => 'this second',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:23PM',
        end               => '06/16/2023 03:47:23PM',
    }, {
        # this second
        date_range_string => 'this 2nd',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:23PM',
        end               => '06/16/2023 03:47:23PM',
    }, {
        # past hour
        date_range_string => 'past hour',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 02:00:00PM',
        end               => '06/16/2023 03:59:59PM',
    }, {
        # past minute
        date_range_string => 'past minute',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:46:00PM',
        end               => '06/16/2023 03:47:59PM',
    }, {
        # past second
        date_range_string => 'past second',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:22PM',
        end               => '06/16/2023 03:47:23PM',
    }, {
        # past second
        date_range_string => 'past 2nd',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:22PM',
        end               => '06/16/2023 03:47:23PM',
    }, {
        # next hour
        date_range_string => 'next hour',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:23PM',
        end               => '06/16/2023 04:47:23PM',
    }, {
        # next minute
        date_range_string => 'next minute',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:23PM',
        end               => '06/16/2023 03:48:23PM',
    }, {
        # next second
        date_range_string => 'next second',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:23PM',
        end               => '06/16/2023 03:47:24PM',
    }, {
        # next second
        date_range_string => 'next 2nd',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/16/2023 03:47:23PM',
        end               => '06/16/2023 03:47:24PM',
    }, {
        # N business days ago from a Monday
        date_range_string => 'three business days ago',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/14/2023 12:00:00AM',
        end               => '06/14/2023 11:59:59PM',
    }, {
        # N business days ago from a Saturday
        date_range_string => 'three business days ago',
        as_of             => '2023-06-17 15:47:23',
        beg               => '06/14/2023 12:00:00AM',
        end               => '06/14/2023 11:59:59PM',
    }, {
        # N business days ago to M business days ago as of a Monday
        date_range_string => 'three business days ago to two business days ago',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/14/2023 12:00:00AM',
        end               => '06/15/2023 11:59:59PM',
    }, {
        # N business days ago to M business days ago as of a Saturday
        date_range_string => 'three business days ago to two business days ago',
        as_of             => '2023-06-17 15:47:23',
        beg               => '06/14/2023 12:00:00AM',
        end               => '06/15/2023 11:59:59PM',
    }, {
        # N minutes ago
        date_range_string => 'three minutes ago',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 03:44:00PM',
        end               => '06/19/2023 03:44:59PM',
    }, {
        # N hours ago
        date_range_string => 'three hours ago',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 12:00:00PM',
        end               => '06/19/2023 12:59:59PM',
    }, {
        # N weekdays ago
        date_range_string => 'three tuesdays ago',
        as_of             => '2023-06-19 15:47:23',
        beg               => '05/30/2023 12:00:00AM',
        end               => '05/30/2023 11:59:59PM',
    }, {
        # N years ago
        date_range_string => 'three years ago',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2020 12:00:00AM',
        end               => '06/19/2020 11:59:59PM',
    }, {
        # N days ago
        date_range_string => 'three days ago',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/16/2023 12:00:00AM',
        end               => '06/16/2023 11:59:59PM',
    }, {
        # N quarters ago
        date_range_string => 'three quarters ago',
        as_of             => '2023-06-19 15:47:23',
        beg               => '09/19/2022 12:00:00AM',
        end               => '09/19/2022 11:59:59PM',
    }, {
        # N days from now
        date_range_string => 'three days from now',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 03:47:23PM',
        end               => '06/22/2023 03:47:23PM',
    }, {
        # N weeks from now
        date_range_string => 'three weeks from now',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 03:47:23PM',
        end               => '07/10/2023 03:47:23PM',
    }, {
        # N months from now
        date_range_string => 'three months from now',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 03:47:23PM',
        end               => '09/19/2023 03:47:23PM',
    }, {
        # N years from now
        date_range_string => 'three years from now',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 03:47:23PM',
        end               => '06/19/2026 03:47:23PM',
    }, {
        # N seconds from now
        date_range_string => 'three seconds from now',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 03:47:23PM',
        end               => '06/19/2023 03:47:26PM',
    }, {
        # N minutes from now
        date_range_string => 'three minutes from now',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 03:47:23PM',
        end               => '06/19/2023 03:50:23PM',
    }, {
        # N hours from now
        date_range_string => 'three hours from now',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/19/2023 03:47:23PM',
        end               => '06/19/2023 06:47:23PM',
    }, {
        # past Large business days
        date_range_string => 'past ten business days',
        as_of             => '2023-07-27 15:47:23',
        beg               => '07/14/2023 12:00:00AM',
        end               => '07/27/2023 11:59:59PM',
    }, {
        # past N business days from a Monday
        date_range_string => 'past three business days',
        as_of             => '2023-06-19 15:47:23',
        beg               => '06/15/2023 12:00:00AM',
        end               => '06/19/2023 11:59:59PM',
    }, {
        # past N business days from a Friday
        date_range_string => 'past three business days',
        as_of             => '2023-06-16 15:47:23',
        beg               => '06/14/2023 12:00:00AM',
        end               => '06/16/2023 11:59:59PM',
    }, {
        # past N business days from a Saturday
        date_range_string => 'past three business days',
        as_of             => '2023-06-17 15:47:23',
        beg               => '06/14/2023 12:00:00AM',
        end               => '06/16/2023 11:59:59PM',
    },  {
        # past N business days from a Sunday
        date_range_string => 'past three business days',
        as_of             => '2023-06-18 15:47:23',
        beg               => '06/14/2023 12:00:00AM',
        end               => '06/16/2023 11:59:59PM',
    }, {
        description       => 'Minutes Ago',
        date_range_string => '2 minutes ago',
        as_of             => '2023-06-06 07:23:00',
        beg               => '06/06/2023 07:21:00AM',
        end               => '06/06/2023 07:21:59AM',
    }, {
        description       => 'Past N minutes',
        date_range_string => 'past 2 minutes',
        as_of             => '2023-06-06 07:23:00',
        beg               => '06/06/2023 07:21:00AM',
        end               => '06/06/2023 07:23:59AM',
    }, {
        description       => 'Last N minutes',
        date_range_string => 'last 2 minutes',
        as_of             => '2023-06-06 07:23:00',
        beg               => '06/06/2023 07:21:00AM',
        end               => '06/06/2023 07:23:59AM',
    }, {
        description       => 'past N hours',
        date_range_string => 'past two hours',
        as_of             => '2023-06-06 07:23:00',
        beg               => '06/06/2023 05:00:00AM',
        end               => '06/06/2023 07:59:59AM',
    }, {
        description       => 'last N hours',
        date_range_string => 'last two hours',
        as_of             => '2023-06-06 07:23:00',
        beg               => '06/06/2023 05:00:00AM',
        end               => '06/06/2023 07:59:59AM',
    }, {
        description       => 'past 3 tuesdays',
        date_range_string => 'past 3 tuesdays',
        as_of             => '2023-06-06 07:23:00',
        beg               => '05/02/2023 12:00:00AM',
        end               => '05/16/2023 11:59:59PM',
    }, {
        description       => 'next 3 tuesdays',
        date_range_string => 'next 3 tuesdays',
        as_of             => '2023-06-06 07:23:00',
        beg               => '06/13/2023 12:00:00AM',
        end               => '06/27/2023 11:59:59PM',
    }, {
        description       => 'next 3 tuesdays',
        date_range_string => 'next 3 tuesdays',
        as_of             => '2023-06-07 07:23:00',
        beg               => '06/13/2023 12:00:00AM',
        end               => '06/27/2023 11:59:59PM',
    }, {
        description       => 'mm-dd-yyyy',
        date_range_string => '08-02-1985',
        as_of             => '2023-06-07 07:23:00',
        beg               => '08/02/1985 12:00:00AM',
        end               => '08/02/1985 11:59:59PM',
    }, {
        description       => 'mm-dd-yyyy',
        date_range_string => '08-25-1985',
        as_of             => '2023-06-07 07:23:00',
        beg               => '08/25/1985 12:00:00AM',
        end               => '08/25/1985 11:59:59PM',
    }, {
        description       => 'mm-dd-yyyy - mm/dd/yyyy',
        date_range_string => '01-01-2014 - 02/28/2016',
        as_of             => '2023-06-07 07:23:00',
        beg               => '01/01/2014 12:00:00AM',
        end               => '02/28/2016 11:59:59PM',
    }, {
        description       => 'mm-dd-yyyy - mm-dd-yyyy',
        date_range_string => '01-01-2014 - 02-28-2016',
        as_of             => '2023-06-07 07:23:00',
        beg               => '01/01/2014 12:00:00AM',
        end               => '02/28/2016 11:59:59PM',
    }, {
        description       => 'mm/dd/yyyy - mm-dd-yyyy',
        date_range_string => '01/01/2014 - 02-28-2016',
        as_of             => '2023-06-07 07:23:00',
        beg               => '01/01/2014 12:00:00AM',
        end               => '02/28/2016 11:59:59PM',
    }, {
        # Midnight
        date_range_string => 'midnight August 4, 2023',
        as_of             => '2023-06-07 07:23:00',
        beg               => '08/04/2023 12:00:00AM',
        end               => '08/04/2023 12:00:00AM',
    }, {
        date_range_string => '2023-07-27',
        as_of             => '2023-07-27 07:23:00',
        beg               => '07/27/2023 12:00:00AM',
        end               => '07/27/2023 11:59:59PM',
    }, {
        date_range_string => '2023-07-27 - 2023-07-28',
        as_of             => '2023-07-27 07:23:00',
        beg               => '07/27/2023 12:00:00AM',
        end               => '07/28/2023 11:59:59PM',
    }, {
        date_range_string => 'past four business days',
        as_of             => '2023-08-03 07:23:00',
        beg               => '07/31/2023 12:00:00AM',
        end               => '08/03/2023 11:59:59PM',
    }, {
        date_range_string => 'past four business days',
        as_of             => '2023-08-04 07:23:00',
        beg               => '08/01/2023 12:00:00AM',
        end               => '08/04/2023 11:59:59PM',
    }, {
        # Thirteenth
        date_range_string => 'December thirteenth 2022',
        as_of             => '2023-08-04 07:23:00',
        beg               => '12/13/2022 12:00:00AM',
        end               => '12/13/2022 11:59:59PM',
    }, {
        # Time with no date
        date_range_string => '3:00pm through 4:00pm',
        as_of             => '2023-08-04 07:23:00',
        beg               => '08/04/2023 03:00:00PM',
        end               => '08/04/2023 04:00:59PM',
    }, {
        date_range_string => 'last weekday at 3:30pm to today at 3:29pm',
        as_of             => '2024-04-29 07:23:00',
        beg               => '04/26/2024 03:30:00PM',
        end               => '04/29/2024 03:29:59PM',
    }, {
        date_range_string => 'past 3 weekdays at 3:30pm to today at 3:29pm',
        as_of             => '2024-04-29 07:23:00',
        beg               => '04/24/2024 03:30:00PM',
        end               => '04/29/2024 03:29:59PM',
    }, {
        date_range_string => 'last weekday',
        as_of             => '2024-04-29 07:23:00',
        beg               => '04/26/2024 12:00:00AM',
        end               => '04/26/2024 11:59:59PM',
    }, {
        date_range_string => 'last 10 weekdays',
        as_of             => '2024-05-28 07:23:00',
        beg               => '05/15/2024 12:00:00AM',
        end               => '05/28/2024 11:59:59PM',
    }, {
        date_range_string => '10 weekdays ago',
        as_of             => '2024-05-28 07:23:00',
        beg               => '05/14/2024 12:00:00AM',
        end               => '05/14/2024 11:59:59PM',
    }, {
        date_range_string => '10 weekdays ago at noon - 8 weekdays ago at noon',
        as_of             => '2024-05-28 07:23:00',
        beg               => '05/14/2024 12:00:00PM',
        end               => '05/16/2024 12:00:00PM',
    }
);

for my $test (@tests)
{
    my $as_of_date = $test->{as_of};

    my ($y, $m, $d, $h, $mn, $s);
    if ($as_of_date =~ /^(\d{4})\-(\d{2})\-(\d{2}) (\d{2}):(\d{2}):(\d{2})$/) {
        ($y, $m, $d, $h, $mn, $s) = ($1, $2, $3, $4, $5, $6);
    } elsif ($as_of_date =~ /^(\d{4})\-(\d{2})\-(\d{2})$/) {
        ($y, $m, $d) = ($1, $2, $3);
    } else {
        warn "$as_of_date is not a recognized format" and next;
    }

    my $parser = Date::RangeParser::EN->new(
        now_callback => sub {
            DateTime->new(
                year => $y,
                month => $m,
                day => $d,
                (hour => $h) x !!$h,
                (minute => $mn) x !!$mn,
                (second => $s) x !!$s,
            );
        },
    );

    my ($beg, $end) = $parser->parse_range($test->{date_range_string});

    SKIP: {
        skip "Skipping $test->{date_range_string} because Date::Manip v5.xx doesn't do that sort of thing." => 4
            if $test->{date_range_string} =~ /^\d-\d/ and $Date::Manip::VERSION lt '6';

        ok(defined $beg, "Beginning date for $test->{date_range_string} is defined");
        ok(defined $end, "End date for $test->{date_range_string} is defined");

        # strftime makes no sense on infinite times
        if ( $beg->is_infinite ) {
            cmp_ok( lc "$beg", '=~', lc $test->{beg}, "Beginning date ok for $test->{date_range_string}");
        }
        else {
            cmp_ok($beg->strftime("%m/%d/%Y %I:%M:%S%p"), 'eq', $test->{beg}, "Beginning date ok for $test->{date_range_string}");
        }
        if ( $end->is_infinite ) {
            cmp_ok( lc "$end", '=~', lc $test->{end}, "Beginning date ok for $test->{date_range_string}");
        }
        else {
            cmp_ok($end->strftime("%m/%d/%Y %I:%M:%S%p"), 'eq', $test->{end}, "Ending date ok for $test->{date_range_string}");
        }
    };
}

my $parser = Date::RangeParser::EN->new(
    datetime_class => 'Date::RangeParser::EN::Test::DateTime',
);

my ($beg, $end) = $parser->parse_range('3 weeks ago');

is(ref $beg, 'Date::RangeParser::EN::Test::DateTime');

$parser = Date::RangeParser::EN->new();
($beg, $end) = $parser->parse_range('3 weeks ago');

is(ref $beg, 'DateTime');

# hour-specific tests
my $now = DateTime->now;
($beg, $end) = $parser->parse_range('the next 2 hours');
cmp_ok("$beg", 'eq', "$now");
my $now_plus_2 = $now->clone->add(hours => 2);
cmp_ok("$end", 'eq', "$now_plus_2");

done_testing;

package Date::RangeParser::EN::Test::DateTime;

use base 'DateTime';

1;

