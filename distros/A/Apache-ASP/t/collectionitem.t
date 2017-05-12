use Apache::ASP::CGI;
&Apache::ASP::CGI::do_self('CollectionItem' => 1, 'NoState' => 0);

__END__

<% 
for('Form', 'QueryString') {
	# basic assignment & lookup
	my $self = $t->eok($Request->$_(), "no collection for $_ found");
	$Request->$_('test', 'value');
	$t->eok($self->{'test'} eq 'value', "count not set value");
	$t->eok($Request->$_('test')->Item() eq 'value', "could not fetch value");

#	$t->eok($Request->Form->('test')->Item() eq 'value', "could not fetch value");

	$Request->{$_}{'undef_test'} = undef;
	$t->eok(! defined $Request->$_('undef_test')->Item(), "could not have undef value");

	# array assignment & lookup
	$self->{'array'} = [1,0,2];
	my @values = $Request->$_('array');
	$t->eok(@values == 3, 'array block lookup test failed');

	my $value = $Request->$_('array');
	$t->eok($value->Item() == 1, 'array single lookup test failed');

	# Item syntax
	$t->eok($Request->$_()->Item('test')->Item() eq 'value', '$Collection->Item(key) lookup syntax');
	$Request->$_()->Item('test', 'value2');
	$t->eok($self->{'test'} eq 'value2', '$Collection->Item(key, value) assignment syntax');

	# Multi values & Count()/Item() testing
	$Request->{$_}{'multi'} = ['4','2','3'];
	my @items = $Request->$_('multi')->Item();
	$t->eok($Request->$_('multi')->Count == 3, 'Multiple values ->Count()');
	$t->eok($Request->$_('multi')->Item() == 4, 'First item of many, scalar context');
	$t->eok($items[1] == 2, 'Middle item of many, array context');
	# collection arrays start counting at 1?
	$t->eok($Request->$_('multi')->Item(1) == 4, 'Index access to multi Item()');

	# Null values & Count() & Item() testing
	$t->eok($Request->$_('NULL')->Count() == 0, 'NULL Item Count == 0');	
	$t->eok(! defined $Request->$_('NULL')->Item(), 'NULL Item returns NULL');	

	
}

$Application->{contents} = 1;
$t->eok($Application->Contents('contents'), '$Collection->Contents(key) lookup syntax');
%>

