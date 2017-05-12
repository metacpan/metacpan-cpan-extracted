use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(
	XMLSubsMatch => 'my:[\w\-]+',
	NoState => 1,
	UseStrict => 1,
	Debug => 0,
	XMLSubsPerlArgs => 'Off',
);

__END__

<% my $ref = { ok => 1, ref => \'data' } ; %>
<my:tag>
  <my:deeptag hello="<%= $ref->{ok} %>"/>
  <my:deeptag></my:deeptag>
</my:tag>
<my:returnok arg-break='3'
  onearg='1'>ok</my:returnok>
<my:args ok="<%= 1 %>" />
<my:args 
   ok="1"
   error="Multiline Arguments"
 />

<my:args ok="<%= $ref->{ok} %>" />
<my:args ok="1<%= $ref->{ok} %>"></my:args>

<my:tag_check_value value="<%= $ref %>" />
<my:tag_check_value value="<%= '' %><%= 1 %>" />
<my:tag_check_value value="<%= '' %><%= 1 %><%= '' %>" />
<my:tag_check_value_ref value="<%= $ref %>" />
<my:tag_check_value_ref value='<%= $ref->{ref} %>' />
<my:tag_check_value_not_ref value='<%= $ref->{ref} %> ' />
<my:tag_check_value_not_ref value='<%= $ref->{ref} %><%= $ref %>' />
<my:tag-check-value value="1" />

<my:deeptag />
<% $t->eok($Deep == 3, "Deep tag to call twice"); %>
<my:args 
   error="Multiline Arguments"
   ok="1"
></my:args>

