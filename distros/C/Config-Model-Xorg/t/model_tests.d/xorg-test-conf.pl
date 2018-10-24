#
# This file is part of Config-Model-Xorg
#
# This software is Copyright (c) 2007-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

$conf_file_name = "xorg.conf" ;
$conf_dir = "etc/X11" ;
$model_to_test = "Xorg" ;

@tests = (
    { name => 'fglrx', },
    { name => 'modern', },
    { name => 'vesa', },
    { name => 'xorg', },
    { name => 'xorg-ati', },
);

1;
