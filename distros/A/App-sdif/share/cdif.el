;;; cdif.el --- cdif and ansi-color interface

;;; Code:

(autoload 'ansi-color-apply-on-region "ansi-color" nil t)

(defun cdif-buffer (&optional prefix)
  "Execute cdif command on current buffer and apply ansi-color.
If PREFIX is non-nil, the '--unit=' option is added to the cdif command."
  (interactive "P")
  (cdif-region (point-min) (point-max) prefix))

(defun cdif-region (begin end &optional options)
  "Execute cdif command on region and apply ansi-color.
If OPTIONS is non-nil, the '--unit=' option is added to the cdif command."
  (interactive "rP")
  (or (executable-find "cdif")
      (error "cdif command not found"))
  (let ((opoint (point))
	(modified (buffer-modified-p))
        (cmd (concat "cdif --nocc --no256 --cm OMARK=W/C,NMARK=W/M,DELETE=APPEND=R/W,OCHANGE=NCHANGE=B/W"
                     (when options
                       " --unit="))))
    (set-mark end)
    (goto-char begin)
    (shell-command-on-region begin end cmd t t nil t)
    (message "applying ansi-color. can take a while.")
    (ansi-color-apply-on-region (region-beginning) (region-end))
    (message "done.")
    ;; save-excursion doesn't recover the point. why?
    (goto-char opoint)
    (set-buffer-modified-p modified)))
