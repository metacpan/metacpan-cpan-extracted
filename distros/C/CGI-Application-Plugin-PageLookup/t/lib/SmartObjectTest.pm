package SmartObjectTest;

sub new {
	my $class = shift;
        my $cgiapp = shift;
        my $page_id = shift;
        my $template = shift;
	my $name = shift;
        my $o =  "$page_id|$name|".($template->query(name=>'home'));
	bless \$o, $class;
	return \$o;
}

sub AUTOLOAD {
        my $self = shift;
        my $p = $AUTOLOAD;
	my @p = split(/::/,$p);
        return "$$self|".(pop @p);
}

sub can {
	return 1;
}

sub jump {
	my $self = shift;
	$$self =~ /^(\w\w)\//;
	my $lang = $1;
	my %a = (en=>'Just when you thought you had got the pattern: jump', de=>'Gerade als Sie dachten, Sie hatten das Muster gehabt:  Sprung');
	return $a{$lang};
}


sub DESTROY {
}

1
