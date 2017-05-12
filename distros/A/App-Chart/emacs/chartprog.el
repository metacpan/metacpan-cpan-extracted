;;; chartprog.el --- stock quotes using Chart.

;; Copyright 2004, 2005, 2006, 2007, 2008, 2009, 2010, 2012, 2013, 2014, 2015, 2016, 2017 Kevin Ryde

;; Author: Kevin Ryde <user42_kevin@yahoo.com.au>
;; Keywords: comm, finance
;; URL: http://user42.tuxfamily.org/chart/index.html

;; This file is part of Chart.
;;
;; Chart is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.
;;
;; Chart is distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
;; details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Chart.  If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:
;;
;; See section "Emacs" in the Chart manual for usage.


;;; Code:

(require 'timer) ;; for xemacs21

(eval-when-compile ;; for macros in emacs20
  (unless (and (fboundp 'declare)
               (fboundp 'dolist)
               (fboundp 'push))
    (require 'cl)))

(defvar bookmark-make-record-function)  ;; in bookmark.el


;;-----------------------------------------------------------------------------
;; customizations

;;;###autoload
(defgroup chartprog nil
  "Chart program interface."
  :prefix "chartprog-"
  :group 'applications
  :link '(custom-manual "(chart)Emacs"))

(defface chartprog-up
  `(;; plain "green" is too light to see against a white background
    (((class color) (background light))
     (:foreground "green4"))
    (((class color))
     (:foreground "green")))
  "Face for a Chart quote which is up."
  :group 'chartprog)

(defface chartprog-down
  `((((class color))
     (:foreground "red")))
  "Face for a Chart quote which is down."
  :group 'chartprog)

(defface chartprog-in-progress
  `((((class color) (background dark))
     (:foreground "cyan"))
    (((class color) (background light))
     (:foreground "blue")))
  "Face for Chart quote fetch in progress."
  :group 'chartprog)

(defcustom chartprog-watchlist-hook nil
  "*Hook called by `chart-watchlist'."
  :type  'hook
  :group 'chartprog)

;;-----------------------------------------------------------------------------

(defvar chartprog-debug nil)

(defun chartprog-debug-message (&rest args)
  (when chartprog-debug
    (let ((buffer (get-buffer-create "*chartprog-debug*")))
      (save-selected-window
        (let ((window (get-buffer-window buffer)))
          (if window (select-window window)))

        (with-current-buffer buffer
          (let ((orig-point (if (eobp) nil (point))))
            (dolist (arg args)
              (goto-char (point-max))
              (if (stringp arg)
                  (insert arg)
                (pp arg (current-buffer))))
            (goto-char (point-max))
            (unless (bolp) (insert "\n"))
            (goto-char (or orig-point (point-max)))
            (goto-char (point-max))))))))


;;-----------------------------------------------------------------------------
;; xemacs compatibility

;; Some past versions didn't have propertize did they?  Forget when or what.
;; xemacs 21.4 has propertize.

;;     (unless (fboundp 'propertize)
;;       (defun chartprog-propertize (str &rest properties)
;;         "Return a copy of STR with PROPERTIES added.
;; PROPERTIES is successive arguments PROPERTY VALUE PROPERTY VALUE ..."
;;         (setq str (copy-sequence str))
;;         (add-text-properties 0 (length str) properties str)
;;         str))))


;;----------------------------------------------------------------------------
;; emacs22 new stuff

(if (eval-when-compile (fboundp 'complete-with-action))
    ;; emacs22 (and in emacs23 recognising the "boundaries" thing)
    (eval-and-compile
      (defalias 'chartprog--complete-with-action
        'complete-with-action))

  ;; emacs21,xemacs21
  (defun chartprog--complete-with-action (action table string pred)
    "An internal part of chartprog.el.
A version of emacs22 `complete-with-action'."
    (cond ((null action)
           (try-completion string table pred))
          ((eq action t)
           (all-completions string table pred))
          (t
           (eq t (try-completion string table pred))))))


;;-----------------------------------------------------------------------------
;; misc

(eval-when-compile
  (defmacro chartprog-with-temp-message (message &rest body)
    "An internal part of chartprog.el.
This macro does not exist when running byte compiled.

Display MESSAGE temporarily while evaluating BODY.
This is the same as `with-temp-message' but has a workaround for a bug in
Emacs 21.4 where the temporary message isn't erased if there was no previous
message."
    (declare (debug t) (indent 1)) ;; from 'cl
    (if (eval-when-compile (featurep 'xemacs))
        ;; one key for each macro usage, which means each usage is not reentrant
        (let ((key (gensym "chartprog-with-temp-message--")))
          `(unwind-protect
               (progn
                 (display-message ',key ,message)
                 (prog1 (progn ,@body)
                   (clear-message ',key)))
             (clear-message ',key)))

      `(let* ((chartprog-with-temp-message--oldmsg (current-message)))
         (unwind-protect
             (prog1 (with-temp-message ,message ,@body)
               (or chartprog-with-temp-message--oldmsg (message nil)))
           (or chartprog-with-temp-message--oldmsg (message nil)))))))

(eval-when-compile
  (defmacro chartprog-save-row-col (&rest body)
    "An internal part of chartprog.el.
This macro does not exist when running byte compiled.

Evaluate BODY, preserving point+mark row/col and window start positions.
This is a bit like `save-excursion', but working with row+column rather than
a point position."
    (declare (debug t) (indent 1)) ;; from 'cl
    `(let* ((point-row (count-lines (point-min) (point-at-bol)))
            (point-col (current-column))
            (mark-pos  (mark t)))
       (and mark-pos
            (goto-char mark-pos))
       (let* ((mark-row    (count-lines (point-min) (point-at-bol)))
              (mark-col    (current-column))
              ;; list of pairs (WINDOW . ROW)
              (window-rows (mapcar (lambda (window)
                                     (cons window
                                           (count-lines (point-min)
                                                        (window-start window))))
                                   (get-buffer-window-list (current-buffer)))))
         (prog1 (progn ,@body)
           (dolist (pair window-rows)
             (goto-char (point-min))
             (forward-line (cdr pair))
             (set-window-start (car pair) (point)))

           (goto-char (point-min))
           (forward-line mark-row)
           (move-to-column mark-col)
           (and mark-pos
                (set-marker (mark-marker) (point)))

           (goto-char (point-min))
           (forward-line point-row)
           (move-to-column point-col))))))


(defun chartprog-intersection (x y)
  "An internal part of chartprog.el.
Return the intersection of lists X and Y, ie. elements common to both.
Elements are compared with `equal' and returned in the same order as they
appear in X.

This differs from the cl.el `intersection' in preserving the order of
elements for the return.  cl.el package doesn't preserve the order."
  (let (ret)
    (dolist (elem x) (if (member elem y) (push elem ret)))
    (nreverse ret)))

(defun chartprog-copy-tree-no-properties (obj)
  "An internal part of chartprog.el.
Return a copy of OBJ with no text properties on strings.
OBJ can be a list or other nested structure understood by
copy-sequence and mapcar."
  (cond ((stringp obj)
         (setq obj (copy-sequence obj))
         (set-text-properties 0 (length obj) nil obj)
         obj)
        ((sequencep obj)
         (mapcar 'chartprog-copy-tree-no-properties obj))
        (t
         obj)))


;;-----------------------------------------------------------------------------
;; subprocess

(defconst chartprog-protocol-version 102
  "An internal part of chartprog.el.
This must be the same as the number in App::Chart::EmacsMain, to
ensure cooperation with the sub-process.")

(defvar chartprog-process nil
  "An internal part of chartprog.el.
The running chart subprocess, or nil if not running.")
(defvar chartprog-process-timer nil
  "An internal part of chartprog.el.
Idle timer to kill chart subprocess when it's unused for a while.")

;; forward references
(defvar chartprog-completion-symbols-alist)
(defvar chartprog-latest-cache)
(defvar chartprog-symlist-alist)
(defvar chartprog-watchlist-map)
(defvar chartprog-watchlist-menu)
(defvar chartprog-quote-symbol)
(defvar chartprog-quote-changed)

(defun chartprog-exec (proc &rest args)
  "An internal part of chartprog.el.
Send the chart subprocess PROC (a symbol) with ARGS (lists,
strings, etc).  This is for an asynchronous or a no-reply message
to the subprocess.  See `chartprog-exec-synchronous' for
executing with reply."

  (unless (memq 'utf-8 (coding-system-list))
    (message "Loading mule-ucs for `utf-8' in XEmacs")
    (require 'un-define))

  ;; startup subprocess if not already running
  (unless chartprog-process
    (when (get-buffer " *chartprog subprocess*") ;; possible old buffer
      (kill-buffer " *chartprog subprocess*"))

    (setq chartprog-process
          (let ((process-connection-type nil)) ;; pipe
            (funcall 'start-process
                     "chartprog"
                     (get-buffer-create " *chartprog subprocess*")
                     "chart" "--emacs")))
    (set-process-coding-system chartprog-process 'utf-8 'utf-8)
    (set-process-filter chartprog-process 'chartprog-process-filter)
    (set-process-sentinel chartprog-process 'chartprog-process-sentinel)

    (if (eval-when-compile (fboundp 'set-process-query-on-exit-flag))
        (set-process-query-on-exit-flag chartprog-process nil) ;; emacs22
      (process-kill-without-query chartprog-process)) ;; emacs21

    (buffer-disable-undo (process-buffer chartprog-process)))

  ;; send this command
  (let ((str (concat (prin1-to-string
                      (chartprog-copy-tree-no-properties (cons proc args)))
                     "\n")))
    (chartprog-debug-message "\noutgoing " str)
    (process-send-string chartprog-process str))

  ;; start or restart idle timer
  (when chartprog-process-timer
    (cancel-timer chartprog-process-timer))
  (setq chartprog-process-timer (run-at-time "5 min" nil 'chartprog-process-kill)))

(defun chartprog-incoming-init (codeset protocol-version)
  "An internal part of chartprog.el.
Handle chart subprocess init message.
CODESET is always \"UTF-8\".
PROTOCOL-VERSION is the protocol number the subprocess is speaking, to be
matched against `chartprog-protocol-version'."

  (unless (= protocol-version chartprog-protocol-version)
    (when (get-buffer "*chartprog-watchlist*") ;; ignore if gone
      (with-current-buffer "*chartprog-watchlist*"
        (let ((inhibit-read-only t))
          (erase-buffer)
          (insert (format "Chart program doesn't match this chartprog.el.

  chartprog.el protocol:  %s
  chart program protocol: %s

Check your installation.
" chartprog-protocol-version protocol-version)))))

    (chartprog-process-kill)
    (error "Chart subprocess protocol version mismatch, got %s want %s"
           chartprog-protocol-version protocol-version)))

(defun chartprog-process-filter (proc str)
  "An internal part of chartprog.el.
The filter function for the chart subprocess per
`set-process-filter'.
STR is more text from the subprocess.
An incoming message is a Lisp form like (FOO (\"ABC\")).
When a complete form has arrived the corresponding
`chart-incoming-FOO' function is called."

  (with-current-buffer (process-buffer proc)
    (goto-char (point-max))
    (insert str)
    (while (progn
             ;; form begins with "(", ignore other diagnostics or whatever
             (goto-char (point-min))
             (skip-chars-forward "^(")
             (delete-region (point-min) (point))

             ;; see if a complete form has arrived
             (let ((form (condition-case nil
                             (read (process-buffer proc))
                           (error nil))))
               (when form
                 (delete-region (point-min) (point))

                 (chartprog-debug-message "incoming " form)
                 (apply (intern (concat "chartprog-incoming-"
                                        (symbol-name (car form))))
                        (cdr form)))

               ;; no more processing after `synchronous', let the result get
               ;; back to the caller before further asynch stuff is
               ;; processed (that further stuff deferred under a timer)
               (when (eq (car form) 'synchronous)
                 (run-at-time 0.0000001 nil
                              (lambda ()
                                (chartprog-process-filter chartprog-process "")))
                 (setq form nil))

               ;; process another form, perhaps
               form)))))

(defun chartprog-process-sentinel (proc event)
  "An internal part of chartprog.el.
The sentinel for the chart subprocess per `set-process-sentinel'.

The subprocess should stay alive forever, until we ask it to stop
by the `chartprog-process-timer, so any termination is
unexpected."
  (when (get-buffer "*chartprog-watchlist*")
    (with-current-buffer "*chartprog-watchlist*"
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (when (looking-at "\\s-*Starting")
            (erase-buffer))
          (insert (format "\nSubprocess died: %s\n\n" event))))))
  (chartprog-process-kill)
  (message "Chart subprocess died: %s" event))

(defun chartprog-process-kill ()
  "An internal part of chartprog.el.
Kill chart subprocess."
  (when chartprog-process-timer
    (cancel-timer chartprog-process-timer)
    (setq chartprog-process-timer nil))
  (when chartprog-process
    ;; clear chartprog-process variable immediately, xemacs recurses to here
    (let ((p chartprog-process))
      (setq chartprog-process nil)
      (set-process-sentinel p nil)
      (set-process-filter p nil)
      (delete-process p)
      (kill-buffer (process-buffer p)))
    ;; go back to uninitialized to force a re-read on the contents if the
    ;; subprocess is restarted, that way any additions while we were away
    ;; will appear
    (setq chartprog-completion-symbols-alist 'uninitialized)
    (setq chartprog-symlist-alist 'uninitialized)
    (setq chartprog-latest-cache (make-hash-table :test 'equal))))


;;-----------------------------------------------------------------------------
;; synchronous commands

(defvar chartprog-exec-synchronous-seq 0)
(defvar chartprog-exec-synchronous-got 0)
(defvar chartprog-exec-synchronous-result nil)

(defun chartprog-incoming-synchronous (got result)
  "An internal part of chartprog.el.
Receive synchronize number GOT from Chart subprocess."
  (setq chartprog-exec-synchronous-got got)
  (setq chartprog-exec-synchronous-result result))

(defun chartprog-exec-synchronous (proc &rest args)
  "An internal part of chartprog.el.
Call chart PROC (a symbol) with ARGS (lists, strings, etc).
Return the return value from that call, when it completes."

  (setq chartprog-exec-synchronous-seq (1+ chartprog-exec-synchronous-seq))
  (apply 'chartprog-exec 'synchronous chartprog-exec-synchronous-seq proc args)

  (while (not (= chartprog-exec-synchronous-seq
                 chartprog-exec-synchronous-got)) ;; ignore old abandoned calls
    (if (not (eq 'run (process-status chartprog-process)))
        (error "Chart subprocess died"))
    (accept-process-output chartprog-process))

  chartprog-exec-synchronous-result)


;;-----------------------------------------------------------------------------
;; incoming from subprocess

(defun chartprog-incoming-update (symbol-list)
  "An internal part of chartprog.el.
Receive advice from Chart subprocess that the symbols (strings)
in SYMBOL-LIST have updated.
Any cached data for these symbols in `chartprog-latest-cache' is
discarded.
Any of these symbols in the watchlist are re-read."
  (chartprog-latest-cache-remove symbol-list)

  (when (member chartprog-quote-symbol symbol-list)
    (setq chartprog-quote-changed t))
  (chartprog-debug-message "chartprog-quote-changed " chartprog-quote-symbol)

  (let ((want-list (chartprog-intersection (chartprog-watchlist-symbol-list)
                                           symbol-list)))
    (chartprog-debug-message "watchlist want-list " want-list)
    (if want-list
        (chartprog-exec 'latest-get-list want-list))))

(defun chartprog-incoming-message (str)
  "An internal part of chartprog.el.
Receive a free-form message STR from the Chart subprocess."
  (message "%s" str))

(defun chartprog-incoming-error (errstr backtrace)
  "An internal part of chartprog.el.
Receive an error message from the Chart subprocess.
ERRSTR is a string.
BACKTRACE is either a string or nil."
  (when backtrace
    (with-current-buffer (get-buffer-create "*chartprog-process-backtrace*")
      (let ((follow (= (point) (point-max))))
        (save-excursion
          (goto-char (point-max))
          (insert "-------------------------------------------------------------------------------\n")
          (insert backtrace))
        (when follow
          (goto-char (point-max))))))
  (message "%s" errstr))


;;-----------------------------------------------------------------------------
;; symbols completion

(defvar chartprog-symbol-history nil
  "History list of Chart symbols entered by the user.")

(defun chartprog-minibuffer-local-completion-map ()
  "An internal part of chartprog.el.
Return a keymap which is like `minibuffer-local-completion-map'
but with <SPACE> self-inserting.
Chart symbols can contain spaces, so <SPACE> is best as an
ordinary insert, not a completion like the default in
`minibuffer-local-completion-map'."
  ;; `minibuffer-local-completion-map' might change so must
  ;; `set-keymap-parent' each time, and the keymap is small enough that may
  ;; as well create a whole fresh one each time
  (let ((m (make-sparse-keymap)))
    (set-keymap-parent m minibuffer-local-completion-map)
    (define-key m " " 'self-insert-command)
    m))

(defvar chartprog-completion-symbols-alist 'uninitialized
  "An internal part of chartprog.el.
Alist of Chart symbols for completing read, or symbol
`uninitialized' if symbol list not yet obtained.

Call function `chartprog-completion-symbols-alist' instead of
using this variable directly.  The function gets the list from
the Chart subprocess when 'uninitialized.")

(defun chartprog-completion-symbols-alist (&optional dummy)
  "An internal part of chartprog.el.
Return an alist of Chart symbols for completing read.
Currently there's nothing in the `cdr's, it's just
\((SYMBOL) (SYMBOL) ...)."
  (when (eq 'uninitialized chartprog-completion-symbols-alist)
    (chartprog-with-temp-message "Receiving database symbols ..."
      (setq chartprog-completion-symbols-alist
            (chartprog-exec-synchronous 'get-completion-symbols))))
  chartprog-completion-symbols-alist)

(defun chartprog-incoming-completion-symbols-update ()
  "An internal part of chartprog.el.
Receive advice from Chart subprocess that completion symbols have changed."
  (setq chartprog-completion-symbols-alist 'uninitialized))

(defun chartprog-symbol-completion-handler (str pred action)
  "An internal part of chartprog.el.
Chart symbol (string) completion handler, for `completing-read'."
  (chartprog--complete-with-action action (chartprog-completion-symbols-alist)
                                   str pred))

(defun chartprog-completing-read-symbol (&optional default)
  "Read a Chart symbol using `completing-read'.
Optional DEFAULT is a string."
  (let ((minibuffer-local-completion-map (chartprog-minibuffer-local-completion-map))
        (completion-ignore-case t))
    (if (equal "" default) ;; allow for empty from thing-at-point
        (setq default nil))
    (completing-read (if default
                         (format "Symbol (%s): " default)
                       "Symbol: ")
                     'chartprog-symbol-completion-handler
                     nil  ;; pred
                     nil  ;; require-match
                     nil  ;; initial-input
                     'chartprog-symbol-history
                     default)))


;;-----------------------------------------------------------------------------
;; symlist stuff

(defvar chartprog-symlist-history nil
  "History list of Chart symlist names entered by the user.")

(defvar chartprog-symlist-alist 'uninitialized
  "An internal part of chartprog.el.
List of of symlists in Chart, or Lisp symbol `uninitialized' if
not yet set.  Currently each list element is a list
    (NAME KEY EDITABLE)
NAME is a string.
KEY is a Lisp symbol.
EDITABLE is t or nil.

NAME is the first in each element so it can be used like an alist
with `completing-read'.

Call function `chartprog-symlist-alist' instead of using this
variable directly.  The function gets the list from the Chart
subprocess when `uninitialized'.")

(defun chartprog-symlist-alist ()
  "An internal part of chartprog.el.
Return the variable `chartprog-symlist-alist', initializing it if
necessary."
  (when (eq 'uninitialized chartprog-symlist-alist)
    (chartprog-with-temp-message "Receiving symlist info ..."
      (chartprog-exec-synchronous 'get-symlist-alist)))
  chartprog-symlist-alist)

(defun chartprog-incoming-symlist-alist (alist)
  "An internal part of chartprog.el.
Receive the `chartprog-symlist-alist' data from Chart subprocess."
  (setq chartprog-symlist-alist alist)

  ;; freshen watchlist mode-line symlist name, if any
  (when (get-buffer "*chartprog-watchlist*")
    (with-current-buffer "*chartprog-watchlist*"
      (force-mode-line-update)))

  ;; fill Chart menu for watchlist
  (mapcar (lambda (elem)
            (let ((name (car elem))
                  (key  (cadr elem)))
              (define-key chartprog-watchlist-menu
                (vector key)
                (cons name `(lambda ()
                              (interactive)
                              (chartprog-watchlist-symlist ',key))))))
          (reverse chartprog-symlist-alist)))

(defun chartprog-incoming-symlist-list-changed (alist)
  "An internal part of chartprog.el.
Receive advice from Chart subprocess that the symlist list
entries have changed.  For example a name change."

  ;; if watchlist then ask for a fresh symlist alist
  (when (get-buffer "*chartprog-watchlist*")
    (chartprog-exec 'get-symlist-alist)))

(defun chartprog-symlist-find (key &optional no-freshen)
  "An internal part of chartprog.el.
KEY is a symbol like `favourites'.
Return its element of `chartprog-symlist-alist', or nil if not found.
`chartprog-symlist-alist' is fetched if yet uninitialized, unless
NO-FRESHEN is non-nil in which case don't fetch just return nil."
  (let (ret)
    (unless (and no-freshen
                 (eq 'uninitialized chartprog-symlist-alist))
      (dolist (elem (chartprog-symlist-alist))
        (if (eq key (cadr elem))
            (setq ret elem))))
    ret))

(defun chartprog-symlist-editable-p (key)
  "Return non-nil if symlist KEY (a Lisp symbol) is editable."
  (nth 2 (chartprog-symlist-find key)))


;;-----------------------------------------------------------------------------
;; symlist name completion

(defun chartprog-symlist-completion-handler (str pred action)
  "Chart symlist completion handler, for `completing-read'."
  (chartprog--complete-with-action action (chartprog-symlist-alist)
                                   str pred))

(defun chartprog-completing-read-symlist ()
  "An internal part of chartprog.el.
Read a Chart symlist using `completing-read'.
The user is presented with the symlist names.
The return is the symlist key, a Lisp symbol such as `favourites'."
  (let ((minibuffer-local-completion-map (chartprog-minibuffer-local-completion-map))
        (completion-ignore-case t))
    (let ((name (completing-read "Symlist: "
                                 'chartprog-symlist-completion-handler
                                 nil  ;; pred
                                 t    ;; require-match
                                 nil  ;; initial-input
                                 'chartprog-symlist-history)))
      (cadr (assoc name (chartprog-symlist-alist))))))


;;-----------------------------------------------------------------------------
;; watchlist funcs

(defvar chartprog-watchlist-current-symlist 'favourites
  "An internal part of chartprog.el.
The key of the current symlist being displayed in the watchlist.
This is a symbol such as `favourites', or `user-1'.")

(defun chartprog-watchlist-find (symbol)
  "An internal part of chartprog.el.
Move point to line for Chart SYMBOL (a string).
Return non-nil if found.
Return nil and leave point unchanged if not found."
  (let ((oldpos (point))
        found)
    (goto-char (point-min))
    ;; continue while not found and can move forward a line
    (while (and (not (setq found (equal symbol (chartprog-watchlist-symbol))))
                (= 0 (forward-line))))
    (unless found
      (goto-char oldpos))
    found))

(defun chartprog-watchlist-symbol ()
  "An internal part of chartprog.el.
Return Char symbol (a string) on current watchlist line, or nil
if none."
  (get-text-property (point-at-bol) 'chartprog-symbol))

(defun chartprog-watchlist-symbol-list ()
  "An internal part of chartprog.el.
Return list of Chart symbols (strings) in watchlist buffer.
If no watchlist buffer then return nil."
  (and (get-buffer "*chartprog-watchlist*") ;; ignore if gone
       (with-current-buffer "*chartprog-watchlist*"
         (let (lst)
           (save-excursion
             (goto-char (point-min))
             (while (let ((symbol (chartprog-watchlist-symbol)))
                      (if symbol
                          (setq lst (cons symbol lst)))
                      (= 0 (forward-line)))))
           (nreverse lst)))))


;;-----------------------------------------------------------------------------
;; watchlist display

(defun chartprog-incoming-symlist-update (key-list)
  "An internal part of chartprog.el.
Receive advice from Chart subprocess that symlists KEY-LIST have updated.
KEY-LIST is a list of Lisp symbols."
  (if (and (get-buffer "*chartprog-watchlist*") ;; ignore if gone
           (memq chartprog-watchlist-current-symlist key-list))
      (chartprog-exec 'get-symlist chartprog-watchlist-current-symlist)))

(defun chartprog-incoming-latest-line-list (lst)
  "An internal part of chartprog.el.
Receive LST of latest elements (SYMBOL STR FACE HELP).
The watchlist buffer is updated with the new data."
  (when (get-buffer "*chartprog-watchlist*") ;; ignore if gone
    (with-current-buffer "*chartprog-watchlist*"
      (chartprog-save-row-col
        (let ((inhibit-read-only t))
          (dolist (elem lst) ;; elements (SYMBOL STR FACE)
            (when (chartprog-watchlist-find (car elem))
              (delete-region (point-at-bol) (point-at-eol))
              (insert (propertize (cadr elem)
                                  'chartprog-symbol (car elem)
                                  'face             (nth 2 elem)
                                  'help-echo        (nth 3 elem))))))))))

(defun chartprog-incoming-symlist-list (symlist symbol-list)
  "An internal part of chartprog.el.
SYMLIST is a Lisp symbol, a symlist key.
SYMBOL-LIST is a list of Chart symbols (strings) which are the
contents of that symlist."
  (when (and (get-buffer "*chartprog-watchlist*")              ;; ignore if gone
             (eq symlist chartprog-watchlist-current-symlist)) ;; or if stray response
    (with-current-buffer "*chartprog-watchlist*"
      (let (alst need)

        ;; build alst (SYMBOL . LINE-STRING) for existing lines
        (save-excursion
          (goto-char (point-min))
          (while (let ((symbol (chartprog-watchlist-symbol)))
                   (when symbol
                     (push (cons symbol
                                 (buffer-substring (point)
                                                   (1+ (point-at-eol))))
                           alst))
                   (= 0 (forward-line)))))

        ;; fill buffer, and use existing lines from alst
        (let ((inhibit-read-only t))
          (chartprog-save-row-col
            (erase-buffer)
            (dolist (symbol symbol-list)
              (insert (or (cdr (assoc symbol alst))
                          (progn
                            (setq need (cons symbol need))
                            (propertize (concat symbol "\n")
                                        'chartprog-symbol symbol)))))
            (unless symbol-list
              (if (chartprog-symlist-editable-p chartprog-watchlist-current-symlist)
                  (insert (format "\n\n(Empty list, use `%s' to add a symbol.)"
                                  (key-description
                                   (car (where-is-internal
                                         'chartprog-watchlist-add
                                         chartprog-watchlist-map)))))
                (insert (format "\n\n(Empty list.)"))))))
        (if need
            (chartprog-exec 'latest-get-list (nreverse need)))))))


;;-----------------------------------------------------------------------------
;; header-line-format hscrolling

(defconst chartprog-header-line-scrolling-align0
  (propertize " " 'display '((space :align-to 0)))
  "An internal part of chartprog.el.
An string which is space with align-to 0 property.")

(defvar chartprog-header-line-scrolling-str nil
  "An internal part of chartprog.el.
Buffer local full `header-line-format' string to be hscrolled.")

(defun chartprog-header-line-scrolling-align ()
  "An internal part of chartprog.el.
Return a string which will align to column 0 in a `header-line-format'."
  (if (string-match "^21\\." emacs-version)
      (and (display-graphic-p)
           (concat " "  ;; the fringe
                   (and (eq 'left (frame-parameter nil 'vertical-scroll-bars))
                        "  ")))  ;; left scrollbar
    ;; in emacs 22 and up align-to understands fringe and scrollbar
    chartprog-header-line-scrolling-align0))

(defun chartprog-header-line-scrolling-eval ()
  "An internal part of chartprog.el.
Install hscrolling header line updates on the windows of the current frame."
  (concat (chartprog-header-line-scrolling-align)
          (substring chartprog-header-line-scrolling-str
                     (min (length chartprog-header-line-scrolling-str)
                          (window-hscroll)))))

(defun chartprog-header-line-scrolling (str)
  "An internal part of chartprog.el.
Set STR as `header-line-format' and make it follow any hscrolling."
  (set (make-local-variable 'chartprog-header-line-scrolling-str) str)
  (set (make-local-variable 'header-line-format)
       '(:eval (chartprog-header-line-scrolling-eval))))


;;-----------------------------------------------------------------------------
;; watchlist commands

(defvar chartprog-watchlist-menu (make-sparse-keymap "Chart")
  "An internal part of chartprog.el.
Menu for Chart watchlist.")

(defvar chartprog-watchlist-map
  (let ((m (make-sparse-keymap)))
    (define-key m "\C-k" 'chartprog-watchlist-kill-line)
    (define-key m "\C-w" 'chartprog-watchlist-kill-region)
    (define-key m "\C-y" 'chartprog-watchlist-yank)
    (define-key m "\C-_" 'chartprog-watchlist-undo)
    (define-key m "a"    'chartprog-watchlist-add)
    (define-key m "g"    'chartprog-watchlist-refresh)
    (define-key m "n"    'next-line)
    (define-key m "q"    'chartprog-watchlist-quit)
    (define-key m "p"    'previous-line)
    (define-key m "L"    'chartprog-watchlist-symlist)
    (define-key m "?"    'chartprog-watchlist-detail)
    (define-key m [menu-bar chartprog] (cons "Chart" chartprog-watchlist-menu))
    m)
  "Keymap for Chart watchlist.")

(defun chartprog-watchlist-want-edit ()
  "An internal part of chartprog.el.
Check that the watchlist being displayed is editable."
  (or (chartprog-symlist-editable-p chartprog-watchlist-current-symlist)
      (error "This list is not editable")))

(defun chartprog-watchlist-detail ()
  "Show detail for this line (stock name and full quote and times)."
  (interactive)
  (let ((str (get-text-property (point-at-bol) 'help-echo)))
    (if str
        (message "%s" str))))

(defun chartprog-watchlist-kill-line ()
  "Kill watchlist line into the kill ring.
Use \\[chartprog-watchlist-yank] to yank it back at a new position."
  (interactive)
  (chartprog-watchlist-want-edit)
  (let ((inhibit-read-only t))
    (save-excursion
      (beginning-of-line)
      (kill-line 1)))
  (chartprog-exec 'symlist-delete chartprog-watchlist-current-symlist
                  (count-lines (point-min) (point-at-bol))
                  1))

(defun chartprog-watchlist-kill-region ()
  "Kill watchlist region between point and mark into the kill ring.
Use \\[chartprog-watchlist-yank] to yank them back at a new position."
  (interactive)
  (chartprog-watchlist-want-edit)
  (beginning-of-line)
  (let* ((point-row (count-lines (point-min) (point)))
         (mark-bol  (save-excursion (goto-char (mark)) (point-at-bol)))
         (mark-row   (count-lines (point-min) mark-bol)))
    (let ((inhibit-read-only t))
      (kill-region mark-bol (point)))
    (chartprog-exec 'symlist-delete chartprog-watchlist-current-symlist
                    (min point-row mark-row)
                    (abs (- point-row mark-row)))))

(defun chartprog-watchlist-mode-line-symlist-name ()
  "An internal part of chartprog.el.
Return the name of the current symlist, for display in the mode line."
  (let ((name (car (chartprog-symlist-find
                    chartprog-watchlist-current-symlist
                    t)))) ;; no freshen
    (when name
      (when (> (length name) 20)
        (setq name (concat (substring name 0 17) "...")))
      (setq name (concat " " name)))
    name))

(defun chartprog-watchlist-update-symlist-name ()
  "Update the symlist name shown in the mode line."

  '(with-current-buffer "*chartprog-watchlist*"
    (setq mode-name (concat "Watchlist - "
                            (car (chartprog-symlist-find
                                  chartprog-watchlist-current-symlist))))))

(defun chartprog-watchlist-symlist (symlist)
  "Select SYMLIST to view."
  (interactive (list (chartprog-completing-read-symlist)))
  (unless (eq symlist chartprog-watchlist-current-symlist)
    (chartprog-exec 'get-symlist symlist))
  (setq chartprog-watchlist-current-symlist symlist))

(defun chartprog-watchlist-add (symbol)
  "Add a symbol to the watchlist (after the current one).
SYMBOL is read from the minibuffer, with completion from the database symbols."
  (interactive (progn (chartprog-watchlist-want-edit)
                      (list (chartprog-completing-read-symbol))))
  (chartprog-watchlist-want-edit)
  (unless (chartprog-watchlist-find symbol)
    (beginning-of-line)
    (forward-line)
    (chartprog-exec 'symlist-insert chartprog-watchlist-current-symlist
                    (count-lines (point-min) (point)) ;; position
                    (list symbol))
    (let ((inhibit-read-only t))
      (insert (propertize (concat symbol "\n") 'chartprog-symbol symbol)))
    (forward-line -1)
    (chartprog-exec 'latest-get-list (list symbol))
    (chartprog-exec 'request-symbols (list symbol))))

(defun chartprog-watchlist-yank ()
  "Yank a watchlist line.
Only lines from the watchlist buffer can be yanked
\(see `chartprog-watchlist-add' to insert an arbitrary symbol)."
  (interactive)
  (chartprog-watchlist-want-edit)
  (let ((str (current-kill 0 t)))
    (if (string-match "\n+\\'" str) ;; lose trailing newlines
        (setq str (replace-match "" t t str)))
    (let ((symbol-list (mapcar (lambda (line)
                                 (get-text-property 0 'chartprog-symbol line))
                               (split-string str "\n"))))
      (if (memq nil symbol-list)
          (error "Can only yank killed watchlist line(s)"))
      (beginning-of-line)
      (chartprog-exec 'symlist-insert chartprog-watchlist-current-symlist
                      (count-lines (point-min) (point)) ;; position
                      symbol-list)
      (let ((inhibit-read-only t))
        (yank)))))

(defun chartprog-watchlist-undo ()
  "Undo last edit in the watchlist."
  (interactive)
  (error "Sorry, not working yet")

  (chartprog-watchlist-want-edit)
  (let ((inhibit-read-only t))
    (undo)))

(defun chartprog-watchlist-refresh (arg)
  "Refresh watchlist quotes.
With a prefix ARG (\\[universal-argument]), refresh only current line.

For the Alerts list, all symbols with alert levels are refreshed,
and the list contents updated accordingly.  (So not merely those
already showing which are refreshed.)"

  (interactive "P")
  ;; updates from the subprocess will come with an in-progress face, but
  ;; apply that here explicitly to have it show immediately
  (if arg
      (progn ;; one symbol
        (let ((inhibit-read-only t))
          (add-text-properties (point-at-bol) (point-at-eol)
                               (list 'face 'chartprog-in-progress)))
        (chartprog-exec 'request-explicit (list (chartprog-watchlist-symbol))))
    (progn ;; whole list
      (let ((inhibit-read-only t))
        (add-text-properties (point-min) (point-max)
                             (list 'face 'chartprog-in-progress)))
      (chartprog-exec 'request-explicit-symlist chartprog-watchlist-current-symlist))))

(defun chartprog-watchlist-quit ()
  "Quit from the watchlist display."
  (interactive)
  (chartprog-process-kill)
  (kill-buffer nil))

;;;###autoload
(defun chart-watchlist ()
  "Chart watchlist display.

\\{chartprog-watchlist-map}
On a colour screen, face `chartprog-up' and face `chartprog-down' show
each line in green or red according to whether the last trade was
higher or lower than the previous close (ie. the change column
positive or negative).  Face `chartprog-in-progress' shows blue while
quotes are being downloaded.

Stock name and quote/last-trade times can be seen in a tooltip by
moving the mouse over each line.  The same can be seen on a text
terminal with `\\[chartprog-watchlist-detail]'."

  (interactive)
  (switch-to-buffer (get-buffer-create "*chartprog-watchlist*"))
  (when (save-excursion
          (goto-char (point-min))
          (or (looking-at "Subprocess died")
              (eq (point-min) (point-max))))

    (setq buffer-read-only nil)
    (erase-buffer)
    (insert "\nStarting chart subprocess ...\n")
    (sit-for 0) ;; redisplay
    (kill-all-local-variables)
    (use-local-map chartprog-watchlist-map)
    (setq major-mode       'chart-watchlist
          mode-name        "Watchlist"
          truncate-lines   t
          buffer-read-only t
          chartprog-watchlist-current-symlist 'favourites)
    (chartprog-header-line-scrolling
     "Symbol       bid/offer     last  change    low    high    volume   when   note")

    (set (make-local-variable 'mode-line-buffer-identification)
         (append (default-value 'mode-line-buffer-identification)
                 '((:eval (chartprog-watchlist-mode-line-symlist-name)))))

    (set (make-local-variable 'bookmark-make-record-function)
         'chartprog-watchlist-bookmark-make-record)

    (when (fboundp 'make-local-hook)
      (make-local-hook 'kill-buffer-hook)) ;; for xemacs21
    (add-hook 'kill-buffer-hook 'chartprog-process-kill t t)

    (chartprog-exec 'get-symlist     chartprog-watchlist-current-symlist)
    ;; want to freshen always, or only on "g" ?
    ;; (chartprog-exec 'request-symlist chartprog-watchlist-current-symlist)
    (chartprog-exec 'get-symlist-alist)

    (run-hooks 'chartprog-watchlist-hook)))

;;-----------------------------------------------------------------------------
;; chart-watchlist tie-in for bookmark.el

(defun chartprog-watchlist-bookmark-make-record ()
  "An internal part of chartprog.el
Return a bookmark record for `chartprog-watchlist'.
This function is designed for use from variable
`bookmark-make-record-function' as a tie-in to bookmark.el.

The bookmark records the symlist displayed.  This is done with
the symlist key, so if the name is edited in chart then it will
still be found.  The bookmark name is the symlist name at the
time the bookmark is set, it won't update.

Line and column of point are not recorded since the watchlist
contents are not available until chart has started and been
queried, which is done asynchronously."

  (list
   ;; symlist name as bookmark name
   (or (car (chartprog-symlist-find
             chartprog-watchlist-current-symlist))
       (symbol-name chartprog-watchlist-current-symlist))

   (cons 'symlist   chartprog-watchlist-current-symlist)
   '(handler      . chartprog-watchlist-bookmark-jump)))

;; autoload so available to saved bookmarks when chartprog.el not yet loaded
;;;###autoload
(defun chartprog-watchlist-bookmark-jump (bmk)
  "Jump to bookmark record BMK for `chartprog-watchlist'.
This is designed for use from the bookmark records created by
`chartprog-watchlist-location-bookmark-make-record'."
  (chart-watchlist)
  (chartprog-watchlist-symlist (bookmark-prop-get bmk 'symlist)))


;;-----------------------------------------------------------------------------
;; quotes

;; `thing-at-point' setups
;; chart-symbol is alphanumerics plus .,^- and ending in an alphanumeric
;; note no [:alnum:] in xemacs 21
(put 'chart-symbol 'beginning-op
     (lambda ()
       (if (re-search-backward "[^A-Za-z0-9.,^-]" nil t)
           (forward-char)
         (goto-char (point-min)))))
(put 'chart-symbol 'end-op
     (lambda ()
       (unless (re-search-forward "\\=[A-Za-z0-9.,^-]*[A-Za-z0-9]" nil t)
         (goto-char (point-max)))))
(put 'chart-symbol 'thing-at-point
     (lambda ()
       (let ((bounds (bounds-of-thing-at-point 'chart-symbol)))
         (and bounds
              (let ((str (buffer-substring (car bounds) (cdr bounds))))
                ;; suffix in upper case, yahoo reuters news often has lower
                (if (string-match "\\(.*\\)\\([.][^.]*\\)" str)
                    (setq str (concat (match-string 1 str)
                                      (upcase (match-string 2 str)))))
                ;; leading "." assumed to be "^", often seen in yahoo reuters
                (if (string-match "^\\." str)
                    (setq str (concat "^" (substring str 1))))
                str)))))

(defvar chartprog-quote-symbol nil)
(defvar chartprog-quote-changed nil)

;;;###autoload
(defun chart-quote (symbol)
  "Show a quote in the message area for the Chart stock SYMBOL.
Interactively SYMBOL is read from the minibuffer, the default is
the symbol at point.

A fresh quote is downloaded like an update in the watchlist.

The current quote is shown with `chartprog-in-progress' face
until it arrives.  \\[keyboard-quit] in the usual way to stop waiting."

  (interactive (list (chartprog-completing-read-symbol (thing-at-point
                                                        'chart-symbol))))
  (message "Fetching ...")
  (setq chartprog-quote-symbol symbol)
  (setq chartprog-quote-changed t)
  (chartprog-exec 'request-explicit (list symbol))

  (while chartprog-quote-symbol
    (when chartprog-quote-changed
      (setq chartprog-quote-changed nil)
      (let* ((elem (chartprog-exec-synchronous 'quote-one symbol))
             (face (nth 2 elem)))
        (message "%s" (propertize (cadr elem) 'face face))
        (redisplay t)
        (when (not (eq face 'chartprog-in-progress))
          (setq chartprog-quote-symbol nil))))
    (if chartprog-quote-symbol
        (accept-process-output))))

;;;###autoload
(defun chart-quote-at-point ()
  "Show a quote in the message area for the Chart stock symbol at point."
  (interactive)
  (chart-quote (thing-at-point 'chart-symbol)))


;;-----------------------------------------------------------------------------
;; latest from elisp

(defvar chartprog-latest-record-calls nil
  "An internal part of chartprog.el.
This is a vector containing a list of Chart symbols (strings).
It's a list in vector, not just a list, so that this variable can
be let-bound to make nested recordings.")

(defvar chartprog-latest-cache
  (make-hash-table :test 'equal :weakness 'value)
  "An internal part of chartprog.el.
A hash table SYMBOL => LATEST-RECORD.
The key is a Chart symbol (a string).
The value is a latest record (a plist).")

(defun chartprog-latest-cache-remove (symbol-list)
  "An internal part of chartprog.el.
Remove all symbols of SYMBOL-LIST from the latest quotes cache."
  (dolist (symbol symbol-list)
    (remhash symbol chartprog-latest-cache)))


;; Autoload this safeness for the benefit of ses.el or similar checking
;; before chartprog.el loads.
;;;###autoload
(put 'chart-latest 'safe-function t)

;;;###autoload
(defun chart-latest (symbol &optional field scale)
  "Return the latest price for SYMBOL (a string) from Chart.
If there's no information available (an unknown symbol, not
online and nothing cached, etc) then return is nil.

This function can be used to get Chart prices in Lisp code.  It
reads the Chart database (using the chart subprocess) but does
not download anything.  Prices are cached so getting multiple
fields doesn't re-query the subprocess.  If using this function
in a SES spreadsheet then see `chart-ses-refresh' to download
prices for symbols used in the spreadsheet.

----
FIELD is a Lisp symbol for what data to return.  The default is
`last' which is the last traded price.  The possible FIELDs are
as follows.  Which ones actually have data depends on the data
source.

    name           string, or nil
    bid            \\=\\
    offer           |
    open            |  price, or nil
    high            |
    low             |
    last            |
    change         /
    quote-date     \ string like \"2012-12-31\", or nil
    last-date      /
    quote-time     \ string like \"16:59:59\", or nil
    last-time      /
    volume         number, or nil
    note           string, or nil

`name' is the stock or commodity name as a string, or nil.

`volume' is in whatever unit the stock or commodity uses, such as
number of shares or number of contracts.  Usually it's an integer
but could be quite large (automatically promoted to a flonum as
necessary).

Dates and times are in the timezone of the symbol.

`note' is a string with extra notes, like a note about
ex-dividend today or trading halted at limit up.  nil if no
notes.

SCALE is how many places to move the decimal point down.  For
example if SCALE is 2 then price 1.23 is returned as 123.  This
is good for working in cents when quotes are in dollars, etc."

  ;; FIXME: Umm, always flonums?
  ;; Prices are returned as flonums of the relevant currency, or if
  ;; the price is an integer then a fixnum.
  ;; If
  ;; prices have fractions of a cent they they might still be flonums.

  ;; In the distant past there was a `decimals' field which was how many
  ;; decimal places on prices.  Now always 0.
  ;;     decimals       integer
  ;; `decimals' is how many decimal places Chart uses for the
  ;; prices internally.  Internally prices are kept as an integer and
  ;; count of decimals.  Using this value for SCALE will ensure an
  ;; integer return.

  (unless (stringp symbol)
    (error "Not a Chart symbol (should be a string)"))
  (if chartprog-latest-record-calls
      (unless (member symbol (aref chartprog-latest-record-calls 0))
        (aset chartprog-latest-record-calls 0
              (cons symbol (aref chartprog-latest-record-calls 0)))))
  (unless field
    (setq field 'last))
  (let ((latest (gethash symbol chartprog-latest-cache)))
    (when (or (not latest)
              (plist-get latest 'dirty))
      ;; ses.el likes to run with inhibit-quit (to force atomic updates),
      ;; but accept-process-output doesn't like that.  with-local-quit here
      ;; will bail out, probably returning nil.
      (with-local-quit
        (setq latest (chartprog-exec-synchronous 'get-latest-record symbol))
        (puthash symbol latest chartprog-latest-cache)))

    (let ((value (plist-get latest field)))
      (when (and value
                 (memq field '(bid offer open high low last change)))
        (let ((factor (- (or scale 0) (plist-get latest 'decimals))))
          (if (/= 0 factor)
              (setq value (* value (expt (if (< factor 0) 10.0 10)
                                         factor))))))
      value)))


;;-----------------------------------------------------------------------------
;; ses.el additions

;;;###autoload
(defun chart-ses-refresh ()
  "Refresh Chart prices in a SES spreadsheet.
`ses-recalculate-all' is run first to find what `chart-latest'
prices are required.  Then quotes for those symbols are
downloaded and `ses-recalculate-all' run a second time to update
the spreadsheet with the new prices.

If the second `ses-recalculate-all' uses prices for further
symbols, perhaps due to tricky conditionals in spreadsheet
formulas, then another downloaded and `ses-recalculate-all' is
done.  This is repeated until all prices used in the recalculate
have been downloaded."

  (interactive)
  (let (fetched)
    (while (let ((record
                  (let ((chartprog-latest-record-calls (vector nil)))
                    (ses-recalculate-all)
                    (aref chartprog-latest-record-calls 0)))
                 want)
             (chartprog-debug-message "record calls %S" record)

             ;; want symbols not already fetched
             (dolist (symbol record)
               (unless (member symbol fetched)
                 (push symbol want)))

             (when want
               (chart-ses-refresh-download want)
               (setq fetched (nconc want fetched))
               t)))))

(defun chart-ses-refresh-download (symbol-list)
  "An internal part of chartprog.el.
Download the symbols (strings) in SYMBOL-LIST for a SES
spreadsheet update."
  (chartprog-with-temp-message (format "Downloading %d quote(s) ..."
                                       (length symbol-list))
    (chartprog-exec 'request-explicit symbol-list)
    (chartprog-latest-cache-remove symbol-list)

    (while symbol-list
      (accept-process-output)

      (dolist (symbol symbol-list)
        (unless (eq (chart-latest symbol 'face) 'chartprog-in-progress)
          (setq symbol-list (remove symbol symbol-list))
          (chartprog-debug-message "ses-refresh got " symbol))))))

;;-----------------------------------------------------------------------------

;; LocalWords: Customizations eg ie watchlist symlist symlists initializing
;; LocalWords: hscrolled hscrolling UTF minibuffer tooltip cl synchronize
;; LocalWords: col init chartprog

(provide 'chartprog)

;;; chartprog.el ends here
