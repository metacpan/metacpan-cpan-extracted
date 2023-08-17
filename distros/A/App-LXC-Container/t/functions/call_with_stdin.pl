#!/bin/false
# not to be used stand-alone
#
# helper function to reassign STDIN:

sub _call_with_stdin($$)
{
    my ($stdin_text, $function) = @_;
    my $orgin = undef;
    open $orgin, '<&', \*STDIN  or  die "can't duplicate STDIN\n";
    close STDIN;
    $stdin_text = join("\n", @$stdin_text, '')  if  ref($stdin_text) eq 'ARRAY';
    open STDIN, '<', \$stdin_text  or  die "can't reassign STDIN\n";
    &$function();
    close STDIN;
    open STDIN, '<&', $orgin  or  die "can't restore STDIN\n";
}

1;
