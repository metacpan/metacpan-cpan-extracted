# Fatchapter theme - add decorative border lines around h1 headings
pass_md+=(--cm 'h1=+;sub{"#\n$_\n#"}')
# The added lines would put the folding of --refill off: turn off the
# default, but not the option given on the command line
default[refill]=
