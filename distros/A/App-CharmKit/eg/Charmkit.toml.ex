# -*- mode:toml; -*-
#
# Example Charmkit.toml file for generating charms

name = "dokuwiki"
author = "Adam Stokes <adam.stokes@ubuntu.com>"
copyright_holder = Adam Stokes
copyright_year = 2016
license = MIT
version = 0.01

[Requirements]
App::Noise = ^0.1

[HooksToReadme]
# Generate Readme from charm hooks
only = hooks/install # generate only from hooks/install file

# Charm attached resources
# Will poll <cwd>/resources directory
[Resources]
sources = ['git://github.com/spaceman/wikicode.tgz']

# Charm Options
# parses config.yaml interpolating any variables
[@CharmOptions]
merge = LEFT

# Actions
# parses actions.yaml
[@CharmActions]
