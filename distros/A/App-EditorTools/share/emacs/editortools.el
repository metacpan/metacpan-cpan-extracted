;; Copyright (C) 2010 Pat Regan <thehead@patshead.com>

;; Keywords: faces
;; Author: Pat Regan <thehead@patshead.com>
;; URL: http://rcs,patshead.com/dists/editortools-vim-el

;; This file is not part of GNU Emacs.

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2, or (at your option) any later
;; version.
;;
;; This is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
;; MA 02111-1307, USA.

;;; Commentary:

;; Requires App::EditorTools Perl module

(defun editortools-renamevariable (varname)
  "Call rename variable on buffer"
  (interactive "sNew Variable Name: ")
  (editortools-modify-buffer "renamevariable" "-l" (number-to-string (line-number-at-pos))
											  "-c" (number-to-string (editortools-get-column (point)))
											  "-r" varname))

(defun editortools-introducetemporaryvariable (varname)
  "Call introducetempoararyvariable on region"
  (interactive "sNew Variable Name: ")
  (let* ((startline (number-to-string (line-number-at-pos (region-beginning))))
         (startcol (number-to-string (editortools-get-column (region-beginning))))
         (endline (number-to-string (line-number-at-pos (region-end))))
         (endcol (number-to-string (- (editortools-get-column (region-end)) 1))))
	(editortools-modify-buffer "introducetemporaryvariable" "-s" (concat startline "," startcol)
															"-e" (concat endline "," endcol)
															"-v" varname)))

(defun editortools-renamepackagefrompath ()
  "Call renamepackagefrompath"
  (interactive)
  (editortools-modify-buffer "renamepackagefrompath" "-f" (buffer-file-name)))

(defun editortools-renamepackage (package-name)
  "Call renamepackage"
  (interactive "sNew Package Name: ")
  (editortools-modify-buffer "renamepackage" "-n" package-name))

(defun editortools-get-column (p)
  "Get the column of a point"
  (save-excursion
    (goto-char p)
    (+ 1 (current-column)))) ; vim counts columns differently

(defun editortools-modify-buffer (&rest command)
  (let ((refactor-buffer (get-buffer-create "*editortools*")))
	(editortools-erase-specific-buffer refactor-buffer)
    (if (editortools-command-succeeds command)
		(editortools-buffer-swap-text-maintain-position refactor-buffer)
	  (message (editortools-specific-buffer-string refactor-buffer)))))

(defun editortools-command-succeeds (command)
  (= (apply 'call-process-region (point-min) (point-max) "editortools"
			nil refactor-buffer t
			command)
	 0))

(defun editortools-erase-specific-buffer (buffer)
  (save-excursion (set-buffer refactor-buffer)
				  (erase-buffer)))

(defun editortools-specific-buffer-string (buffer)
  (save-excursion (set-buffer refactor-buffer)
				  (buffer-string)))

(defun editortools-buffer-swap-text-maintain-position (buffer)
  (let ((p (point)))
	(buffer-swap-text buffer)
	(goto-char p)))

(require 'cperl-mode)
(define-key cperl-mode-map (kbd "C-c e r") 'editortools-renamevariable)
(define-key cperl-mode-map (kbd "C-c e t") 'editortools-introducetemporaryvariable)

(provide 'editortools)
