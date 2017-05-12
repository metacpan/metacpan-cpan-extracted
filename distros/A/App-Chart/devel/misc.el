;; Copyright 2014, 2015, 2016, 2017 Kevin Ryde

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


;;-----------------------------------------------------------------------------

(progn
  (setq chartprog-debug t)
  (save-selected-window
    (save-excursion
      (switch-to-buffer-other-window "*chartprog-debug*"))))

;;-----------------------------------------------------------------------------

(let ((inhibit-quit t))
  (accept-process-output))

(let ((inhibit-quit t))
  (remhash "CBA.AX" chartprog-latest-cache)
  (chart-latest "CBA.AX" 'last))


;;-----------------------------------------------------------------------------
(chart-latest "CBA.AX" 'name)
(chart-latest "CBA.AX" 'bid)
(chart-latest "CBA.AX" 'quote-date)
(chart-latest "BHP.AX" 'quote-time)
(chart-latest "CBA.AX" 'last)
(chart-latest "CBA.AX" 'last-date)
(chart-latest "CBA.AX" 'last-time)

(chart-latest "WOW.AX" 'last-date)

chartprog-latest-cache
(chart-quote "CBA.AX")

(encode-time 0 0 0 31 12 2010 "GMT")
(encode-time 0 0 0 31 12 2010 1000)
(encode-time 0 0 0 31 12 2010 "nosuchzone")
(encode-time 0 0 0 31 12 2010 "Australia/Sydney")
(encode-time 0 0 0 31 12 2010 "EST-10")
(encode-time 0 0 0 31 12 2010 (* 3600 10))

;;-----------------------------------------------------------------------------
(unsafep 'chart-latest)
(unsafep '(chart-latest "BHP.AX"))
(get 'chart-latest 'safe-function)
(put 'chart-latest 'safe-function t)


;;-----------------------------------------------------------------------------

(progn
  (chartprog-exec 'request-explicit '("BHP.AX"))
  (chart-quote "BHP.AX"))
(chart-latest "BHP.AX" 'last-date)

(chart-ses-refresh-download '("BHP.AX" "CBA.AX"))
(chart-ses-refresh-download '("NAB.AX"))

;;-----------------------------------------------------------------------------
(let (lst)
  (chart-latest "BHP.AX" 'last 2)
  (maphash (lambda (key value)
             (push (list key value) lst))
           chartprog-latest-cache)
  lst)


;;-----------------------------------------------------------------------------

(easy-menu-define my-pop SYMBOL MAPS DOC MENU)


;;-----------------------------------------------------------------------------
;; after-change-functions save-match-data

(add-to-list 'mode-line-misc-info '(:eval (my-mode-line-bit)))
(defun my-mode-line-bit ()
  "abc")
(progn
  (looking-at "..")
  (force-mode-line-update)
  (match-data))


;;-----------------------------------------------------------------------------

(let ((completion-ignore-case t))
  (completing-read "Symlist: "
                   '(("All") ("Alerts"))
                   nil  ;; pred
                   t    ;; require-match
                   nil  ;; initial-input
                   ))

;;-----------------------------------------------------------------------------
(chartprog-symlist-editable-p 'favourites)
(chartprog-symlist-editable-p 'alerts)

(require 'chartprog)
(chartprog-completing-read-symlist)

;;-----------------------------------------------------------------------------

(progn
  (add-to-list 'load-path (expand-file-name "."))
  (require 'my-byte-compile)
  (my-byte-compile "../emacs/chartprog.el"))
(progn
  (add-to-list 'load-path (expand-file-name "."))
  (require 'my-byte-compile)
  (my-show-autoloads))


;;-----------------------------------------------------------------------------

;; ;; emacs has `compare-strings' to do this, but xemacs doesn't
;; (defun chartprog-string-prefix-ci-p (part str)
;;   "Return t if PART is a prefix of STR, case insensitive."
;;   (and (>= (length str) (length part))
;;        (string-equal (upcase part)
;;                      (upcase (substring str 0 (length part))))))

;; ;; "completing-read with require-match will return with just a prefix
;; ;; of one or more names, use the first."  FIXME: Is this true?  Or was
;; ;; true in the past?
;; (dolist (elem (reverse (chartprog-symlist-alist)))
;;   (if (chartprog-string-prefix-ci-p name (car elem))
;;       (setq key (cadr elem))))
;; (or key (error "Oops, symlist name %S not found" name))
;; key)))

;;-----------------------------------------------------------------------------
(require 'bookmark)

(let ((chartprog-watchlist-current-symlist 'foo))
  (chartprog-watchlist-bookmark-make-record))
(let ((chartprog-watchlist-current-symlist nil))
  (chartprog-watchlist-bookmark-make-record))

(chartprog-watchlist-bookmark-make-record)
