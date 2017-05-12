# App::AllMyChangesUtils

This is repo with several scripts that create data files that can be imported
to the site https://allmychanges.com

## How to install `amch` script

The site https://allmychanges.com has special script `amch` that can export &
import data. [Official repo](https://github.com/svetlyak40wt/allmychanges).

To install script `amch` you should run:

    pip install allmychanges

Then you should create config file `allmychanges.cfg` **in the directory where
you will run `amch`**. The token you can take at https://allmychanges.com/account/token/

    [allmychanges]
    token = MY-SECRET-TOKEN

You can check if your installation works by running `amch export`. It should
output all your data to the STDOUT.

## How to use scripts from this repo

    ./bin/get_github_favorites bessarabov > list

It will create file `list` with all git repos user `bessarabov` have
favourited at GitHub. The file is created in the special format that
can be parsed by `amch` script. To load all that data to the site
https://allmychanges.com you should run:

    cat list | amch import
