;;
;; This file does 3 things.
;;
;;  * adds this directory to load-path
;;  * adds autoload (by loading "loaddefs.el") if missing
;;  * adds perl-minlint-mode to cperl-mode-hook.
;;

(let ((fsym 'perl-minlint-mode)
      (target 'cperl-mode-hook)
      (dir (or (and load-file-name (file-name-directory load-file-name))
	       default-directory)));; for ^X^E
  (add-to-list 'load-path dir)
  (if (or (not (fboundp fsym))
	  (autoloadp (symbol-function fsym)))
      (load (concat dir "loaddefs.el")))
  (add-hook target fsym)
  ;; (message "cperl-mode-hook is: %s" cperl-mode-hook)
  )

