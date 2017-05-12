use C::Include;
use hiew;
use vars qw/$inc $file $buffer/;
use strict;

$inc = new C::Include( \*DATA );

# Make struct instance
$file = $inc->make_struct('FILE');

# Fill struct fields
$$file{path} = '';
$$file{name} = $0;
$$file{links}[1]{linkname} = 'link to '.$0;
$$file{links}[1]{is_hard}  = 1;

# Pack struct to buffer
$buffer = $file->pack();

# Pack to buffer predefined array of structs
#$buffer .= $_->pack for @{ $include->{file} };

# Struct size
printf "Size of struct FILE: %d bytes\n",   $file->size;
printf "Size of unsigned long: %d bytes\n", $inc->sizeof('unsigned long');

# Print buffer to STDOUT
hiew( $buffer );


__DATA__
#define __MAXPATH 64

/* File object definition */
struct FILE{
    char path[__MAXPATH];
    char name[__MAXPATH];
    struct{
        char linkname[__MAXPATH];
        byte is_hard;
    }links[2];
}file[10];

/* Used in APP */
typedef struct                  
{
 word year;
 byte day;
 byte month;
} date;
