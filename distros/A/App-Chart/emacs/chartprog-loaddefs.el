;;; chartprog-loaddefs.el --- autoloads for chart.el functions.

;; Copyright 2005, 2006, 2007, 2008, 2009, 2010, 2014, 2015, 2016, 2017 Kevin Ryde

;; Author: Kevin Ryde <user42_kevin@yahoo.com.au>
;; Keywords: comm, finance
;; URL: http://user42.tuxfamily.org/chart/index.html

;; This file is part of Chart.
;;
;; Chart is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; Chart is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Chart.  If not, see <http://www.gnu.org/licenses/>.


;;; Code:

(autoload 'chart-watchlist                   "chartprog" nil t)
(autoload 'chartprog-watchlist-bookmark-jump "chartprog" nil t)
(autoload 'chart-quote                       "chartprog" nil t)
(autoload 'chart-quote-at-point              "chartprog" nil t)
(autoload 'chart-latest                      "chartprog" nil t)
(autoload 'chart-ses-refresh                 "chartprog" nil t)

;; set safe-function now for the benefit of ses.el or similar checking
;; before chartprog.el loads
(put 'chart-latest 'safe-function t)

;; with :load chartprog.el so as to create its member variables when viewed
(defgroup chartprog nil "Chart program interface."
  :group 'applications
  :load   "chartprog")

(provide 'chartprog-loaddefs)

;;; chartprog-loaddefs.el ends here
