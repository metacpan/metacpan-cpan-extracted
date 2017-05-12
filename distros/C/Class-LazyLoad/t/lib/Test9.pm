package Test9;

sub new
{
	return bless({}, 'Class::LazyLoad');
}

sub hello 
{
	return "hello";
}

1;
__END__
