perl-minlint-mode
====================

To use `perl-minlint-mode`, please load `subdirs.el` in this directory.
It will setup `load-path`, `cperl-mode-hook` and `autoload`.

For now, recommended way to install perl-minlint-mode is

```sh
#
# This assumes you have ~/bin in your $PATH
#
cd ~/bin
git clone https://github.com/hkoba/app-perlminlint.git
ln -s app-perlminlint/script/perlminlint .

#
# This assumes you use ~/.emacs.d/init.el (rather than ~/.emacs)
#
cd ~/.emacs.d
ln -s ../app-perlminlint/elisp perlminlint
```

Then you can setup perl-minlint-mode by adding
`(load "~/.emacs.d/perlminlint/subdirs")`
to your `~/.emacs.d/init.el`.

Alternatively, you can load **all** `subdirs.el` under `~/.emacs.d`
by adding following snippet in init.el:

```lisp
;;
;; Load all "*/subdirs.el" under this-dir.
;;
(let ((load-all-subdirs
       (lambda (this-dir)
         (let (fn err (default-directory this-dir))
           (dolist (file (cdr (cdr (directory-files this-dir))))
             (setq fn (concat (file-name-as-directory file) "subdirs.el"))
             (if (and (file-directory-p file)
                      (file-exists-p fn))
                 (condition-case err
                     (load fn)
                   (error
                    (message "Can't load %s: %s" fn err)))
               (message "load-all-subdirs: skipped %s" file)))))))
  (funcall load-all-subdirs
           (or (and load-file-name (file-name-directory load-file-name))
               default-directory)))
```

Tramp support
--------------------

perl-minlint-mode supports
[tramp](http://www.emacswiki.org/emacs/TrampMode).
To use perl-minlint-mode via tramp, you first need to install
perlminlint script on your remote machine, like above.

If perl-minlint-mode fails to find your `perlminlint` script 
even after successful installation, you may need to set 
`tramp-remote-path` properly
(but this doesn't work for me, honestly :-<).
Alternatively, you can explicitly specify host-specific path for 
perlminlint executable via `perl-minlint-script-for-tramp-host-alist`
like following:

```lisp
(eval-after-load "perl-minlint"
  '(progn
     (add-to-list 'perl-minlint-script-for-tramp-host-alist
		  '("myserver" . "~/bin/perlminlint"))))
```
