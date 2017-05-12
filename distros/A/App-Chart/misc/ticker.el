;; Copyright 2008, 2009 Kevin Ryde

;; This file is part of Chart.
;;
;; Chart is free software; you can redistribute it and/or modify it under the
;; terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 3, or (at your option) any later version.
;;
;; Chart is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License along
;; with Chart.  If not, see <http://www.gnu.org/licenses/>.

(defvar ticker-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m "q"         'ticker-quit)
    m)
  "Keymap for `ticker-mode' display buffer.")

(defun ticker-quit ()
  (interactive)
  (delete-window))

(defun ticker-timer-scroll (buffer)
  (dolist (window (get-buffer-window-list buffer))
    (with-selected-window window
      (let ((offset (- (point) (window-hscroll)))
            (new-hscroll (if (> (+ (window-hscroll) (window-width)) (point-max))
                             (point-min)
                           (1+ (window-hscroll)))))
        (goto-char (+ new-hscroll offset))
        (set-window-hscroll window new-hscroll)))))

(defvar ticker-timer nil)
(make-local-variable 'ticker-timer)

(defun ticker-stop-timer ()
  (when ticker-timer
    (cancel-timer ticker-timer)
    (setq ticker-timer nil)))

(defun ticker-mode ()
  "Show a scrolling ticker.
"
  (kill-all-local-variables)
  (setq major-mode        'ticker-mode
        mode-name         "Ticker"
        truncate-lines    t)
  (use-local-map ticker-mode-map)
  (setq buffer-read-only t)

  (setq ticker-timer (run-at-time 0 1 'ticker-timer-scroll (current-buffer)))
  (add-hook 'kill-buffer-hook 'ticker-stop-timer t t)

  (run-hooks 'ticker-mode-hook))

(progn
  (if (get-buffer "x")
      (kill-buffer "x"))
  (let ((window-min-height 1))
    (split-window nil 2))
  (switch-to-buffer "x")
  (insert "fjksdj fksd jfksd fksd jfksd jfk sjdfk jsdkf sjdkf jsdkf jsdk fjsdk fjksd fjksd fjksd fjksd fjk sdjfksd fjkj kj kj k jk jk jk k ")
  (ticker-mode))

;; (cancel-timer (car timer-list))
