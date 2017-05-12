;;; Apache::ASP mmm-mode config, by Joshua Chamas, 6/17/2001
(require 'mmm-auto)
(require 'mmm-compat)
(require 'mmm-vars)
(setq mmm-global-mode 'maybe)

; sets meta-p to reparse buffer in case the buffer does
; no update automatically while typing
(global-set-key "\M-p"  'mmm-parse-buffer)

;; create asp-perl mmm-mode subclass 
(mmm-add-group 'asp-perl '((asp-perl-blocks
			    :submode perl-mode
			    :match-face (("<%" . mmm-code-submode-face)
					 ("<%=" . mmm-output-submode_face))
			    :front "<%=?"
			    :back "%>"
			    )))

; .asp, .htm, .inc files will be parsed with mmm-mode
(add-to-list 'mmm-mode-ext-classes-alist '(nil "\\.\\(asp\\|htm\\|inc\\)" asp-perl))
(add-hook 'mmm-major-mode-hook 'turn-on-auto-fill)

; turn off background color for code blocks, may set it if you like
(set-face-background 'mmm-default-submode-face nil)
;(set-face-background 'mmm-default-submode-face "gray")

; set major mode for these files to HTML mode, except global.asa which you 
; want to treat as a pure perl file
(setq auto-mode-alist (append '(
				("\\.pm$" . cperl-mode)
				("\\.asa$" . cperl-mode)
				("\\.inc$" . html-mode)
				("\\.htm" . html-mode)
				("\\.asp$" . html-mode)
				) auto-mode-alist))
