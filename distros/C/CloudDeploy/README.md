# CloudDeploy

This repo has all the code needed to work with your CloudDeploy deployments.

## Bootstrapping (1st time use)

The project uses Carton to handle dependencies. You can set up your environment using
the default `bootstrap` target:

```shell
make
```

The first time this can take quite a long time, so relax and go grab a coffee.

The default target also includes the following targets (cdinit / installdeps)

## Environment setup

To use the clouddeploy scripts you need to set up your environment. You can easily
generate a file that you can store anywhere.

Everytime you want to use the scripts you will have to copy and paste the commands
from the file.

```shell
make cdinit
```

It will ask for git authoring information (full name and email).

## Bash completion 

You can use `make` to generate/refresh bash completion file. It is recommended that you do this once in a while.
```shell
make bash_completion
```

## Refresh carton modules

You can use `make` to update cartonized local modules. It is recommended that you do this once in a while.
```shell
make installdeps
```

## Script reference

[refresh-customer-projects](script/refresh-customer-projects) is a script that will
help to maintain the customer infrastructure repositories. It will clone new
repositories you don't have and will update any project you already have cloned.

It takes care if you are not in the master branch or if you have uncommited changes.

It also tracks possible stale repositories you might have.
