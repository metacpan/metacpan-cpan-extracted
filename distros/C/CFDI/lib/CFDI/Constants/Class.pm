package CFDI::Constants::Class;
use strict;
our $VERSION = 0.3;

require Exporter;
our @EXPORT = qw(
  CONTENT 
  ELEMENT 
  TEXT 
  COMMENT 
  ATTRIBUTES
  DECLARATION 
  NAME 
  INSTRUCTION 
);
our @ISA = qw(Exporter);

use constant CONTENT => 1;
use constant ELEMENT => 3;
use constant TEXT => 4;
use constant COMMENT => 5;
use constant ATTRIBUTES => 6;
use constant DECLARATION => 7;
use constant NAME => 8;
use constant INSTRUCTION => 9;

1;