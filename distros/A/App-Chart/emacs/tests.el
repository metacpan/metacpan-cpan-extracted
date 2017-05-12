;;; Test some of chartprog.el.

;; Copyright 2005, 2007, 2008, 2009, 2016, 2017 Kevin Ryde

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


(add-to-list 'load-path (getenv "srcdir"))
(require 'chartprog)


(defun test (name data want got)
  (unless (equal want got)
    (error "%s:
  data: %s
  want: %s
  got:  %s\n"
             name data want got)))


;;-----------------------------------------------------------------------------
;; chartprog-intersection
;;

(let* ((x    '())
       (y    '())
       (want '())
       (got  (chartprog-intersection x y)))
  (test "chartprog-intersection" (list x y) want got))

(let* ((x    '(1))
       (y    '())
       (want '())
       (got  (chartprog-intersection x y)))
  (test "chartprog-intersection" (list x y) want got))

(let* ((x    '(1))
       (y    '(1))
       (want '(1))
       (got  (chartprog-intersection x y)))
  (test "chartprog-intersection" (list x y) want got))

(let* ((x    '(1 2))
       (y    '(2 1))
       (want '(1 2))
       (got  (chartprog-intersection x y)))
  (test "chartprog-intersection" (list x y) want got))

(let* ((x    '("a" "b" "c"))
       (y    '("b" "c" "d"))
       (want '("b" "c"))
       (got  (chartprog-intersection x y)))
  (test "chartprog-intersection" (list x y) want got))

;;-----------------------------------------------------------------------------
;; chartprog-with-temp-message

(let* ((msg1 "foo")
       (msg2 "bar")
       (want 'hello)
       (got  (chartprog-with-temp-message msg1
               (chartprog-with-temp-message msg2
                 'hello))))
  (test "chartprog-with-temp-message" (list msg1 msg2) want got))

;; this only tests anything in normal interactive mode, in emacs -batch
;; (curent-message) is always nil
(let* ((msg1 "foo")
       (msg2 "bar")
       (want nil)
       (got  (progn
               (chartprog-with-temp-message msg1
                 (chartprog-with-temp-message msg2
                   'hello))
               (current-message))))
  (test "chartprog-with-temp-message" (list msg1 msg2) want got))

;;-----------------------------------------------------------------------------
;; (thing-at-point 'chart-symbol)

(with-temp-buffer
  (dolist (elem '(("F" "F")))
    (let* ((str  (nth 0 elem))
           (want (nth 1 elem)))
      (erase-buffer)
      (insert str)
      (goto-char (point-min))
      (let ((got (thing-at-point 'chart-symbol)))
  (test "thing-at-point 'chart-symbol" str want got)))))


;;-----------------------------------------------------------------------------

(chart-latest "BHP.AX")
(chart-latest "BHP.AX" 'last 2)
(chart-latest "BHP.AX" 'last-date)

;;-----------------------------------------------------------------------------
