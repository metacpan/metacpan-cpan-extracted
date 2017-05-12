use Apache::ASP::CGI;

$SIG{__WARN__} = \&Carp::cluck;
local $^W = 1;
&Apache::ASP::CGI::do_self('NoState' => 1, Debug => 0, UseStrict => 0);

__END__

<% use lib '.';	use T;	$t =T->new(); %>

<% for my $temp ( 1..2 ) { %>
  <% 
    $Response->Debug("writing temp include piece of $temp");
    open(PIECE, ">include_change_piece.inc_temp");
    print PIECE $temp;
    close PIECE;
    sleep 1;
     
    for my $type ( qw( inline dynamic inline dynamic ) ) {  
      $Response->Debug("--- temp: $temp, type: $type");
      my $out = $Response->TrapInclude($type."_include_change.inc");
      $$out =~ s/\s+$//isg;
      $t->eok(($$out eq $temp), "Failed to match output of $$out to expected $temp for type: $type");
      $Response->Debug("--- output: $$out");
    }
  %>
<% } %>
<% 
  $t->eok($Server->{asp}{parse_file_count} == 6, "parse_file_count check failed");
  $t->eok($Server->{asp}{parse_inline_count} == 2, "parse_inline_count check failed");
%>
