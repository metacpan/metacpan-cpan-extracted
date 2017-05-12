package DCE::test;
require DCE::Status;	

use vars qw(@ISA @EXPORT $TRACE);
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(test trace dump_hash dump_inc password_prompt);

sub test {
    my($num,$status) = @_;
    my $msg = DCE::Status::error_string($status);
    print($status == 0 ? "ok $num\n" : "not ok $num $msg\n");
}

sub trace {
    return unless $ENV{DCE_PERL_TRACE} || $TRACE;
    print STDERR @_;
}

sub dump_hash {
    my($hash,$n) = @_;
    my($key);
    foreach $key (keys %$hash) {
	if(ref $hash->{$key}) {
	    trace "$key =>\n";
	    dump_hash($hash->{$key},1);
	}
	else {
	    trace "   " x $n if $n;
	    trace "$key = $hash->{$key}\n";
	}
    } 
}

sub dump_inc {
   join '', map { "$_ = $INC{$_}\n" } sort keys %INC;
}

sub password_prompt {
    my $pwd;
    print "Enter your password: ";
    system stty => '-echo';
    chomp($pwd = <STDIN>);
    system stty => 'echo';
    $pwd;
}

__END__
