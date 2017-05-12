# Bendigo Stock Exchange (BSX) setups.

# Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2012 Kevin Ryde

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
# You should have received a copy of the GNU General Public License along
# with Chart.  If not, see <http://www.gnu.org/licenses/>.

package App::Chart::Suffix::BEN;
use strict;
use warnings;
use Locale::TextDomain ('App-Chart');

use App::Chart;
use App::Chart::Sympred;
use App::Chart::TZ;
use App::Chart::Weblink;


# Victoria is the same as NSW these days, but let's not assume that rare
# outbreak of interstate cooperation will be permanent (in the past the
# dates to begin or end daylight savings have varied).
#
my $timezone_bendigo = App::Chart::TZ->new
  (name     => __('Bendigo'),
   choose   => [ 'Australia/Melbourne' ],
   fallback => 'EST-10');

my $pred = App::Chart::Sympred::Suffix->new ('.BEN');
$timezone_bendigo->setup_for_symbol ($pred);

# App::Chart::setup_source_help
#   ($pred, __p('manual-node','Bendigo Stock Exchange'));


#------------------------------------------------------------------------------
# weblink - company info

App::Chart::Weblink->new
  (pred => $pred,
   name => __('BSX _Company Information'),
   desc => __('Open web browser at the Bendigo Stock Exchange information page for this company'),
   proc => sub {
     my ($symbol) = @_;
     return 'http://www.bsx.com.au/markets_pricesresearch_com.asp?security='
       . secode_for_symbol ($symbol);
   });
# weblink_message __('Fetching BSX symbol codes ...')


#-----------------------------------------------------------------------------
# security codes
#
# The home page
#
#     http://www.bsx.com.au
#
# has a pull-down menu of symbols, with the code numbers to be used for
# quotes and trade history.
#
# The cache here saves the code numbers for one day (the current trading
# day, bendigo time).  This ensures we don't download every time, but still
# have a fresh set of codes, in case there's additions or perhaps changes.
#
# Thought was given to a more sophisticated caching scheme, for instance use
# an old code and if the quote turns out to be for something else and the
# cache isn't fresh then refill it and get the quote again.  But for the
# data download it'd be a case of checking the name against the database
# name, since there's no symbol on that page, except that for the initial
# download when there's no database name yet the cache would have to be
# pre-freshened.  This seems unnecessarily complicated to merely avoid
# downloading one page, especially when it's compressed to about 3kbytes if
# we've got gzip or zlib.


# return option code string, or undef if unknown
sub secode_for_symbol {
  my ($symbol) = @_;
  require App::Chart::Pagebits;
  my $h = App::Chart::Pagebits::get
    (name      => __('BSX stock numbers'),
     url       => 'http://www.bsx.com.au',
     key       => 'bendigo-codes',
     freq_days => 1,
     timezone  => $timezone_bendigo,
     parse     => \&secodes_parse);
  return $h->{$symbol};
}

# return hash reference { $symbol => $code, ... }
sub secodes_parse {
  my ($content) = @_;
  my %hash;
  while ($content =~ m{<option value=\"([0-9]+)\">([A-Z]+)</option>}g) {
    $hash{"$2.BEN"} = $1;
  }
  return \%hash;
}

1;
__END__

#------------------------------------------------------------------------------


# This uses the quotes pages like
#
#     http://www.bsx.com.au/markets_pricesresearch_pri.asp?security=20
#
# with the security code number from the symbols menu on the home page.
#
# www.bsx.com.au sends gzipped data, which is good since it compresses
# about 19kbytes of javascript junk down to about 3kbytes sent.
#
# The trade history pages like
#
#     http://www.bsx.com.au/markets_pricesresearch_tra.asp?security=1
#
# also have a current bid/offer and show the date/time of the last trade.
# Not sure if there's much value showing open/high/low/volume from trading
# that could be weeks ago.

# return list (ADATE TIME) for latest quote
#
# the BSX system takes changes only during 9:30am-11:30am weekdays (order
# entry 9:30 to 11, then trading 11 to 11:30), so outside those hours lock
# to 11:30am
#
# http://www.bsx.com.au/markets_aboutbsxmarkets_tra.asp
#
sub quote_date_time {
#   (tm->adate-time-within (localtime (current-time) (timezone-bendigo))
# 			 #,(hms->seconds 9 30 0)
# 			 #,(hms->seconds 11 30 0)))
}

sub bendigo_quote {

sub quote_parse {
  my ($resp) = @_;
  my $content = $resp->decoded_content (raise_error => 1);

  my @data = ();
  my $h = { source      => __PACKAGE__,
            resp        => $resp,
            date_format => 'dmy',
            data        => \@data };

  require HTML::TableExtract;

  my $te = HTML::TableExtract->new
    (headers   => ['code', 'bid', 'offer', 'last'],
     keep_html => 1);
  $te->parse($content);

  my ($ts) = $te->tables || die 'BSX: quote columns not found';
  $te = HTML::TableExtract->new
    (depth => $ts->depth,
     count => $ts->count + 1);
  $te->tables || die 'BSX: reparse table not found';

#   (receive-list (quote-adate quote-time)
#       (bendigo-quote-adate-time)

# 			# eg: <span class="Blue"><br><br><b>Capilano Honey Limited</b><br><font color=red>TRADING HALT</font><br></span><br>
# 			(m      (regexp-exec #,(regexp "Blue.*<b>.*red[^>]*>([^<]+)" regexp/icase regexp/newline) body))
# 			(note   (and m (match:substring m 1))))


  foreach my $row ($te->rows) {
    my ($code, $bid, $offer, $last) = @$row;
    $code =~ /(.*)\(([^)]+)\)/ or next;
    my $name   = $1;
    my $symbol = "$2.BEN";
    push @data, { symbol => $symbol,
                  name   => $name,
                  bid    => $bid,
                  offer  => $offer,
                  last   => $last };

			       #:quote-adate quote-adate
			       #:quote-time  quote-time
			       #:note        note
  }
}

(define (bendigo-latest-get symbol-list extra-list proc)
  (for-each (lambda (symbol)
	      (define option (symbol->option symbol))

	      (if (not option)
		  (proc (list (latest-new-unknown symbol)))

		  (receive (headers body)
		      (http-request (string-append "http://www.bsx.com.au/markets_pricesresearch_pri.asp?security=" option)
				    #:want-ok #t)
		    (proc (body->latest-list body)))))

	    symbol-list))

(latest-handler! #:selector   bendigo-symbol?  
		 #:handler    bendigo-latest-get
		 #:adate-time bendigo-quote-adate-time)



;;-----------------------------------------------------------------------------
;; download
;;
;; This uses the "view all" trade history pages like
;;
;;     http://www.bsx.com.au/markets_pricesresearch_tra_popup.asp?security=20
;;
;; with the security number from the home page menu (cached above).
;;
;; This history has each trade individually, but we collapse that to daily
;; open/high/low/close.


;; Eg:
;; <span class="Blue"><b>Capilano Honey Limited</b></span><br>
;; <span class="Blue"><br>Trade History<br></span><br>
;; <table ...
;;
;; Or when ex dividend:
;; <span class="Blue"><b>Capilano Honey Limited</b><br><font color=red>XD</font></span><br>
;; <span class="Blue"><br>Trade History<br></span><br>
;;
;; Or when halted:
;; <span class="Blue"><b>Capilano Honey Limited</b><br><font color=red>TRADING HALT</font></span><br>
;; <span class="Blue"><br>Trade History<br></span><br>
;;
;; match 1 is company name
;;
(define history-regexp
  "<b>([^<]+)[^\n]*\n[^\n]*<br>Trade History")

(define (bendigo-process-download symbol url headers body)
  (define commodity (chart-symbol-sans-dot symbol))

  (let* ((m        (must-match (string-match history-regexp body)))
	 (name     (match:substring m 1))
	 (row-list (html-table-rows body
				    ;; skip empty table, the second is wanted
				    (string-contains-after-ci body "<table"
							      (match:end m)))))

    (let ((headings (map! string-trim-right (first row-list))))
      (or (equal? headings '("Qty" "Price" "Date" "Time"))
	  (error "BSX: unrecognised data columns:" headings)))
    (set! row-list (cdr row-list))

    (download-process
     #:module          (_ "BSX")
     #:symbol-list     (list symbol)
     #:name            name
     #:url             url
     #:headers         headers
     #:currency        "AUD"
     #:hi              (bendigo-available-tdate)
     #:last-download   #t
     #:prefer-decimals 2
     #:row-list
     (map (lambda (row-list)
	    (receive-list (volume-1 price-1 date time-1)
		(first row-list)
	      ;; most recent first in list, so reverse for sessions
	      (list #:tdate     (d/m/y-str->tdate date)
		    #:commodity commodity
		    #:sessions  (reverse! (map second row-list))
		    #:volume    (apply + (map! string->number-err
					       (map first row-list))))))
	  (partition-equal-adjacent third row-list)))))

;; latest download data available
;; guess today available from 6pm
;;
(define (bendigo-available-tdate)
  (tdate-today-after 18 0 (timezone-melbourne)))

(define (bendigo-download symbol-list)
  (for-each
   (lambda (symbol)
     (download-status (_ "BSX") (_ "data") symbol)

     (let ((option (symbol->option symbol)))
       (if (not option)
	   (download-message
	    (string-append (_ "BSX") ": " (_ "unknown symbol") " " symbol))

	   (let ((url (string-append "http://www.bsx.com.au/markets_pricesresearch_tra_popup.asp?security=" option)))
	     (receive (headers body)
		 (http-request url #:want-ok #t)
	       (bendigo-process-download symbol url headers body))))))
   symbol-list))

(define (bendigo-backto want-tdate symbol-list)
  (download-message
   (string-append (_ "BSX") ": " (_ "no further historical data available"))))

(download-handler! #:selector   bendigo-symbol?
		   #:update     bendigo-download
		   #:avail-proc bendigo-available-tdate
		   #:backto     bendigo-backto)
