(defun followme-after-save-hook ()
  "After saving a text file, run followme"
  (if buffer-file-name
      (progn
        (setq is-md-file (numberp (string-match "\.md$" buffer-file-name)))
        (if is-md-file
            (progn
              (shell-command (concat "/usr/local/bin/followme " buffer-file-name))
              (message "Converted %s with followme" buffer-file-name))))))
(add-hook 'after-save-hook 'followme-after-save-hook)
