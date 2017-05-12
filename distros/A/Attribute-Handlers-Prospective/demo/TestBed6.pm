package TestBed6;

$DB::single = 1;

use Attribute::Handlers::Prospective 'Perl6';

use Data::Dumper 'Dumper';

sub UNIVERSAL::Attr is ATTR(CODE) {
	print 'Attr: ', Dumper \@_;
}

sub UNIVERSAL::VarAttr is ATTR(CHECK,RUN,VAR) {
	tie ${$_[2]}, Loud;
}

sub UNIVERSAL::Another_Attr is ATTR(ANY) {
	print 'Another_Attr: ', Dumper \@_;
}


package Loud;

sub TIESCALAR { bless {} }

sub STORE { print "<<<STORING $_[1]>>>\n" ; $_[0]{val} = $_[1] }
sub FETCH { print "<<<FETCHING>>>\n"; $_[0]{val} }

1;
