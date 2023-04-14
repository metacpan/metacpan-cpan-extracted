* documentation needs much work
* explain workflow on init?
* tests
* Other sub commands
  * refresh - reloads sub-commands (warns or removes non-accessible projects)
  * .
* Hooks?
  * Add a hook infrastructure / API
  * Why is that useful?
    * change the way files are managed? e.g. new ways of finding files
    * Other things could be useful to dynamically modify.
* Dynamic env?
* Session recording for restarts
    * When starting a session the session would be pushed to a list
    * when restarting sessions could be unshifted from list
    * Would work with both start and edit (stored globally and locally respecitvely)
    * Have a sub command to show the session list
    * Have a clear sub-command
