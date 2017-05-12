;;
;; To use perlminlint from flycheck-mode in cperl-mode, load this file.
;;

(add-hook
 'cperl-mode-hook

 (lambda ()
   (require 'flycheck)
   (let ((when-sym 'flycheck-check-syntax-automatically)
	 (save-only '(save)))
     ;;
     ;; Enable flycheck
     ;;
     ;; To prevent checking while buffer initialization.
     (let ((flycheck-check-syntax-automatically save-only))
       (flycheck-mode))
     
     ;;
     ;; perlminlint doesn't work with temporary files.
     ;;
     (set (make-variable-buffer-local when-sym) save-only)

     (message "syntax is checked when: %s" (eval when-sym))

     ;;
     ;; Same above.
     ;;
     (flycheck-set-checker-properties
      'perl
      '((flycheck-command "perlminlint" source-original)))))

  ;; (message "cperl-mode-hook is: %s" cperl-mode-hook)
)
