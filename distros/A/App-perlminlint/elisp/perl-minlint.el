;;; perl-minlint.el -- minor mode for automatic lint whenever you save.

;;; Copyright (C) 2014 KOBAYASI Hiroaki

;; Author: KOBAYASI Hiroaki <hkoba@cpan.org>

(require 'cl)

(defcustom perl-minlint-script "perlminlint"
  "Default command to test a Perl script")

(defcustom perl-minlint-script-for-tramp-host-alist ()
  "Alist of tramp hostname vs perlminlint path.

Use like this:

(eval-after-load \"perl-minlint\"
  '(progn
     (add-to-list 'perl-minlint-script-for-tramp-host-alist
		  '(\"myserver\" . \"/opt/bin/perlminlint\"))))
")

(make-variable-buffer-local
 (defvar perl-minlint-is-available nil
   "(used from modeline)"))

(defvar perl-minlint-re-perl-errors
  " at \\([^ ]*\\) line \\([0-9]+\\)[.,]"
  "Regexp to parse perl error file and line.")

(defvar perl-minlint-mode-map (make-sparse-keymap))
(define-key perl-minlint-mode-map [f5] 'perl-minlint-run)

;;;###autoload
(define-minor-mode perl-minlint-mode
  "Run perlminlint in after-save-hook."
  :keymap perl-minlint-mode-map
  :lighter (perl-minlint-is-available
	    "{F5->lint}" "!NO LINT!")
  :global nil
  (let ((hook 'after-save-hook) (fn 'perl-minlint-run)
	(buf (current-buffer)))
    (cond ((and (boundp 'mmm-temp-buffer-name)
		(equal (buffer-name) mmm-temp-buffer-name))
	   (message "skipping perl-minlint-mode for %s" buf)
	   nil)
	  (perl-minlint-mode
	   (setq perl-minlint-is-available
		 (perl-minlint-find-executable buf))
	   (when (not perl-minlint-is-available)
	     (error "perlminlint: Can't find executable for %s"
		    perl-minlint-script))
	   (message "enabling perl-minlint-mode for %s" buf)
	   (add-hook hook fn nil t))
	  (t
	   (message "disabling perl-minlint-mode for %s" buf)
	   (remove-hook hook fn t)))))

;;;###autoload
(defun perl-minlint-run (&optional force)
  "Run perlminlint for current buffer.
By default, this runs only in perl-minlint-mode.
To use this in other mode, please give t for optional argument FORCE.
"
  (interactive "P")
  (let ((buf (current-buffer)))
    (if (or force perl-minlint-mode)
	(perl-minlint-run-and-raise buf)
      (message "Not in perl-minlint-mode, skipped."))))

(defun perl-minlint-run-and-raise (buffer)
  (perl-minlint-plist-bind (file line err rc)
      (perl-minlint-run-and-parse-lint-result buffer)
    (unless (eq rc 0)
      (beep))
    (when (and file
	       (not (equal (expand-file-name file)
			   (perl-minlint-tramp-localname buffer)))
	       (not (equal file "-")))
	(message "opening error file: %s" file)
	(find-file-other-window file))
    (when (and file line)
      (goto-line (string-to-number line)))
    (message "%s"
	     (cond ((> (length err) 0)
		    err)
		   ((not (eq rc 0))
		    "Unknown error")
		   (t
		    "lint OK")))))

(defun perl-minlint-run-and-parse-lint-result (buffer)
  (perl-minlint-plist-bind (rc err)
      (perl-minlint-shell-command (perl-minlint-find-executable buffer)
				  " "
				   (perl-minlint-tramp-localname buffer))
    (when rc
      (let (match diag)
	(when (setq match
		    (perl-minlint-match
		     perl-minlint-re-perl-errors
		     err 'file 1 'line 2))
	  (setq diag (substring err 0 (plist-get match 'pos))))
	(append `(rc ,rc err ,(or diag err)) match)))))

(defun perl-minlint-shell-command (cmd &rest args)
  (let ((tmpbuf (generate-new-buffer " *perl-minlint-temp*"))
	rc err)
    (save-window-excursion
      (unwind-protect
	  (setq rc (perl-minlint-tramp-command-in
		    (current-buffer)
		    cmd args tmpbuf))
	(setq err (with-current-buffer tmpbuf
		    ;; To remove last \n
		    (goto-char (point-max))
		    (skip-chars-backward "\n")
		    (delete-region (point) (point-max))
		    (buffer-string)))
	;; (message "error=(((%s)))" err)
	(kill-buffer tmpbuf)))
    `(rc ,rc err ,err)))

;;;;========================================
;;; Codes for tramp support

(defun perl-minlint-tramp-command-in (curbuf cmd args &optional outbuf errorbuf)
  (let ((command (apply #'concat (perl-minlint-tramp-localname cmd)
			args)))
    (if (perl-minlint-is-tramp (buffer-file-name curbuf))
	(tramp-handle-shell-command
	 command outbuf errorbuf)
      (shell-command command outbuf errorbuf))))

(defun perl-minlint-tramp-localname (fn-or-buf)
  ;;; XXX: How about accepting dissected-vec as argument?
  (let ((fn (cond ((stringp fn-or-buf)
		   fn-or-buf)
		  ((bufferp fn-or-buf)
		   (buffer-file-name fn-or-buf))
		  (t
		   (error "Invalid argument %s" fn-or-buf)))))
    (if (perl-minlint-is-tramp fn)
	(let ((vec (tramp-dissect-file-name fn)))
	  (tramp-file-name-localname vec))
      fn)))

(defun perl-minlint-find-executable (buf)
  (let ((fn (buffer-file-name buf)))
    (cond ((perl-minlint-is-tramp fn)
	   (let* ((vec (tramp-dissect-file-name fn))
		  (specific (perl-minlint-executable-for-host
			     (tramp-file-name-host vec))))
	     (or specific
		 (tramp-find-executable vec perl-minlint-script
					(tramp-get-remote-path vec)))))
	  (t
	   (executable-find perl-minlint-script)))))

(defun perl-minlint-executable-for-host (host)
  (let ((found (assoc host perl-minlint-script-for-tramp-host-alist)))
    (cdr found)))

(defun perl-minlint-is-tramp (fn)
  (and (fboundp 'tramp-tramp-file-p)
       (tramp-tramp-file-p fn)))

;;;;========================================

(defun perl-minlint-match (pattern str &rest key-offset)
  "match PATTERN to STR and extract match-portions specified by KEY-OFFSET."
  (let (res spec key off pos end)
    (save-match-data
      (when (setq pos (string-match pattern str))
	(setq end (match-end 0))
	(while key-offset
	  (setq key (car key-offset)
		off (cadr key-offset))
	  (setq res (append (list key (match-string off str)) res))
	  (setq key-offset (cddr key-offset)))
	(append `(pos ,pos end ,end) res)))))

;;========================================
(defmacro perl-minlint-plist-bind (vars form &rest body)
  "Extract specified VARS from FORM result
and evaluate BODY.

\(perl-minlint-plist-bind (file line err) (somecode...)
	    body)

is expanded into:

\(let* ((result (somecode...))
       (file (plist-get result 'file))
       (line (plist-get result 'line))
       (err  (plist-get result 'err)))
  body)"

  (declare (debug ((&rest symbolp) form &rest form)))

  ;; This code is heavily borrowed from cl-macs.el:multiple-value-bind
  (let ((temp (make-symbol "--perl-minlint-plist-bind-var--")))
    (list* 'let* (cons (list temp form)
		       (mapcar (function
				(lambda (v)
				  (list v (list 'plist-get temp `(quote ,v)))))
			       vars))
	   body)))

(unless (get 'perl-minlint-plist-bind 'edebug-form-spec)
  (put 'perl-minlint-plist-bind 'edebug-form-spec
       '((&rest symbolp) form &rest form)))

(put 'perl-minlint-plist-bind 'lisp-indent-function 2)
;;========================================
