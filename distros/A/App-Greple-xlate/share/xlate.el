;;; xlate.el

(defvar xlate-default-target-lang "EN-US"
  "Default target language for translation.")

(defvar xlate-languages
  '("BG" "CS" "DA" "DE" "EL" "EN-GB" "EN-US" "ES" "ET" "FI"
    "FR" "HU" "ID" "IT" "JA" "KO" "LT" "LV" "NB" "NL" "PL"
    "PT-BR" "PT-PT" "RO" "RU" "SK" "SL" "SV" "TR" "UK" "ZH")
  "List of supported languages for xlate command.")

(defun xlate-buffer (&optional prefix)
  "Execute deepl command on current buffer."
  (interactive "P")
  (if prefix
      (xlate-region (region-beginning) (region-end))
    (xlate-region (point-min) (point-max))))

(defun xlate-region (begin end &optional target-lang)
  "Execute xlate on region with an optional target language.
If called with a prefix argument (C-u), prompt for the target language."
  (interactive
   (list (region-beginning) (region-end)
         (if current-prefix-arg
             (completing-read (format "Target language (default: %s): "
                                      xlate-default-target-lang)
                              xlate-languages nil t)
           nil)))
  (let ((lang (or target-lang xlate-default-target-lang)))
    (shell-command-on-region
     begin end
     (format "xlate -a -s -o cm -w72 -p '(?s).+' -t %s -" lang)
     t t nil t)
    (setq xlate-default-target-lang lang))) ; Update the default target language
