;; lookup.el --- run the perl lookup script https://metacpan.org/release/App-lookup

;; Copyright (C) 2013 Ahmad Syaltut

;; Author: Ahmad Syaltut <syaltut@cpan.org>
;; Keywords: perl, processes, tools

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;; Short demo: <http://i.minus.com/inRg3aL2wGGQ5.gif>.

;;; Installation:

;; Put this file somewhere in your `load-path`, and put the following in your
;; `~/.emacs` file

;;     (require 'lookup)

;; Optionally, bind the command `lookup` and `lookup-quick` to handy
;; keybindings:

;;     ;; mnemonic: w for web, (yes, the command "lookup-quick" uses the capital
;;     ;; "W")
;;     (global-set-key (kbd "C-c w") 'lookup)
;;     (global-set-key (kbd "C-c W") 'lookup-quick)

;;; Code:

(require 'thingatpt)

(defgroup lookup nil
  "Run the command lookup"
  :prefix "lookup-"
  :group 'tools
  :group 'processes)

(defcustom lookup-command "lookup"
  "The lookup command.

  If you're using cygwin, you should modify this variable like so
  (see the CAVEATS section in lookup documentation):

      (when (eq system-type 'cygwin)
        (setq lookup-command \"lookup -w 'cygstart'\"))"
  :group 'lookup :type 'string)

(defcustom lookup-prompt-function
  (if (fboundp 'ido-completing-read)
      'ido-completing-read
    'completing-read)
  "The function used to prompt user for lookup sites")

(defcustom lookup-sites-mode-alist nil
  "Alist mapping major-modes to their associated sites.
  Each cons cell in this alist contains the name of the major-mode
  as the associated key and the name of the sites (multiple sites
  are accepted) as the associated value.

  For example, to associate `ruby-mode' with the sites rubygems and
  ruby-doc (assuming both sites are defined in the configuration
  file ~/.lookuprc):

    (add-to-list 'lookup-sites-mode-alist '(ruby-mode \"rubygems\" \"ruby-doc\")"
  :group 'lookup :type 'alist)

(defvar lookup-hist nil
  "History of previous queries to the command lookup")

(defvar lookup-sites-cache nil
  "Store the list of sites accepted by lookup")

(defun lookup--get-sites (&optional recache)
  "Get a list of sites accepted by lookup by returning the value of variable `lookup-sites-cache'.
  If it's not been set yet (or if the optional argument RECACHE is
  non-nil), set its value by parsing the output of the command
  `lookup --sites'"
  (when (or recache
            (not lookup-sites-cache))
    (message "Please wait, caching sites...")
    (let ((output (shell-command-to-string
                   (format "%s --sites" lookup-command)))
          sites)
      (with-temp-buffer
        (insert output)
        (sort-lines t (point-min) (point-max))
        (goto-char (point-min))
        (while (re-search-forward "^- \\(.+\\)\s+:" nil t)
          (push (match-string 1) sites)))
      ;; TODO: make the regexp above less stupid, so we don't have to strip
      ;; the trailing whitespace
      (setq lookup-sites-cache (mapcar
                                (lambda (site)
                                  (replace-regexp-in-string
                                   "\s*$" "" site))
                                sites))))
  lookup-sites-cache)

(defun lookup--prompt-for-query (&optional site)
  "Prompt user for query argument to the command lookup.
  The prompt message is adjusted depending on the existence of
  symbol under point and whether the argument SITE is supplied or
  not."
  (let* ((word (thing-at-point 'symbol))
         (query (read-string
                 (cond ((and word site)
                        (format "Query %s (default %s): " site word))
                       (site
                        (format "Query %s: " site))
                       (word
                        (format "Query (default %s): " word))
                       (t
                        "Query: "))
                 nil 'lookup-hist word)))
    (when (string= "" query)
      (error "The query can not be empty"))
    query))

(defvar lookup-sites-hist nil
  "History of previously searched sites")

(defun lookup--prompt-for-sites (sites)
  (funcall lookup-prompt-function "Site: " sites nil t nil 'lookup-sites-hist))

(defun lookup-quick ()
  "Call `lookup' with predefined sites based on current `major-mode'.
  This command will complain if current `major-mode' is not
  associated with any sites (see the variable
  `lookup-sites-mode-alist' on how to associate a major-mode with
  lookup sites)"
  (interactive)
  (let ((possible-sites (cdr (assoc major-mode lookup-sites-mode-alist)))
        query sitename)
    (unless possible-sites
      (error "%s is not associated with any site" major-mode))
    (setq sitename
          (if (> (length possible-sites) 1)
              (lookup--prompt-for-sites possible-sites)
            (car possible-sites)))
    (setq query (lookup--prompt-for-query sitename))
    (lookup sitename query)))

(defun lookup (sitename query &optional recache)
  "Interact with the program lookup within emacs.
  SITENAME and QUERY will be passed to lookup as its command line
  arguments.

  When used interactively, prompt user the list of available sites
  for SITENAME and the query string QUERY (defaults to symbol at
  point). With one prefix-arg (the argument RECACHE if called from
  lisp), recache the sites first."
  (interactive
   (let ((sites (lookup--get-sites current-prefix-arg)))
     (list
      (lookup--prompt-for-sites sites)
      (lookup--prompt-for-query)
      current-prefix-arg)))
  (shell-command
   (format "%s '%s' %s" lookup-command sitename query)))

(provide 'lookup)

;;; lookup.el ends here
