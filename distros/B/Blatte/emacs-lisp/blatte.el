;;; blatte.el - Major mode for editing Blatte source <http://www.blatte.org/>

;; Copyright 2001 Bob Glickstein

;; Author: Bob Glickstein <bobg@blatte.org> <http://www.blatte.org/bobg/>
;; Maintainer: Bob Glickstein <bobg@blatte.org>
;; Version: 0.6

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation; either version 2, or (at your
;; option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, send e-mail to
;; this program's maintainer or write to the Free Software Foundation,
;; Inc., 59 Temple Place, Suite 330; Boston, MA 02111-1307, USA.

;;; Plug:

;; Check out my book, "Writing GNU Emacs Extensions," from O'Reilly
;; and Associates.  <http://www.ora.com/catalog/gnuext/>

;;; Code:

(require 'derived)

(defvar blatte-mode-map nil
  "*Keymap for Blatte mode.")
(if blatte-mode-map
    nil
  (setq blatte-mode-map (make-sparse-keymap))
  (define-key blatte-mode-map "\t" 'indent-for-tab-command))

(define-derived-mode blatte-mode text-mode "Blatte"
  "Major mode for editing Blatte source."
  (make-local-variable 'comment-column)
  (make-local-variable 'comment-start-skip)
  (make-local-variable 'comment-start)
  (make-local-variable 'comment-end)
  (make-local-variable 'font-lock-defaults)
  (make-local-variable 'indent-line-function)
  (make-local-variable 'imenu-generic-expression)
  (setq comment-column 40
        comment-start-skip "\\\\;\\s-*"
        comment-start "\\; "
        comment-end ""                  ;xxx also set comment-indent-function?
        font-lock-defaults '(blatte-font-lock-keywords t)
        indent-line-function 'blatte-indent-line)
  (setq imenu-generic-expression
        '((nil "^{\\\\def\\s-*\\\\\\([A-Za-z_][A-Za-z_0-9?!+-]*\\)" 1))))

(defconst blatte-keywords
  '(define set! lambda let let* letrec if cond while and or))

(defconst blatte-keyword-regex
  (format "\\\\\\(%s\\)"
          (mapconcat '(lambda (x) (regexp-quote (symbol-name x)))
                     blatte-keywords
                     "\\|")))

(defvar blatte-font-lock-keywords
  `(("\\\\;.*" . font-lock-comment-face)
    ("\\\\\\\\" . font-lock-keyword-face)
    ("\\\\/" . font-lock-keyword-face)
    ("\\\\\"\\([^\\\\]\\|\\\\[^\"]\\)*\\\\\"" 0 font-lock-string-face t)
    (,(format "{\\(%s\\)\\>" blatte-keyword-regex) 1 font-lock-keyword-face)
    ("{\\(\\\\[A-Za-z][A-Za-z_0-9]*\\)" 1 font-lock-function-name-face)
    ("\\\\[&=]?[A-Za-z][A-Za-z_0-9]*" . font-lock-variable-name-face))
  "*Font lock keywords for Blatte mode.")

(defun blatte-indent-line ()
  (save-match-data
    (let* ((start (point))

           ;; position of first non-whitespace on this line
           (bol (progn (back-to-indentation) (point)))

           ;; indentation of this line
           (current-indent (current-column))

           ;; position of innermost enclosing open-brace
           (enclosing-open (condition-case nil
                               (let ((looping t))
                                 (while looping
                                   (backward-up-list 1)
                                   (setq looping
                                         (/= (following-char) ?{)))
                                 (point))
                             (error nil)))

           ;; column of that open-brace
           (open-column (and enclosing-open (current-column)))

           ;; the Blatte keyword, if any, that follows
           (keyword (and enclosing-open
                         (progn
                           (forward-char 1)
                           (and (looking-at blatte-keyword-regex)
                                (match-string 1)))))

           ;; position of first non-whitespace on previous nonblank
           ;; line
           (prev-bol (progn
                       (goto-char bol)
                       (and (zerop (forward-line -1))
                            (progn
                              (end-of-line)
                              (skip-chars-backward " \t\n\r\f")
                              (and (not (memq (preceding-char)
                                              '(0 ?\  ?\t ?\n ?\r ?\f)))
                                   (progn
                                     (back-to-indentation)
                                     (point)))))))

           ;; indentation of prev-bol
           (prev-indent (and prev-bol (current-column)))

           ;; the position of the open-brace enclosing the beginning
           ;; of the previous line
           (prev-open (and prev-bol
                           (progn
                             (condition-case nil
                                 (let ((looping t))
                                   (while looping
                                     (backward-up-list 1)
                                     (setq looping
                                           (/= (following-char) ?{)))
                                   (point))
                               (error nil)))))

           (result (cond (keyword (+ open-column 2))

                         ;; if current line and previous line are
                         ;; contained in the same level of braces, use
                         ;; previous line's indentation
                         ((and prev-open
                               (equal enclosing-open prev-open))
                          prev-indent)

                         ;; if current line is enclosed in braces, use
                         ;; the brace's column + 1
                         (enclosing-open (1+ open-column))

                         ;; Use previous line's indentation
                         (prev-indent prev-indent)

                         ;; No indentation
                         (t 0))))

      (goto-char bol)
      (if (and (= start bol)
               (>= (current-indentation) result))
          ;; repeated presses of TAB should indent the line further
          (indent-relative)
        (indent-line-to result)))))

(provide 'blatte)

;;; blatte.el ends here
