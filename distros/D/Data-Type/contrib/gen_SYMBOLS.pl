#!/usr/bin/perl

# (c) 2004 by Murat Uenalan. All rights reserved. Note: This program is
# free software; you can redistribute it and/or modify it under the same
# terms as perl itself

#chdir('..');

print qx{grep -h -E "^\s*package" Type.pm.tmpl Type/*.tmpl Type/Collection/*.tmpl |sort -u > SYMBOLS}

