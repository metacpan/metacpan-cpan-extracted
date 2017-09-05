#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use C::Tokenize 'strip_comments';
my $json =<<EOF;
{
/* Comment comment comment */
"/* not comment */":"/* not comment */",
"value":["//not comment"] // Comment
}
EOF
print strip_comments ($json);
