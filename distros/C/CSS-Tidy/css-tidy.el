(defun css-tidy ()
    (interactive)
    (call-process-region (point-min) (point-max)
			 "/home/ben/software/install/bin/csstidy"
			 (current-buffer) t)
)

