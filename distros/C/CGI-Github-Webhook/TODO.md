TODO for CGI::Github::Webhook
=============================

* Provide access methods to commonly used data inside the `POST`ed JSON.
* Adding support for "build passed/failed/errored" hooks to create e.g.
  buttons based on images made via [Shields.io](http://shields.io/).
* If the trigger script is backgrounded, there's not much more control
  over what happens afterwards. It would be nice if there was some
  hook to run after the trigger script has been run and which would
  check the trigger script's exit code to e.g. change the state badge.
* Provide some kind of locking to only run one instance of the trigger
  script or at least its final syncing.
* Use [Semantic Versioning](https://semver.org/) aka `breaking.feature.fix`.
* Make `secret` optional. That way, the webhook will also work with GitLab.
