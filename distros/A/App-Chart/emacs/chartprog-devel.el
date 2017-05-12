;;; chartprog-devel.el --- Chart development helpers for Emacs.

;; Copyright 2002, 2003, 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2014, 2016 Kevin Ryde

;; Author: Kevin Ryde <user42_kevin@yahoo.com.au>
;; Keywords: tools
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


;; See the Chart manual for instructions.


;;; Code:

(defvar chartprog-directory "~/Chart"
  "Chart user settings directory, per App::Chart::chart_directory().")


;;-----------------------------------------------------------------------------
;; scheme indentation.

(put 'after-load                     'scheme-indent-function 1)
(put 'c-gtk-clist-call-with-freeze   'scheme-indent-function 1)
(put 'c-gtk-idle-add-priority        'scheme-indent-function 1)
(put 'c-gtk-input-add                'scheme-indent-function 2)
(put 'c-gtk-signal-connect-once      'scheme-indent-function 2)
(put 'c-gtk-signal-connect-t         'scheme-indent-function 2)
(put 'c-gtk-timeout-add              'scheme-indent-function 1)
(put 'c-gtk-tree-require-n-items     'scheme-indent-function 2)
(put 'c-gtk-widget-drawing           'scheme-indent-function 1)
(put 'c-lazy-catch                   'scheme-indent-function 1)
(put 'call-with-cleanup              'scheme-indent-function 1)
(put 'call-with-each-lang            'scheme-indent-function 1)
(put 'call-with-env-var              'scheme-indent-function 2)
(put 'call-with-http-in-progress     'scheme-indent-function 1)
(put 'call-with-input-file-or        'scheme-indent-function 2)
(put 'call-with-string-in-file       'scheme-indent-function 1)
(put 'call-with-tempfileport         'scheme-indent-function 1)
(put 'choke-call                     'scheme-indent-function 2)
(put 'database-call-with-lock        'scheme-indent-function 1)
(put 'database-call-with-output-file 'scheme-indent-function 1)
(put 'database-call-modify-data      'scheme-indent-function 1)
(put 'database-call-modify-notes     'scheme-indent-function 1)
(put 'directory-files                'scheme-indent-function 2)
(put 'for-each-smarker               'scheme-indent-function 1)
(put 'gtk-idle-add-priority          'scheme-indent-function 1)
(put 'gtk-input-add                  'scheme-indent-function 2)
(put 'gtk-signal-connect             'scheme-indent-function 2)
(put 'gtk-timeout-add                'scheme-indent-function 1)
(put 'let-toplevel       'scheme-indent-function 'scheme-let-indent)
(put 'let-toplevel*      'scheme-indent-function 'scheme-let-indent)
(put 'notify-connect                 'scheme-indent-function 1)
(put 'receive-list                   'scheme-indent-function 2)
(put 'program-version-proc           'scheme-indent-function 1)
(put 'sensitive-preferences          'scheme-indent-function 1)
(put 'sensitive-series               'scheme-indent-function 1)
(put 'sockpool-call                  'scheme-indent-function 1)
(put 'symbol-exchange-url!           'scheme-indent-function 1)
(put 'weblink-handler!               'scheme-indent-function 1)
(put 'yahoo-quote-delay!             'scheme-indent-function 1)


;;-----------------------------------------------------------------------------
;; bogus mime charsets in some html seen

;; for html-coding.el
(eval-after-load "mm-util"
  '(progn
     ;; CME pages (old stuff, might be all utf-8 now)
     (add-to-list 'mm-charset-synonym-alist '(iso8859-1 . iso-8859-1))

     ;; TGE disclaimer.e.html (though no actual jp chars)
     (add-to-list 'mm-charset-synonym-alist '(x-euc-jp . euc-jp))

     ;; Fukuoka (which is defunct) historical.html
     (add-to-list 'mm-charset-synonym-alist '(x-sjis . shift_jis))))

(when (fboundp 'define-coding-system-alias) ;; emacs 22 or xemacs
  (define-coding-system-alias 'iso8859-1 'iso-8859-1)
  (define-coding-system-alias 'x-euc-jp  'euc-jp)
  (define-coding-system-alias 'x-sjis    'shift_jis))


(provide 'chartprog-devel)

;;; chartprog-devel.el ends here
