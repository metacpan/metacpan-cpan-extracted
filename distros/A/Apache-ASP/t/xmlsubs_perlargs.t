use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self(
	XMLSubsMatch => 'my:\w+',
	NoState => 1,
	UseStrict => 1,
	Debug => 3,
#	XMLSubsPerlArgs => 1,
);

__END__

<% my $ref = { ok => 1 } ; %>
<my:tag>
  <my:deeptag hello="1"/>
  <my:deeptag></my:deeptag>
</my:tag>
<my:returnok arg-break=3
  onearg=1>ok</my:returnok>
<my:args ok=1 />
<my:args 
   ok=1
   error="Multiline Arguments"
 />

=pod
<my:args ok="$ref->{ok}" />
<my:args ok="$ref->{ok}"></my:args>
=cut

<my:deeptag />
<% $t->eok($Deep == 3, "Deep tag to call twice"); %>
<my:args 
   error="Multiline Arguments"
   ok=1
></my:args>

=pod
<my:args ok={ 1 => 2}/>
<my:args ok="$ref->{ok}"
	 />
=cut
