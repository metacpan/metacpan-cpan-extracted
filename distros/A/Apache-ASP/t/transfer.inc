
<% 
 $t->eok($0 =~ /transfer\.inc$/ ? 1 : 0, "\$0 is not correct: $0");
 $Server->Transfer({ File => 'transfer2.inc' });
 die("should never get here");
%>
