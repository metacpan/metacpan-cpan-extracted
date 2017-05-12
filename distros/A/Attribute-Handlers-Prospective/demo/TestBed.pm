package TestBed;

$DB::single = 1;

use Attribute::Handlers::Prospective;

use Data::Dumper 'Dumper';

sub Attr : ATTR(CODE) {
	print 'Attr: ', Dumper \@_;
}

sub VarAttr : ATTR(CHECK,RUN,VAR) {
	tie ${$_[2]}, Loud;
}

sub Another_Attr : ATTR(ANY,RAWDATA) {
	print 'Another_Attr: ', Dumper \@_;
}

sub AUTOATTR : ATTR {
	print 'Default attribute handler: ', Dumper \@_;
}

sub PREATTR: ATTR {
 	use Data::Dumper 'Dumper';
 	print "Pre: ", Dumper [ \@_ ];
}
 
sub POSTATTR: ATTR {
 	use Data::Dumper 'Dumper';
	print "Post: ", Dumper [ \@_ ];
}

package Loud;

sub TIESCALAR { bless {} }

sub STORE { print "<<<STORING $_[1]>>>\n" ; $_[0]{val} = $_[1] }
sub FETCH { print "<<<FETCHING>>>\n"; $_[0]{val} }

1;

sub Ly: ATTR {}
