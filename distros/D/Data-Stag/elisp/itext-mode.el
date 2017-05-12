;; itext-mode.el --- a major mode for editing dna sequences
;;
;; ~/lib/emacs/jhg-lisp/itext-mode.el ---
;;
;; $Id: itext-mode.el,v 1.1 2002/12/03 19:18:06 cmungall Exp $
;;
;; Author:  harley@bcm.tmc.edu
;; URL:     http://www.hgsc.bcm.tmc.edu/~harley/elisp/itext-mode.el
;;

;;; Commentary:
;; --------------------
;; A collection of functions for editing DNA sequences.  It
;; provides functions to make editing easier.
;;
;; itext-mode will:
;;  * Fontify keywords and line numbers in sequences, but not bases.
;;  * Incrementally search dna over pads and numbers
;;  * Complement and reverse complement a region.
;;  * Move over bases and entire sequences.
;;  * Detect sequence files by content.

;;; Installation:
;; --------------------
;; Here are two suggested ways for installing this package.
;; You can choose to autoload it when needed, or load it
;; each time emacs is started.  Put one of the following
;; sections in your .emacs:
;;
;; ---Autoload:
;;  (autoload 'itext-mode "itext-mode" "Major mode for dna" t)
;;  (add-to-list
;;     'auto-mode-alist
;;     '("\\.\\(fasta\\|fa\\|exp\\|ace\\|gb\\)\\'" . itext-mode))
;;  (add-hook 'itext-mode-hook 'turn-on-font-lock)
;;
;; ---Load:
;;  (setq itext-do-setup-on-load t)
;;  (load "/pathname/itext-mode")

;;; Code:

;; Setup
(defvar itext-mode-hook nil
  "*Hook to setup `itext-mode'.")

(defvar itext-mode-load-hook nil
  "*Hook to run when `itext-mode' is loaded.")

(defvar itext-setup-on-load nil
  "*If not nil setup itext mode on load by running `itext-`add-hook's'.")


;; I also use "Alt" as C-c is too much to type for cursor motions.
(defvar itext-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Ctrl bindings
    (define-key map "\C-cc"	'itext-add-elt)
    ;; XEmacs does not like the Alt bindings
    (cond ((not running-xemacs)
      (define-key map [A-right]	'itext-add-elt)))
    map)
  "The local keymap for `itext-mode'.")

;;;###autoload
(defun itext-mode ()
  "Major mode for editing ITEXT.

This mode also customizes isearch to search over line breaks.

\\{itext-mode-map}"
  (interactive)
  ;;
  (kill-all-local-variables)
  (setq mode-name "itext")
  (setq major-mode 'itext-mode)
  (use-local-map itext-mode-map)
  ;;
  (make-local-variable 'font-lock-defaults)
  (setq font-lock-defaults '(itext-font-lock-keywords))
  ;;
  (make-local-variable 'dna-valid-base-regexp)
  (make-local-variable 'dna-sequence-start-regexp)
  (make-local-variable 'dna-cruft-regexp)
  (make-local-variable 'dna-isearch-case-fold-search)
  ;;
  (run-hooks 'itext-mode-hook)
  )


;; Keywords
;; Todo: Seperate the keywords into a list for each format, rather
;; than one for all.
(defvar itext-font-lock-keywords
  '(
    ("\\(\\#.*\\)"
     (1 font-lock-comment-face)
     )
    ;; elements
    ("^ *\\([-_.a-zA-Z_0-9]+\\):"
     (1 font-lock-function-name-face)
     )
    ;; others...?
    )
  "Expressions to hilight in `itext-mode'.")


;;;###autoload
(defun itext-add-hooks ()
  "Add a default set of itext-hooks.
These hooks will activate `itext-mode' when visiting a file
which has a itext-like name (.itext) or whose contents
looks like itext.  It will also turn enable fontification for `itext-mode'."
  (add-hook 'itext-mode-hook 'turn-on-font-lock)
  (add-to-list
   'auto-mode-alist
   '("\\.\\(itext\\|itxt\\)\\'" . itext-mode))
  )

;; Setup hooks on request when this mode is loaded.
(if itext-setup-on-load
    (itext-add-hooks))



