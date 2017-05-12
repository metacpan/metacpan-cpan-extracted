2003-01-08 22:05  tfb

	* ChangeLog (1.32): changelog commit

2003-01-08 22:04  tfb

	* boot.lisp (1.22): Many changes to clean up IO functions and
	provide implementations for the emacs rep.
	
	This is still pretty broken.

2002-10-22 20:11  tfb

	* ChangeLog (1.31): changelog commit

2002-10-21 15:12  tfb

	* system-commands.lisp (1.7): Added stuff for `always last' and
	`always first' menus, which have weights > and < respectively.
	
	Added a browse documentation command which looks in a subdir called
	docs of *WELD-ROOT* for index.html, and points a browser at it if
	found.

2002-10-18 00:21  tfb

	* pkg.lisp (1.10), system-commands.lisp (1.6): General checkin of
	some improvements to the module tree drawing stuff.  This still
	needs some error handling for menus at the weld level, the module
	chaining stuff from NBS.  Then it is probably OK as a demo of NGDM
	1.2 (and the weld version should probably be bumped then too)

2002-08-16 21:14  tfb

	* ChangeLog (1.30): changelog commit (Weld 0.6)

2002-08-16 21:10  tfb

	* boot-expat.lisp (1.8), boot.lisp (1.21), component-structure.lisp
	(1.11), system-commands.lisp (1.5): Changes to allow variant cf
	read packages.	This changes the syntax of DECLARE-CF-READ-SYMBOLS
	and DECLARE-SHARED-CF-READ-SYMBOLS incompatibly, since they now
	need to be able to specify a package.  So this is Weld 0.6

2002-08-12 12:33  tfb

	* ChangeLog (1.29): changelog commit

2002-08-12 09:40  tfb

	* boot.lisp (1.20): Changes to various LOOPs to use a more
	idiosyncratic thing:	 (loop for (i . j) in x       ...)
	
	rather than
	
	    (loop for y in x
		  for (i . j) = y
		  ...)
	
	I don't know why I ever did the latter - I must have misunderstood
	destructuring in LOOP.

2002-08-08 21:04  tfb

	* boot.lisp (1.19), pkg.lisp (1.9): Make the various boot-location
	control things variables, and allow `fileless' booting if they are
	NIL.  This helps being a library as you can control where it boots
	better.

2002-08-07 19:32  tfb

	* ChangeLog (NGDM-POST-1_0.2): changelog commit

2002-08-07 19:21  tfb

	* boot.lisp (NGDM-POST-1_0.1): hosts-equal wildness fix from main
	branch

2002-08-06 20:06  tfb

	* ChangeLog (NGDM-POST-1_0.1): initial branch changelog commit

2002-07-31 11:39  tfb

	* ChangeLog (1.28): changelog commit

2002-07-31 11:36  tfb

	* boot.lisp (1.18): Fixed a problem which made it fail to boot
	(hosts-equal was getting :WILD) Added a couple of switches to
	enable backtracing during boot and to enable backtracing in the
	rep.

2002-07-31 10:57  tfb

	* ChangeLog (1.27): changelog commit

2002-07-31 10:53  tfb

	* boot-expat.lisp (1.7), boot.lisp (1.17), component-structure.lisp
	(1.10), pkg.lisp (1.8), session-cometh.lisp (1.3),
	system-commands.lisp (1.4): Grand package renaming: weld packages
	are now com.cley.weld.* Fixed a few bugs as well (why didn't these
	show up earlier?) this is weld 0.5 / ngdm 1.1 as it is not
	compatible with anything earlier

2002-07-30 13:15  tfb

	* pkg.lisp (1.7): Change all package definitions to use
	ORG.TFEB.CLC rather than CL.  This means that all packages now get
	the conduits version of DEFPACKAGE, and will not be compatible with
	anything earlier.  The tag LAST-OLD-PACKAGE-NAMES is the last
	NGDM-1.0 compatible version.

2002-07-19 14:09  tfb

	* ChangeLog (1.26): changelog commit

2002-07-18 19:22  tfb

	* boot.lisp (1.16): better hostery when looking for boot files
	(dotted names...)

2002-07-10 12:26  tfb

	* ChangeLog (1.25): changelog commit

2002-07-10 12:26  tfb

	* boot-expat.lisp (1.6): Unixify some more namestrings

2002-07-10 12:06  tfb

	* ChangeLog (1.24): changelog commit

2002-07-10 11:57  tfb

	* boot-expat.lisp (1.5), boot.lisp (1.15), component-structure.lisp
	(1.9), system-commands.lisp (1.3): Clean up progress notes (many
	but fairly trivial changes)

2002-07-08 21:12  tfb

	* ChangeLog (1.23): changelog commit

2002-07-08 21:06  tfb

	* boot.lisp (1.14): Support for setting boot location and root
	location - extra args to ENSURE-WELD-BOOT-STATE

2002-07-04 15:08  tfb

	* ChangeLog (1.22): changelog commit

2002-07-04 01:06  tfb

	* boot.lisp (1.13), pkg.lisp (1.6): Added DEBUG-PARAMETERS boot
	form, and corresponding hook.  Made the rep understand :backtrace t
	to mean `backtrace on error'

2002-06-28 17:01  tfb

	* session-cometh.lisp (1.2): Made it somewhat smarter about
	reporting the actual date of a module.

2002-06-20 05:02  tfb

	* ChangeLog (1.21): changelog commit

2002-06-20 04:05  tfb

	* boot-expat.lisp (1.4): Add listifying elts for weld.rc or ngdm.rc

2002-06-16 00:28  tfb

	* ChangeLog (1.20): changelog commit

2002-06-15 23:36  tfb

	* component-structure.lisp (1.8): unixify namestrings (I think this
	is right)

2002-06-15 23:26  tfb

	* component-structure.lisp (1.7): Added import cleaning (which was
	the original thing we wanted, sigh)

2002-06-15 23:08  tfb

	* component-structure.lisp (1.6): Changed CLEAN-COMPONENT to be
	more careful.
	
	Added CLEAN-MODULE.

2002-06-15 22:30  tfb

	* component-structure.lisp (1.5), pkg.lisp (1.5): CLEAN-COMPONENT

2002-06-15 22:30  tfb

	* system-commands.lisp (1.2): Added single-arg version

2002-06-15 17:24  tfb

	* pkg.lisp (1.4), sysdcl.lisp (1.5), system-commands.lisp (1.1):
	Add general-purpose system-command support, replacing the stuff CRS
	had and allowing anyone to execute named system commands.

2002-06-10 03:22  tfb

	* ChangeLog (1.19): changelog commit

2002-06-09 23:37  tfb

	* boot.lisp (1.12), pkg.lisp (1.3): New function,
	PROBE-WELD-BOOT-FILE, which lets us know if a boot file can be
	found.	This lets it tell if non-interactive booting is OK.

2002-06-08 23:52  tfb

	* ChangeLog (1.18): restructuring of modules, auto patching

2002-06-08 23:45  tfb

	* boot.lisp (1.11), session-cometh.lisp (1.1), sysdcl.lisp (1.4):
	Fairly large changes to the module structure: weld is now the
	substrate code (weld-low), together with session, application & rep
	code.  CRS and NBS can be loaded on top of this, and should be
	distributed as separate systems.
	
	Modules can now load patches for themselves, based on a patch tree
	corresponding to the module tree.

2002-06-08 00:04  tfb

	* ChangeLog (1.17): changelog commit

2002-06-07 23:55  tfb

	* sysdcl.lisp (1.3): A grand renaming of system names to be dotted
	and mostly hierarchical in the proper way.  See meta/Lisp-style

2002-06-06 22:27  tfb

	* ChangeLog (1.16): changelog commit

2002-06-04 17:57  tfb

	* component-structure.lisp (1.4): dump build parameters to a subdir
	of the stage root.

2002-06-02 12:44  tfb

	* ChangeLog (1.15): changelog commit

2002-06-02 12:33  tfb

	* ChangeLog (1.14), boot.lisp (1.10), component-structure.lisp
	(1.3), pkg.lisp (1.2), sysdcl.lisp (1.2): merge to MAIN from
	EXPERIMENTAL-NBS.
	
	This is merge 1 to MAIN
	
	Tags
	
		MAIN-PRE-1 on MAIN before merge
		MAIN-MERGE-1 on EXPERIMENTAL-NBS before merge
		MAIN-POST-1 on MAIN after merge

2002-05-30 14:08  tfb

	* ChangeLog (EXPERIMENTAL-NBS.4): changelog commit

2002-05-29 23:28  tfb

	* component-structure.lisp (EXPERIMENTAL-NBS.1): Optionalized some
	arguments (subdir) and changed stage -> build by default

2002-05-15 22:47  tfb

	* ChangeLog (EXPERIMENTAL-NBS.3): changelog commit

2002-05-15 15:23  tfb

	* boot.lisp (EXPERIMENTAL-NBS.1): Pervasive changes to module
	declarations - Anders pointed out they were buggy because they
	tried to ask for *compile-file-pathname* when it didn't exist.
	
	Made sure import directory exists before an import
	
	allowed :CONCRETE as well as :LEAF, and fixed a bug in featurized
	classes

2002-05-13 02:45  tfb

	* ChangeLog (EXPERIMENTAL-NBS.2): changelog commit

2002-05-13 01:37  tfb

	* ChangeLog (NGDM-POST-0_6.1): changelog commit

2002-05-05 22:02  tfb

	* ChangeLog (EXPERIMENTAL-NBS.1): changelog commit

2002-05-05 21:57  tfb

	* pkg.lisp, sysdcl.lisp (EXPERIMENTAL-NBS.[1,1]): Reworked system
	declarations: split them amongst the subsystems, and made the
	top-level sysdcl simply load all the subsys decls.
	
	Moved package definitions into per-system files.  Packages still
	use non-structured names though this is a step towards making them
	structured.

2002-05-05 21:57  tfb

	* pkg.lisp (1.1): file pkg.lisp was initially added on branch
	EXPERIMENTAL-NBS.

2002-05-05 21:57  tfb

	* sysdcl.lisp (1.1): file sysdcl.lisp was initially added on branch
	EXPERIMENTAL-NBS.

2002-05-05 21:06  tfb

	* ChangeLog (1.13): changelog commit

2002-05-04 16:26  tfb

	* component-structure.lisp (1.2): added submodule.def support.

2002-05-02 11:34  tfb

	* boot.lisp (1.9): Added an option to ENSURE-WELD-BOOT-STATE and
	its callees to allow specification of the file to boot from.  So
	
		(ensure-weld-boot-state :host :boot-file
	"/local/.../boot.def")
	
	will boot it to HOST from a given file.
	
	I'm not sure this is enough, since other things can cause it to
	boot,  As a way of getting around this there is also a NO-USER
	option, which says just to fake a user boot (don't actually read
	the weldrc).  So you can say
	
		(ensure-weld-boot-state :user :boot-file ... :no-user t)
	
	which will not read the user's weldrc, but will look like it has.

2002-03-22 11:53  tfb

	* ChangeLog (1.12): ChangeLog commit

2002-03-20 18:47  tfb

	* boot-expat.lisp (1.3): better expat connection noises

2002-03-18 15:06  tfb

	* ChangeLog (1.11): changelog commit

2002-03-18 15:03  tfb

	* boot.lisp (1.8): Merge nettest march 2002 changes to main branch

2002-03-13 11:25  tfb

	* boot.lisp (NETTEST-VISIT-MAR-2002.1): Changed all the
	DECLARE-MODULE forms to find the write date of the source file if
	possible, so that module information is a bit more informative and
	stable.  Maybe they should do this by default?

2002-03-09 22:22  tfb

	* ChangeLog (1.10): changelog commit

2002-03-09 22:19  tfb

	* boot.lisp (1.7): Changes to support code loading at boot time:
	moved the careful file loading stuff from CRS into PATCH, and added
	handlers to boot.lisp.

2002-03-08 22:43  tfb

	* ChangeLog (1.9): changelog commit

2002-03-08 22:34  tfb

	* boot-expat.lisp (1.2): Made expat connectery actually work

2002-03-07 12:54  tfb

	* boot-expat.lisp (1.1), boot.lisp (1.6): added the boot-expat
	file, and removed the expat stuff from the main boot file

2002-03-06 15:19  tfb

	* ChangeLog (1.8): changelog commit

2002-03-05 13:57  tfb

	* .cvsignore (1.2): added *.wfasl to .cvsignores

2002-03-05 11:10  tfb

	* boot.lisp (1.5): Added declarations / definitions (which should
	it be?) of suitable listifying XML elements for boot.def,
	module.def, component.def, eo.def

2002-02-26 20:13  tfb

	* ChangeLog (1.7): changelog commit

2002-02-26 20:12  tfb

	* boot.lisp (1.4): declared some module names

2002-02-24 22:09  tfb

	* ChangeLog (1.6): changelog commit

2002-02-24 21:53  tfb

	* boot.lisp (1.3): changes to new hook definition format (with
	arglist).

2002-02-24 17:35  tfb

	* ChangeLog (1.5): changelog commit

2002-02-24 17:35  tfb

	* .cvsignore (1.1): added .cvsignore to all src dirs - it seems to
	be an artifact of the cygwin cvs client that .cvsignore works in
	subdirs.

2002-02-23 02:41  tfb

	* ChangeLog (1.4): changelog commit

2002-02-23 02:37  tfb

	* boot.lisp (1.2): added new feature: COM.CLEY.WELD/NGDM which
	means `this version of weld is eing compiled as NGDM'. 
	Conditionalised the boot location and rc file names based on this
	feature.

2002-02-21 23:19  tfb

	* ChangeLog (1.3): another commit, this one should be stable I hope
	(or nearly)

2002-02-21 23:12  tfb

	* ChangeLog (1.2): changelogs update

2002-02-21 23:11  tfb

	* ChangeLog (1.1): changelogs

2002-02-14 14:23  tfb

	* boot.lisp (1.1), component-structure.lisp (1.1): Initial revision

2002-02-14 14:23  tfb

	* boot.lisp (1.1.1.1), component-structure.lisp (1.1.1.1): initial
	import of WELD (ex NGDM)

