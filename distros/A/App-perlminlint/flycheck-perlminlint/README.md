Flycheck support
====================

After you successfully installed perlminlint, you can also use it
from [Flycheck](http://flycheck.readthedocs.org/en/latest/index.html)
in cperl-mode. 

Note: This flycheck support restricts 
the check events only to `save`, because without having real (saved) file
many perl checking doesn't work properly.


Installation
--------------------

To use perlminlint from flycheck, you have 2 options:

* Just copy contents of [subdirs.el] into your `~/.emacs.d/init.el`
* Alternatively, you can put a symlink of this `flycheck-perlminlint`
directory under `~/.emacs.d` and
load [subdirs.el] by adding following snippet, which will load all
`~/.emacs.d/*/subdirs.el`, in init.el:

```lisp
;;
;; Load all "*/subdirs.el" under this-dir. Put this in ~/.emacs.d/init.el
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

[subdirs.el]: subdirs.el
